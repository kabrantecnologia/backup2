#!/bin/bash

# Navega para o diretório do script para que possamos usar caminhos relativos
cd "$(dirname "$0")"

# Verifica se o npx está instalado
if ! command -v npx &> /dev/null
then
    echo "npx não foi encontrado. Por favor, instale o Node.js e o npm."
    echo "Você pode baixar em: https://nodejs.org/"
    exit
fi

echo "Formatando arquivos SQL..."

# Loop através de todos os arquivos .sql no diretório
for file in *.sql; do
  # Verifica se é um arquivo
  if [ -f "$file" ]; then
    echo "Formatando $file..."
    # Formata o arquivo e salva em um arquivo temporário, depois substitui o original
    # Isso evita problemas de o arquivo ser sobrescrito enquanto é lido
    npx --yes sql-formatter "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
  fi
done

echo "Formatação concluída."
