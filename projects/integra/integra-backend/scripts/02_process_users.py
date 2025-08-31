import pandas as pd
import os
import re
import uuid
from unidecode import unidecode
import logging
from datetime import datetime

# --- Basic Setup ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, 'legado', 'dados-legados')
MIGRATIONS_DIR = os.path.join(BASE_DIR, 'legado-migration')
LEGADO_MIG_DIR = os.path.join(BASE_DIR, 'legado-migration')
LOG_DIR = os.path.join(BASE_DIR, 'scripts', 'logs')
OUTPUT_SQL_FILE = os.path.join(LEGADO_MIG_DIR, '9020_migration_core_users.sql')
ORPHAN_LOG_FILE = os.path.join(LOG_DIR, 'usuarios_orfãos.log')

# --- Configuration ---
FILE_MAP = {
    'bazar/USUARIO.CSV': {'id_col': 'codi_usu', 'name_col': 'nome_usu', 'table_name': 'BAZAR_USUARIO'},
    'central-doacao/USUARIO.CSV': {'id_col': 'codi_usu', 'name_col': 'nome_usu', 'table_name': 'DOACAO_USUARIO'},
    'financeiro/USUARIO.CSV': {'id_col': 'codi_usu', 'name_col': 'nome_usu', 'table_name': 'FINANCEIRO_USUARIO'},
    'pessoal/USUARIO.CSV': {'id_col': 'codi_usu', 'name_col': 'nome_usu', 'table_name': 'PESSOAL_USUARIO'},
    'recepcao/USUARIO.csv': {'id_col': 'codi_usu', 'name_col': 'nome_usu', 'table_name': 'RECEPCAO_USUARIO'},
    'refeitorio/USUARIO.CSV': {'id_col': 'codi_usu', 'name_col': 'nome_usu', 'table_name': 'REFEITORIO_USUARIO'},
    'telemarketing/TELEFO.CSV': {'id_col': 'codi_tel', 'name_col': 'nome_tel', 'table_name': 'TELEMARKETING_TELEFONISTA'},
    'transporte/usuario.csv': {'id_col': 'codi_usu', 'name_col': 'nome_usu', 'table_name': 'TRANSPORTE_USUARIO'},
}

# --- Helper Functions ---
def normalize_name(name):
    """Cleans and standardizes a name string."""
    if not isinstance(name, str):
        return ""
    return unidecode(name).strip().upper()

def generate_email(name, new_user_id):
    """Generates a unique placeholder email from a name."""
    if not name:
        # Fallback for empty names
        return f"{new_user_id[:8]}@nacj.org.br"
    first_name = name.split()[0].lower()
    first_name = re.sub(r'[^a-z]', '', first_name) # Keep only letters
    return f"{first_name}.{new_user_id[:4]}@nacj.org.br"

