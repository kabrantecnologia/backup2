# Plano: Correção de Autenticação - Edge Functions Cappta

**Data:** 2025-08-19 20:00  
**Baseado em:** Análise das Edge Functions Asaas funcionais  
**Objetivo:** Resolver erro 401 e atingir 5/5 testes de integração  

## Análise Comparativa: Asaas vs Cappta

### ✅ **Edge Functions Asaas (FUNCIONANDO)**

#### Estrutura Robusta:
```typescript
// asaas_account_create/index.ts
import {
  loadConfig,
  validateConfig,
  createLogger,
  authMiddleware,
  createAsaasClient,
  // ... 20+ imports organizados
} from '../_shared/index.ts';

async function handleRequest(request: Request): Promise<Response> {
  const logger = createLogger({
    name: 'AsaasAccountCreate',
    minLevel: LogLevel.INFO
  });

  try {
    // 1. Carrega e valida configurações
    const config = loadConfig();
    const configValidation = validateConfig(config);
    
    // 2. Inicializa cliente Supabase
    const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey, {
      auth: { persistSession: false }
    });

    // 3. Autenticação e autorização DETALHADA
    const authResult = await authMiddleware(
      request,
      supabase,
      logger,
      ['ADMIN', 'SUPER_ADMIN']  // Múltiplas roles aceitas
    );

    if (!authResult.success) {
      return authResult.response!;
    }

    // 4. Logging detalhado de debugging
    const authHeader = request.headers.get('Authorization');
    logger.info('Headers da requisição', {
      hasAuthHeader: !!authHeader,
      authHeaderPrefix: authHeader ? authHeader.substring(0, 20) + '...' : 'null',
      method: request.method,
      url: request.url
    });

    // ... resto da lógica
  } catch (error) {
    // Error handling robusto com IDs únicos
    const errorId = crypto.randomUUID();
    logger.critical('Erro inesperado', {
      errorId,
      message: error.message,
      stack: error.stack
    });
    
    return createInternalErrorResponse(
      'Erro interno do servidor',
      error.message,
      errorId
    );
  }
}

serve(withErrorHandling(handleRequest));
```

### ❌ **Edge Functions Cappta (PROBLEMA)**

#### Estrutura Simplificada Demais:
```typescript
// cappta_webhook_manager/index.ts
serve(async (req) => {  // ← Função anônima simples
  try {
    const config = loadConfig();
    
    const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey, { 
      auth: { persistSession: false } 
    });
    
    const authResult = await authMiddleware(req, supabase, logger, ['ADMIN']); // ← Apenas 1 role
    if (!authResult.success || !authResult.user) {
      return authResult.response || createInternalErrorResponse('Falha na autenticação');
    }

    // ... lógica sem logging detalhado
  } catch (error) {
    // Error handling básico
    return createInternalErrorResponse('Ocorreu um erro inesperado.');
  }
});
```

## Problemas Identificados

### 1. **Arquitetura Inconsistente**
- **Asaas**: Handler dedicado + error handling robusto
- **Cappta**: Função anônima + error handling básico

### 2. **Logging Insuficiente**
- **Asaas**: Logs detalhados de auth headers, tokens, debugging
- **Cappta**: Logs mínimos, não há visibilidade do problema

### 3. **Error Handling Limitado**
- **Asaas**: IDs de erro únicos, stack traces, debugging detalhado
- **Cappta**: Mensagens genéricas

### 4. **Roles e Permissões**
- **Asaas**: Aceita `['ADMIN', 'SUPER_ADMIN']`
- **Cappta**: Apenas `['ADMIN']` - pode estar muito restritivo

## Plano de Correção

### **Etapa 1: Diagnóstico Detalhado** 🔍

#### 1.1 Adicionar Logging Avançado nas Edge Functions Cappta
```typescript
// Adicionar em cappta_webhook_manager e cappta_pos_create
const authHeader = request.headers.get('Authorization');
const contentType = request.headers.get('Content-Type');
const userAgent = request.headers.get('User-Agent');

logger.info('Headers da requisição', {
  hasAuthHeader: !!authHeader,
  authHeaderPrefix: authHeader ? authHeader.substring(0, 20) + '...' : 'null',
  contentType,
  userAgent,
  method: request.method,
  url: request.url
});

logger.info('Configuração carregada', {
  supabaseUrl: config.supabaseUrl,
  hasServiceRoleKey: !!config.supabaseServiceRoleKey,
  serviceRoleKeyPrefix: config.supabaseServiceRoleKey ? config.supabaseServiceRoleKey.substring(0, 20) + '...' : 'null'
});
```

