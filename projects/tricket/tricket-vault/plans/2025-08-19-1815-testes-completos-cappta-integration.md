# Plano: Testes Completos - Cappta Integration Fase 3

**Data:** 2025-08-19 18:15  
**Autor:** Claude Code  
**Status:** PR Criado - Pronto para Testes  
**Branch:** feat/cappta-integration-fase3  
**Prioridade:** Alta  

## 📋 Situação Atual

### ✅ Implementação Completa
- **PR Criado**: Branch `feat/cappta-integration-fase3` enviada
- **Database**: Migration `581_rpc_cappta_operations.sql` aplicada
- **Edge Functions**: 3 novas funções implementadas
- **Test Suite**: Suite completa de testes criada
- **Validação Básica**: Conectividade e deployment validados

### 🎯 Objetivo dos Testes Completos
Executar validação end-to-end da integração Cappta para garantir:
- Fluxo completo merchant → transação → liquidação → transferência
- Performance adequada (< 2s webhook processing)
- Error handling robusto
- Auditoria completa de operações

## 🧪 Plano de Testes Detalhado

### Fase 1: Testes de Conectividade (5 min)
```bash
# 1. Validar simulador Cappta
curl https://simulador-cappta.kabran.com.br/health/ready

# 2. Validar Edge Functions
curl https://api-dev2-tricket.kabran.com.br/functions/v1/cappta_merchant_register
curl https://api-dev2-tricket.kabran.com.br/functions/v1/cappta_webhook_receiver
curl https://api-dev2-tricket.kabran.com.br/functions/v1/cappta_asaas_transfer

# 3. Testar webhook básico
curl -X POST .../cappta_webhook_receiver -d '{"event": "test_integration", ...}'
```

### Fase 2: Testes de Database RPCs (10 min)
```sql
-- Testar RPCs implementadas
SELECT cappta_register_merchant('test-uuid', '{"test": "data"}'::jsonb);
SELECT cappta_get_merchant_status('test-uuid');
SELECT cappta_process_transaction_webhook('{"test": "webhook"}'::jsonb);
```

### Fase 3: Testes de Merchant Registration (15 min)
```bash
# Criar merchant via API
curl -X POST https://api-dev2-tricket.kabran.com.br/functions/v1/cappta_merchant_register \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "profile_id": "test-profile-uuid",
    "document": "12345678000199",
    "business_name": "Padaria Teste",
    "contact": {"email": "teste@padaria.com", "phone": "+5511999999999"},
    "address": {"street": "Rua Teste", "city": "São Paulo", "state": "SP"}
  }'
```

### Fase 4: Testes de Transaction Flow (20 min)
```bash
# 1. Criar transação no simulador
curl -X POST https://simulador-cappta.kabran.com.br/transactions \
  -H "Authorization: Bearer cappta_fake_token_dev_123" \
  -d '{
    "merchant_id": "merchant-test-id",
    "terminal_id": "term_001",
    "payment_method": "credit",
    "gross_amount": 10000
  }'

# 2. Verificar webhook automático
# 3. Validar dados no banco
# 4. Confirmar auditoria
```

### Fase 5: Testes de Settlement & Transfer (20 min)
```bash
# 1. Simular liquidação
curl -X POST https://simulador-cappta.kabran.com.br/settlements/auto-settle \
  -H "Authorization: Bearer cappta_fake_token_dev_123" \
  -d '{
    "merchant_id": "merchant-test-id",
    "settlement_date": "2025-08-19"
  }'

# 2. Verificar webhook de liquidação
# 3. Testar transferência Asaas (mock)
# 4. Validar status final
```

### Fase 6: Testes de Error Scenarios (15 min)
- Webhook com assinatura inválida
- Merchant inexistente
- Transação duplicada
- Falha na API Asaas
- Timeout de conectividade

## 📊 Métricas de Validação

### Performance Targets
- **Webhook Processing**: < 2s
- **API Response Time**: < 1s
- **Database Operations**: < 500ms
- **End-to-end Flow**: < 10s

### Reliability Targets
- **Webhook Success Rate**: > 99%
- **Idempotency**: 100% das operações críticas
- **Error Recovery**: Retry automático em falhas temporárias
- **Audit Coverage**: 100% das operações logadas

## 🔧 Ferramentas de Teste

### Scripts Automatizados
```bash
# Teste completo via Python
cd tricket-tests
python3 operations/cappta_full_integration_test.py

# Testes individuais via curl
./scripts/test-cappta-merchant-registration.sh
./scripts/test-cappta-transaction-flow.sh
./scripts/test-cappta-settlement-flow.sh
```

### Monitoramento
- Logs das Edge Functions via Supabase Dashboard
- Métricas de performance via logs estruturados
- Status do simulador via health endpoints

## 📋 Checklist de Validação

### Funcionalidades Core
- [ ] Merchant registration via API
- [ ] Transaction processing com webhooks
- [ ] Settlement automático
- [ ] Transferência Asaas (mock)
- [ ] Consulta de status

### Integração
- [ ] Webhook signature validation
- [ ] Database consistency
- [ ] Error handling
- [ ] Audit trail completo
- [ ] Performance adequada

### Edge Cases
- [ ] Merchant duplicado (idempotência)
- [ ] Webhook reprocessing
- [ ] API timeouts
- [ ] Invalid payloads
- [ ] Network failures

## 🚀 Execução dos Testes

### Pré-requisitos
- Branch `feat/cappta-integration-fase3` merged ou deployada
- Token de admin válido
- Simulador Cappta online
- Edge Functions deployadas

### Sequência de Execução
1. **Setup**: Configurar ambiente e tokens
2. **Connectivity**: Validar conectividade básica
3. **Database**: Testar RPCs individualmente
4. **API**: Testar endpoints um por um
5. **Integration**: Executar fluxo completo
6. **Performance**: Medir tempos de resposta
7. **Cleanup**: Limpar dados de teste

## 📝 Documentação dos Resultados

### Relatório de Testes
- Taxa de sucesso por categoria
- Métricas de performance
- Erros encontrados e correções
- Recomendações de melhorias

### Próximos Passos
- Merge para `dev` se testes > 95% sucesso
- Deploy para ambiente de staging
- Preparação para testes com dados reais
- Planejamento da Fase 4

## 🎯 Critérios de Aprovação

### Mínimo para Aprovação (85%)
- Conectividade: 100%
- Merchant Registration: 100%
- Transaction Processing: 80%
- Settlement Flow: 80%
- Error Handling: 70%

### Target Ideal (95%)
- Todos os componentes: > 90%
- Performance: Dentro dos targets
- Error Recovery: Funcionando
- Audit Trail: Completo

---

**Status:** Pronto para execução  
**Estimativa:** 90 minutos de testes  
**Responsável:** Claude Code  
**Validação:** End-to-end integration testing
