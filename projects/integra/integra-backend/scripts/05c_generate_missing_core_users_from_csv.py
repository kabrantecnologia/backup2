import os
import re
import uuid
import logging
from datetime import datetime
import pandas as pd
from unidecode import unidecode

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, 'legado', 'dados-legados', 'claudinei', 'EMPREGADOS.XLSX - Funcionários TI.csv')
SQL_9010 = os.path.join(BASE_DIR, 'legado-migration', '9010_migration_pessoal_funcio.sql')
SQL_9020 = os.path.join(BASE_DIR, 'legado-migration', '9020_migration_core_users.sql')
OUT_SQL = os.path.join(BASE_DIR, 'legado-migration', '9022_migration_core_users_from_csv.sql')
LOG_DIR = os.path.join(BASE_DIR, 'scripts', 'logs')

DEFAULT_PASSWORD = 'Mudar@1234'


def normalize_name(s: str) -> str:
    return unidecode(str(s)).strip().upper() if isinstance(s, str) else ''


def load_csv_name_email(csv_path: str) -> dict:
    try:
        df = pd.read_csv(csv_path, header=None, names=['name','email','role'], encoding='utf-8')
    except UnicodeDecodeError:
        df = pd.read_csv(csv_path, header=None, names=['name','email','role'], encoding='latin1')
    name_email = {}
    for _, r in df.iterrows():
        name = normalize_name(r['name']) if pd.notna(r['name']) else ''
        email = (str(r['email']).strip().lower() if pd.notna(r['email']) else '')
        if name and email:
            name_email[name] = email
    return name_email


def load_core_people(sql_path: str) -> dict:
    # person_id -> name_norm
    person_regex = re.compile(r"INSERT INTO public\.core_people \(id, name, type\) VALUES \('([a-f0-9\-]+)', '([^']*)', 'individual'\);")
    with open(sql_path, 'r', encoding='utf-8') as f:
        content = f.read()
    mapping = {}
    for pid, name in person_regex.findall(content):
        mapping[pid] = normalize_name(name)
    return mapping


def load_core_users_person_ids(sql_path: str) -> set:
    link_regex = re.compile(r"INSERT INTO public\.core_users \(id, person_id\) VALUES \('[a-f0-9\-]+', '([a-f0-9\-]+)'\);")
    s = set()
    with open(sql_path, 'r', encoding='utf-8') as f:
        for line in f:
            m = link_regex.search(line)
            if m:
                s.add(m.group(1))
    return s


def main():
    os.makedirs(LOG_DIR, exist_ok=True)
    logging.basicConfig(level=logging.INFO, format='%(message)s')

    if not (os.path.exists(CSV_PATH) and os.path.exists(SQL_9010) and os.path.exists(SQL_9020)):
        logging.error('Arquivos necessários não encontrados.')
        return

    name_email = load_csv_name_email(CSV_PATH)  # name_norm -> email
    people_map = load_core_people(SQL_9010)     # person_id -> name_norm

    # Index people by name
    people_by_name = {}
    for pid, n in people_map.items():
        people_by_name.setdefault(n, []).append(pid)

    existing_person_ids = load_core_users_person_ids(SQL_9020)

    # Determine candidate person_ids to create users for: names present in CSV & 9010 but missing in 9020
    candidates = []  # (person_id, name_norm, email)
    skipped_ambiguous = []  # names with >1 person_id
    skipped_no_email = []   # names without email in CSV

    for name_norm, email in name_email.items():
        pids = people_by_name.get(name_norm, [])
        if not pids:
            continue  # not in 9010
        if len(pids) > 1:
            skipped_ambiguous.append(name_norm)
            continue
        pid = pids[0]
        if pid in existing_person_ids:
            continue  # already has core_user
        if not email or '@' not in email:
            skipped_no_email.append(name_norm)
            continue
        candidates.append((pid, name_norm, email))

    created = 0
    with open(OUT_SQL, 'w', encoding='utf-8') as f:
        f.write("-- Create/link users for CSV names present in core_people (9010) but absent in core_users (9020)\n")
        f.write("-- Idempotent: reuses existing auth.users by email (case-insensitive) and ensures core_users link.\n\n")
        for pid, name_norm, email in candidates:
            gen_user_id = str(uuid.uuid4())
            safe_email = email.replace("'", "''")
            raw_app_meta_data = '{ "provider":"email", "providers":["email"] }'
            raw_user_meta_data = '{}'
            f.write("DO $$\n")
            f.write("DECLARE\n")
            f.write("  v_user_id uuid;\n")
            f.write("  v_existing_person uuid;\n")
            f.write("BEGIN\n")
            # Find existing user by email (case-insensitive)
            f.write(
                f"  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('{safe_email}') LIMIT 1;\n"
            )
            # Insert if missing
            f.write("  IF v_user_id IS NULL THEN\n")
            f.write(f"    v_user_id := '{gen_user_id}';\n")
            f.write(
                "    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) "
                f"VALUES (v_user_id, 'authenticated', 'authenticated', '{safe_email}', crypt('{DEFAULT_PASSWORD}', gen_salt('bf')), NOW(), NULL, NULL, '{raw_app_meta_data}', '{raw_user_meta_data}', NOW(), NOW());\n"
            )
            f.write("  END IF;\n")
            # Ensure core_users link
            f.write(
                "  SELECT person_id INTO v_existing_person FROM public.core_users WHERE id = v_user_id;\n"
            )
            f.write("  IF v_existing_person IS NULL THEN\n")
            f.write(
                f"    INSERT INTO public.core_users (id, person_id) VALUES (v_user_id, '{pid}');\n"
            )
            f.write("  ELSIF v_existing_person <> '" + pid + "' THEN\n")
            f.write(
                f"    RAISE NOTICE 'User % already linked to person %; expected %', v_user_id, v_existing_person, '{pid}';\n"
            )
            f.write("  END IF;\n")
            f.write("END$$;\n\n")
        f.write("-- End\n")
        created = len(candidates)

    # Log summary
    summary_path = os.path.join(LOG_DIR, '9022_generation_summary.log')
    with open(summary_path, 'w', encoding='utf-8') as lf:
        lf.write(f"Candidatos gerados: {created}\n")
        lf.write(f"Ignorados por ambiguidade de person_id: {len(skipped_ambiguous)}\n")
        for n in skipped_ambiguous:
            lf.write(f"AMBIGUO: {n}\n")
        lf.write(f"Ignorados sem email válido: {len(skipped_no_email)}\n")
        for n in skipped_no_email:
            lf.write(f"SEM_EMAIL: {n}\n")

    logging.info('Arquivo SQL gerado: %s', OUT_SQL)
    logging.info('Resumo salvo em: %s', summary_path)
    logging.info('Candidatos criados: %d | Ambíguos: %d | Sem email: %d', created, len(skipped_ambiguous), len(skipped_no_email))


if __name__ == '__main__':
    main()
