# Plano: Investigação e Correção - Token Cappta Simulator

**Data:** 2025-08-19 18:32  
**Autor:** Claude Code  
**Branch:** dev  
**Prioridade:** Alta  
**Status:** Investigação Ativa  

## 🎯 Objetivo

Investigar e corrigir o problema de autenticação (HTTP 401) no Simulador Cappta para permitir testes completos da integração.

## 🔍 Problema Identificado

Durante os testes da Fase 3, o simulador Cappta retornou erro 401 para todas as tentativas de autenticação:

```bash
curl -s https://simulador-cappta.kabran.com.br/merchants/ \
  -H "Authorization: Bearer cappta_fake_token_dev_123"
# Resultado: {"message":"Invalid authentication token","error_code":"HTTP_401","status_code":401}

curl -s https://simulador-cappta.kabran.com.br/merchants/ \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
# Resultado: {"message":"Invalid authentication token","error_code":"HTTP_401","status_code":401}
```

## 📋 Plano de Investigação

### Fase 1: Análise da Configuração Atual (15 min)

#### 1.1 Verificar Configuração do Simulador
```bash
# Analisar arquivo de configuração
cat ~/workspaces/projects/tricket/cappta-simulator/.env

# Verificar se o simulador está usando o token correto
grep -r "API_TOKEN" ~/workspaces/projects/tricket/cappta-simulator/
```

#### 1.2 Analisar Código de Autenticação do Simulador
```bash
# Verificar implementação da autenticação
find ~/workspaces/projects/tricket/cappta-simulator/ -name "*.py" -exec grep -l "auth\|token\|bearer" {} \;

# Analisar middleware de autenticação
grep -A 10 -B 5 "Authorization\|Bearer\|token" ~/workspaces/projects/tricket/cappta-simulator/app/api/*.py
```

#### 1.3 Verificar Status do Serviço
```bash
# Testar health endpoint
curl -s https://simulador-cappta.kabran.com.br/health/ready

# Verificar logs do simulador (se disponível)
# Testar endpoint sem autenticação para verificar se está online
curl -s https://simulador-cappta.kabran.com.br/
```

### Fase 2: Identificação do Token Esperado (20 min)

#### 2.1 Analisar Implementação da Validação
- Verificar se o simulador espera JWT ou token simples
- Identificar algoritmo de validação (se JWT)
- Verificar se há validação de expiração
- Analisar claims esperados

#### 2.2 Verificar Configurações de Ambiente
```bash
# Verificar variáveis de ambiente do simulador
grep -E "TOKEN|SECRET|KEY" ~/workspaces/projects/tricket/cappta-simulator/.env
grep -E "TOKEN|SECRET|KEY" ~/workspaces/projects/tricket/cappta-simulator/config/settings.py
```

#### 2.3 Analisar Logs de Erro (se disponível)
- Verificar logs de autenticação falhada
- Identificar mensagens de debug específicas
- Analisar stack trace de validação

### Fase 3: Testes de Diferentes Formatos (25 min)

#### 3.1 Testar Token Simples
```bash
# Testar token configurado no .env
curl -s https://simulador-cappta.kabran.com.br/merchants/ \
  -H "Authorization: Bearer cappta_fake_token_dev_123"

# Testar sem prefixo Bearer
curl -s https://simulador-cappta.kabran.com.br/merchants/ \
  -H "Authorization: cappta_fake_token_dev_123"

# Testar header alternativo
curl -s https://simulador-cappta.kabran.com.br/merchants/ \
  -H "X-API-Token: cappta_fake_token_dev_123"
```

#### 3.2 Testar JWT Token
```bash
# Testar JWT do .env
curl -s https://simulador-cappta.kabran.com.br/merchants/ \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."

# Gerar novo JWT se necessário (com claims corretos)
# Testar com diferentes algoritmos (HS256, RS256)
```

#### 3.3 Testar Configurações Alternativas
```bash
# Testar diferentes endpoints para identificar padrão
curl -s https://simulador-cappta.kabran.com.br/health/auth \
  -H "Authorization: Bearer [TOKEN]"

# Testar método POST vs GET
curl -X POST https://simulador-cappta.kabran.com.br/auth/validate \
  -H "Authorization: Bearer [TOKEN]"
```

### Fase 4: Correção e Validação (20 min)

#### 4.1 Implementar Correção
- Atualizar token no arquivo de configuração
- Regenerar JWT se necessário
- Atualizar variáveis de ambiente

