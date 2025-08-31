#!/bin/bash

# Script de instalação e configuração do bolt.diy com Docker
# Autor: Assistente GitHub Copilot

echo "========================================"
echo "    🚀 bolt.diy Docker Setup Script    "
echo "========================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para mostrar mensagens coloridas
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se o Docker está instalado
check_docker() {
    print_info "Verificando se Docker está instalado..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker não está instalado. Instale o Docker primeiro:"
        echo "  Ubuntu/Debian: sudo apt update && sudo apt install docker.io docker-compose"
        echo "  CentOS/RHEL: sudo yum install docker docker-compose"
        echo "  Ou baixe do site oficial: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose não está instalado."
        echo "  Instale docker-compose ou use uma versão mais recente do Docker"
        exit 1
    fi
    
    print_success "Docker está instalado!"
}

# Verificar se o arquivo .env.local existe
check_env() {
    print_info "Verificando arquivo de configuração..."
    if [ ! -f ".env.local" ]; then
        print_warning "Arquivo .env.local não encontrado. Criando um modelo..."
        create_env_template
    else
        print_success "Arquivo .env.local encontrado!"
    fi
}

# Criar template do arquivo .env.local
create_env_template() {
    cat > .env.local << EOF
# Configurações principais do bolt.diy
NODE_ENV=development
PORT=5173
VITE_LOG_LEVEL=debug
DEFAULT_NUM_CTX=32768
RUNNING_IN_DOCKER=true

# ====================================================
# CONFIGURAÇÃO DE APIs - ADICIONE SUAS CHAVES AQUI
# ====================================================

# OpenAI (GPT-3.5, GPT-4, etc.)
OPENAI_API_KEY=

# Anthropic (Claude)
ANTHROPIC_API_KEY=

# Google (Gemini)
GOOGLE_GENERATIVE_AI_API_KEY=

# Groq (Modelos rápidos)
GROQ_API_KEY=

# OpenRouter (Acesso a vários modelos)
OPEN_ROUTER_API_KEY=

# Hugging Face
HuggingFace_API_KEY=

# xAI (Grok)
XAI_API_KEY=

# Together AI
TOGETHER_API_KEY=
TOGETHER_API_BASE_URL=https://api.together.xyz

# Ollama (se estiver rodando localmente)
OLLAMA_API_BASE_URL=http://host.docker.internal:11434

# AWS Bedrock (formato JSON)
# AWS_BEDROCK_CONFIG={"region":"us-east-1","accessKeyId":"your_key","secretAccessKey":"your_secret"}

# Configurações de desenvolvimento (não altere)
VITE_HMR_PROTOCOL=ws
VITE_HMR_HOST=localhost
VITE_HMR_PORT=5173
CHOKIDAR_USEPOLLING=true
WATCHPACK_POLLING=true
EOF
    
    print_warning "Arquivo .env.local criado! Edite-o e adicione suas chaves de API antes de continuar."
}

# Menu de opções
show_menu() {
    echo
    print_info "Escolha uma opção:"
    echo "1) 🔧 Modo Desenvolvimento (recomendado para desenvolvimento)"
    echo "2) 🚀 Modo Produção (build local)"
    echo "3) 📦 Usar Imagem Pré-construída (mais rápido)"
    echo "4) 🛠️  Editar configurações (.env.local)"
    echo "5) 📊 Ver status dos containers"
    echo "6) 🛑 Parar todos os containers"
    echo "7) 🗑️  Limpar containers e images"
    echo "8) 📋 Mostrar logs"
    echo "9) ❌ Sair"
    echo
}

# Executar em modo desenvolvimento
run_development() {
    print_info "Iniciando bolt.diy em modo desenvolvimento..."
    print_info "Isso pode demorar alguns minutos na primeira vez..."
    docker compose --profile development up
}

# Executar em modo produção
run_production() {
    print_info "Iniciando bolt.diy em modo produção..."
    print_info "Fazendo build da aplicação..."
    docker compose --profile production up --build
}

# Executar imagem pré-construída
run_prebuilt() {
    print_info "Iniciando bolt.diy com imagem pré-construída..."
    docker compose --profile prebuilt up
}

# Editar configurações
edit_config() {
    if command -v nano &> /dev/null; then
        nano .env.local
    elif command -v vim &> /dev/null; then
        vim .env.local
    elif command -v vi &> /dev/null; then
        vi .env.local
    else
        print_error "Nenhum editor de texto encontrado. Edite o arquivo .env.local manualmente."
    fi
}

# Ver status dos containers
show_status() {
    print_info "Status dos containers:"
    docker compose ps
}

# Parar containers
stop_containers() {
    print_info "Parando todos os containers..."
    docker compose --profile development down
    docker compose --profile production down
    docker compose --profile prebuilt down
    print_success "Containers parados!"
}

# Limpar containers e imagens
cleanup() {
    print_warning "Esta operação irá remover todos os containers e imagens do bolt.diy"
    read -p "Tem certeza? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Limpando containers e imagens..."
        docker compose down --rmi all --volumes --remove-orphans
        docker system prune -f
        print_success "Limpeza concluída!"
    fi
}

# Mostrar logs
show_logs() {
    print_info "Mostrando logs dos containers..."
    docker compose logs --follow
}

# Função principal
main() {
    echo
    print_info "Inicializando setup do bolt.diy..."
    
    check_docker
    check_env
    
    while true; do
        show_menu
        read -p "Digite sua opção (1-9): " choice
        
        case $choice in
            1) run_development ;;
            2) run_production ;;
            3) run_prebuilt ;;
            4) edit_config ;;
            5) show_status ;;
            6) stop_containers ;;
            7) cleanup ;;
            8) show_logs ;;
            9) 
                print_info "Saindo..."
                exit 0
                ;;
            *)
                print_error "Opção inválida. Digite um número de 1 a 9."
                ;;
        esac
        
        echo
        read -p "Pressione Enter para continuar..."
    done
}

# Verificar se está na pasta correta
if [ ! -f "package.json" ] || [ ! -f "docker-compose.yaml" ]; then
    print_error "Este script deve ser executado na pasta raiz do bolt.diy"
    print_info "Certifique-se de estar na pasta que contém os arquivos package.json e docker-compose.yaml"
    exit 1
fi

# Executar função principal
main
