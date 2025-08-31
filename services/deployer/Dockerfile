# Usar uma imagem base oficial do Python
FROM python:3.9-slim

# Instalar git, que é necessário para o script fazer 'git pull'
RUN apt-get update && apt-get install -y git

# Definir o diretório de trabalho no contêiner
WORKDIR /app

# Copiar o arquivo de dependências e instalar
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar o script principal e a configuração
COPY deployer.py .
COPY config.json .

# Expor a porta que o Gunicorn irá rodar
EXPOSE 8080

# Comando para iniciar o servidor web
# Ele executa o deployer.py em modo 'serve'
CMD ["python3", "deployer.py", "serve"]
