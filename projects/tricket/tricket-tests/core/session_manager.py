import os
import json
from typing import Dict, Any, Optional

SESSION_FILE = os.path.expanduser("~/.testing_system_session.json")
TOKENS_FILE = os.path.expanduser("~/.testing_system_tokens.json")

_session_data = {}
_tokens_data = {}

def load_session():
    """Carrega os dados da sessão do arquivo JSON."""
    global _session_data
    if os.path.exists(SESSION_FILE):
        try:
            with open(SESSION_FILE, 'r') as f:
                _session_data = json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            _session_data = {}
            if os.path.exists(SESSION_FILE):
                os.remove(SESSION_FILE)
    return _session_data

def save_session(data):
    """Salva os dados da sessão no arquivo JSON."""
    global _session_data
    _session_data.update(data)
    with open(SESSION_FILE, 'w') as f:
        json.dump(_session_data, f, indent=4)

def get_session_data():
    """Retorna os dados da sessão carregados."""
    return _session_data

def clear_session():
    """Limpa o arquivo de sessão."""
    global _session_data
    _session_data = {}
    if os.path.exists(SESSION_FILE):
        os.remove(SESSION_FILE)

# Sistema de Tokens de Acesso
def load_tokens():
    """Carrega os tokens de acesso do arquivo JSON."""
    global _tokens_data
    if os.path.exists(TOKENS_FILE):
        try:
            with open(TOKENS_FILE, 'r') as f:
                _tokens_data = json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            _tokens_data = {"users": {}}
            if os.path.exists(TOKENS_FILE):
                os.remove(TOKENS_FILE)
    else:
        _tokens_data = {"users": {}}
    return _tokens_data

def save_tokens():
    """Salva os tokens de acesso no arquivo JSON."""
    global _tokens_data
    with open(TOKENS_FILE, 'w') as f:
        json.dump(_tokens_data, f, indent=4)

def save_user_token(user_email: str, token_data: Dict[str, Any]):
    """Salva os tokens de acesso para um usuário específico."""
    global _tokens_data
    if "users" not in _tokens_data:
        _tokens_data["users"] = {}
    
    _tokens_data["users"][user_email] = {
        "access_token": token_data.get("access_token"),
        "refresh_token": token_data.get("refresh_token"),
        "expires_at": token_data.get("expires_at"),
        "user_id": token_data.get("user_id"),
        "created_at": token_data.get("created_at"),
        "last_used": token_data.get("last_used")
    }
    save_tokens()

def get_user_token(user_email: str) -> Optional[Dict[str, Any]]:
    """Retorna os tokens de acesso para um usuário específico."""
    global _tokens_data
    return _tokens_data.get("users", {}).get(user_email)

def get_all_tokens() -> Dict[str, Dict[str, Any]]:
    """Retorna todos os tokens de acesso armazenados."""
    global _tokens_data
    return _tokens_data.get("users", {})

def remove_user_token(user_email: str):
    """Remove os tokens de acesso de um usuário específico."""
    global _tokens_data
    if "users" in _tokens_data and user_email in _tokens_data["users"]:
        del _tokens_data["users"][user_email]
        save_tokens()

def clear_all_tokens():
    """Limpa todos os tokens de acesso."""
    global _tokens_data
    _tokens_data = {"users": {}}
    if os.path.exists(TOKENS_FILE):
        os.remove(TOKENS_FILE)

def get_current_user() -> Optional[str]:
    """Retorna o e-mail do usuário atualmente logado."""
    session = get_session_data()
    return session.get("user", {}).get("email")

def get_current_token() -> Optional[str]:
    """Retorna o token de acesso do usuário atualmente logado."""
    current_user = get_current_user()
    if current_user:
        token_data = get_user_token(current_user)
        return token_data.get("access_token") if token_data else None
    return None

# Carrega os dados quando o módulo é importado
load_session()
load_tokens()
