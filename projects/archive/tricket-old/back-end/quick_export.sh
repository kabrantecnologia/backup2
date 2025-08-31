#!/bin/bash

# Script de exportação rápida do Storage Supabase
# Uso: ./quick_export.sh [tipo] [destino]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORAGE_DIR="$SCRIPT_DIR/volumes/storage"
DATE=$(date +%Y%m%d_%H%M%S)

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_help() {
    echo "🚀 Script de Exportação Rápida do Storage Supabase"
    echo ""
    echo "Uso: $0 [TIPO] [DESTINO]"
    echo ""
    echo "TIPOS disponíveis:"
    echo "  all              - Exportar todo o storage"
    echo "  product-images   - Exportar apenas imagens de produtos"
    echo "  app-images      - Exportar apenas imagens da aplicação"
    echo "  emails          - Exportar apenas arquivos de email"
    echo "  backup          - Criar backup completo compactado"
    echo ""
    echo "Exemplos:"
    echo "  $0 all ~/meu-backup"
    echo "  $0 product-images ~/imagens-produtos"
    echo "  $0 backup ~/backups"
    echo ""
    echo "Se DESTINO não for especificado, usará ~/supabase-export-[DATA]"
}

check_requirements() {
    if [[ ! -d "$STORAGE_DIR" ]]; then
        print_error "Diretório de storage não encontrado: $STORAGE_DIR"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 não encontrado. Por favor, instale o Python 3."
        exit 1
    fi
}

get_storage_info() {
    print_info "📊 Informações do Storage:"
    
    # Tamanho total
    total_size=$(du -sh "$STORAGE_DIR" 2>/dev/null | cut -f1)
    print_info "   Tamanho total: $total_size"
    
    # Contagem de arquivos por bucket
    for bucket in product-images app-images emails; do
        bucket_dir="$STORAGE_DIR/stub/stub/$bucket"
        if [[ -d "$bucket_dir" ]]; then
            count=$(find "$bucket_dir" -type f 2>/dev/null | wc -l)
            size=$(du -sh "$bucket_dir" 2>/dev/null | cut -f1)
            print_info "   $bucket: $count arquivos ($size)"
        fi
    done
    echo ""
}

export_storage() {
    local export_type="$1"
    local destination="$2"
    
    # Definir destino padrão se não especificado
    if [[ -z "$destination" ]]; then
        destination="$HOME/supabase-export-$DATE"
    fi
    
    print_info "🔄 Iniciando exportação..."
    print_info "   Tipo: $export_type"
    print_info "   Destino: $destination"
    echo ""
    
    case "$export_type" in
        "all")
            python3 "$SCRIPT_DIR/export_storage.py" \
                --source "$STORAGE_DIR" \
                --destination "$destination"
            ;;
        "product-images"|"app-images"|"emails")
            python3 "$SCRIPT_DIR/export_storage.py" \
                --source "$STORAGE_DIR" \
                --destination "$destination" \
                --bucket "$export_type"
            ;;
        "backup")
            # Criar backup completo com estrutura preservada
            backup_dir="$destination/backup-$DATE"
            python3 "$SCRIPT_DIR/export_storage.py" \
                --source "$STORAGE_DIR" \
                --destination "$backup_dir" \
                --preserve-structure \
                --create-archive \
                --archive-name "$destination/supabase-storage-backup-$DATE"
            ;;
        *)
            print_error "Tipo de exportação inválido: $export_type"
            show_help
            exit 1
            ;;
    esac
}

verify_export() {
    local destination="$1"
    
    if [[ -d "$destination" ]]; then
        local exported_count=$(find "$destination" -type f 2>/dev/null | wc -l)
        print_success "Exportação concluída!"
        print_info "   Arquivos exportados: $exported_count"
        print_info "   Localização: $destination"
        
        # Mostrar tamanho do export
        local export_size=$(du -sh "$destination" 2>/dev/null | cut -f1)
        print_info "   Tamanho: $export_size"
    else
        print_error "Diretório de destino não encontrado: $destination"
    fi
}

main() {
    # Verificar argumentos
    if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    local export_type="$1"
    local destination="$2"
    
    # Verificar requisitos
    check_requirements
    
    # Mostrar informações
    get_storage_info
    
    # Perguntar confirmação
    read -p "Deseja continuar com a exportação? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Exportação cancelada pelo usuário."
        exit 0
    fi
    
    # Executar exportação
    local start_time=$(date +%s)
    export_storage "$export_type" "$destination"
    local end_time=$(date +%s)
    
    # Verificar resultado
    if [[ -z "$destination" ]]; then
        destination="$HOME/supabase-export-$DATE"
    fi
    verify_export "$destination"
    
    # Mostrar tempo decorrido
    local duration=$((end_time - start_time))
    print_success "Tempo total: ${duration}s"
}

# Executar função principal
main "$@"
