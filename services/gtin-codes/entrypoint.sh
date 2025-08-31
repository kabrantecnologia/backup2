#!/bin/bash
set -e

# Cria o diretório de dados e garante permissões
mkdir -p /app/data
chmod -R 777 /app/data

# Instala as dependências do Playwright
playwright install --with-deps

# Executa o script Python apenas uma vez
python /app/collect_barcodes.py

# Verifica se o arquivo de saída foi criado
if [ -f "/app/data/barcodes_robust.csv" ]; then
    echo "Arquivo de saída gerado com sucesso!"
    echo "Conteúdo do arquivo:"
    cat /app/data/barcodes_robust.csv
else
    echo "Erro: O arquivo de saída não foi encontrado."
fi

# Mantém o contêiner em execução
while true; do
    echo "Contêiner em execução. Pressione Ctrl+C para sair."
    sleep 3600  # Mantém o contêiner em execução por 1 hora
    # Se precisar executar novamente após 1 hora, descomente a linha abaixo
    # python /app/collect_barcodes.py
done
