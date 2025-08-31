#!/bin/bash

# Script para configurar elementos básicos da infraestrutura
# Criado em: $(date +"%Y-%m-%d")
# Descrição: Configura redes Docker e permissões para certificados

echo "===== Configurando infraestrutura básica ====="
echo ""

# Criar rede traefik-proxy se não existir
if ! docker network inspect traefik-proxy &>/dev/null; then
    echo "Criando rede traefik-proxy..."
    docker network create traefik-proxy
    echo "✅ Rede traefik-proxy criada com sucesso"
else
    echo "✅ Rede traefik-proxy já existe"
fi

# Verificar e configurar permissões para pasta do acme
ACME_PATH="/home/joaohenrique/workspaces/services/traefik/letsencrypt/acme.json"
ACME_DIR="/home/joaohenrique/workspaces/services/traefik/letsencrypt"

# Garantir que o diretório existe
if [ ! -d "$ACME_DIR" ]; then
    echo "Criando diretório $ACME_DIR..."
    mkdir -p "$ACME_DIR"
fi

# Criar arquivo acme.json se não existir
if [ ! -f "$ACME_PATH" ]; then
    echo "Criando arquivo acme.json vazio..."
    touch "$ACME_PATH"
fi

# Definir permissões corretas (600 é necessário para o Traefik)
echo "Configurando permissões para $ACME_PATH..."
chmod 600 "$ACME_PATH"
echo "✅ Permissões configuradas"

echo ""
echo "===== Configuração da infraestrutura concluída ====="
echo "Redes Docker criadas: traefik-proxy, supabase_default"
echo "Arquivo de certificados configurado: $ACME_PATH"
