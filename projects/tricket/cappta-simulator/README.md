# Cappta Fake Simulator

Simulador da API Cappta para desenvolvimento do sistema Tricket. Permite testar fluxos de pagamento sem dependência da integração real.

## Funcionalidades

- **Gerenciamento de Comerciantes**: Cadastro e consulta de comerciantes
- **Simulação de Transações**: Criação de vendas simuladas com cálculo automático de taxas
- **Sistema de Liquidação**: Processamento de liquidações D+1 simulado
- **Webhooks**: Notificações automáticas para o sistema Tricket
- **Integração Asaas**: Simulação de transferências via API Asaas
- **Auditoria Completa**: Logs detalhados de todas as operações

## Arquitetura

```
cappta-simulator/
├── app/
│   ├── main.py              # FastAPI application
│   ├── models/              # Pydantic models
│   ├── api/                 # API endpoints
│   ├── services/            # Business logic
│   └── database/            # SQLite local
├── config/
│   └── settings.py          # Configuration
├── docker-compose.yml       # Container setup
├── Dockerfile
└── requirements.txt
```

## Configuração

### Variáveis de Ambiente (.env)

```bash
# Environment
ENVIRONMENT=dev
DEBUG=true

# API Configuration
API_TOKEN=cappta_fake_token_dev_123
API_HOST=0.0.0.0
API_PORT=8000

# Asaas Integration
ASAAS_API_KEY=sandbox_key_demo
ASAAS_BASE_URL=https://sandbox.asaas.com/api/v3
CAPPTA_MASTER_ACCOUNT_ID=acc_cappta_fake_demo

# Tricket Integration
TRICKET_WEBHOOK_URL=http://localhost:54321/functions/v1/cappta_webhook_receiver
TRICKET_WEBHOOK_SECRET=webhook_secret_dev_123

# Security
ALLOWED_IPS=["127.0.0.1", "localhost", "::1"]

# Database
DATABASE_URL=sqlite:///./cappta_simulator.db
```

## Instalação e Execução

### Método 1: Python Local

```bash
# Instalar dependências
pip install -r requirements.txt

# Executar servidor
python -m uvicorn app.main:app --host localhost --port 8000

# Ou usar o script direto
python app/main.py
```

### Método 2: Docker

```bash
# Build da imagem
docker build -t cappta-fake-simulator .

# Executar container
docker-compose up -d

# Verificar logs
docker-compose logs -f
```

## Uso da API

### Autenticação

Todas as rotas (exceto documentação) requerem autenticação via Bearer token:

```bash
curl -H "Authorization: Bearer cappta_fake_token_dev_123" \
     http://localhost:8000/merchants/
```

### Endpoints Principais

#### Health Checks

```bash
# Status básico
GET /

# Health check detalhado
GET /detailed

# Readiness probe
GET /ready

# Liveness probe  
GET /live
```

#### Comerciantes

```bash
# Listar comerciantes
GET /merchants/

# Criar comerciante
POST /merchants/
{
  "merchant_id": "uuid",
  "asaas_account_id": "acc_123", 
  "business_name": "Padaria da Maria",
  "document": "12345678901",
  "email": "maria@padaria.com",
  "phone": "11999999999"
}

# Consultar comerciante
GET /merchants/{merchant_id}

# Ativar/desativar comerciante
PUT /merchants/{merchant_id}/status?is_active=true
```

#### Transações

```bash
# Criar transação
POST /transactions/
{
  "merchant_id": "uuid",
  "terminal_id": "term_001",
  "payment_method": "credit",
  "gross_amount": 10000,
  "installments": 1
}

# Listar transações
GET /transactions/

# Consultar transação
GET /transactions/{transaction_id}

# Atualizar status
PUT /transactions/{transaction_id}/status
{
  "status": "approved",
  "reason": "Manual approval"
}

# Simulação em lote
POST /transactions/simulate-batch
{
  "merchant_id": "uuid",
  "count": 10,
  "amount_range": [1000, 50000]
}
```

#### Liquidações

```bash
# Criar liquidação
POST /settlements/
{
  "merchant_id": "uuid",
  "transaction_refs": ["evt_123", "evt_456"],
  "settlement_date": "2025-08-19",
  "force_settlement": false
}

# Listar liquidações
GET /settlements/

# Consultar liquidação
GET /settlements/{settlement_id}

# Liquidação automática
POST /settlements/auto-settle
{
  "merchant_id": "uuid",
  "settlement_date": "2025-08-19"
}

# Resumo do comerciante
GET /settlements/merchant/{merchant_id}/summary
```

## Regras de Negócio

### Cálculo de Taxas

- **Taxa Padrão**: 3% + R$ 0,30 por transação
- **Parcelamento**: Taxa adicional de 0.5% por parcela acima de 1x
- **PIX**: Taxa fixa de R$ 0,10
- **Débito**: Taxa de 2% + R$ 0,20

### Liquidação

