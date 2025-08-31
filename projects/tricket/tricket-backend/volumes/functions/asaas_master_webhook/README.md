# Asaas Master Webhook Handler

## 📋 Visão Geral

Esta Edge Function processa webhooks da **conta master Asaas** - a conta pai que gerencia todas as subcontas do sistema Tricket.

## 🎯 Propósito

- Receber e processar eventos globais da conta master Asaas
- Propagar mudanças para subcontas relacionadas
- Manter consistência entre conta master e subcontas
- Registrar histórico de eventos e transações

## 🔧 Eventos Suportados

| Evento | Descrição | Ação |
|--------|-----------|------|
| `PAYMENT_RECEIVED` | Pagamento recebido na master | Atualizar saldos das subcontas |
| `TRANSFER_COMPLETED` | Transferência concluída | Registrar transação master |
| `SUBSCRIPTION_CREATED` | Nova assinatura criada | Propagar para subcontas |
| `CUSTOMER_CREATED` | Novo cliente criado | Configurar subconta |
| `INVOICE_CREATED` | Nova fatura gerada | Notificar subcontas |

## 📡 Como Usar

### 1. Configurar Webhook no Asaas

```bash
URL: https://api-dev2-tricket.kabran.com.br/functions/v1/asaas_master_webhook
Headers:
  - Content-Type: application/json
  - asaas-signature: <assinatura-hmac>
```

### 2. Testar Localmente

```bash
# Deploy da função
supabase functions deploy asaas_master_webhook

# Testar com curl
curl -X POST https://api-dev2-tricket.kabran.com.br/functions/v1/asaas_master_webhook \
  -H "Content-Type: application/json" \
  -d '{
    "event": "PAYMENT_RECEIVED",
    "payment": {
      "id": "pay_123456",
      "customer": "cus_789",
      "value": 1000.00,
      "netValue": 970.00,
      "status": "RECEIVED",
      "billingType": "CREDIT_CARD"
    }
  }'
```

### 3. Payload Exemplo

#### Pagamento Recebido
```json
{
  "event": "PAYMENT_RECEIVED",
  "payment": {
    "id": "pay_123456",
    "customer": "cus_789",
    "value": 1000.00,
    "netValue": 970.00,
    "status": "RECEIVED",
    "billingType": "CREDIT_CARD",
    "paymentDate": "2024-08-09T20:00:00.000Z"
  }
}
```

#### Transferência Concluída
```json
{
  "event": "TRANSFER_COMPLETED",
  "transfer": {
    "id": "tra_789123",
    "value": 500.00,
    "netValue": 495.00,
    "transferFee": 5.00,
    "status": "DONE",
    "transferType": "PIX",
    "effectiveDate": "2024-08-09"
  }
}
```

#### Novo Cliente
```json
{
  "event": "CUSTOMER_CREATED",
  "customer": {
    "id": "cus_456789",
    "name": "João Silva",
    "email": "joao@example.com",
    "cpfCnpj": "123.456.789-00",
    "phone": "(11) 98765-4321"
  }
}
```

## 📊 Tabelas Criadas

### master_webhook_events
- Registro de todos os eventos recebidos
- Status de processamento
- Dados completos do evento

### master_financial_transactions
- Transações financeiras da conta master
- Transferências, pagamentos, etc.

### asaas_accounts
- Subcontas gerenciadas pela master
- Campos adicionais para integração

### subaccount_balance_history
- Histórico de mudanças de saldo
- Rastreabilidade completa

## 🔐 Segurança

- Validação de assinatura HMAC-SHA256
- RLS (Row Level Security) ativado
- Logs estruturados para auditoria
- Rate limiting implícito

## 🚀 Deploy

```bash
# Deploy para staging
supabase functions deploy asaas_master_webhook --project-ref <staging-project>

# Deploy para produção
supabase functions deploy asaas_master_webhook --project-ref <prod-project>

# Configurar webhook no painel Asaas
# URL: https://<project>.supabase.co/functions/v1/asaas_master_webhook
```

## 📈 Monitoramento

### Queries Úteis

```sql
-- Eventos por tipo
SELECT event_type, COUNT(*) FROM master_webhook_events GROUP BY event_type;

-- Subcontas ativas
SELECT COUNT(*) FROM asaas_accounts WHERE status = 'ACTIVE';

-- Transações recentes
SELECT * FROM master_financial_transactions ORDER BY created_at DESC LIMIT 10;

-- Resumo de saldos
SELECT 
  COUNT(*) as total_accounts,
  SUM(balance) as total_balance,
  AVG(balance) as avg_balance
FROM asaas_accounts WHERE status = 'ACTIVE';
```

### Logs

Todos os eventos são logados com:
- ID do evento
- Tipo do evento
- Contas afetadas
- Tempo de processamento
- Erros (se houver)

## 🐛 Debug

### Verificar últimos eventos
```sql
SELECT 
  event_type,
  processed,
  created_at,
  processing_error
FROM master_webhook_events 
ORDER BY created_at DESC 
LIMIT 20;
```

### Verificar processamento de evento específico
```sql
SELECT * FROM master_webhook_events 
WHERE event_data->>'id' = 'pay_123456';
```
