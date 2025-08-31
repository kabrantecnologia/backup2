import os
import json
from supabase import create_client, Client
from dotenv import load_dotenv

_client: Client = None
_config: dict = None

# Carrega variáveis do arquivo .env localizado na raiz de testing-tricket/
# Isso permite configurar SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY fora do código-fonte
_BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
_DOTENV_PATH = os.path.join(_BASE_DIR, '.env')
load_dotenv(_DOTENV_PATH)

def load_config(project_name: str) -> dict:
    """Carrega as configurações de um projeto específico."""
    config_path = os.path.join(os.path.dirname(__file__), '..', 'config', f"{project_name}.json")
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"Arquivo de configuração não encontrado para o projeto: {project_name}")
    
    with open(config_path, 'r') as f:
        return json.load(f)

def get_supabase_client(project_name: str) -> Client:
    """Retorna uma instância do cliente Supabase para o projeto selecionado."""
    global _client, _config
    
    if _client is None or (_config and _config.get("PROJECT_NAME") != project_name):
        _config = load_config(project_name)
        # Preferir variáveis de ambiente; usar config como fallback
        env_url = os.getenv("SUPABASE_URL")
        env_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
        url = env_url or _config.get("SUPABASE_URL")
        key = env_key or _config.get("SUPABASE_SERVICE_ROLE_KEY")
        
        if not url or not key:
            raise ValueError("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios (via variáveis de ambiente ou no arquivo de configuração).")
            
        _client = create_client(url, key)
        
    return _client

def set_session(client: Client, session_data: dict):
    """Define a sessão no cliente Supabase, verificando se a sessão é válida."""
    if session_data and session_data.get("access_token"):
        client.auth.set_session(session_data["access_token"], session_data.get("refresh_token"))
    else:
        # Limpa a sessão no cliente se os dados forem inválidos
        client.auth.signOut()

def get_config(project_name: str) -> dict:
    """Retorna a configuração carregada para o projeto."""
    global _config
    if _config is None or _config.get("PROJECT_NAME") != project_name:
        _config = load_config(project_name)
    return _config
