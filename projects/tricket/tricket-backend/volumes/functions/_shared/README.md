# Módulos Compartilhados - Edge Functions

Esta pasta contém módulos compartilhados para as Edge Functions do Supabase, implementando uma arquitetura modular e reutilizável baseada em princípios de código limpo.

## 📁 Estrutura dos Módulos

### `config.ts`
**Gerenciamento de Configurações**
- Carregamento e validação de variáveis de ambiente
- Interface tipada para configurações da aplicação
- Validação de URLs e tokens obrigatórios

```typescript
import { loadConfig, validateConfig } from './_shared/config.ts';

const config = loadConfig();
const validation = validateConfig(config);
```

### `logger.ts`
**Sistema de Logging Estruturado**
- Logging JSON estruturado para melhor observabilidade
- Diferentes níveis de log (DEBUG, INFO, WARN, ERROR, CRITICAL)
- Formatação consistente com timestamps e contexto

```typescript
import { createLogger, LogLevel } from './_shared/logger.ts';

const logger = createLogger({
  name: 'MyFunction',
  minLevel: LogLevel.INFO
});

logger.info('Operação realizada', { userId: '123', duration: 150 });
```

### `crypto.ts`
**Utilitários de Criptografia**
- Criptografia AES-GCM com PBKDF2 para dados sensíveis
- Geração de tokens seguros
- Funções específicas para API Keys

```typescript
import { encryptApiKey, generateSecureToken } from './_shared/crypto.ts';

const encrypted = await encryptApiKey(apiKey, masterSecret);
const token = generateSecureToken(32);
```

### `auth.ts`
**Autenticação e Autorização**
- Middleware de autenticação JWT
- Verificação de roles (RBAC)
- Respostas padronizadas para erros de auth

```typescript
import { authMiddleware } from './_shared/auth.ts';

const authResult = await authMiddleware(
  request,
  supabase,
  logger,
  ['ADMIN', 'SUPER_ADMIN']
);
```

### `asaas-client.ts`
**Cliente para API do Asaas**
- Interface consistente para operações do Asaas
- Tratamento de erros padronizado
- Logging automático de requisições

```typescript
import { createAsaasClient } from './_shared/asaas-client.ts';

const client = createAsaasClient({
  apiUrl: config.asaasApiUrl,
  accessToken: config.asaasMasterAccessToken,
  logger
});

const response = await client.createAccount(payload);
```

### `asaas-payload-transformer.ts`
**Transformação de Dados para Asaas**
- Conversão de dados internos para formato Asaas
- Validação e formatação de CPF/CNPJ, telefone, CEP
- Configuração automática de webhooks

```typescript
import { transformProfileToAsaasPayload } from './_shared/asaas-payload-transformer.ts';

const { payload, webhookToken } = transformProfileToAsaasPayload(
  profileData,
  webhookConfig,
  logger
);
```

### `response.ts`
**Respostas HTTP Padronizadas**
- Respostas consistentes com CORS
- Factory functions para diferentes tipos de erro
- Tratamento automático de requisições OPTIONS

```typescript
import { 
  createSuccessResponse, 
  createValidationErrorResponse,
  withErrorHandling 
} from './_shared/response.ts';

return createSuccessResponse(data, 'Operação realizada com sucesso');
```

### `validation.ts`
**Validação de Dados**
- Validadores para CPF, CNPJ, email, telefone, CEP
- Formatação de documentos brasileiros
- Sistema de validação baseado em regras

```typescript
import { isValidCPF, formatCPF, validateFields } from './_shared/validation.ts';

const isValid = isValidCPF('12345678901');
const formatted = formatCPF('12345678901'); // 123.456.789-01
```

## 🚀 Como Usar

### 1. Importação Simples
```typescript
import { 
  loadConfig,
  createLogger,
  authMiddleware,
  createSuccessResponse 
} from '../_shared/index.ts';
```

### 2. Estrutura Recomendada para Edge Functions
```typescript
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { 
  loadConfig,
  createLogger,
  authMiddleware,
  withErrorHandling,
  createSuccessResponse 
} from '../_shared/index.ts';

async function handleRequest(request: Request): Promise<Response> {
  const logger = createLogger({ name: 'MyFunction' });
  const config = loadConfig();
  
  // Autenticação
  const authResult = await authMiddleware(request, supabase, logger, ['ADMIN']);
  if (!authResult.success) return authResult.response!;
  
  // Lógica da função...
  
  return createSuccessResponse(data, 'Sucesso');
}

serve(withErrorHandling(handleRequest));
```

## 🔧 Configuração Necessária

### Variáveis de Ambiente (.env)
```bash
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Asaas
ASAAS_API_URL=https://api-sandbox.asaas.com/v3
ASAAS_MASTER_ACCESS_TOKEN=your-asaas-token

# Segurança
ENCRYPTION_SECRET=your-encryption-secret

# URLs
API_EXTERNAL_URL=https://your-api.com
```

## 📊 Benefícios da Arquitetura

### ✅ **Reutilização**
- Código compartilhado entre múltiplas Edge Functions
- Redução de duplicação de código

### ✅ **Manutenibilidade**
- Separação clara de responsabilidades
- Fácil localização e correção de bugs

### ✅ **Testabilidade**
- Módulos pequenos e focados
- Fácil criação de testes unitários

### ✅ **Consistência**
- Padrões uniformes de logging, erro e resposta
- Comportamento previsível

### ✅ **Escalabilidade**
- Fácil adição de novos módulos
- Arquitetura preparada para crescimento

## 🔄 Migração de Funções Existentes

Para migrar uma função existente:

1. **Identifique responsabilidades** na função atual
2. **Extraia lógica comum** para os módulos compartilhados
3. **Refatore a função** para usar os novos módulos
4. **Teste** a funcionalidade
5. **Substitua** o arquivo original

### Exemplo de Refatoração

**Antes (monolítico):**
```typescript
// 590 linhas de código misturado
serve(async (req) => {
  // Autenticação inline
  // Validação inline
  // Lógica de negócio
  // Tratamento de erro inline
});
```

**Depois (modular):**
```typescript
// ~200 linhas focadas na lógica de negócio
import { authMiddleware, createLogger, /* ... */ } from '../_shared/index.ts';

async function handleRequest(request: Request): Promise<Response> {
  // Código limpo e focado
}

serve(withErrorHandling(handleRequest));
```

## 📝 Próximos Passos

1. **Refatorar outras Edge Functions** usando esta arquitetura
2. **Adicionar testes unitários** para os módulos
3. **Implementar métricas** e observabilidade
4. **Documentar APIs** específicas de cada módulo
5. **Criar templates** para novas Edge Functions
