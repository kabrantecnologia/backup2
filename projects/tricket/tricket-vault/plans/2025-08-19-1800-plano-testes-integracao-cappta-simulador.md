# Plano de Testes - Integração Tricket + Simulador Cappta

**Data:** 2025-08-19 18:00  
**Branch:** `feat/testes-integracao-cappta-simulador`  
**Status:** Preparação Completa - Pronto para Execução  

## Objetivo

Validar a integração completa entre o sistema Tricket e o Simulador Cappta deployado no ambiente dev2, testando comunicação, autenticação, webhooks e operações de negócio.

## Contexto

Com o Simulador Cappta deployado em `https://simulador-cappta.kabran.com.br` e as Edge Functions Tricket desenvolvidas, precisamos validar:

1. Comunicação bidirecional entre sistemas
2. Fluxos de webhook
3. Operações de criação de POS
4. Autenticação e autorização
5. Logs e monitoramento

## Preparação Realizada

### 1. Configuração do Ambiente

#### Variáveis de Ambiente Configuradas (`.env`)
```bash
# Cappta - Configuração para usar o Simulador
CAPPTA_API_URL=https://simulador-cappta.kabran.com.br
CAPPTA_API_TOKEN=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
RESELLER_DOCUMENT=58074056000170
```

#### Fluxo de Integração
```
Tricket Edge Functions → Simulador Cappta (dev2) → Webhooks → Tricket
```

### 2. Infraestrutura de Código

#### Cliente Cappta (`cappta-client.ts`)
- Comunicação HTTP com simulador
- Headers de autenticação
- Tratamento de erros
- Logging integrado

#### Configuração Atualizada (`config.ts`)
- Variáveis Cappta adicionadas
- Validação de URLs e tokens
- Configuração centralizada

#### Edge Functions Identificadas
1. `cappta_webhook_manager` - Gerenciar webhooks (register/query/inactivate)
2. `cappta_webhook_receiver` - Receber webhooks da Cappta
3. `cappta_pos_create` - Criar dispositivos POS

### 3. Suite de Testes Automatizados

#### Arquivo: `test_cappta_integration.py`
Testes implementados:
- ✅ Health check do simulador
- ✅ Validação das Edge Functions
- ✅ Teste webhook manager
- ✅ Teste POS create  
- ✅ Teste fluxo completo de webhooks

## Plano de Execução dos Testes

### Fase 1: Testes Básicos de Conectividade
1. **Health Check Simulador**
   - URL: `https://simulador-cappta.kabran.com.br/health/ready`
   - Verificar se simulador está respondendo
   - Validar tempo de resposta

2. **Health Check Edge Functions**
   - Testar endpoints OPTIONS
   - Verificar disponibilidade das funções

### Fase 2: Testes de Autenticação e Autorização
1. **Token de Admin**
   - Obter token válido do sistema
   - Validar permissões ADMIN

2. **Webhook Manager**
   - Registrar webhook de teste
   - Consultar status do webhook
   - Validar comunicação com simulador

### Fase 3: Testes de Operações de Negócio
1. **Criação de POS**
   - Payload: serial_key, model_id, keys
   - Validar resposta do simulador
   - Verificar persistência no banco

2. **Fluxo de Webhooks**
   - Enviar webhook de teste
   - Validar processamento
   - Verificar logs

### Fase 4: Testes de Integração Completa
1. **Fluxo End-to-End**
   - Tricket → Simulador → Webhook → Tricket
   - Validar dados em todas as etapas
   - Verificar consistência

## Critérios de Sucesso

### Mínimo Aceitável (80% dos testes)
- Simulador respondendo
- Edge Functions funcionando
- Autenticação funcionando
- Pelo menos 1 operação de negócio

### Ideal (100% dos testes)
- Todos os health checks passando
- Webhook manager completo
- POS create funcionando
- Fluxo completo de webhooks

## Comandos de Execução

### Setup do Ambiente
```bash
# Navegar para testes
cd ~/workspaces/projects/tricket/tricket-tests

# Instalar dependências (se necessário)
pip install -r requirements.txt
```

### Execução dos Testes
```bash
# Executar suite completa
python testing/test_captta_integration.py

# Ou via Make
make test-cappta-integration  # (se implementado)
```

### Logs e Monitoramento
```bash
# Ver logs do simulador
docker logs cappta-simulator -f

# Ver logs do Supabase
# (através do dashboard ou logs locais)
```

## Estrutura de Relatório

### Automático (pelo script)
- Status de cada teste
- Taxa de sucesso geral
- Detalhes de falhas
- Dados de resposta

### Manual (a documentar)
- Performance observada
- Problemas encontrados
- Sugestões de melhoria
- Próximos passos

## Possíveis Problemas e Soluções

### 1. Simulador Não Responde
**Problema:** Timeout ou 502/503 errors  
**Solução:** Verificar deploy do simulador, reiniciar container

### 2. Autenticação Falhando
**Problema:** 401 Unauthorized  
**Solução:** Verificar tokens, permissões RBAC

### 3. Edge Functions Com Erro
**Problema:** 500 Internal Server Error  
**Solução:** Verificar variáveis ambiente, logs do Supabase

### 4. Webhook Não Processando
**Problema:** Timeout ou payload inválido  
**Solução:** Verificar URL webhook receiver, formato payload

## Próximos Passos Pós-Teste

### Se Testes Passarem (≥80%)
1. Documentar resultados em changelog
2. Fazer commit das melhorias
3. Preparar para testes manuais mais complexos
4. Planejar integração com front-end

### Se Testes Falharem (<80%)
1. Analisar logs detalhados
2. Corrigir problemas identificados
3. Re-executar testes
4. Documentar lições aprendidas

## Arquivos Modificados/Criados

### Novos Arquivos
- `tricket-backend/volumes/functions/_shared/cappta-client.ts`
- `tricket-tests/testing/test_cappta_integration.py`

### Arquivos Modificados
- `tricket-backend/.env` (URLs Cappta)
- `tricket-backend/volumes/functions/_shared/config.ts` (configurações Cappta)

## Dependências Externas

### Sistemas
- Simulador Cappta (dev2): `https://simulador-cappta.kabran.com.br`
- Supabase Tricket: `https://dev2.tricket.kabran.com.br`
- Traefik (proxy): Configurado para ambos

### Credenciais
- Token Cappta oficial (mantido para compatibilidade)
- RESELLER_DOCUMENT: `58074056000170`
- Tokens admin do sistema Tricket

## Timeline Estimado

- **Setup e Preparação:** ✅ Concluído
- **Execução dos Testes:** ~30 minutos
- **Análise e Documentação:** ~30 minutos  
- **Correções (se necessárias):** 1-2 horas
- **Validação Final:** ~15 minutos

**Total Estimado:** 2-3 horas para ciclo completo

---

**Responsável:** Claude Code  
**Revisão:** Necessária pós-execução  
**Aprovação:** Pendente resultados dos testes