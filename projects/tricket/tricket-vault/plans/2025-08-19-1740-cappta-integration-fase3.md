# Plano: Cappta Integration - Fase 3: Implementação Completa da API

**Data:** 2025-08-19 17:40  
**Autor:** Claude Code  
**Branch:** feat/cappta-integration-fase3  
**Prioridade:** Alta  

## 📋 Situação Atual

### ✅ Já Implementado
- **Cappta Simulator**: Funcional com APIs completas (merchants, transactions, settlements)
- **Database Schema**: Tabelas Cappta criadas (`240_cappta_integration.sql`)
- **Edge Functions**: Estrutura básica criada (webhook_receiver, webhook_manager, pos_create)
- **Testes**: Suite de integração implementada (`test_cappta_integration.py`)
- **Correções**: Problemas de autenticação resolvidos (changelog 2025-08-19-2025)

### ❌ Lacunas Identificadas
1. **Edge Functions incompletas**: Apenas estrutura básica, sem lógica de negócio
2. **Integração Asaas**: Não conectada ao fluxo Cappta
3. **RPCs ausentes**: Funções de banco para operações Cappta
4. **Webhook processing**: Receiver não processa eventos reais
5. **Merchant onboarding**: Fluxo não implementado

## 🎯 Objetivos da Fase 3

Implementar integração completa entre Tricket, Simulador Cappta e Asaas para permitir:
- Cadastro de merchants via API Cappta
- Processamento de transações com webhooks
- Liquidação automática via Asaas
- Auditoria completa de operações

## 🏗️ Arquitetura da Solução

### Fluxo Principal
```
1. Merchant Registration (Tricket) → Cappta API → Database
2. Transaction (Simulator) → Webhook → Edge Function → Database
3. Settlement (D+1) → Asaas Transfer → Webhook → Ledger Update
```

### Componentes a Implementar
1. **RPCs Cappta** (`580_functions_cappta.sql` - expandir)
2. **Edge Function Enhancements** (lógica de negócio)
3. **Asaas Integration** (transferências automáticas)
4. **Webhook Processing** (eventos reais)

## 📝 Implementações Detalhadas

### 1. RPCs Cappta (Database)

**Arquivo:** `tricket-backend/supabase/migrations/581_rpc_cappta_operations.sql`

```sql
-- RPC: Registrar merchant na Cappta
CREATE OR REPLACE FUNCTION public.cappta_register_merchant(
    p_profile_id UUID,
    p_merchant_data JSONB
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_account_id UUID;
BEGIN
    -- Validar se profile existe e é PJ
    -- Criar registro em cappta_accounts
    -- Retornar dados para chamada API
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: Processar webhook de transação
CREATE OR REPLACE FUNCTION public.cappta_process_transaction_webhook(
    p_webhook_data JSONB
) RETURNS JSONB AS $$
DECLARE
    v_transaction_id UUID;
    v_merchant_account UUID;
BEGIN
    -- Validar assinatura webhook
    -- Inserir/atualizar cappta_transactions
    -- Triggerar processo de liquidação se aprovada
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: Processar liquidação
CREATE OR REPLACE FUNCTION public.cappta_process_settlement(
    p_merchant_id UUID,
    p_settlement_data JSONB
) RETURNS JSONB AS $$
BEGIN
    -- Calcular valores líquidos
    -- Criar transferência Asaas
    -- Atualizar status das transações
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 2. Edge Function: Merchant Registration

**Arquivo:** `tricket-backend/volumes/functions/cappta_merchant_register/index.ts`

```typescript
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { authMiddleware } from '../_shared/auth.ts';
import { createLogger } from '../_shared/logger.ts';

const logger = createLogger({ name: 'CapptaMerchantRegister' });

serve(async (request) => {
  // Autenticação
  const authResult = await authMiddleware(request, supabase, logger, ['ADMIN', 'SUPER_ADMIN']);
  
  // Validar dados do merchant
  const merchantData = await request.json();
  
  // Chamar RPC para registrar
  const { data, error } = await supabase.rpc('cappta_register_merchant', {
    p_profile_id: merchantData.profile_id,
    p_merchant_data: merchantData
  });
  
  // Chamar API do simulador Cappta
  const capptaResponse = await fetch(`${CAPPTA_SIMULATOR_URL}/merchants`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${CAPPTA_API_TOKEN}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      external_merchant_id: merchantData.profile_id,
      document: merchantData.document,
      business_name: merchantData.business_name,
      // ... outros campos
    })
  });
  
  // Atualizar banco com resposta da Cappta
  // Retornar resultado
});
```

### 3. Enhanced Webhook Receiver

**Arquivo:** `tricket-backend/volumes/functions/cappta_webhook_receiver/index.ts` (atualizar)

```typescript
// Adicionar processamento real de webhooks
const processWebhook = async (payload: CapptaWebhookPayload) => {
  switch (payload.event) {
    case 'transaction.approved':
      return await supabase.rpc('cappta_process_transaction_webhook', {
        p_webhook_data: payload.data
      });
    
    case 'settlement.completed':
      return await supabase.rpc('cappta_process_settlement', {
        p_merchant_id: payload.data.merchant_id,
        p_settlement_data: payload.data
      });
    
    default:
      logger.warn('Evento não reconhecido', { event: payload.event });
  }
};
```

### 4. Asaas Integration Enhancement

**Arquivo:** `tricket-backend/volumes/functions/cappta_asaas_transfer/index.ts`

```typescript
// Nova Edge Function para transferências automáticas
import { AsaasClient } from '../_shared/asaas_client.ts';

