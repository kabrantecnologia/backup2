# Guia de Configuração Manual - Webhook Asaas Master

## 📋 Configuração no Portal Asaas

### 1. Acesso ao Portal
- **URL**: https://www.asaas.com/
- **Login**: Use as credenciais da conta master

### 2. Configuração do Webhook

#### Passo 1: Acessar Configurações
1. Clique no seu perfil (canto superior direito)
2. Selecione **"Minha Conta"**
3. Vá para a aba **"Integrações"**
4. Clique em **"Webhooks"**

#### Passo 2: Adicionar Novo Webhook
1. Clique em **"Adicionar Webhook"**
2. **URL do Webhook**: 
   ```
   https://api-dev2-tricket.kabran.com.br/functions/v1/asaas_master_webhook
   ```
3. **Método HTTP**: POST
4. **Tipo de Autenticação**: Bearer Token
5. **Token**: Use o mesmo token do Supabase (SUPABASE_ANON_KEY)

#### Passo 3: Selecionar Eventos
Marque os seguintes eventos:
- ✅ **PAYMENT_RECEIVED** - Pagamento recebido
- ✅ **TRANSFER_COMPLETED** - Transferência concluída
- ✅ **SUBSCRIPTION_CREATED** - Nova assinatura
- ✅ **CUSTOMER_CREATED** - Novo cliente
- ✅ **PAYMENT_CREATED** - Novo pagamento criado
- ✅ **PAYMENT_CONFIRMED** - Pagamento confirmado
- ✅ **PAYMENT_OVERDUE** - Pagamento vencido

#### Passo 4: Configuração de Segurança
- **Assinatura de Webhook**: Ativado
- **Chave Secreta**: Use a mesma chave do ambiente (ASAAS_WEBHOOK_SECRET)
- **Verificação SSL**: Ativado

### 3. Teste de Webhook

#### Teste Manual no Portal:
1. Na lista de webhooks, clique em **"Testar"**
2. Selecione um evento para teste
3. Clique em **"Enviar Teste"**

#### Verificação:
- Verifique os logs no Supabase Dashboard
- Confira a tabela `master_webhook_events` para ver se o evento foi registrado
- Status deve aparecer como **"processed"** ou **"error"**

### 4. URLs de Ambiente

#### Desenvolvimento:
```
URL: https://api-dev2-tricket.kabran.com.br/functions/v1/asaas_master_webhook
Token: [SUPABASE_ANON_KEY do ambiente dev]
```

#### Produção:
```
URL: https://api-tricket.kabran.com.br/functions/v1/asaas_master_webhook
Token: [SUPABASE_ANON_KEY do ambiente prod]
```

### 5. Queries de Verificação

#### Verificar últimos eventos:
```sql
SELECT event_type, status, created_at, error_message 
FROM master_webhook_events 
ORDER BY created_at DESC 
LIMIT 10;
```

#### Verificar saldos das subcontas:
```sql
SELECT customer_id, balance, last_balance_update 
FROM v_subaccount_financial_summary 
ORDER BY last_balance_update DESC;
```

### 6. Troubleshooting

#### Erro 401 (Unauthorized):
- Verifique se o token Bearer está correto
- Confirme que a URL está completa

#### Erro 500 (Internal Server):
- Verifique os logs no Supabase Dashboard
- Confirme se todas as variáveis de ambiente estão configuradas

#### Eventos não chegando:
- Verifique se os eventos estão marcados corretamente
- Confirme se a URL está acessível publicamente
- Teste com um evento manual no portal

### 7. Suporte

Se encontrar problemas:
1. Verifique os logs no Supabase Dashboard
2. Teste manualmente via Postman
3. Confira a documentação: `/volumes/functions/asaas_master_webhook/README.md`

---
**Última atualização**: 09/08/2024
**Responsável**: João Henrique Andrade
