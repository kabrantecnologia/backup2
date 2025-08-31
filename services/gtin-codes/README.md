# Scraper de Códigos de Barras

Este projeto contém um script Python que coleta códigos de barras de produtos do site da Megga Distribuidora e os salva em um arquivo CSV. O script é executado em um contêiner Docker para facilitar a implantação e execução.

## Requisitos

- Docker
- Docker Compose

## Configuração

1. **Clone o repositório**
   ```bash
   git clone <seu-repositorio>
   cd gtin-codes
   ```

2. **Construa a imagem Docker**
   ```bash
   docker-compose build
   ```

3. **Execute o contêiner**
   ```bash
   docker-compose up -d
   ```

## Estrutura de Arquivos

- `collect_barcodes.py`: Script principal de scraping
- `Dockerfile`: Configuração do contêiner Docker
- `docker-compose.yml`: Configuração do serviço Docker
- `requirements.txt`: Dependências do Python
- `data/`: Diretório onde os arquivos CSV serão salvos (montado como volume)
- `entrypoint.sh`: Script de inicialização do contêiner

## Variáveis de Ambiente

Você pode configurar as seguintes variáveis de ambiente no arquivo `docker-compose.yml`:

- `SITEMAP_URL`: URL do sitemap de produtos (padrão: sitemap da Megga Distribuidora)
- `OUTPUT_FILE`: Caminho para o arquivo de saída (padrão: `data/barcodes_robust.csv`)
- `REQUEST_TIMEOUT`: Timeout para requisições em milissegundos (padrão: 30000)

## Monitoramento

Para ver os logs do contêiner em execução:

```bash
docker-compose logs -f
```

## Parando o Contêiner

Para parar o contêiner:

```bash
docker-compose down
```

## Dados Coletados

Os dados coletados são salvos no arquivo CSV especificado, contendo as seguintes colunas:

- Nome do Produto
- Código de Barras
- Data da Coleta

## Solução de Problemas

Se encontrar problemas com permissões de arquivo, execute:

```bash
sudo chown -R $USER:$USER data/
```

## Notas

- O script faz pausas entre as requisições para evitar sobrecarregar o servidor.
- Os logs são salvos em `scraper.log` dentro do contêiner.
