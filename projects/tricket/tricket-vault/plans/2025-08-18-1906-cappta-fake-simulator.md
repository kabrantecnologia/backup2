# Plano: Cappta Fake Simulator + Asaas Master

Data/Hora: 2025-08-18 19:06 BRT
Branch: feat/cappta-fake-simulator (a partir de dev)

## Objetivo
Viabilizar o desenvolvimento dos fluxos financeiros sem dependência imediata da integração Cappta real, por meio de um serviço Python (FastAPI) que simula a Cappta e utiliza uma conta-matriz no Asaas ("Cappta Fake Account") para realizar transferências aos comerciantes, enquanto o backend registra créditos via ledger interno.

## Referências
- Documentação Cappta (White Label API): https://integration.cappta.com.br/#4053598f-9566-46a3-9527-4bd72b50c297
- Diretrizes do projeto: `tricket-vault/docs/project-overview.md`, `tricket-vault/docs/PRD-tricket-e.md`, `tricket-vault/docs/product-plan-epics-user-stories.md`

## Escopo desta fase (documentação e implementação)
- Definir arquitetura completa do simulador.
- Definir contratos de API detalhados e autenticação.
- Definir entidades e fluxo de eventos até o ledger interno.
- Implementar simulador FastAPI completo.
- Configurar ambiente de desenvolvimento com Docker.
- Integrar com sistema de testes existente.

## Arquitetura proposta

### Estrutura do Simulador
```
tricket-backend/simulators/cappta-fake/
├── app/
│   ├── main.py              # FastAPI main application
│   ├── models/              # Pydantic models
│   │   ├── merchant.py      # Modelos de comerciante
│   │   ├── transaction.py   # Modelos de transação
│   │   └── settlement.py    # Modelos de liquidação
│   ├── services/            # Business logic
│   │   ├── asaas_client.py  # Cliente Asaas
│   │   ├── transaction_processor.py
│   │   ├── settlement_processor.py
│   │   └── webhook_sender.py
│   ├── api/                 # API endpoints
│   │   ├── merchants.py     # Gestão de comerciantes
│   │   ├── transactions.py  # Simulação de vendas
│   │   ├── settlements.py   # Liquidações
│   │   └── health.py        # Health checks
│   └── database/            # SQLite local para dados do simulador
│       ├── models.py        # SQLAlchemy models
│       └── connection.py    # Database connection
├── config/
│   └── settings.py          # Configurações por ambiente
├── docker-compose.yml       # Container do simulador
├── Dockerfile
├── requirements.txt
└── README.md
```

### Endpoints da API
- `POST /merchants`: cadastrar comerciante (mapear merchant_id → conta Asaas)
- `GET /merchants/{merchant_id}`: consultar dados do comerciante
- `POST /terminals`: cadastrar terminais associados
- `POST /transactions`: registrar vendas simuladas
- `GET /transactions/{transaction_id}`: consultar transação
- `POST /settlements`: efetivar liquidação
- `GET /settlements/{merchant_id}`: consultar liquidações
- `POST /webhook/tricket`: webhook para notificar Tricket

### Integração Asaas
- Conta-matriz "Cappta Fake Account" com saldo fictício (ambiente de desenvolvimento)
- API de transferências para contas dos comerciantes
- Webhook de confirmação de transferência do Asaas → Edge Function no backend → crédito no ledger
- Sistema de reconciliação automática

### Ledger Interno (fonte de verdade dos saldos)
- Contas e lançamentos (`balance_pending`, `balance_available`)
- Idempotência por `external_event_id`/`asaas_payment_id`
- Reconciliação periódica Asaas × ledger
- Auditoria completa de transações

## Contratos de API Detalhados

### Autenticação
- Bearer token + allowlist de IP em DEV
- Header: `Authorization: Bearer <token>`
- Validação de IP permitidos para ambiente de desenvolvimento

### Modelos de Dados

