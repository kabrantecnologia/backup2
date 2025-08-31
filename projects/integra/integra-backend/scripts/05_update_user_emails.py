import os
import re
import csv
import logging
from datetime import datetime
from unidecode import unidecode
import pandas as pd
try:
    from rapidfuzz import fuzz
except Exception:  # optional dependency
    fuzz = None

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LEGADO_DATA_DIR = os.path.join(BASE_DIR, 'legado', 'dados-legados')
LEGADO_MIG_DIR = os.path.join(BASE_DIR, 'legado-migration')
LOG_DIR = os.path.join(BASE_DIR, 'scripts', 'logs')

# Inputs
EMPLOYEE_CSV = os.path.join(
    BASE_DIR,
    'legado', 'dados-legados', 'claudinei',
    'EMPREGADOS.XLSX - Funcionários TI.csv'
)
# Prior migration outputs
PEOPLE_MIGS_GLOB_DIR = LEGADO_MIG_DIR  # scan for core_people inserts across files here
USERS_CORE_MIG_SQL = os.path.join(LEGADO_MIG_DIR, '9020_migration_core_users.sql')

# Output
OUTPUT_SQL_FILE = os.path.join(LEGADO_MIG_DIR, '9021_migration_insert_user_emails.sql')

# Filters
BLOCKLIST_WORDS = set([
    'RH','TI','FINANCEIRO','DEPARTAMENTO','COORD','SUPORTE','ADM','DIRETORIA',
    'MANUTENCAO','ALMOXARIFADO','PATRIMONIAL','MARKETING','NUTRICAO','ODONTOLOGIA',
    'BAZAR','TRANSPORTE','CONTROLADORIA','GERÊNCIA','DIRETOR','DIRETORA','CONFERÊNCIA'
])


def normalize_name(name: str) -> str:
    if not isinstance(name, str) or not name.strip():
        return ''
    return unidecode(name).strip().upper()


def tokenize(name_norm: str) -> set:
    """Tokenize a normalized name into distinct words (letters/digits only)."""
    if not name_norm:
        return set()
    # Keep alnum and spaces only, split, remove empty
    cleaned = re.sub(r"[^A-Z0-9\s]", " ", name_norm)
    return set(t for t in cleaned.split() if t)


def load_people_from_migrations(migs_dir: str) -> dict:
    """Parse migration .sql files to extract person_id -> normalized name for individual people."""
    person_regex = re.compile(r"INSERT INTO public\.core_people \(id, name, type\) VALUES \('([a-f0-9\-]+)', '([^']*)', 'individual'\);")
    mapping = {}  # person_id -> normalized_name
    for fname in os.listdir(migs_dir):
        if not fname.endswith('.sql'):
            continue
        fpath = os.path.join(migs_dir, fname)
        try:
            with open(fpath, 'r', encoding='utf-8') as f:
                content = f.read()
            for person_id, name in person_regex.findall(content):
                mapping[person_id] = normalize_name(name)
        except Exception as e:
            logging.warning(f"Falha ao ler {fpath}: {e}")
    return mapping


def load_core_user_link(sql_file: str) -> dict:
    """Parse 9020 migration to map person_id -> auth_user_id created there."""
    link_regex = re.compile(r"INSERT INTO public\.core_users \(id, person_id\) VALUES \('([a-f0-9\-]+)', '([a-f0-9\-]+)'\);")
    link = {}
    try:
        with open(sql_file, 'r', encoding='utf-8') as f:
            for line in f:
                m = link_regex.search(line)
                if m:
                    auth_user_id, person_id = m.group(1), m.group(2)
                    link[person_id] = auth_user_id
    except FileNotFoundError:
        logging.critical(f"Arquivo não encontrado: {sql_file}. Certifique-se de executar primeiro o 02_process_users.py para gerar 9020.")
        raise
    return link


def should_filter(name_norm: str) -> bool:
    if not name_norm or len(name_norm) < 4:
        return True
    words = set(name_norm.split())
    if words & BLOCKLIST_WORDS:
        return True
    return False


def read_employee_csv(path: str) -> list:
    """Reads the employees CSV. Expected columns: name, email, role (comma-separated)."""
    rows = []
    # Try pandas for robustness with UTF-8
    try:
        df = pd.read_csv(path, header=None, names=['name','email','role'], encoding='utf-8')
    except UnicodeDecodeError:
        df = pd.read_csv(path, header=None, names=['name','email','role'], encoding='latin1')
    for _, r in df.iterrows():
        name = str(r['name']).strip() if pd.notna(r['name']) else ''
        email = str(r['email']).strip().lower() if pd.notna(r['email']) else ''
        role = str(r['role']).strip() if pd.notna(r['role']) else ''
        rows.append({'name': name, 'email': email, 'role': role, 'name_norm': normalize_name(name)})
    return rows


def derive_name_from_email(email: str) -> str:
    """Derive a best-effort name from the email local-part."""
    try:
        local = email.split('@', 1)[0]
    except Exception:
        return ''
    # Replace separators with spaces
    local = re.sub(r"[._-]+", " ", local)
    # Remove non-letters (keep digits rarely makes sense in names)
    local = re.sub(r"[^a-zA-Z\s]", " ", local)
    # Title case then normalize to keep consistency with people names
    return normalize_name(local)


def pick_unique_best(candidates: list) -> str | None:
    """Return the sole candidate if unique; otherwise None."""
    uniq = list(set(candidates))
    if len(uniq) == 1:
        return uniq[0]
    return None


