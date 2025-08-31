#!/bin/bash

# Script para gerenciar autenticação do bolt.diy
# Gerenciamento de usuários HTTP Basic Auth

echo "========================================"
echo "    🔒 bolt.diy User Management Script    "
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

# Diretórios
TRAEFIK_DIR="/home/joaohenrique/workspaces/services/traefik"
AUTH_FILE="$TRAEFIK_DIR/auth/bolt-auth"
PROVIDER_FILE="$TRAEFIK_DIR/providers/bolt-diy.yml"

# Verificar se htpasswd está instalado
if ! command -v htpasswd &> /dev/null; then
    print_error "htpasswd não está instalado!"
    print_info "Execute: sudo apt install apache2-utils"
    exit 1
fi

# Verificar se o diretório auth existe
if [ ! -d "$TRAEFIK_DIR/auth" ]; then
    print_info "Criando diretório auth..."
    mkdir -p "$TRAEFIK_DIR/auth"
fi

# Menu de opções
show_menu() {
    echo
    print_info "Escolha uma opção:"
    echo "1) 👤 Adicionar usuário"
    echo "2) 🗑️  Remover usuário"
    echo "3) 📋 Listar usuários"
    echo "4) 🔄 Alterar senha"
    echo "5) 🔒 Ver credenciais atuais"
    echo "6) 🚀 Reiniciar bolt.diy"
    echo "7) ❌ Sair"
    echo
}

# Adicionar usuário
add_user() {
    echo
    read -p "Nome de usuário: " username
    if [ -z "$username" ]; then
        print_error "Nome de usuário não pode estar vazio!"
        return
    fi
    
    read -s -p "Senha: " password
    echo
    if [ -z "$password" ]; then
        print_error "Senha não pode estar vazia!"
        return
    fi
    
    read -s -p "Confirmar senha: " password2
    echo
    
    if [ "$password" != "$password2" ]; then
        print_error "Senhas não coincidem!"
        return
    fi
    
    # Verificar se usuário já existe
    if [ -f "$AUTH_FILE" ] && grep -q "^$username:" "$AUTH_FILE"; then
        print_warning "Usuário já existe! Use a opção 4 para alterar a senha."
        return
    fi
    
    # Adicionar usuário
    htpasswd -b "$AUTH_FILE" "$username" "$password"
    print_success "Usuário '$username' adicionado com sucesso!"
    
    update_provider
    restart_service
}

# Remover usuário
remove_user() {
    if [ ! -f "$AUTH_FILE" ]; then
        print_error "Arquivo de autenticação não existe!"
        return
    fi
    
    echo
    print_info "Usuários atuais:"
    cut -d: -f1 "$AUTH_FILE" | nl
    
    echo
    read -p "Nome de usuário para remover: " username
    if [ -z "$username" ]; then
        print_error "Nome de usuário não pode estar vazio!"
        return
    fi
    
    if ! grep -q "^$username:" "$AUTH_FILE"; then
        print_error "Usuário não encontrado!"
        return
    fi
    
    # Confirmar remoção
    read -p "Tem certeza que deseja remover '$username'? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operação cancelada."
        return
    fi
    
    # Remover usuário
    htpasswd -D "$AUTH_FILE" "$username"
    print_success "Usuário '$username' removido com sucesso!"
    
    update_provider
    restart_service
}

# Listar usuários
list_users() {
    if [ ! -f "$AUTH_FILE" ]; then
        print_warning "Nenhum arquivo de autenticação encontrado!"
        return
    fi
    
    echo
    print_info "Usuários cadastrados:"
    cut -d: -f1 "$AUTH_FILE" | nl
}

# Alterar senha
change_password() {
    if [ ! -f "$AUTH_FILE" ]; then
        print_error "Arquivo de autenticação não existe!"
        return
    fi
    
    echo
    print_info "Usuários atuais:"
    cut -d: -f1 "$AUTH_FILE" | nl
    
    echo
    read -p "Nome de usuário: " username
    if [ -z "$username" ]; then
        print_error "Nome de usuário não pode estar vazio!"
        return
    fi
    
    if ! grep -q "^$username:" "$AUTH_FILE"; then
        print_error "Usuário não encontrado!"
        return
    fi
    
    read -s -p "Nova senha: " password
    echo
    if [ -z "$password" ]; then
        print_error "Senha não pode estar vazia!"
        return
    fi
    
    read -s -p "Confirmar nova senha: " password2
    echo
    
    if [ "$password" != "$password2" ]; then
        print_error "Senhas não coincidem!"
        return
    fi
    
    # Alterar senha
    htpasswd -b "$AUTH_FILE" "$username" "$password"
    print_success "Senha do usuário '$username' alterada com sucesso!"
    
    update_provider
    restart_service
}

# Ver credenciais atuais
show_credentials() {
    echo
    print_info "Credenciais de acesso atuais:"
    echo "  🌐 URL: https://bolt.kabran.com.br"
    
    if [ -f "$AUTH_FILE" ]; then
        echo "  👤 Usuários:"
        cut -d: -f1 "$AUTH_FILE" | sed 's/^/    - /'
        echo "  🔒 Senha: (definida pelo usuário)"
    else
        print_warning "Nenhuma autenticação configurada!"
    fi
}

# Atualizar arquivo provider com usuários
update_provider() {
    if [ ! -f "$AUTH_FILE" ]; then
        print_error "Arquivo de autenticação não existe!"
        return
    fi
    
    print_info "Atualizando arquivo provider..."
    
    # Criar lista de usuários formatada para YAML
    users_yaml=""
    while IFS= read -r line; do
        if [ ! -z "$line" ]; then
            users_yaml="$users_yaml          - \"$line\"\n"
        fi
    done < "$AUTH_FILE"
    
    # Atualizar arquivo provider
    cat > "$PROVIDER_FILE" << EOF
http:
  routers:
    # Roteador para o bolt.diy com autenticação básica
    bolt-diy:
      rule: "Host(\`bolt.kabran.com.br\`)"
      entrypoints:
        - websecure
      service: bolt-diy-service
      tls:
        certresolver: cloudflare
      middlewares:
        - bolt-auth-inline

  middlewares:
    # Middleware de autenticação básica inline para o bolt.diy
    bolt-auth-inline:
      basicAuth:
        users:
$(printf "$users_yaml")
  
  services:
    # Serviço para o bolt.diy
    bolt-diy-service:
      loadBalancer:
        servers:
          - url: "http://bolt-diy:5173"
EOF
    
    print_success "Arquivo provider atualizado!"
}

# Reiniciar serviço
restart_service() {
    print_info "Reiniciando bolt.diy para aplicar mudanças..."
    cd /home/joaohenrique/workspaces/bolt.diy
    docker compose --profile development restart > /dev/null 2>&1
    print_success "Serviço reiniciado!"
}

# Função principal
main() {
    # Verificar se está no diretório correto
    if [ ! -d "$TRAEFIK_DIR" ]; then
        print_error "Diretório do Traefik não encontrado!"
        print_info "Esperado: $TRAEFIK_DIR"
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Digite sua opção (1-7): " choice
        
        case $choice in
            1) add_user ;;
            2) remove_user ;;
            3) list_users ;;
            4) change_password ;;
            5) show_credentials ;;
            6) restart_service ;;
            7) 
                print_info "Saindo..."
                exit 0
                ;;
            *)
                print_error "Opção inválida. Digite um número de 1 a 7."
                ;;
        esac
        
        echo
        read -p "Pressione Enter para continuar..."
    done
}

# Executar função principal
main
