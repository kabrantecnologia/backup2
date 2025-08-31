# Deployer

# Guia para Deploy Automatizado de Novos Projetos

Este documento detalha o processo para configurar um novo projeto para ser automaticamente implantado através do serviço `webhook-deployer` sempre que houver um `push` no seu repositório GitHub.

---

### Pré-requisitos

1.  O serviço `webhook-deployer` deve estar configurado e rodando.
2.  O código-fonte do novo projeto já deve estar clonado no servidor (ex: em `/opt/novo-projeto`).
3.  O projeto deve ser containerizado e ter seu próprio `docker-compose.yml`.

---

### Passo 1: Criar o Script de Deploy

Para cada novo projeto, você precisa de um script de shell que execute as ações de deploy. Ele deve ser colocado em um subdiretório dentro de `/opt/Deployer/`.

1.  **Crie um diretório para o script:**
    ```bash
    mkdir /opt/Deployer/NovoProjeto-Deployer
    ```

2.  **Crie o arquivo de script** (ex: `deploy-novo-projeto.sh`) dentro do novo diretório com o seguinte template:

    ```bash
    #!/bin/bash
    # Script de deploy para [NOME DO PROJETO]

    set -e

    # --- CONFIGURAÇÕES ---
    PROJECT_DIR="/opt/novo-projeto" # Caminho para o diretório do projeto
    DOCKER_DIR="$PROJECT_DIR/docker"  # Caminho para o diretório com o docker-compose.yml
    CONTAINER_NAME="novo-projeto-container" # Nome do contêiner principal da aplicação
    APP_URL="https://app.novo-projeto.com.br" # URL para acessar a aplicação
    # ---------------------

    # Cores para logs
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m'

    log_message() {
      echo -e "${2}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
    }

    log_message "Iniciando deploy de '[NOME DO PROJETO]'..." "$YELLOW"

    # 1. Navega para o diretório do projeto e atualiza o código
    cd "$PROJECT_DIR"
    git pull || {
      log_message "Erro ao atualizar o código do repositório." "$RED"
      exit 1
    }

    # 2. Navega para o diretório do Docker e reconstrói o contêiner
    cd "$DOCKER_DIR"
    docker compose up -d --build || {
      log_message "Erro ao reconstruir o contêiner." "$RED"
      exit 1
    }

    # 3. Verifica se o contêiner está rodando
    if docker ps | grep -q "$CONTAINER_NAME"; then
      log_message "O contêiner '$CONTAINER_NAME' está rodando." "$GREEN"
    else
      log_message "Aviso: O contêiner '$CONTAINER_NAME' não parece estar rodando." "$RED"
    fi

    log_message "Deploy concluído! Acesse $APP_URL para verificar." "$GREEN"
    ```

3.  **Personalize as variáveis** no topo do script com os dados do seu novo projeto.

---

### Passo 2: Configurar o Projeto no Servidor

Agora, prepare o script e o repositório do projeto no servidor.

1.  **Dê permissão de execução ao script:**
    ```bash
    chmod +x /opt/Deployer/NovoProjeto-Deployer/deploy-novo-projeto.sh
    ```

2.  **Altere a URL do Git para usar SSH:** Isso é crucial para que o `git pull` funcione sem pedir senha dentro do contêiner de deploy.
    *   Primeiro, verifique a URL atual:
        ```bash
        cd /opt/novo-projeto && git remote -v
        ```
    *   Copie a parte `usuario/repositorio.git` da URL HTTPS e use-a para montar a URL SSH. Em seguida, execute:
        ```bash
        cd /opt/novo-projeto && git remote set-url origin git@github.com:usuario/repositorio.git
        ```

---

### Passo 3: Configurar o Webhook no GitHub

O último passo é dizer ao GitHub para notificar nosso serviço sempre que houver uma atualização.

1.  Vá para o repositório do seu projeto no GitHub.
2.  Navegue até **Settings > Webhooks**.
3.  Clique em **Add webhook**.
4.  Preencha o formulário:
    *   **Payload URL**: `https://deploy.kabran.com.br/webhook/deploy/<app_name>`
        *   **Importante:** O `<app_name>` na URL deve corresponder ao nome do diretório do script de deploy (ex: `NovoProjeto-Deployer`). O serviço usa esse nome para encontrar o script correto.
    *   **Content type**: `application/json`
    *   **Secret**: Use o mesmo token secreto definido na variável `WEBHOOK_SECRET_TOKEN` no arquivo `docker-compose.yml` do `webhook-deployer`.

5.  Salve o webhook.

---

### Passo 4: Testar e Depurar

Faça um `git push` de qualquer alteração para o seu repositório. O deploy deve começar automaticamente.

Para monitorar o processo:

*   **Logs do processo de deploy:**
    ```bash
    docker logs -f webhook-deployer
    ```

*   **Logs da sua aplicação após o deploy:**
    ```bash
    docker logs -f <nome_do_container_da_app>
    ```

Se tudo estiver configurado corretamente, você verá a mágica acontecer em tempo real.
