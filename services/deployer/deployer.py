#!/home/joaohenrique/workspaces/.venv/bin/python

import json
import os
import subprocess
import sys
import hmac
import hashlib
import logging
import threading
from flask import Flask, request, jsonify

# --- Configuração e Constantes ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(SCRIPT_DIR, 'config.json')

YELLOW = '\033[1;33m'
GREEN = '\033[0;32m'
RED = '\033[0;31m'
NC = '\033[0m'

# --- Funções Auxiliares ---
def log_message(message, color):
    print(f"{color}{message}{NC}")

def load_config():
    """Carrega e valida o arquivo de configuração."""
    # Log de depuração para mostrar o caminho exato do arquivo de configuração
    log_message(f"Tentando carregar arquivo de configuração em: {os.path.abspath(CONFIG_FILE)}", YELLOW)
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
        if 'base_dir' not in config or 'applications' not in config:
            raise KeyError("'base_dir' e 'applications' são chaves obrigatórias no config.json")
        return config
    except (FileNotFoundError, json.JSONDecodeError, KeyError) as e:
        log_message(f"Erro crítico ao carregar config.json: {e}", RED)
        return None

def run_command(command, cwd=None):
    try:
        # Usar capture_output=True para evitar que o stdout/stderr do git/docker polua a saída do webhook
        subprocess.run(command, check=True, shell=True, cwd=cwd)
        return True
    except subprocess.CalledProcessError as e:
        log_message(f"Erro ao executar comando: {' '.join(command)}\n--- STDOUT ---\n{e.stdout}\n--- STDERR ---\n{e.stderr}", RED)
        return False

# --- Lógica de Geração de Arquivos Docker ---
def get_dockerfile_content():
    return """FROM node:18 as build
WORKDIR /app
COPY ./package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:stable-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD nginx -g 'daemon off;'
"""

def get_docker_compose_content(app_name, domain_url):
    service_name = app_name.replace('_', '-')
    project_name_base = service_name.replace('-frontend', '')
    project_name = f"{project_name_base}-app"
    return f"""name: {project_name}
services:
  {service_name}:
    image: {service_name}:latest
    build:
      context: ..
      dockerfile: docker/Dockerfile
    container_name: {service_name}
    restart: unless-stopped
    labels:
      - \"traefik.enable=true\"
      - \"traefik.http.routers.{service_name}.rule=Host(`{domain_url}`)\"
      - \"traefik.http.routers.{service_name}.entrypoints=web,websecure\"
      - \"traefik.http.routers.{service_name}.tls.certresolver=cloudflare\"
      - \"traefik.http.services.{service_name}.loadbalancer.server.port=80\"
    networks:
      - traefik-proxy
networks:
  traefik-proxy:
    external: true
"""

# --- Lógica Principal de Deploy ---
def create_gitignore(project_dir):
    """Cria um arquivo .gitignore na raiz do projeto se não existir."""
    gitignore_path = os.path.join(project_dir, '.gitignore')
    if not os.path.exists(gitignore_path):
        with open(gitignore_path, 'w') as f:
            f.write("# Docker\ndocker/")
        log_message("Arquivo .gitignore criado com sucesso.", GREEN)
    else:
        log_message("Arquivo .gitignore já existe. Mantendo o arquivo existente.", YELLOW)

def implement_app(app_config, base_dir):
    log_message(f"Iniciando/Atualizando implementação de {app_config['name']}...", YELLOW)

    # Extrai o nome base do projeto (ex: 'modelo' de 'modelo_frontend')
    project_name_base = app_config['name'].replace('_frontend', '')
    # Constrói o caminho para a subpasta 'front-end'
    project_dir = os.path.join(base_dir, project_name_base, 'front-end')

    if not os.path.exists(project_dir):
        log_message(f"Clonando repositório {app_config['repo_url']}...", GREEN)
        if not run_command(f"git clone --branch {app_config['branch']} {app_config['repo_url']} {project_dir}"):
            return
    else:
        log_message(f"Diretório {project_dir} já existe. Pulando o clone.", YELLOW)

    # Cria o .gitignore na raiz do projeto
    create_gitignore(project_dir)

    docker_dir = os.path.join(project_dir, 'docker')
    os.makedirs(docker_dir, exist_ok=True)

    with open(os.path.join(docker_dir, 'Dockerfile'), 'w') as f:
        f.write(get_dockerfile_content())
    with open(os.path.join(docker_dir, 'docker-compose.yml'), 'w') as f:
        f.write(get_docker_compose_content(app_config['name'], app_config['domain_url']))
    log_message(f"Arquivos Docker para {app_config['name']} criados/atualizados.", GREEN)

def deploy_app(app_config, base_dir):
    log_message(f"Iniciando deploy de {app_config['name']}...", YELLOW)

    # Extrai o nome base do projeto (ex: 'modelo' de 'modelo_frontend')
    project_name_base = app_config['name'].replace('_frontend', '')
    # Constrói o caminho para a subpasta 'front-end'
    project_dir = os.path.join(base_dir, project_name_base, 'front-end')
    if not os.path.exists(project_dir):
        log_message(f"Diretório {project_dir} não encontrado. Execute a implementação primeiro.", RED)
        return

    log_message(f"Atualizando repositório para {app_config['name']}...", GREEN)
    if not run_command('git pull', cwd=project_dir):
        return

    log_message(f"Iniciando container Docker para {app_config['name']}...", GREEN)
    docker_dir = os.path.join(project_dir, 'docker')
    if not run_command('docker compose up -d --build', cwd=docker_dir):
        return
    log_message(f"Deploy de {app_config['name']} concluído com sucesso!", YELLOW)

