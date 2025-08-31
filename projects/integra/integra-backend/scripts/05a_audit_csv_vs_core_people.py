import os
import re
import logging
from datetime import datetime
import pandas as pd
from unidecode import unidecode

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, 'legado', 'dados-legados', 'claudinei', 'EMPREGADOS.XLSX - Funcionários TI.csv')
CORE_PEOPLE_SQL = os.path.join(BASE_DIR, 'legado-migration', '9010_migration_pessoal_funcio.sql')
LOG_DIR = os.path.join(BASE_DIR, 'scripts', 'logs')

NORMALIZED_TXT = os.path.join(LOG_DIR, 'csv_names_normalized.txt')
REPORT_TXT = os.path.join(LOG_DIR, 'csv_core_people_match_report.txt')


def normalize_name(name: str) -> str:
    if not isinstance(name, str) or not name.strip():
        return ''
    return unidecode(name).strip().upper()


def load_csv_names(path: str) -> list[str]:
    # The CSV appears to have no header: name,email,role
    try:
        df = pd.read_csv(path, header=None, names=['name','email','role'], encoding='utf-8')
    except UnicodeDecodeError:
        df = pd.read_csv(path, header=None, names=['name','email','role'], encoding='latin1')
    names = []
    for _, r in df.iterrows():
        name = r['name'] if pd.notna(r['name']) else ''
        names.append(normalize_name(str(name)))
    # dedupe and drop empties
    names = [n for n in set(names) if n]
    names.sort()
    return names


def load_core_people_names(sql_file: str) -> list[str]:
    # Align pattern with scripts/02_process_users.py
    person_regex = re.compile(r"INSERT INTO public\.core_people \(id, name, type\) VALUES \('[a-f0-9\-]+', '([^']*)', 'individual'\);")
    content = ''
    with open(sql_file, 'r', encoding='utf-8') as f:
        content = f.read()
    names = [normalize_name(m) for m in person_regex.findall(content)]
    names = [n for n in set(names) if n]
    names.sort()
    return names


def main():
    os.makedirs(LOG_DIR, exist_ok=True)
    logging.basicConfig(level=logging.INFO, format='%(message)s')

    if not os.path.exists(CSV_PATH):
        logging.error(f'CSV não encontrado: {CSV_PATH}')
        return
    if not os.path.exists(CORE_PEOPLE_SQL):
        logging.error(f'Arquivo core_people não encontrado: {CORE_PEOPLE_SQL}')
        return

    csv_names = load_csv_names(CSV_PATH)
    people_names = set(load_core_people_names(CORE_PEOPLE_SQL))

    matches = []
    missing = []
    for n in csv_names:
        if n in people_names:
            matches.append(n)
        else:
            missing.append(n)

    with open(NORMALIZED_TXT, 'w', encoding='utf-8') as f:
        for n in csv_names:
            f.write(n + '\n')

    with open(REPORT_TXT, 'w', encoding='utf-8') as f:
        f.write('=== CSV vs core_people (9010) - Auditoria ===\n')
        f.write(f'Total CSV nomes únicos: {len(csv_names)}\n')
        f.write(f'Matches exatos (normalizados): {len(matches)}\n')
        f.write(f'Não encontrados: {len(missing)}\n\n')
        f.write('--- Matches ---\n')
        for n in matches:
            f.write(n + '\n')
        f.write('\n--- Não encontrados ---\n')
        for n in missing:
            f.write(n + '\n')

    logging.info('=== Resultado ===')
    logging.info(f'Total CSV nomes únicos: {len(csv_names)}')
    logging.info(f'Matches exatos: {len(matches)}')
    logging.info(f'Não encontrados: {len(missing)}')
    logging.info(f'Normalizados em: {NORMALIZED_TXT}')
    logging.info(f'Relatório: {REPORT_TXT}')


if __name__ == '__main__':
    main()
