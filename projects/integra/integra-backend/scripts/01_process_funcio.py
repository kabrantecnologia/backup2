import pandas as pd
import uuid
import os
import logging
from datetime import datetime
from unidecode import unidecode

def process_funcio_csv():
    """
    Processes the FUNCIO.CSV file to generate a SQL migration script for populating
    core_departments, core_people, and hr_employees tables, with data validation.
    """
    # --- Configuration & Logging Setup ---

    base_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    csv_path = os.path.join(base_path, 'legado', 'dados-legados', 'pessoal', 'FUNCIO.CSV')
    output_sql_path = os.path.join(base_path, 'legado-migration', '9010_migration_pessoal_funcio.sql')
    log_dir = os.path.join(base_path, 'scripts', 'logs')

    # --- Create log directory if it doesn't exist ---
    os.makedirs(log_dir, exist_ok=True)

    # --- Logger Configuration ---
    log_filename = datetime.now().strftime('migration_log_%Y-%m-%d_%H-%M-%S.log')
    log_filepath = os.path.join(log_dir, log_filename)

    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_filepath, encoding='utf-8'),
            logging.StreamHandler()
        ]
    )

    logging.info("Iniciando migração de PESSOAL/FUNCIO.CSV...")

    try:
        df = pd.read_csv(csv_path, sep=',', encoding='latin1', dtype={'regi_fun': str})
        logging.info(f"- Arquivo lido com sucesso. Total de {len(df)} registros.")
    except FileNotFoundError:
        logging.error(f"Erro: Arquivo não encontrado em {csv_path}")
        return

    # --- 1. Extract and Normalize Departments ---
    unique_departments = df['seto_fun'].str.strip().str.upper().unique()
    department_map = {name: str(uuid.uuid4()) for name in unique_departments if pd.notna(name) and name}
    department_legacy_id_map = {name: i + 1 for i, name in enumerate(department_map.keys())}
    logging.info(f"- Identificados {len(department_map)} departamentos únicos válidos.")

    # --- Initialize SQL statement lists ---
    department_inserts = []
    people_inserts = []
    employee_inserts = []
    mapping_inserts = []

    # --- 2. Process Data ---
    for index, row in df.iterrows():
        # --- Validate Employee Name ---
        employee_name = str(row.get('nome_fun', '')).strip()
        if not employee_name:
            logging.warning(f"Ignorando linha {index + 2} por ter nome de funcionário vazio.")
            continue

        # --- Get Department --- 
        dept_name_raw = str(row.get('seto_fun', '')).strip().upper()
        department_uuid = department_map.get(dept_name_raw)
        if not department_uuid:
            logging.warning(f"Departamento '{dept_name_raw}' para o funcionário '{employee_name}' não é válido ou não foi encontrado. Pulando funcionário.")
            continue

        # --- Prepare Inserts ---
        person_uuid = uuid.uuid4()
        employee_code = str(row.get('regi_fun', '')).strip()

        # a. Core People
        people_inserts.append(
            f"INSERT INTO public.core_people (id, name, type) VALUES ('{person_uuid}', '{employee_name.replace("'", "''")}', 'individual');"
        )

        # b. HR Employees
        status = 'active' if row.get('situ_fun') == 'A' else 'inactive'
        admission_date_str = str(row.get('data_adm', '')).strip()
        admission_date_sql = 'NULL'
        if admission_date_str:
            try:
                pd_date = pd.to_datetime(admission_date_str, format='%d/%m/%Y', errors='coerce')
                if pd.notna(pd_date):
                    admission_date_sql = f"'{pd_date.strftime('%Y-%m-%d')}'"
                else:
                    logging.warning(f"Data de admissão '{admission_date_str}' inválida para {employee_name}. Usando NULL.")
            except Exception as e:
                logging.warning(f"Erro ao processar data '{admission_date_str}' para {employee_name}: {e}. Usando NULL.")
        
        employee_inserts.append(
            f"INSERT INTO public.hr_employees (person_id, department_id, status, employee_code, admission_date) "
            f"VALUES ('{person_uuid}', '{department_uuid}', '{status}', '{employee_code}', {admission_date_sql});"
        )

        # c. Migration Mapping
        mapping_inserts.append(
            f"INSERT INTO public.migration_id_mapping (legacy_table_name, legacy_id, new_table_name, new_uuid) VALUES ('FUNCIO', '{employee_code}', 'core_people', '{person_uuid}');"
        )

    # --- Prepare Department Inserts ---
    for name, dept_uuid in department_map.items():
        dept_name_cleaned = name.replace("'", "''")
        legacy_id = department_legacy_id_map[name]
        
        department_inserts.append(
            f"INSERT INTO public.core_departments (id, name) VALUES ('{dept_uuid}', '{dept_name_cleaned}');"
        )
        mapping_inserts.append(
            f"INSERT INTO public.migration_id_mapping (legacy_table_name, legacy_id, new_table_name, new_uuid) VALUES ('DEPARTMENTS_FROM_FUNCIO', '{legacy_id}', 'core_departments', '{dept_uuid}');"
        )

    # --- 3. Generate SQL Script ---
    logging.info(f"- Gerando script SQL em {output_sql_path}...")
    # Garante que o diretório de saída exista
    os.makedirs(os.path.dirname(output_sql_path), exist_ok=True)
    with open(output_sql_path, 'w', encoding='utf-8') as f:
        f.write("-- Migration for PESSOAL/FUNCIO.CSV --\n\n")
        f.write("-- Inserting Departments --\n")
        f.write('\n'.join(department_inserts))
        f.write("\n\n")
        f.write("-- Inserting People --\n")
        f.write('\n'.join(people_inserts))
        f.write("\n\n")
        f.write("-- Inserting Employees --\n")
        f.write('\n'.join(employee_inserts))
        f.write("\n\n")
        f.write("-- Inserting ID Mappings --\n")
        f.write('\n'.join(mapping_inserts))
        f.write("\n")

    logging.info(f"- {len(department_inserts)} registros de departamentos preparados.")
    logging.info(f"- {len(people_inserts)} registros de pessoas preparados.")
    logging.info(f"- {len(employee_inserts)} registros de funcionários preparados.")
    logging.info(f"- {len(mapping_inserts)} registros de mapeamento de ID preparados.")
    logging.info("Processo concluído com sucesso.")

if __name__ == "__main__":
    process_funcio_csv()
