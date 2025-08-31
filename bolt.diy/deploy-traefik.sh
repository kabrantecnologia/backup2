#!/bin/bash

# Script para deploy do bolt.diy com Traefik
# Configuração para bolt.kabran.com.br

echo "========================================"
echo "    🚀 bolt.diy Traefik Deploy Script    "
echo "========================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Verificar se está na pasta correta
if [ ! -f "package.json" ] || [ ! -f "docker-compose.yaml" ]; then
    print_error "Execute este script na pasta raiz do bolt.diy"
    exit 1
fi

# Verificar se a rede traefik-proxy existe
if ! docker network ls | grep -q "traefik-proxy"; then
    print_info "Criando rede traefik-proxy..."
    docker network create traefik-proxy
    print_success "Rede traefik-proxy criada!"
else
    print_success "Rede traefik-proxy já existe!"
fi

# Verificar se o Traefik está rodando
if ! docker ps | grep -q "traefik-main"; then
    print_warning "Traefik não está rodando!"
    print_info "Iniciando Traefik primeiro..."
    
    if [ -d "/home/joaohenrique/workspaces/services/traefik" ]; then
        cd /home/joaohenrique/workspaces/services/traefik
        docker compose up -d
        print_success "Traefik iniciado!"
        cd - > /dev/null
    else
        print_error "Diretório do Traefik não encontrado!"
        print_info "Certifique-se de que o Traefik está configurado em /home/joaohenrique/workspaces/services/traefik"
        exit 1
    fi
else
    print_success "Traefik já está rodando!"
fi

# Verificar arquivo .env.local
if [ ! -f ".env.local" ]; then
    print_warning "Arquivo .env.local não encontrado!"
    print_info "Usando configurações padrão. Configure suas API keys depois."
fi

# Parar containers existentes se estiverem rodando
print_info "Parando containers existentes..."
docker compose down --remove-orphans

# Iniciar bolt.diy
print_info "Iniciando bolt.diy com Traefik..."
print_info "Domínio: https://bolt.kabran.com.br"
print_info "Aguarde alguns minutos para o certificado SSL ser gerado..."

docker compose --profile development up -d

# Verificar se o container foi iniciado
sleep 5
if docker ps | grep -q "bolt-diy"; then
    print_success "bolt.diy iniciado com sucesso!"
    echo
    print_info "Acessos disponíveis:"
    echo "  🌐 Público: https://bolt.kabran.com.br"
    echo "  🏠 Local:   http://localhost:5173"
    echo
    print_info "Logs em tempo real:"
    echo "  docker compose logs -f"
    echo
    print_warning "Aguarde 1-2 minutos para o certificado SSL ser emitido"
    print_info "Você pode acompanhar o processo nos logs do Traefik"
else
    print_error "Falha ao iniciar bolt.diy"
    print_info "Verificando logs..."
    docker compose logs
    exit 1
fi

echo
print_success "Deploy concluído! 🎉"