const processCapptaSettlement = async (settlementData: any) => {
  const asaasClient = new AsaasClient();
  
  // Criar transferência para merchant
  const transfer = await asaasClient.createTransfer({
    value: settlementData.net_amount / 100, // Converter centavos
    pixAddressKey: settlementData.merchant_pix_key,
    description: `Liquidação Cappta - ${settlementData.settlement_id}`
  });
  
  // Atualizar banco com ID da transferência
  await supabase
    .from('cappta_transactions')
    .update({ 
      asaas_transfer_id: transfer.id,
      settlement_status: 'processing'
    })
    .eq('settlement_id', settlementData.settlement_id);
};
```

## 🧪 Testes de Integração

### Cenários a Implementar
1. **Merchant Onboarding Completo**
2. **Transação → Webhook → Liquidação**
3. **Transferência Asaas Automática**
4. **Error Handling e Retry Logic**

### Arquivo de Teste Atualizado
**Arquivo:** `tricket-tests/operations/cappta_full_integration_test.py`

```python
def test_full_merchant_flow(self):
    """Testa fluxo completo: cadastro → transação → liquidação"""
    
    # 1. Registrar merchant
    merchant_data = self.create_test_merchant()
    
    # 2. Simular transação
    transaction = self.simulate_transaction(merchant_data['merchant_id'])
    
    # 3. Aguardar webhook
    time.sleep(2)
    
    # 4. Verificar processamento
    self.verify_transaction_processed(transaction['id'])
    
    # 5. Simular liquidação D+1
    settlement = self.simulate_settlement(merchant_data['merchant_id'])
    
    # 6. Verificar transferência Asaas
    self.verify_asaas_transfer(settlement['id'])
```

## 📋 Cronograma de Implementação

### Fase 3.1: Database & RPCs (2h)
- [ ] Criar migration `581_rpc_cappta_operations.sql`
- [ ] Implementar RPCs principais
- [ ] Aplicar migration e testar

### Fase 3.2: Edge Functions (3h)
- [ ] Implementar `cappta_merchant_register`
- [ ] Atualizar `cappta_webhook_receiver`
- [ ] Criar `cappta_asaas_transfer`
- [ ] Testar autenticação e conectividade

### Fase 3.3: Integração Asaas (2h)
- [ ] Implementar lógica de transferência
- [ ] Configurar webhooks Asaas para status
- [ ] Testar fluxo completo

### Fase 3.4: Testes & Validação (2h)
- [ ] Atualizar suite de testes
- [ ] Executar testes de integração
- [ ] Validar métricas de performance

## 🎯 Critérios de Sucesso

### Funcionalidades
- ✅ Merchant registration via API
- ✅ Transaction processing com webhooks
- ✅ Automatic settlement via Asaas
- ✅ Complete audit trail

### Performance
- ⏱️ Webhook processing < 2s
- ⏱️ Settlement processing < 5s
- 📊 99% webhook delivery success
- 📊 100% transaction audit coverage

### Testes
- 🧪 5/5 integration tests passing
- 🧪 End-to-end flow validation
- 🧪 Error scenarios covered
- 🧪 Performance benchmarks met

## 🚀 Próximos Passos

1. **Criar branch** `feat/cappta-integration-fase3`
2. **Implementar RPCs** conforme especificação
3. **Desenvolver Edge Functions** com lógica completa
4. **Integrar com Asaas** para transferências
5. **Executar testes** e validar fluxo completo
6. **Documentar** e criar changelog

## 📝 Observações Técnicas

- Manter compatibilidade com simulador existente
- Implementar retry logic para webhooks
- Usar transações database para consistência
- Logs estruturados para debugging
- Métricas de performance integradas

---

**Status:** Pronto para implementação  
**Estimativa:** 9 horas de desenvolvimento  
**Dependências:** Simulador Cappta funcional, Asaas integration ativa
