#!/bin/bash

# Script para remover arquivos desnecessários para Docker
# Mantém apenas os arquivos essenciais para funcionamento

echo "========================================"
echo "    🧹 bolt.diy Docker Cleanup Script    "
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

print_info "Analisando arquivos para remoção..."

# Arquivos e diretórios desnecessários para Docker
UNNECESSARY_FILES=(
    # Configuração de desenvolvimento local
    ".env.example"
    ".env.production"
    ".editorconfig"
    ".prettierignore"
    ".prettierrc"
    ".eslintrc.json"
    "eslint.config.mjs"
    
    # Husky (Git hooks)
    ".husky"
    
    # Electron (aplicação desktop)
    "electron"
    "electron-builder.yml"
    "electron-update.yml"
    "vite-electron.config.ts"
    "notarize.cjs"
    
    # Cloudflare Workers/Pages
    "wrangler.toml"
    ".wrangler"
    "functions"
    "worker-configuration.d.ts"
    "load-context.ts"
    "bindings.sh"
    
    # Scripts de desenvolvimento local
    "scripts"
    "pre-start.cjs"
    
    # Documentação original
    "README.md"
    "CONTRIBUTING.md"
    "PROJECT.md"
    "FAQ.md"
    "LICENSE"
    "CHANGES.md"
    "changelog.md"
    
    # Arquivos de tipos específicos
    "types"
    
    # Assets do Electron
    "assets"
    
    # Documentação GitHub
    "docs"
    
    # Configuração UnoCSS (se não essencial)
    "uno.config.ts"
)

# Mostrar arquivos que serão removidos
echo
print_warning "Os seguintes arquivos/diretórios serão removidos:"
for item in "${UNNECESSARY_FILES[@]}"; do
    if [ -e "$item" ]; then
        echo "  - $item"
    fi
done

echo
print_warning "Arquivos que serão MANTIDOS para Docker:"
echo "  - package.json, pnpm-lock.yaml (dependências)"
echo "  - docker-compose.yaml, Dockerfile (Docker)"
echo "  - vite.config.ts, tsconfig.json (build)"
echo "  - .env.local (configuração)"
echo "  - app/, public/, icons/ (código da aplicação)"
echo "  - setup-docker.sh, deploy-traefik.sh, manage-auth.sh (scripts Docker)"
echo "  - DOCKER_SETUP.md, AUTHENTICATION.md (documentação Docker)"

echo
read -p "Continuar com a limpeza? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Operação cancelada."
    exit 0
fi

# Fazer backup opcional
read -p "Criar backup antes da limpeza? (Y/n): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    print_info "Criando backup..."
    BACKUP_DIR="../bolt.diy-backup-$(date +%Y%m%d_%H%M%S)"
    cp -r . "$BACKUP_DIR"
    print_success "Backup criado em: $BACKUP_DIR"
fi

print_info "Iniciando limpeza..."

# Remover arquivos
removed_count=0
for item in "${UNNECESSARY_FILES[@]}"; do
    if [ -e "$item" ]; then
        if [ -d "$item" ]; then
            rm -rf "$item"
            print_success "Diretório removido: $item"
        else
            rm -f "$item"
            print_success "Arquivo removido: $item"
        fi
        ((removed_count++))
    fi
done

# Limpar cache e builds
if [ -d "node_modules/.cache" ]; then
    rm -rf node_modules/.cache
    print_success "Cache do node_modules limpo"
fi

if [ -d ".next" ]; then
    rm -rf .next
    print_success "Cache do Next.js removido"
fi

if [ -d "dist" ]; then
    rm -rf dist
    print_success "Diretório dist removido"
fi

# Atualizar .dockerignore
print_info "Atualizando .dockerignore..."
cat > .dockerignore << 'EOF'
# Arquivos de desenvolvimento e Git
.git
.github/
.husky/

# Logs e cache
**/*.log
**/dist
**/build
**/.cache
logs
dist-ssr
.DS_Store

# Backup e arquivos temporários
**/backup
**/*.tmp
**/*.temp

# Scripts não essenciais (mantemos apenas os Docker)
scripts/
bindings.sh

# Documentação original (mantemos apenas Docker docs)
README.md
CONTRIBUTING.md
PROJECT.md
FAQ.md
LICENSE
CHANGES.md
changelog.md

# Configuração específica de ambientes
.env.example
.env.production

# Electron e Workers
electron/
functions/
.wrangler/
wrangler.toml
EOF

print_success ".dockerignore atualizado"

# Mostrar estatísticas
echo
print_success "Limpeza concluída!"
print_info "Arquivos/diretórios removidos: $removed_count"

# Mostrar tamanho do diretório
if command -v du &> /dev/null; then
    size=$(du -sh . | cut -f1)
    print_info "Tamanho atual do diretório: $size"
fi

# Listar arquivos restantes
echo
print_info "Arquivos restantes (principais):"
ls -la | grep -E "(docker|package|vite|tsconfig|\.env|\.md|\.sh)" | head -20

echo
print_success "Projeto otimizado para Docker! 🐳"
print_info "Para testar: ./setup-docker.sh ou docker compose --profile development up"
