import os
import re
import logging
import pandas as pd
from unidecode import unidecode

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, 'legado', 'dados-legados', 'claudinei', 'EMPREGADOS.XLSX - Funcionários TI.csv')
SQL_9010 = os.path.join(BASE_DIR, 'legado-migration', '9010_migration_pessoal_funcio.sql')
SQL_9020 = os.path.join(BASE_DIR, 'legado-migration', '9020_migration_core_users.sql')
LOG_DIR = os.path.join(BASE_DIR, 'scripts', 'logs')
REPORT = os.path.join(LOG_DIR, 'audit_9010_vs_9020_for_csv.txt')


def normalize_name(s: str) -> str:
    return unidecode(str(s)).strip().upper() if isinstance(s, str) else ''


def load_csv_names(csv_path: str) -> list[str]:
    try:
        df = pd.read_csv(csv_path, header=None, names=['name','email','role'], encoding='utf-8')
    except UnicodeDecodeError:
        df = pd.read_csv(csv_path, header=None, names=['name','email','role'], encoding='latin1')
    names = [normalize_name(n) for n in df['name'].tolist()]
    names = [n for n in set(names) if n]
    names.sort()
    return names


def load_core_people(sql_path: str) -> dict[str, str]:
    # person_id -> name_norm
    person_regex = re.compile(r"INSERT INTO public\.core_people \(id, name, type\) VALUES \('([a-f0-9\-]+)', '([^']*)', 'individual'\);")
    with open(sql_path, 'r', encoding='utf-8') as f:
        content = f.read()
    mapping = {}
    for pid, name in person_regex.findall(content):
        mapping[pid] = normalize_name(name)
    return mapping


def load_core_users_person_ids(sql_path: str) -> set[str]:
    # Extract person_id referenced by core_users rows
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

    csv_names = set(load_csv_names(CSV_PATH))
    people_map = load_core_people(SQL_9010)  # person_id -> name
    people_by_name = {}
    for pid, n in people_map.items():
        people_by_name.setdefault(n, []).append(pid)

    # Names present both in CSV and 9010
    names_in_both = sorted(csv_names & set(people_by_name.keys()))
    person_ids_expected = set()
    for n in names_in_both:
        # could be multiple person_ids for same name; include all
        person_ids_expected.update(people_by_name.get(n, []))

    core_users_person_ids = load_core_users_person_ids(SQL_9020)

    found = sorted(pid for pid in person_ids_expected if pid in core_users_person_ids)
    missing = sorted(pid for pid in person_ids_expected if pid not in core_users_person_ids)

    with open(REPORT, 'w', encoding='utf-8') as f:
        f.write('=== Auditoria: CSV names em 9010 -> presença em 9020 ===\n')
        f.write(f'Nomes CSV únicos: {len(csv_names)}\n')
        f.write(f'Nomes também em 9010: {len(names_in_both)}\n')
        f.write(f'Person IDs esperados (de 9010 p/ esses nomes): {len(person_ids_expected)}\n')
        f.write(f'Presentes em 9020 (core_users): {len(found)}\n')
        f.write(f'Ausentes em 9020: {len(missing)}\n\n')
        f.write('--- Presentes (person_id | name) ---\n')
        for pid in found:
            f.write(f"{pid} | {people_map.get(pid, '')}\n")
        f.write('\n--- Ausentes (person_id | name) ---\n')
        for pid in missing:
            f.write(f"{pid} | {people_map.get(pid, '')}\n")

    logging.info('Relatório gerado: %s', REPORT)
    logging.info('Resumo: nomes CSV & 9010=%d, person_ids esperados=%d, presentes em 9020=%d, ausentes=%d',
                 len(names_in_both), len(person_ids_expected), len(found), len(missing))


if __name__ == '__main__':
    main()
