import pandas as pd
import uuid
import re
import logging
import csv
from unidecode import unidecode
import numpy as np

# --- Configuração de diretórios ---
import os
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG_DIR = os.path.join(BASE_DIR, 'scripts', 'logs')
os.makedirs(LOG_DIR, exist_ok=True)
log_file = os.path.join(LOG_DIR, '03_process_telemarketing_people.log')
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file, mode='w'),
        logging.StreamHandler()
    ]
)

# --- Constantes e Caminhos ---
FICHARI_CSV_PATH = os.path.join(BASE_DIR, 'legado', 'dados-legados', 'telemarketing', 'FICHARI.CSV')
MIGRATION_FUNCIONARIOS_SQL_PATH = os.path.join(BASE_DIR, 'legado-migration', '9010_migration_pessoal_funcio.sql')
OUTPUT_SQL_PATH = os.path.join(BASE_DIR, 'legado-migration', '9030_migration_telemarketing_people.sql')

# --- Funções Auxiliares ---
def normalize_name(name):
    """Normaliza um nome para comparação: maiúsculas, sem acentos e espaços extras."""
    if not isinstance(name, str):
        return ''
    return unidecode(name).upper().strip()

def extract_uuid_from_line(line):
    """Extrai um UUID de uma linha de SQL INSERT."""
    match = re.search(r"VALUES \('([0-9a-f\-]+)'", line)
    if match:
        return match.group(1)
    return None

def extract_name_from_line(line):
    """Extrai um nome de uma linha de SQL INSERT em core_people."""
    # Tenta extrair o nome completo (full_name)
    match = re.search(r"'full_name', '([^']*)'\),", line)
    if match:
        return match.group(1)
    return None

def parse_phone(phone_str):
    """Limpa e formata um número de telefone."""
    if pd.isna(phone_str) or not isinstance(phone_str, str):
        return None
    # Remove caracteres não numéricos
    cleaned_phone = re.sub(r'\D', '', phone_str).strip()
    if len(cleaned_phone) >= 10: # Considera válido se tiver DDD + número
        return cleaned_phone
    return None