- **Prazo**: D+1 para crédito, D+0 para débito e PIX
- **Agrupamento**: Por comerciante e data de liquidação
- **Valor Mínimo**: R$ 10,00 para liquidação automática

### Status de Transação

- `pending`: Aguardando processamento
- `approved`: Aprovada e capturada
- `declined`: Negada
- `cancelled`: Cancelada
- `settled`: Liquidada

### Status de Liquidação

- `pending`: Aguardando processamento
- `processing`: Em processamento no Asaas
- `completed`: Concluída com sucesso
- `failed`: Falhou

## Webhooks

O simulador envia webhooks para o sistema Tricket em eventos importantes:

### Eventos de Transação

```json
{
  "event": "transaction.approved",
  "data": {
    "transaction_id": "txn_123",
    "merchant_id": "uuid",
    "amount": 9700,
    "status": "approved",
    "captured_at": "2025-08-18T19:00:00Z",
    "external_event_id": "evt_unique"
  },
  "timestamp": "2025-08-18T19:00:00Z"
}
```

### Eventos de Liquidação

```json
{
  "event": "settlement.completed",
  "data": {
    "settlement_id": "stl_456",
    "merchant_id": "uuid",
    "net_amount": 48500,
    "transaction_count": 5,
    "settlement_date": "2025-08-18",
    "asaas_transfer_id": "transfer_789"
  },
  "timestamp": "2025-08-18T19:00:00Z"
}
```

### Assinatura

Todos os webhooks incluem assinatura HMAC-SHA256 no header `X-Cappta-Signature`.

## Monitoramento

### Logs

O simulador gera logs estruturados:

```bash
# Ver logs em tempo real
tail -f cappta_simulator.log

# Logs via Docker
docker-compose logs -f cappta-fake-simulator
```

### Métricas

- **Database**: Status da conexão SQLite
- **Webhooks**: Taxa de sucesso e falhas
- **Asaas**: Status da configuração
- **Sistema**: CPU, memória, disco

### Banco de Dados

```bash
# Verificar tabelas criadas
sqlite3 cappta_simulator.db ".tables"

# Consultar transações
sqlite3 cappta_simulator.db "SELECT * FROM transactions LIMIT 5;"

# Limpar dados de teste
rm cappta_simulator.db
```

## Desenvolvimento

### Estrutura do Código

- **Models**: Validação e serialização de dados (Pydantic)
- **API**: Endpoints REST organizados por domínio
- **Services**: Lógica de negócio e integração externa
- **Database**: Modelos SQLAlchemy e gestão de conexão

### Testes

```bash
# Executar testes de importação
python test_imports.py

# Teste manual dos endpoints
curl -H "Authorization: Bearer cappta_fake_token_dev_123" \
     http://localhost:8000/ready
```

### Debug

```bash
# Executar em modo debug
python -m uvicorn app.main:app --reload --log-level debug

# Verificar configurações
python -c "from config.settings import settings; print(settings.dict())"
```

## Integração com Tricket

### Edge Function Webhook

O simulador espera que exista uma Edge Function em:
`http://localhost:54321/functions/v1/cappta_webhook_receiver`

### Fluxo Completo

1. **Transação**: Simulador cria transação → envia webhook
2. **Liquidação**: Processamento D+1 → transferência Asaas → webhook
3. **Ledger**: Edge Function processa webhook → atualiza saldo interno

### Teste de Integração

```bash
# Criar merchant
curl -X POST -H "Authorization: Bearer cappta_fake_token_dev_123" \
     -H "Content-Type: application/json" \
     -d '{"merchant_id":"test-uuid","asaas_account_id":"acc_test",...}' \
     http://localhost:8000/merchants/

# Simular vendas
curl -X POST -H "Authorization: Bearer cappta_fake_token_dev_123" \
     -H "Content-Type: application/json" \
     -d '{"merchant_id":"test-uuid","terminal_id":"term_001","gross_amount":10000}' \
     http://localhost:8000/transactions/

# Processar liquidação
curl -X POST -H "Authorization: Bearer cappta_fake_token_dev_123" \
     -H "Content-Type: application/json" \
     -d '{"merchant_id":"test-uuid"}' \
     http://localhost:8000/settlements/auto-settle
```

## Solução de Problemas

### Erro de Porta em Uso

```bash
# Encontrar processo
lsof -i :8000

# Matar processo
pkill -f "uvicorn app.main:app"
```

### Erro de Banco

```bash
# Recriar banco
rm cappta_simulator.db
python -c "from app.database.connection import create_tables; create_tables()"
```

### Erro de Configuração

```bash
# Verificar .env
cat .env

# Testar configurações
python -c "from config.settings import settings; print(f'Token: {settings.API_TOKEN}')"
```

## Documentação da API

Com o servidor rodando, acesse:

- **Swagger UI**: http://localhost:8000/docs
- **OpenAPI JSON**: http://localhost:8000/openapi.json
- **ReDoc**: http://localhost:8000/redoc