#### 1.2 Implementar Error IDs Únicos
```typescript
catch (error) {
  const errorId = crypto.randomUUID();
  
  logger.critical('Erro inesperado no gerenciador de webhooks da Cappta', {
    errorId,
    message: error.message,
    stack: error.stack,
    timestamp: new Date().toISOString(),
    requestHeaders: Object.fromEntries(request.headers.entries())
  });
  
  return createInternalErrorResponse(
    'Erro interno do servidor',
    error.message,
    errorId
  );
}
```

### **Etapa 2: Padronização de Arquitetura** 🏗️

#### 2.1 Refatorar Edge Functions Cappta para usar padrão Asaas
```typescript
// cappta_webhook_manager/index.ts
async function handleCapptaWebhookManager(request: Request): Promise<Response> {
  const logger = createLogger({
    name: 'CapptaWebhookManager',
    minLevel: LogLevel.INFO
  });

  const startTime = Date.now();
  
  try {
    // 1. Validar configurações
    const config = loadConfig();
    const configValidation = validateConfig(config);
    
    if (!configValidation.isValid) {
      logger.error('Configuração inválida', { errors: configValidation.errors });
      return createInternalErrorResponse(
        'Configuração inválida',
        configValidation.errors.join(', ')
      );
    }

    // 2. Inicializar Supabase
    const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey, {
      auth: { persistSession: false }
    });

    // 3. Autenticação com logging detalhado
    const authResult = await authMiddleware(
      request,
      supabase,
      logger,
      ['ADMIN', 'SUPER_ADMIN'] // ← Aceitar múltiplas roles como Asaas
    );

    if (!authResult.success) {
      return authResult.response!;
    }

    // ... resto da lógica
    
  } catch (error) {
    const duration = Date.now() - startTime;
    const errorId = crypto.randomUUID();
    
    logger.critical('Erro inesperado', {
      errorId,
      message: error.message,
      stack: error.stack,
      duration_ms: duration
    });
    
    return createInternalErrorResponse(
      'Erro interno do servidor',
      error.message,
      errorId
    );
  }
}

serve(withErrorHandling(handleCapptaWebhookManager));
```

#### 2.2 Implementar Handler Dedicado para POS Create
```typescript
// cappta_pos_create/index.ts - seguir mesmo padrão
async function handleCapptaPosCreate(request: Request): Promise<Response> {
  // Mesma estrutura do handleCapptaWebhookManager
}
```

### **Etapa 3: Investigação de Configuração** 🔧

#### 3.1 Verificar Chaves JWT no Ambiente dev2
```bash
# Verificar se as chaves estão sendo carregadas corretamente
echo "SUPABASE_URL: $SUPABASE_URL"
echo "SERVICE_ROLE_KEY presente: $([ -n "$SUPABASE_SERVICE_ROLE_KEY" ] && echo "SIM" || echo "NÃO")"

# Verificar se as chaves são consistentes entre ambientes
```

#### 3.2 Testar Autenticação Diretamente
```typescript
// Adicionar endpoint de debug temporário
async function debugAuth(request: Request): Promise<Response> {
  const token = extractTokenFromHeader(request);
  
  if (!token) {
    return createResponse({ error: "No token provided" }, 400);
  }

  try {
    const { data: { user }, error } = await supabase.auth.getUser(token);
    
    return createResponse({
      tokenPresent: !!token,
      tokenPrefix: token.substring(0, 20) + '...',
      userFound: !!user,
      error: error?.message,
      userId: user?.id,
      userEmail: user?.email
    });
  } catch (e) {
    return createResponse({ debugError: e.message }, 500);
  }
}
```

### **Etapa 4: Testes e Validação** ✅

