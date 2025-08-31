 🚀 Prompt Contextual - Continuidade no Servidor dev2

  Status Atual do Projeto

  Integração Tricket + Simulador Cappta: 85% Completa

  - Taxa de Sucesso Atual: 60% (3/5 testes)
  - Ambiente: dev2.tricket.kabran.com.br
  - Branch: feat/testes-integracao-cappta-simulador

  ---
  ✅ SUCESSOS CONQUISTADOS

  Infraestrutura 100% Operacional:

  - Simulador Cappta:
  https://simulador-cappta.kabran.com.br ✅
  - Edge Functions: Respondendo corretamente ✅
  - Webhook Flow: Processamento completo ✅
  - Configurações: Variáveis de ambiente sincronizadas
   ✅

  Componentes Funcionais:

  1. Simulador Health: 200 OK
  2. Edge Functions Health: 200 OK
  3. Webhook Flow: Processamento bidirecional
  funcional

  ---
  ❌ PROBLEMA ATUAL: Autenticação JWT (401)

  Falhas Específicas:

  - cappta_webhook_manager: Token inválido ou expirado
  - cappta_pos_create: Token inválido ou expirado

  Causa Identificada:

  Edge Functions Cappta usam arquitetura simplificada
  vs. Edge Functions Asaas (funcionais) que usam
  arquitetura robusta.

  ---
  📋 PLANO DE CORREÇÃO DESENVOLVIDO

  Baseado em: Análise das Edge Functions Asaas 
  funcionais

  Documento: tricket-vault/plans/2025-08-19-2000-plano
  -correcao-auth-cappta-edge-functions.md

  Diferenças Críticas Identificadas:

  Edge Functions Asaas (FUNCIONANDO):

  async function handleRequest(request: Request): 
  Promise<Response> {
    const logger = createLogger({ name:
  'AsaasAccountCreate', minLevel: LogLevel.INFO });

    // Logging detalhado de auth headers
    const authHeader =
  request.headers.get('Authorization');
    logger.info('Headers da requisição', {
      hasAuthHeader: !!authHeader,
      authHeaderPrefix: authHeader ?
  authHeader.substring(0, 20) + '...' : 'null'
    });

    // Múltiplas roles aceitas
    const authResult = await authMiddleware(request,
  supabase, logger, ['ADMIN', 'SUPER_ADMIN']);

    // Error handling com IDs únicos
    const errorId = crypto.randomUUID();
    logger.critical('Erro inesperado', { errorId,
  message: error.message });
  }

  Edge Functions Cappta (PROBLEMA):

  serve(async (req) => {  // Função anônima simples
    const authResult = await authMiddleware(req,
  supabase, logger, ['ADMIN']); // Apenas 1 role
    // Logging mínimo, error handling básico
  });

  ---
  🎯 PRÓXIMOS PASSOS IMEDIATOS

  Etapa 1: Diagnóstico Detalhado

  1. Adicionar logging avançado nas Edge Functions
  Cappta
  2. Implementar error IDs únicos para rastreamento
  3. Executar testes com logs detalhados para
  identificar causa raiz

  Etapa 2: Correção Arquitetural

  1. Refatorar Edge Functions para padrão Asaas
  (handlers dedicados)
  2. Aceitar múltiplas roles: ['ADMIN', 'SUPER_ADMIN']
  3. Implementar logging extensivo como nas funções
  Asaas

  Etapa 3: Validação Final

  1. Executar suite completa de testes
  2. Atingir 5/5 testes passando
  3. Documentar correções aplicadas

  ---
  🔧 COMANDOS PARA EXECUÇÃO

  Testes de Integração:

  cd /tricket-tests
  python testing/test_cappta_integration.py

  Diagnóstico Específico:

  # Ver logs das Edge Functions
  # Testar autenticação diretamente
  curl -X POST "https://api-dev2-tricket.kabran.com.br
  /functions/v1/cappta_webhook_manager" \
    -H "Authorization: Bearer [TOKEN_ADMIN]" \
    -H "Content-Type: application/json" \
    -d '{"action": "register", "type": 
  "merchantAccreditation"}'

  ---
  📁 ARQUIVOS RELEVANTES

  Edge Functions Cappta (para modificar):

  - tricket-backend/volumes/functions/cappta_webhook_m
  anager/index.ts
  - tricket-backend/volumes/functions/cappta_pos_creat
  e/index.ts

  Edge Functions Asaas (referência):

  - tricket-backend/volumes/functions/asaas_account_cr
  eate/index.ts

  Shared Components:

  - tricket-backend/volumes/functions/_shared/auth.ts
  -
  tricket-backend/volumes/functions/_shared/config.ts

  Testes:

  - tricket-tests/testing/test_cappta_integration.py

  ---
  🎯 OBJETIVO FINAL

  Resolver erro 401 e atingir 5/5 testes de integração
   passando:
  - ✅ Simulador Health
  - ✅ Edge Functions Health
  - ❌ Webhook Manager → CORRIGIR
  - ❌ POS Create → CORRIGIR
  - ✅ Webhook Flow

  ---
  💡 CONTEXTO PARA CLAUDE

  Você está continuando um projeto de integração entre
   Tricket e Simulador Cappta. A infraestrutura está 
  100% operacional, mas há um problema específico de 
  autenticação JWT nas Edge Functions Cappta que estão
   retornando erro 401. Já foi identificado que o 
  problema é uma diferença de arquitetura entre as 
  Edge Functions Asaas (que funcionam) e as Edge 
  Functions Cappta (que falham). Um plano detalhado de
   correção já foi desenvolvido baseado na análise das
   funções funcionais.

  Próximo passo: Implementar logging detalhado nas
  Edge Functions Cappta para identificar a causa raiz
  exata do erro 401, seguido da refatoração
  arquitetural para seguir o padrão das funções Asaas
  funcionais.