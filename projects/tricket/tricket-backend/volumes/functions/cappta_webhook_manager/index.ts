import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';
import { corsHeaders } from '../_shared/cors.ts';
import { createLogger } from '../_shared/logger.ts';
import { authMiddleware } from '../_shared/auth.ts';
import {
  createSuccessResponse,
  createBadRequestResponse,
  createInternalErrorResponse,
} from '../_shared/response.ts';
import { loadConfig, validateConfig } from '../_shared/config.ts';
import { createCapptaClient } from '../_shared/cappta-client.ts';

const logger = createLogger({ name: 'CapptaWebhookManager' });

serve(async (req) => {
  const startTime = Date.now();
  const errorId = crypto.randomUUID();
  
  // Log inicial da requisição
  logger.info('Requisição recebida para webhook manager', { 
    method: req.method, 
    url: req.url,
    errorId,
    timestamp: new Date().toISOString()
  });

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const config = loadConfig();
    const validation = validateConfig(config);
    if (!validation.isValid) {
      logger.error('Configuração inválida', { errors: validation.errors, errorId });
      return createInternalErrorResponse(`Configuração do servidor inválida: ${validation.errors.join(', ')}`);
    }

    // Log detalhado dos headers para debugging
    const authHeader = req.headers.get('Authorization');
    const contentType = req.headers.get('Content-Type');
    const userAgent = req.headers.get('User-Agent');
    
    logger.info('Headers da requisição', {
      hasAuthHeader: !!authHeader,
      authHeaderPrefix: authHeader ? authHeader.substring(0, 20) + '...' : 'null',
      contentType,
      userAgent,
      method: req.method,
      url: req.url,
      errorId
    });

    const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey, { auth: { persistSession: false } });
    
    logger.info('Iniciando autenticação com roles múltiplos', { 
      requiredRoles: ['ADMIN', 'SUPER_ADMIN'],
      errorId 
    });
    
    const authResult = await authMiddleware(req, supabase, logger, ['ADMIN', 'SUPER_ADMIN']);
    if (!authResult.success || !authResult.user) {
      logger.error('Falha na autenticação - detalhes completos', {
        authResultSuccess: authResult.success,
        hasUser: !!authResult.user,
        hasResponse: !!authResult.response,
        errorId,
        authHeader: authHeader ? 'presente' : 'ausente'
      });
      return authResult.response || createInternalErrorResponse('Falha na autenticação');
    }
    
    logger.info('Usuário autenticado com sucesso', { 
      userId: authResult.user.id,
      roles: authResult.user.roles,
      errorId
    });

    const { action, type } = await req.json();

    if (!action || !['register', 'query', 'inactivate'].includes(action)) {
      return createBadRequestResponse('Ação inválida. Use \'register\', \'query\', ou \'inactivate\'.');
    }

    if (!type || !['merchantAccreditation', 'transaction'].includes(type)) {
      return createBadRequestResponse('Tipo de webhook inválido. Use \'merchantAccreditation\' ou \'transaction\'.');
    }

    const capptaClient = createCapptaClient(config.capptaApiUrl, config.capptaApiToken);
    let response;

    logger.info(`Executando ação '${action}' para o tipo '${type}' no webhook da Cappta.`);

    switch (action) {
      case 'register':
        // Lógica para registrar webhook na API da Cappta
        // A URL do webhook será a URL da nossa própria função de webhook receiver
        const webhookUrl = `${config.apiExternalUrl}/functions/v1/cappta_webhook_receiver`;
        response = await capptaClient.registerWebhook(config.resellerDocument, type, webhookUrl);
        break;
      case 'query':
        response = await capptaClient.queryWebhook(config.resellerDocument, type);
        break;
      case 'inactivate':
        response = await capptaClient.inactivateWebhook(config.resellerDocument, type);
        break;
    }

    if (!response.success) {
      logger.error('Falha na operação com a API da Cappta', { error: response.error, status: response.statusCode });
      return createInternalErrorResponse(`Falha na API da Cappta: ${JSON.stringify(response.error)}`);
    }

    return createSuccessResponse(response.data, `Ação '${action}' executada com sucesso.`);

  } catch (error) {
    const duration = Date.now() - startTime;
    
    // Log detalhado do erro para debugging
    logger.critical('Erro inesperado no gerenciador de webhooks da Cappta', {
      errorId,
      message: error.message,
      stack: error.stack,
      duration_ms: duration,
      errorType: error.constructor.name,
      errorCode: error.code || 'unknown',
      timestamp: new Date().toISOString()
    });
    
    // Log adicional se for erro de rede ou API
    if (error.message.includes('fetch') || error.message.includes('network') || error.message.includes('timeout')) {
      logger.error('Erro de conectividade detectado', {
        errorId,
        possibleCause: 'Network connectivity or API timeout',
        suggestion: 'Check network connection and API endpoints'
      });
    }

    return createInternalErrorResponse('Ocorreu um erro inesperado.', error.message, errorId);
  }
});
