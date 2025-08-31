import pandas as pd
import logging
import os
import re
import uuid
from datetime import datetime

# Configuração de logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Caminhos dos arquivos
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUT_CSV_PATH = os.path.join(BASE_DIR, 'legado/dados-legados/telemarketing/REGISTRO.CSV')
# Lê o mapeamento gerado pelo script 03 no novo destino
PERSON_MIGRATION_SQL_PATH = os.path.join(BASE_DIR, 'legado-migration', '9030_migration_telemarketing_people.sql')
OUTPUT_SQL_PATH = os.path.join(BASE_DIR, 'legado-migration', '9040_migration_telemarketing_interactions.sql')

def parse_date(date_str):
    """Converte data do formato DD/MM/YYYY para YYYY-MM-DD HH:MI:SS."""
    if not date_str or pd.isna(date_str):
        return None
    try:
        return datetime.strptime(str(date_str), '%d/%m/%Y').strftime('%Y-%m-%d %H:%M:%S')
    except ValueError:
        logging.warning(f"Formato de data inválido encontrado: '{date_str}'. Ignorando.")
        return None

def load_person_id_map_from_migration_file(file_path):
    """Carrega o mapeamento de IDs legados para novos UUIDs a partir de um arquivo de migração SQL."""
    person_id_map = {}
    # Expressão regular para capturar o legacy_id e o new_uuid dos inserts de mapeamento
    # Exemplo: INSERT INTO public.migration_id_mapping (legacy_id, new_uuid, ...) VALUES ('12345', 'uuid-goes-here', ...);
    regex = re.compile(r"INSERT INTO public\.migration_id_mapping .*? VALUES \('([^']*)', '([^']*)', 'FICHARI'[^;]*;", re.IGNORECASE)
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            matches = regex.findall(content)
            for legacy_id, new_uuid in matches:
                person_id_map[legacy_id] = new_uuid
        logging.info(f"{len(person_id_map)} IDs de pessoas carregados do arquivo de migração '{os.path.basename(file_path)}'.")
    except FileNotFoundError:
        logging.error(f"Arquivo de migração de pessoas não encontrado em: {file_path}")
        return None
    except Exception as e:
        logging.error(f"Erro ao ler o arquivo de migração de pessoas: {e}")
        return None
        
    return person_id_map

def main():
    logging.info("Iniciando o processo de migração de interações de telemarketing...")

    # Carregar mapeamento de IDs de pessoas do arquivo de migração SQL
    person_id_map = load_person_id_map_from_migration_file(PERSON_MIGRATION_SQL_PATH)
    if person_id_map is None:
        logging.error("Falha ao carregar o mapeamento de IDs. Abortando o processo.")
        return

    try:
        # Ler o arquivo CSV legado
        df = pd.read_csv(INPUT_CSV_PATH, sep=',', encoding='latin-1', dtype=str, keep_default_na=False)
        logging.info(f"Arquivo '{os.path.basename(INPUT_CSV_PATH)}' lido com sucesso. {len(df)} registros encontrados.")
    except FileNotFoundError:
        logging.error(f"Arquivo de entrada não encontrado em: {INPUT_CSV_PATH}")
        return

    sql_commands = []
    new_migration_ids = []
    processed_count = 0
    skipped_count = 0
    invalid_date_count = 0

    # Iterar sobre as linhas do DataFrame
    for index, row in df.iterrows():
        legacy_person_id = str(row.get('matr_reg', '')).strip()
        
        person_uuid = person_id_map.get(legacy_person_id)

        if not person_uuid:
            log_message = f"ID de pessoa '{legacy_person_id}' não encontrado no mapeamento. Pulando linha {int(index) + 2}."
            logging.warning(log_message)
            skipped_count += 1
            continue

        interaction_date = parse_date(row.get('data_reg'))
        if not interaction_date:
            invalid_date_count += 1
            skipped_count += 1
            continue

        obs1 = str(row.get('obse_reg', ''))
        obs2 = str(row.get('situ_reg', ''))
        description = f"{obs1} {obs2}".strip().replace("'", "''")

        history_id = str(uuid.uuid4())
        legacy_interaction_id = str(row.get('num_reg', f"unq_{index}"))

        sql_commands.append(
            f"INSERT INTO public.core_history_logs (id, person_id, date, type, description, status) VALUES ('{history_id}', '{person_uuid}', '{interaction_date}', 'telemarketing', '{description}', 'recorded');"
        )

        new_migration_ids.append(
            f"INSERT INTO public.migration_id_mapping (legacy_id, new_uuid, legacy_table_name, description) VALUES ('{legacy_interaction_id}', '{history_id}', 'REGISTRO', 'Migração de interação de telemarketing');"
        )
        processed_count += 1

    if sql_commands:
        # Garante que o diretório de saída exista
        os.makedirs(os.path.dirname(OUTPUT_SQL_PATH), exist_ok=True)
        with open(OUTPUT_SQL_PATH, 'w', encoding='utf-8') as f:
            f.write('-- Início da migração de interações de telemarketing\n')
            f.write('\n'.join(sql_commands))
            f.write('\n\n-- Início dos registros de mapeamento de ID para interações\n')
            f.write('\n'.join(new_migration_ids))
            f.write('\n-- Fim da migração\n')
        logging.info(f"Script SQL de migração gerado em '{OUTPUT_SQL_PATH}'.")

    logging.info("--- Resumo do Processo ---")
    logging.info(f"Total de registros lidos: {len(df)}")
    logging.info(f"Interações migradas com sucesso: {processed_count}")
    logging.info(f"Registros pulados (ID não encontrado ou data inválida): {skipped_count}")
    logging.info(f"  - Datas inválidas: {invalid_date_count}")
    logging.info(f"  - IDs não encontrados: {skipped_count - invalid_date_count}")
    logging.info("Processo concluído.")

if __name__ == '__main__':
    main()