# --- Lógica Principal ---
def process_telemarketing_people():
    logging.info("Iniciando o processamento de pessoas do Telemarketing.")

    # 1. Carregar Mapeamento Existente
    existing_people = {}
    # Regex para capturar UUID e Nome de 'INSERT INTO public.core_people (id, name, type) VALUES (...);'
    people_insert_pattern = re.compile(r"INSERT INTO public\.core_people \(id, name, type\) VALUES \('([0-9a-f\-]+)', '([^']*)', 'individual'\);")
    try:
        with open(MIGRATION_FUNCIONARIOS_SQL_PATH, 'r', encoding='utf-8') as f:
            for line in f:
                match = people_insert_pattern.search(line)
                if match:
                    person_uuid, person_name = match.groups()
                    normalized = normalize_name(person_name)
                    if normalized not in existing_people:
                        existing_people[normalized] = person_uuid
        logging.info(f"{len(existing_people)} pessoas existentes carregadas de '{MIGRATION_FUNCIONARIOS_SQL_PATH}'.")
    except FileNotFoundError:
        logging.error(f"Arquivo de migração de funcionários não encontrado em '{MIGRATION_FUNCIONARIOS_SQL_PATH}'. Abortando.")
        return

    # 2. Ler Dados Legados (Abordagem Robusta)
    column_names = [
        'sequ_fic','matr_fic','nome_fic','tplg_fic','ende_fic','nume_fic','comp_fic','bair_fic','cida_fic',
        'esta_fic','cepo_fic','tele_fic','telr_fic','telc_fic','celu_fic','whac_fic','telo_fic','whao_fic',
        'emai_fic','nasc_fic','sexo_fic','resp_fic','sexr_fic','nasr_fic','cpfr_fic','docr_fic','telrr_fic',
        'telcr_fic','celr_fic','emar_fic','pare_fic','conta_fic','obse_fic','apon_fic','data_fic','bloq_fic',
        'carn_fic','cont_fic','nlig_fic','situ_fic','sant_fic','docu_fic','banc_fic','npar_fic','tipo_fic',
        'valo_fic','aten_fic','jorn_fic','pesq_fic','usua_fic','midi_fic','sepa_fic','mala_fic','cart_fic',
        'debi_fic','agen_fic','dvag_fic','ctba_fic','dvct_fic','tpct_fic','venc_fic','inst_fic','copa_fic',
        'ncem_fic','ncop_fic','cpf_fic','iden_fic','grup_fic','envi_fic','recu_fic','docu_ref','banc_ref'
    ]
    data = []
    try:
        with open(FICHARI_CSV_PATH, 'r', encoding='latin1', errors='ignore') as f:
            # Pula a linha do cabeçalho
            next(f)
            reader = csv.reader(f, quotechar='"')
            for i, fields in enumerate(reader):
                num_fields = len(fields)
                if num_fields == len(column_names):
                    data.append(fields)
                elif num_fields == len(column_names) + 1:
                    # Causa provável: uma vírgula no último campo sem aspas.
                    # Ex: ...,campoA,campoB parte 1,campoB parte 2
                    # Junta os dois últimos campos.
                    corrected_fields = fields[:-2] + [','.join(fields[-2:])]
                    data.append(corrected_fields)
                    logging.info(f"Linha {i+2} corrigida: {num_fields} -> {len(corrected_fields)} campos.")
                else:
                    logging.warning(f"Linha {i+2} ignorada por ter {num_fields} campos (esperado: {len(column_names)}): {','.join(fields)}")
        
        df = pd.DataFrame(data, columns=column_names)
        df = df.astype(str).replace('nan', '') # Garante que tudo seja string e remove 'nan'

        logging.info(f"{len(df)} registros lidos e processados de '{FICHARI_CSV_PATH}'.")

    except FileNotFoundError:
        logging.error(f"Arquivo FICHARI.CSV não encontrado em '{FICHARI_CSV_PATH}'. Abortando.")
        return
    except Exception as e:
        logging.error(f"Erro ao ler o arquivo CSV manualmente: {e}")
        return

    # 3. Iterar, Unificar e Gerar SQL
    sql_statements = []
    stats = {'total': len(df), 'novos': 0, 'unificados': 0}

    for _, row in df.iterrows():
        matr_fic_str = row.get('matr_fic', '0').strip()
        
        # Tenta converter para número. Se não for um número válido ou for 0, pula.
        try:
            matr_fic = int(matr_fic_str)
            if matr_fic == 0:
                raise ValueError("Matrícula é zero")
        except (ValueError, TypeError):

            logging.warning(f"Registro sem MATR_FIC encontrado. Linha: {row.to_dict()}")
            continue

        legacy_id = matr_fic

        donor_name = row.get('nome_fic')
        if not donor_name or pd.isna(donor_name):
            logging.warning(f"Registro com nome vazio ignorado. Matrícula: {matr_fic}")
            continue
        donor_name = str(donor_name).strip()

        normalized_donor_name = normalize_name(donor_name)

        person_id = None
        
        # a/b. Verifica se a pessoa já existe
        if normalized_donor_name in existing_people:
            person_id = existing_people[normalized_donor_name]
            stats['unificados'] += 1
            logging.info(f"Doador '{donor_name}' (ID: {legacy_id}) unificado com pessoa existente (UUID: {person_id}).")
        else:
            # c. Se não existir, cria nova pessoa
            stats['novos'] += 1
            person_id = str(uuid.uuid4())
            existing_people[normalized_donor_name] = person_id # Adiciona ao set para evitar duplicatas nesta execução

            # INSERT para core_people
            # Limpa o nome para evitar problemas com aspas
            clean_donor_name = donor_name.replace("'", "''")

            person_sql = (
                f"INSERT INTO public.core_people (id, name, type, status) "
                f"VALUES ('{person_id}', '{clean_donor_name}', 'individual', 'active');"
            )
            sql_statements.append(person_sql)

            # INSERT para core_addresses (se houver)
            address_street = row.get('ENDE_FIC')
            if pd.notna(address_street):
                address_id = str(uuid.uuid4())
                address_sql = (
                    f"INSERT INTO public.core_addresses (id, person_id, street, number, district, city, state, zip_code, is_primary) "
                    f"VALUES ('{address_id}', '{person_id}', '{str(address_street).replace("'", "''")}', '{str(row.get('NUME_FIC', '')).replace("'", "''")}', "
                    f"'{str(row.get('BAIR_FIC', '')).replace("'", "''")}', '{str(row.get('CIDA_FIC', '')).replace("'", "''")}', "
                    f"'{str(row.get('ESTA_FIC', '')).replace("'", "''")}', '{str(row.get('CEP_FIC', '')).replace("'", "''")}', TRUE);"
                )
                sql_statements.append(address_sql)
                # Mapeamento do endereço
                sql_statements.append(f"INSERT INTO public.migration_id_mapping (legacy_table_name, legacy_id, new_table_name, new_uuid) VALUES ('FICHARI', '{legacy_id}_address', 'core_addresses', '{address_id}');")

            # INSERT para core_contacts (telefones e email)
            contact_mapping = {
                'tele_fic': 'phone',
                'telr_fic': 'phone',
                'telc_fic': 'phone',
                'celu_fic': 'mobile',
                'whac_fic': 'whatsapp',
                'telo_fic': 'phone',
                'whao_fic': 'whatsapp',
                'emai_fic': 'email'
            }

            for col, contact_type in contact_mapping.items():
                value = row.get(col)
                if pd.notna(value) and str(value).strip():
                    cleaned_value = ''
                    # Limpa o valor dependendo do tipo
                    if contact_type in ['phone', 'mobile', 'whatsapp']:
                        cleaned_value = parse_phone(value)
                    elif contact_type == 'email':
                        if '@' in str(value):
                            cleaned_value = str(value).replace("'", "''").strip()
                    
                    # Se o valor for válido após a limpeza, insere
                    if cleaned_value:
                        contact_id = str(uuid.uuid4())
                        contact_sql = (
                            f"INSERT INTO public.core_contacts (id, person_id, type, value, is_primary) "
                            f"VALUES ('{contact_id}', '{person_id}', '{contact_type}', '{cleaned_value}', FALSE);"
                        )
                        sql_statements.append(contact_sql)
                        
                        # Cria um ID legado único para o mapeamento
                        legacy_contact_id = f"{legacy_id}_{col}_{cleaned_value}"
                        mapping_sql = (
                            f"INSERT INTO public.migration_id_mapping (legacy_table_name, legacy_id, new_table_name, new_uuid) "
                            f"VALUES ('FICHARI', '{legacy_contact_id}', 'core_contacts', '{contact_id}');"
                        )
                        sql_statements.append(mapping_sql)

        # d. Adiciona mapeamento para a pessoa
        mapping_sql = (
            f"INSERT INTO public.migration_id_mapping (legacy_table_name, legacy_id, new_table_name, new_uuid) "
            f"VALUES ('FICHARI', '{legacy_id}', 'core_people', '{person_id}');"
        )
        sql_statements.append(mapping_sql)

    # 4. Gerar Script SQL
    try:
        # Garante que o diretório de saída exista
        os.makedirs(os.path.dirname(OUTPUT_SQL_PATH), exist_ok=True)
        with open(OUTPUT_SQL_PATH, 'w', encoding='utf-8') as f:
            f.write('-- Migration for Telemarketing People, Addresses, and Contacts\n')
            f.write('-- Generated by scripts/03_process_telemarketing_people.py\n\n')
            for stmt in sql_statements:
                f.write(stmt + '\n')
        logging.info(f"Script SQL de migração gerado em '{OUTPUT_SQL_PATH}'.")
    except Exception as e:
        logging.error(f"Erro ao escrever o arquivo SQL de saída: {e}")

    # 5. Log de Auditoria Final
    logging.info("--- Resumo do Processo ---")
    logging.info(f"Total de registros lidos: {stats['total']}")
    logging.info(f"Novas pessoas inseridas: {stats['novos']}")
    logging.info(f"Registros unificados com pessoas existentes: {stats['unificados']}")
    logging.info("Processo concluído.")

if __name__ == '__main__':
    process_telemarketing_people()
