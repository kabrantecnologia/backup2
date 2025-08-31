# 🔍 Logger de Credenciais Asaas - Debug

> ⚠️ **IMPORTANTE**: Esta funcionalidade é **TEMPORÁRIA** para debugging e **DEVE SER REMOVIDA** antes da produção.

## 📋 Objetivo

Facilitar o acesso às credenciais de contas Asaas criadas para operações manuais e debugging de webhooks.

## 🚀 Como usar

### 1. Configuração

As credenciais são automaticamente salvas quando uma conta é criada via `asaas_account_create`.

### 2. Acesso via script

```bash
# Listar todas as credenciais (últimas 10)
deno run --allow-net --allow-read get_credentials.ts

# Buscar por profile_id
deno run --allow-net --allow-read get_credentials.ts c0e54584-5691-4f96-879f-c98cd41239b1

# Buscar por asaas_account_id
deno run --allow-net --allow-read get_credentials.ts asaas_123456789
```

### 3. Variáveis de ambiente

Configure as variáveis ou edite o script `get_credentials.ts`:

```bash
export SUPABASE_URL="http://localhost:54321"
export SUPABASE_SERVICE_ROLE_KEY="seu-service-role-key"
```

## 📊 Estrutura dos dados salvos

```typescript
interface AccountCredentials {
  profile_id: string;           // ID do perfil no Tricket
  asaas_account_id: string;     // ID da conta no Asaas
  webhook_token: string;        // Token para webhooks (36 chars)
  api_key: string;             // API Key da conta
  wallet_id: string;           // ID da carteira
  created_at: string;          // Data de criação
  environment: string;         // 'development' | 'production'
}
```

## 🔍 Consultas úteis

### Buscar token específico
```sql
SELECT webhook_token 
FROM debug_account_credentials 
WHERE profile_id = 'seu-profile-id';
```

### Listar todos os tokens
```sql
SELECT 
  profile_id,
  asaas_account_id,
  webhook_token,
  created_at
FROM debug_account_credentials 
ORDER BY created_at DESC;
```

## 🧹 Limpeza para produção

Antes de ir para produção:

1. **Remover importações** da função `asaas_account_create`
2. **Remover chamadas** ao `logAccountCredentials()`
3. **Remover tabela** `debug_account_credentials`
4. **Remover pasta** `/logs`

### Comando para limpar

```sql
-- Remover tabela de debug
DROP TABLE IF EXISTS debug_account_credentials;

-- Remover índices
DROP INDEX IF EXISTS idx_debug_credentials_profile_id;
DROP INDEX IF EXISTS idx_debug_credentials_asaas_id;
DROP INDEX IF EXISTS idx_debug_credentials_created_at;
```

## ⚠️ Segurança

- **Nunca commitar** API keys reais
- **Usar apenas em ambiente de desenvolvimento**
- **Revisar antes de qualquer deploy**