# --- Lógica para CLI Interativo ---
def select_app(config):
    apps = config['applications']
    print("Selecione a aplicação:")
    for i, app in enumerate(apps):
        print(f"  {i + 1}) {app['name']}")
    try:
        choice = int(input("Opção: ")) - 1
        return apps[choice] if 0 <= choice < len(apps) else None
    except (ValueError, IndexError):
        return None

def select_action():
    print("\nSelecione a ação:")
    print("  1) Implementar (clonar/configurar)")
    print("  2) Deploy (atualizar/iniciar)")
    try:
        choice = int(input("Ação: "))
        return str(choice) if choice in [1, 2] else None
    except ValueError:
        return None

def main_cli():
    """Ponto de entrada para o modo CLI interativo."""
    config = load_config()
    if not config:
        return

    app_config = select_app(config)
    if not app_config:
        log_message("Seleção inválida.", RED)
        return

    action = select_action()
    if not action:
        log_message("Ação inválida.", RED)
        return

    if action == '1':
        implement_app(app_config, config['base_dir'])
    elif action == '2':
        deploy_app(app_config, config['base_dir'])

# --- Lógica do Servidor Web (Webhook) ---
app = Flask(__name__)

# Carrega a configuração globalmente para o Flask
config_data = load_config()
if config_data:
    SECRET_TOKEN = os.environ.get("WEBHOOK_SECRET_TOKEN", config_data.get("webhook_secret"))
    REPO_TO_APP_NAME = {app['repo_name']: app['name'] for app in config_data.get('applications', [])}
else:
    SECRET_TOKEN = None
    REPO_TO_APP_NAME = {}

@app.route('/status', methods=['GET'])
def status():
    return jsonify({'status': 'ok'}), 200

@app.route('/webhook/deploy/<app_short_name>', methods=['POST'])
def webhook_deploy(app_short_name):
    if not SECRET_TOKEN:
        return jsonify({'status': 'error', 'message': 'Servidor não configurado.'}), 500

    signature_header = request.headers.get('X-Hub-Signature-256')
    if not signature_header:
        return jsonify({'status': 'error', 'message': 'Unauthorized: Missing signature header'}), 401
    
    sha_name, signature = signature_header.split('=', 1)
    mac = hmac.new(SECRET_TOKEN.encode('utf-8'), msg=request.data, digestmod=hashlib.sha256)
    if not hmac.compare_digest(mac.hexdigest(), signature):
        return jsonify({'status': 'error', 'message': 'Unauthorized: Invalid signature'}), 401

    # Constrói o nome completo da aplicação a partir do nome curto na URL
    app_name_to_deploy = f"{app_short_name}_frontend"

    # Valida o payload do GitHub para segurança
    data = request.get_json()
    repo_name_from_payload = data.get('repository', {}).get('name')
    log_message(f"Webhook recebido para '{app_name_to_deploy}' (repo do payload: '{repo_name_from_payload}').", GREEN)

    # Verificação de segurança: o nome construído e o nome do repo no payload devem ser idênticos.
    if app_name_to_deploy != repo_name_from_payload:
        log_message(f"Discrepância de segurança: URL app '{app_name_to_deploy}' não corresponde ao repositório do payload '{repo_name_from_payload}'.", RED)
        return jsonify({"error": "Requisição inválida: a URL não corresponde ao repositório do payload."}), 400
    # Busca a configuração da aplicação diretamente no dicionário global
    app_config = APPLICATIONS.get(app_name_to_deploy)

    # Se a aplicação não for encontrada na configuração, retorna um erro claro.
    if not app_config:
        error_msg = f"ERRO FATAL: Aplicação '{app_name_to_deploy}' (mapeada da URL) não existe no config.json."
        log_message(error_msg, RED)
        return jsonify({"error": error_msg}), 404
    if app_config:
        log_message(f"Iniciando deploy para '{app_name_to_deploy}' em background...", YELLOW)
        deploy_thread = threading.Thread(target=deploy_app, args=(app_config, config_data['base_dir']))
        deploy_thread.start()
        return jsonify({'status': 'accepted', 'message': f"Deploy para '{app_name_to_deploy}' iniciado."}), 202
    else:
        return jsonify({'status': 'error', 'message': f'Configuração para {app_name_to_deploy} não encontrada.'}), 404

# --- Ponto de Entrada Principal ---
if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'serve':
        if not config_data or not SECRET_TOKEN:
            log_message("Impossível iniciar servidor: verifique config.json e a chave 'webhook_secret'.", RED)
        else:
            log_message("Iniciando servidor webhook em modo produção (gunicorn)...", YELLOW)
            gunicorn_path = "/home/joaohenrique/workspaces/.venv/bin/gunicorn"
            os.system(f'{gunicorn_path} --bind 0.0.0.0:8080 --workers 2 --log-level info "deployer:app"')
    else:
        main_cli() # Executa o modo interativo