#### 4.2 Validar Correção
```bash
# Testar autenticação corrigida
curl -s https://simulador-cappta.kabran.com.br/merchants/ \
  -H "Authorization: Bearer [CORRECTED_TOKEN]"

# Testar operações CRUD
curl -X POST https://simulador-cappta.kabran.com.br/merchants \
  -H "Authorization: Bearer [CORRECTED_TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{"external_merchant_id": "test-001", "document": "12345678000199"}'
```

## 🔧 Ferramentas de Diagnóstico

### Scripts de Teste
```bash
#!/bin/bash
# test-cappta-auth.sh

SIMULATOR_URL="https://simulador-cappta.kabran.com.br"
TOKENS=(
    "cappta_fake_token_dev_123"
    "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
    "simple_token_123"
)

for token in "${TOKENS[@]}"; do
    echo "Testing token: ${token:0:20}..."
    response=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer $token" \
        "$SIMULATOR_URL/merchants/")
    echo "Response: $response"
    echo "---"
done
```

### JWT Decoder
```bash
# Decodificar JWT para analisar claims
echo "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." | base64 -d
```

## 📊 Cenários Possíveis

### Cenário 1: Token Expirado
- **Causa**: JWT com timestamp expirado
- **Solução**: Regenerar token com nova expiração
- **Teste**: Verificar claim `exp` no JWT

### Cenário 2: Algoritmo Incorreto
- **Causa**: JWT assinado com algoritmo diferente do esperado
- **Solução**: Usar algoritmo correto (HS256/RS256)
- **Teste**: Verificar header `alg` do JWT

### Cenário 3: Claims Inválidos
- **Causa**: JWT sem claims obrigatórios
- **Solução**: Incluir claims esperados (`iss`, `sub`, `aud`)
- **Teste**: Decodificar e verificar payload

### Cenário 4: Configuração de Ambiente
- **Causa**: Simulador usando token diferente do configurado
- **Solução**: Sincronizar configuração
- **Teste**: Verificar variáveis de ambiente

### Cenário 5: Header Format
- **Causa**: Formato de header incorreto
- **Solução**: Usar formato correto (`Bearer`, `X-API-Token`)
- **Teste**: Testar diferentes formatos

## 📋 Checklist de Investigação

### Configuração
- [ ] Verificar token no `.env` do simulador
- [ ] Analisar código de autenticação
- [ ] Verificar variáveis de ambiente
- [ ] Confirmar status do serviço

### Token Analysis
- [ ] Decodificar JWT atual
- [ ] Verificar expiração
- [ ] Validar algoritmo de assinatura
- [ ] Analisar claims obrigatórios

### Testes
- [ ] Testar token simples
- [ ] Testar JWT atual
- [ ] Testar formatos alternativos
- [ ] Testar diferentes endpoints

### Correção
- [ ] Implementar correção identificada
- [ ] Atualizar configurações
- [ ] Validar autenticação
- [ ] Testar operações completas

## 🎯 Critérios de Sucesso

### Mínimo Aceitável
- ✅ Autenticação retorna HTTP 200
- ✅ Endpoint `/merchants/` acessível
- ✅ Operações básicas funcionais

### Target Ideal
- ✅ Todas as APIs do simulador acessíveis
- ✅ CRUD completo funcionando
- ✅ Webhooks sendo enviados corretamente
- ✅ Testes de integração passando

## 📝 Documentação da Solução

### Arquivo de Resultado
`tricket-vault/changelogs/2025-08-19-HHMM-correcao-token-cappta.md`

### Conteúdo Esperado
- Causa raiz identificada
- Solução implementada
- Testes de validação
- Configuração final
- Próximos passos

## ⏱️ Cronograma

| Fase | Duração | Atividades |
|------|---------|------------|
| **Fase 1** | 15 min | Análise da configuração atual |
| **Fase 2** | 20 min | Identificação do token esperado |
| **Fase 3** | 25 min | Testes de diferentes formatos |
| **Fase 4** | 20 min | Correção e validação |
| **Total** | **80 min** | Investigação completa |

## 🚀 Próximos Passos Após Correção

1. **Re-executar testes da Fase 3** com autenticação corrigida
2. **Validar fluxo completo** merchant → transaction → settlement
3. **Atualizar documentação** com configuração correta
4. **Prosseguir para Fase 4** da integração Cappta

---

**Status:** Pronto para execução  
**Responsável:** Claude Code  
**Estimativa:** 80 minutos de investigação  
**Dependências:** Acesso ao código do simulador Cappta