#### 4.1 Criar Suite de Testes Específica para Auth
```python
# test_auth_debugging.py
def test_auth_headers():
    """Testa se headers de auth estão sendo enviados corretamente"""
    
def test_token_validation():
    """Testa validação de token diretamente"""
    
def test_role_permissions():
    """Testa se usuário admin tem roles corretas"""
```

#### 4.2 Implementar Monitoramento de Auth
```typescript
// Adicionar métricas de auth em todas as Edge Functions
logger.info('Auth attempt', {
  hasToken: !!token,
  tokenValid: authResult.success,
  userRoles: authResult.user?.roles,
  requiredRoles,
  authDuration: authEndTime - authStartTime
});
```

## Timeline de Execução

### **Dia 1: Diagnóstico** 🔍
- ✅ Adicionar logging detalhado nas Edge Functions Cappta
- ✅ Implementar error IDs únicos
- ✅ Deploy e executar testes com logs avançados
- ✅ Analisar logs para identificar causa raiz

### **Dia 2: Correção** 🔧
- 🔄 Refatorar arquitetura das Edge Functions Cappta
- 🔄 Implementar padrão Asaas (handlers dedicados)
- 🔄 Ajustar roles aceitas: `['ADMIN', 'SUPER_ADMIN']`
- 🔄 Deploy e testar correções

### **Dia 3: Validação** ✅
- 🚀 Executar suite completa de testes
- 🚀 Validar 5/5 testes passando
- 🚀 Documentar lições aprendidas
- 🚀 Implementar monitoramento permanente

## Critérios de Sucesso

### **Mínimo (80%)**
- ✅ Logs detalhados implementados
- ✅ Causa raiz do erro 401 identificada
- ✅ Pelo menos 4/5 testes passando

### **Ideal (100%)**
- ✅ Arquitetura padronizada com padrão Asaas
- ✅ 5/5 testes de integração passando
- ✅ Monitoramento de auth implementado
- ✅ Error handling robusto

## Possíveis Causas e Soluções

### **Causa 1: Chaves JWT Diferentes**
- **Sintoma**: Token válido localmente, inválido no dev2
- **Solução**: Sincronizar `JWT_SECRET` entre ambientes

### **Causa 2: Service Role Key Incorreta**
- **Sintoma**: Erro ao inicializar cliente Supabase
- **Solução**: Verificar `SUPABASE_SERVICE_ROLE_KEY` no dev2

### **Causa 3: Roles Insuficientes**
- **Sintoma**: Usuário admin rejeitado por permissões
- **Solução**: Aceitar `['ADMIN', 'SUPER_ADMIN']` como Asaas

### **Causa 4: Token Expirado**
- **Sintoma**: Token funcionava antes, agora não funciona
- **Solução**: Gerar novo token admin no ambiente de testes

## Arquivos a Modificar

### **Edge Functions:**
- `cappta_webhook_manager/index.ts` - Refatoração completa
- `cappta_pos_create/index.ts` - Refatoração completa

### **Testes:**
- `test_cappta_integration.py` - Adicionar debug de auth
- `test_auth_debugging.py` - Nova suite específica

### **Documentação:**
- `CHANGELOG.md` - Documentar correções
- `AUTH_DEBUGGING.md` - Guia de troubleshooting

## Lições das Edge Functions Asaas

### **1. Estrutura de Handler Dedicado**
```typescript
async function handleRequest(request: Request): Promise<Response>
serve(withErrorHandling(handleRequest));
```

### **2. Logging Extensivo**
```typescript
logger.info('Headers da requisição', { /* detalhes */ });
logger.info('Configuração carregada', { /* detalhes */ });
logger.info('Usuário autenticado', { /* detalhes */ });
```

### **3. Error Handling com IDs**
```typescript
const errorId = crypto.randomUUID();
logger.critical('Erro inesperado', { errorId, /* detalhes */ });
```

### **4. Múltiplas Roles Aceitas**
```typescript
['ADMIN', 'SUPER_ADMIN'] // Ao invés de apenas ['ADMIN']
```

---

**Resultado Esperado:** Resolver o erro 401 e conseguir **5/5 testes de integração passando**, estabelecendo uma base sólida para o desenvolvimento futuro da integração Tricket + Cappta! 🚀