def match_person_id(name_norm: str, email: str, people_map: dict, name_to_person: dict,
                    people_tokens: dict, people_by_token: dict, logger: logging.Logger) -> tuple[str | None, str]:
    """Try multiple matching strategies to find a person_id.

    Returns: (person_id or None, reason string)
    """
    # 1) Exact name match
    pid = name_to_person.get(name_norm)
    if pid:
        return pid, 'exact_name'

    # 2) Name derived from email local-part (exact)
    if email:
        email_name = derive_name_from_email(email)
        if email_name:
            pid2 = name_to_person.get(email_name)
            if pid2:
                return pid2, 'email_local_exact'

    # 3) Token-overlap containment (unique)
    tokens = tokenize(name_norm)
    if tokens:
        candidate_pids = set()
        for t in tokens:
            for pid3 in people_by_token.get(t, []):
                candidate_pids.add(pid3)
        # Score by Jaccard overlap of tokens
        scored = []
        for pid3 in candidate_pids:
            ptoks = people_tokens.get(pid3, set())
            if not ptoks:
                continue
            inter = len(tokens & ptoks)
            union = len(tokens | ptoks)
            score = inter / union if union else 0.0
            if score >= 0.8 or (inter >= 2 and inter == min(len(tokens), len(ptoks))):
                scored.append((score, pid3))
        scored.sort(reverse=True)
        if scored:
            top_score = scored[0][0]
            top = [pid3 for s, pid3 in scored if s == top_score]
            if len(top) == 1:
                return top[0], f'token_overlap:{top_score:.2f}'

    # 4) Fuzzy last-resort (only if rapidfuzz is available)
    if fuzz is not None and name_norm:
        best_pid = None
        best_ratio = 0
        for pid4, pname in people_map.items():
            if not pname:
                continue
            ratio = fuzz.token_set_ratio(name_norm, pname)
            if ratio > best_ratio:
                best_ratio = ratio
                best_pid = pid4
        if best_pid and best_ratio >= 92:  # conservative threshold
            return best_pid, f'fuzzy:{best_ratio}'

    return None, 'no_unique_match'


def main():
    os.makedirs(LOG_DIR, exist_ok=True)
    log_filename = f"email_update_{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.log"
    log_filepath = os.path.join(LOG_DIR, log_filename)
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_filepath, mode='w', encoding='utf-8'),
            logging.StreamHandler()
        ]
    )

    logging.info('--- INICIANDO ATUALIZAÇÃO DE EMAILS DOS USUÁRIOS ---')

    if not os.path.exists(EMPLOYEE_CSV):
        logging.critical(f"CSV de funcionários não encontrado: {EMPLOYEE_CSV}")
        return

    # Load prior migrations
    people_map = load_people_from_migrations(PEOPLE_MIGS_GLOB_DIR)  # person_id -> name_norm
    if not people_map:
        logging.critical("Nenhuma pessoa encontrada nos arquivos de migração (core_people). Abortando.")
        return
    # Build name_norm -> person_id (prefer 1:1) and token indexes
    name_to_person = {}
    people_tokens = {}
    people_by_token: dict[str, list] = {}
    for pid, n in people_map.items():
        if not n:
            continue
        if n not in name_to_person:
            name_to_person[n] = pid
        toks = tokenize(n)
        people_tokens[pid] = toks
        for t in toks:
            people_by_token.setdefault(t, []).append(pid)

    person_to_user = load_core_user_link(USERS_CORE_MIG_SQL)  # person_id -> auth_user_id
    if not person_to_user:
        logging.critical("Nenhuma ligação person_id -> user_id encontrada no 9020. Abortando.")
        return

    # Read employees
    employees = read_employee_csv(EMPLOYEE_CSV)
    total = len(employees)
    logging.info(f"Lidos {total} funcionários do CSV.")

    updates = []
    matched = 0
    filtered = 0
    no_match = []

    for emp in employees:
        name_norm = emp['name_norm']
        email = emp['email']

        if should_filter(name_norm):
            filtered += 1
            continue
        if not email or '@' not in email:
            no_match.append((emp['name'], 'email inválido'))
            continue

        # Try multi-strategy matching
        person_id, reason = match_person_id(name_norm, email, people_map, name_to_person,
                                            people_tokens, people_by_token, logging)
        if not person_id:
            no_match.append((emp['name'], reason))
            continue

        user_id = person_to_user.get(person_id)
        if not user_id:
            no_match.append((emp['name'], 'sem user vinculado'))
            continue

        # Prepare update for auth.users.email
        safe_email = email.replace("'", "''")
        updates.append(f"UPDATE auth.users SET email='{safe_email}' WHERE id='{user_id}';")
        matched += 1

    # Write SQL
    os.makedirs(os.path.dirname(OUTPUT_SQL_FILE), exist_ok=True)
    with open(OUTPUT_SQL_FILE, 'w', encoding='utf-8') as f:
        f.write('-- Update real emails for users created in 9020, based on HR CSV.\n')
        f.write('-- Target table: auth.users (email).\n\n')
        for line in updates:
            f.write(line + '\n')

    logging.info(f"Atualizações geradas: {matched}. Filtrados: {filtered}. Sem correspondência: {len(no_match)}.")
    if no_match:
        unmatched_log = os.path.join(LOG_DIR, 'emails_sem_correspondencia.log')
        with open(unmatched_log, 'w', encoding='utf-8') as lf:
            for name, reason in no_match:
                lf.write(f"{name} | {reason}\n")
        logging.info(f"Lista de não mapeados salva em: {unmatched_log}")

    logging.info(f"Script SQL gerado em: {OUTPUT_SQL_FILE}")
    logging.info('--- ATUALIZAÇÃO DE EMAILS CONCLUÍDA ---')


if __name__ == '__main__':
    try:
        import pandas as pd  # noqa: F401
        from unidecode import unidecode  # noqa: F401
    except ImportError:
        print('Pandas e Unidecode são necessários. Instale com: pip install pandas unidecode')
        raise SystemExit(1)
    main()