#### TransactionStatus
```python
class TransactionStatus(Enum):
    PENDING = "pending"
    APPROVED = "approved" 
    DECLINED = "declined"
    CANCELLED = "cancelled"
    SETTLED = "settled"
```

#### PaymentMethod
```python
class PaymentMethod(Enum):
    CREDIT = "credit"
    DEBIT = "debit"
    PIX = "pix"
```

### Endpoints Detalhados

#### `POST /merchants`
```json
{
  "merchant_id": "uuid",
  "asaas_account_id": "acc_123",
  "business_name": "Padaria da Maria",
  "document": "12345678901",
  "email": "maria@padaria.com",
  "phone": "+5511999999999"
}
```

#### `POST /transactions`
```json
{
  "merchant_id": "uuid",
  "terminal_id": "term_001",
  "transaction_id": "txn_unique_id",
  "nsu": "000001234",
  "authorization_code": "AUTH123456",
  "payment_method": "credit",
  "card_brand": "visa",
  "gross_amount": 10000,
  "fee_amount": 300,
  "net_amount": 9700,
  "installments": 1,
  "status": "approved",
  "captured_at": "2025-08-18T19:00:00Z",
  "external_event_id": "string-unique"
}
```

#### `POST /settlements`
```json
{
  "merchant_id": "uuid",
  "settlement_id": "stl_unique_id",
  "gross_amount": 50000,
  "fee_amount": 1500,
  "net_amount": 48500,
  "transaction_refs": ["external_event_id-1", "external_event_id-2"],
  "settlement_date": "2025-08-18",
  "status": "processing"
}
```

#### `POST /webhook/tricket`
```json
{
  "event_type": "transaction.approved",
  "merchant_id": "uuid",
  "transaction_id": "txn_123",
  "amount": 9700,
  "timestamp": "2025-08-18T19:00:00Z",
  "signature": "sha256_signature"
}
```

### Configurações por Ambiente
```python
class Settings:
    # Asaas Integration
    ASAAS_API_KEY: str = "sandbox_key"
    ASAAS_BASE_URL: str = "https://sandbox.asaas.com/api/v3"
    CAPPTA_MASTER_ACCOUNT_ID: str = "acc_cappta_fake"
    
    # Tricket Integration
    TRICKET_WEBHOOK_URL: str = "http://localhost:54321/functions/v1/cappta_webhook_receiver"
    TRICKET_WEBHOOK_SECRET: str = "webhook_secret"
    
    # Business Rules
    DEFAULT_FEE_PERCENTAGE: float = 3.0  # 3%
    DEFAULT_FEE_FIXED: int = 30  # R$ 0,30
    SETTLEMENT_DELAY_HOURS: int = 24  # D+1 simulado
    MAX_TRANSACTION_AMOUNT: int = 1000000  # R$ 10.000,00
    
    # Database
    DATABASE_URL: str = "sqlite:///./cappta_simulator.db"
    
    # Security
    API_TOKEN: str = "cappta_simulator_token_dev"
    ALLOWED_IPS: list = ["127.0.0.1", "localhost"]
```

## Integração com documentação Cappta
- Os endpoints e campos do simulador serão inspirados na documentação Cappta (White Label), priorizando:
  - Modelo de autenticação por token em header.
  - Estruturas de vendas/autorizações (NSU, authorization_code).
  - Possíveis eventos de captura e liquidação.
- O objetivo é manter o contrato do simulador compatível para facilitar a troca pela Cappta real.

## Critérios de aceite desta fase
- Branch criada.
- Plano e changelog adicionados ao repositório.
- Sem alterações de código/backend/migrations nesta etapa.

## Próximas etapas (não incluídas agora)
- Migrations do ledger e Edge Function webhook Asaas.
- Implementação do serviço FastAPI do simulador e Dockerfile.
- Testes de integração Pytest (E2E) com o simulador.