# --- Main ETL Logic ---
def main():
    """Main function to perform the ETL process for users."""
    # --- Logging Setup ---
    os.makedirs(LOG_DIR, exist_ok=True)
    log_filename = f"migration_log_{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.log"
    log_filepath = os.path.join(LOG_DIR, log_filename)
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_filepath, mode='w', encoding='utf-8'),
            logging.StreamHandler()
        ]
    )

    logging.info("--- INICIANDO PROCESSO DE MIGRAÇÃO DE USUÁRIOS ---")

    # ETAPA 1: Mapeamento e Consolidação de Usuários
    all_users = []
    logging.info(f"Lendo {len(FILE_MAP)} arquivos de usuários legados de '{DATA_DIR}'...")
    for file_path, details in FILE_MAP.items():
        full_path = os.path.join(DATA_DIR, file_path)
        try:
            logging.info(f"Processando arquivo: {file_path}")
            try:
                df = pd.read_csv(full_path, sep=',', quotechar='"', encoding='latin1', skipinitialspace=True)
            except UnicodeDecodeError:
                df = pd.read_csv(full_path, sep=',', quotechar='"', encoding='utf-8', skipinitialspace=True)
            
            df.columns = [str(col).strip().lower() for col in df.columns]
            logging.info(f"  > Encontrados {len(df)} registros.")

            for _, row in df.iterrows():
                legacy_id = row.get(details['id_col'])
                name = row.get(details['name_col'])
                normalized = normalize_name(name)
                if normalized:
                    all_users.append({
                        'legacy_id': str(legacy_id),
                        'legacy_table': details['table_name'],
                        'name': normalized
                    })
        except FileNotFoundError:
            logging.warning(f"Arquivo não encontrado: {full_path}. Pulando.")
        except Exception as e:
            logging.error(f"Erro ao processar o arquivo {full_path}: {e}")

    total_records = len(all_users)
    logging.info(f"Total de {total_records} registros de usuários brutos coletados.")

    # ETAPA 2: Filtragem e Deduplicação
    logging.info("Iniciando filtragem de usuários...")
    blocklist = ['RH', 'TI', 'FINANCEIRO', 'DEPARTAMENTO', 'COORD', 'SUPORTE', 'ADM', 'DIRETORIA', 'MANUTENCAO', 'ALMOXARIFADO', 'PATRIMONIAL', 'MARKETING', 'NUTRICAO', 'ODONTOLOGIA', 'BAZAR', 'TRANSPORTE', 'CONTROLADORIA']
    
    filtered_users = []
    filtered_out_count = 0
    for user in all_users:
        name = user['name']
        reason = None
        if len(name) < 4:
            reason = "nome muito curto (< 4 caracteres)"
        else:
            words_in_name = set(name.split())
            if any(word in blocklist for word in words_in_name):
                reason = "nome contém palavra na blocklist"
        
        if reason:
            logging.debug(f"Usuário '{name}' filtrado. Motivo: {reason}")
            filtered_out_count += 1
            continue
        
        filtered_users.append(user)
    logging.info(f"{filtered_out_count} usuários filtrados. {len(filtered_users)} usuários restantes.")

    logging.info("Iniciando deduplicação de usuários...")
    unique_users = {}
    for user in filtered_users:
        name = user['name']
        if name not in unique_users:
            unique_users[name] = {'legacy_ids': []}
        unique_users[name]['legacy_ids'].append({'id': user['legacy_id'], 'table': user['legacy_table']})
    logging.info(f"{len(unique_users)} usuários únicos encontrados após deduplicação.")

    # ETAPA 3: Carregamento de Dados de `core_people`
    logging.info("Carregando dados de 'core_people' para associação...")
    person_regex = re.compile(r"INSERT INTO public\.core_people \(id, name, type\) VALUES \('([a-f0-9\-]+)', '([^']*)', 'individual'\);")
    # Inicializa acumulador antes de popular
    people_data = []
    migration_files = [f for f in os.listdir(MIGRATIONS_DIR) if f.endswith('.sql')]

    for file_name in migration_files:
        with open(os.path.join(MIGRATIONS_DIR, file_name), 'r', encoding='utf-8') as f:
            content = f.read()
            matches = person_regex.findall(content)
            for person_id, name in matches:
                people_data.append({'person_id': person_id, 'name': normalize_name(name)})

    if not people_data:
        logging.critical("Nenhum dado de 'core_people' encontrado. Abortando.")
        return

    people_df = pd.DataFrame(people_data).drop_duplicates(subset=['name'])
    logging.info(f"{len(people_df)} pessoas únicas carregadas de arquivos de migração.")

    # ETAPA 4: Geração do Script SQL e Registros de Auditoria
    logging.info("Iniciando associação de usuários e geração de SQL...")
    associated_count = 0
    orphan_count = 0
    sql_inserts = []
    mapping_inserts = []
    orphan_log_entries = []
    default_password = 'Mudar@1234'

    for name, data in unique_users.items():
        match = people_df[people_df['name'].str.contains(name, na=False)]
        if not match.empty:
            person_id = match.iloc[0]['person_id']
            associated_count += 1
            auth_user_id = str(uuid.uuid4())
            email = generate_email(name, auth_user_id)
            raw_app_meta_data = f'{{ "provider":"email", "providers":["email"] }}'
            raw_user_meta_data = f'{{}}'

            sql_inserts.append(
                f"INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at) "
                f"VALUES ('{auth_user_id}', 'authenticated', 'authenticated', '{email}', crypt('{default_password}', gen_salt('bf')), NOW(), NULL, NULL, '{raw_app_meta_data}', '{raw_user_meta_data}', NOW(), NOW());"
            )
            sql_inserts.append(
                f"INSERT INTO public.core_users (id, person_id) VALUES ('{auth_user_id}', '{person_id}');"
            )
            for legacy in data['legacy_ids']:
                mapping_inserts.append(
                    f"INSERT INTO public.migration_id_mapping (legacy_id, legacy_table_name, new_uuid, new_table_name) VALUES ('{legacy['id']}', '{legacy['table']}', '{auth_user_id}', 'core_users');"
                )
        else:
            orphan_count += 1
            orphan_log_entries.append(f"NOME: {name}, FONTES: {data['legacy_ids']}")

    logging.info(f"Associação concluída. {associated_count} usuários associados, {orphan_count} órfãos.")

    if orphan_log_entries:
        logging.info(f"Registrando {orphan_count} usuários órfãos em '{os.path.basename(ORPHAN_LOG_FILE)}'")
        with open(ORPHAN_LOG_FILE, 'w', encoding='utf-8') as f:
            f.write('\n'.join(orphan_log_entries))

    logging.info(f"Gerando script SQL em '{os.path.basename(OUTPUT_SQL_FILE)}'...")
    # Garante que o diretório de saída exista
    os.makedirs(os.path.dirname(OUTPUT_SQL_FILE), exist_ok=True)
    with open(OUTPUT_SQL_FILE, 'w', encoding='utf-8') as f:
        f.write('-- Migration for auth.users and core_users --\n\n')
        f.write('\n'.join(sql_inserts))
        f.write('\n\n-- Migration ID Mappings --\n\n')
        f.write('\n'.join(mapping_inserts))
        f.write('\n')

    logging.info(f"- Inserções para 'auth.users': {associated_count}")
    logging.info(f"- Inserções para 'core_users': {associated_count}")
    logging.info(f"- Inserções para 'migration_id_mapping': {len(mapping_inserts)}")
    logging.info("--- PROCESSO DE MIGRAÇÃO DE USUÁRIOS CONCLUÍDO ---")

if __name__ == '__main__':
    try:
        import pandas as pd
        from unidecode import unidecode
    except ImportError:
        print("Pandas e Unidecode são necessários. Por favor, instale-os com: pip install pandas unidecode")
        exit(1)
    main()
