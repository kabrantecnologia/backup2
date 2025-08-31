# Asaas Webhooks List - Documentação

## 📋 Descrição

Edge Function que lista todos os webhooks cadastrados em uma conta Asaas, permitindo visualizar e gerenciar as configurações de webhooks ativas.

## 🔗 Endpoint

```
POST https://your-project.supabase.co/functions/v1/asaas_webhooks_list
```

## 📖 Documentação da API

Esta função implementa a funcionalidade equivalente ao endpoint da API Asaas:
- **Documentação oficial**: https://docs.asaas.com/reference/list-webhooks
- **Método**: GET (via API Asaas) → POST (nossa função)

## 📤 Requisição

### Headers
```
Content-Type: application/json
```

### Body
```json
{
  "asaas_account_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Campos Obrigatórios
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `asaas_account_id` | string | ID da conta Asaas no banco de dados |

## 📥 Resposta

### Sucesso (200)
```json
{
  "success": true,
  "message": "Webhooks listados com sucesso",
  "data": {
    "account_id": "550e8400-e29b-41d4-a716-446655440000",
    "asaas_account_id": "acc_123456789",
    "webhooks": [
      {
        "object": "webhook",
        "id": "webhook_123456",
        "name": "AccountStatus",
        "url": "https://api.tricket.com.br/functions/v1/asaas_webhook_account_status",
        "email": "baas@tricket.com.br",
        "enabled": true,
        "interrupted": false,
        "authToken": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
        "events": [
          "ACCOUNT_STATUS_BANK_ACCOUNT_INFO_APPROVED",
          "ACCOUNT_STATUS_BANK_ACCOUNT_INFO_AWAITING_APPROVAL",
          "ACCOUNT_STATUS_UPDATED"
        ],
        "sendType": "SEQUENTIALLY",
        "status": "ACTIVE",
        "deleted": false,
        "dateCreated": "2025-01-25T10:30:00Z",
        "dateUpdated": "2025-01-25T10:30:00Z"
      },
      {
        "object": "webhook",
        "id": "webhook_789012",
        "name": "TransferStatus",
        "url": "https://api.tricket.com.br/functions/v1/asaas_webhook_transfer_status",
        "email": "baas@tricket.com.br",
        "enabled": true,
        "interrupted": false,
        "authToken": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
        "events": [
          "TRANSFER_CREATED",
          "TRANSFER_PENDING",
          "TRANSFER_DONE",
          "TRANSFER_FAILED"
        ],
        "sendType": "SEQUENTIALLY",
        "status": "ACTIVE",
        "deleted": false,
        "dateCreated": "2025-01-25T10:30:00Z",
        "dateUpdated": "2025-01-25T10:30:00Z"
      }
    ],
    "total_count": 2,
    "has_more": false
  }
}
```

## ❌ Erros

### 400 - Bad Request
```json
{
  "success": false,
  "error": "Dados de entrada inválidos",
  "details": "Campos obrigatórios: asaas_account_id"
}
```

### 404 - Not Found
```json
{
  "success": false,
  "error": "Conta Asaas não encontrada",
  "details": "Conta com ID especificado não existe"
}
```

### 500 - Internal Server Error
```json
{
  "success": false,
  "error": "Erro interno do servidor",
  "details": "Erro ao comunicar com API Asaas"
}
```

## 🔐 Segurança

### Autenticação
- **Token de API**: Cada conta possui sua própria API key criptografada
- **Validação**: Token é descriptografado antes de usar na API Asaas
- **Isolamento**: Webhooks são listados apenas para a conta específica

### Rate Limiting
- **Limites**: Respeita os limites da API Asaas
- **Caching**: Não implementa cache (dados em tempo real)

## 🧪 Testes

### Teste Manual com curl
```bash
curl -X POST https://your-project.supabase.co/functions/v1/asaas_webhooks_list \
  -H "Content-Type: application/json" \
  -d '{
    "asaas_account_id": "550e8400-e29b-41d4-a716-446655440000"
  }'
```

### Casos de Teste
1. **Sucesso**: Conta válida com webhooks configurados
2. **Conta não encontrada**: ID inexistente
3. **Payload inválido**: Falta campo obrigatório
4. **Método incorreto**: GET ao invés de POST
5. **Erro de API**: Falha na comunicação com Asaas

## 📊 Estrutura de Webhooks

### Campos do Webhook
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `object` | string | Tipo do objeto (sempre "webhook") |
| `id` | string | ID único do webhook no Asaas |
| `name` | string | Nome descritivo do webhook |
| `url` | string | URL de destino do webhook |
| `email` | string | Email para notificações |
| `enabled` | boolean | Se o webhook está ativo |
| `interrupted` | boolean | Se o webhook está interrompido |
| `authToken` | string | Token de autenticação do webhook |
| `events` | array | Lista de eventos que disparam o webhook |
| `sendType` | string | Tipo de envio (SEQUENTIALLY/NON_SEQUENTIALLY) |
| `status` | string | Status do webhook (ACTIVE/INACTIVE) |
| `deleted` | boolean | Se o webhook foi deletado |
| `dateCreated` | string | Data de criação |
| `dateUpdated` | string | Data da última atualização |

### Eventos Suportados

#### Account Status Events
- `ACCOUNT_STATUS_BANK_ACCOUNT_INFO_APPROVED`
- `ACCOUNT_STATUS_BANK_ACCOUNT_INFO_AWAITING_APPROVAL`
- `ACCOUNT_STATUS_BANK_ACCOUNT_INFO_PENDING`
- `ACCOUNT_STATUS_BANK_ACCOUNT_INFO_REJECTED`
- `ACCOUNT_STATUS_GENERAL_APPROVAL_PENDING`
- `ACCOUNT_STATUS_GENERAL_APPROVAL_REJECTED`
- `ACCOUNT_STATUS_UPDATED`

#### Transfer Status Events
- `TRANSFER_CREATED`
- `TRANSFER_PENDING`
- `TRANSFER_IN_BANK_PROCESSING`
- `TRANSFER_BLOCKED`
- `TRANSFER_DONE`
- `TRANSFER_FAILED`
- `TRANSFER_CANCELLED`

## 🔗 Integrações

### Tabelas Utilizadas
- `asaas_accounts`: Dados da conta e API key criptografada

### Dependências
- **API Asaas**: Endpoint `/webhooks` para listagem
- **Criptografia**: Descriptografa API key antes de usar

## ⚙️ Configuração

### Variáveis de Ambiente
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
ASAAS_API_URL=https://api.asaas.com/v3
ENCRYPTION_SECRET=your-32-char-secret
```

## 📈 Monitoramento

### Métricas Importantes
- **Taxa de Sucesso**: % de listagens bem-sucedidas
- **Tempo de Resposta**: Duração média das requisições
- **Erros por Tipo**: Distribuição de tipos de erro
- **Volume de Requisições**: Número de consultas por período

### Logs
- **Nível**: INFO para operações bem-sucedidas, ERROR para falhas
- **Contexto**: ID da conta, tempo de processamento, contagem de webhooks

## 🔧 Manutenção

### Atualizações Futuras
- Suporte para paginação (offset/limit)
- Filtros por status ou tipo de evento
- Cache temporário para reduzir chamadas à API
- Webhook health check

---

**Última atualização**: 2025-08-08  
**Autor**: Sistema de Integração Asaas  
**Versão**: 1.0
