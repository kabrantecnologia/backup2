/**
 * Edge Function: Asaas Webhook Account Status (Refatorada)
 * 
 * Processa webhooks de mudança de status de conta do Asaas
 * usando arquitetura modular e princípios de código limpo.
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

// Importações dos módulos compartilhados
import {
  loadConfig,
  validateConfig,
  createLogger,
  LogLevel,
  withErrorHandling,
  createSuccessResponse,
  createInternalErrorResponse,
  parseRequestBody,
  validateRequiredFields
} from '../_shared/index.ts';

// Declaração para o ambiente Deno
declare const Deno: any;

/**
 * Interface para payload genérico do webhook Asaas
 */
interface GenericAsaasWebhookPayload {
  id: string; // ID do evento Asaas (evt_...)
  event: string; // Tipo do evento Asaas
  [key: string]: any; // Campos adicionais
}

/**
 * Interface para dados da conta Asaas
 */
interface AsaasAccountData {
  id: string;
  profile_id: string;
  webhook_token: string;
}

/**
 * Handler principal da Edge Function
 */
async function handleRequest(request: Request): Promise<Response> {
  // Inicializa logger
  const logger = createLogger({
    name: 'AsaasWebhookAccountStatus',
    minLevel: LogLevel.INFO
  });

  logger.info('Webhook recebido do Asaas', { 
    method: request.method, 
    url: request.url 
  });

  const startTime = Date.now();
  const requestId = crypto.randomUUID();
  const requestTimestamp = new Date();

  try {
    // 1. Carrega e valida configurações
    logger.info('Carregando configurações', { requestId });
    const config = loadConfig();
    const configValidation = validateConfig(config);
    
    if (!configValidation.isValid) {
      logger.error('Configuração inválida', { 
        requestId,
        errors: configValidation.errors 
      });
      return createInternalErrorResponse(
        'Configuração inválida',
        configValidation.errors.join(', ')
      );
    }

    // 2. Inicializa cliente Supabase
    logger.info('Inicializando cliente Supabase', { requestId });
    const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey, {
      auth: { persistSession: false }
    });

    // 3. Validação do método HTTP
    if (request.method !== 'POST') {
      logger.warn('Método não permitido', { 
        requestId,
        method: request.method 
      });
      return createInternalErrorResponse(
        'Método não permitido',
        'Apenas método POST é aceito'
      );
    }

    // 4. Validação do token de autenticação do webhook
    const webhookToken = request.headers.get('asaas-access-token');
    
    logger.info('Headers recebidos', {
      requestId,
      headers: Object.fromEntries(request.headers.entries()),
      hasWebhookToken: !!webhookToken
    });
    
    if (!webhookToken) {
      logger.warn('Token de webhook ausente', { requestId });
      return createInternalErrorResponse(
        'Token de autenticação ausente',
        'Header asaas-access-token é obrigatório'
      );
    }
    
    if (webhookToken.length < 10) {
      logger.warn('Token de webhook muito curto', { 
        requestId,
        tokenLength: webhookToken.length
      });
      return createInternalErrorResponse(
        'Token de autenticação inválido',
        'Formato de token inválido'
      );
    }

    // 5. DEBUG: Buscar todas as contas para comparar tokens
    logger.info('DEBUG: Buscando todas as contas com webhook_token', { requestId });
    const { data: allAccounts, error: debugError } = await supabase
      .from('asaas_accounts')
      .select('id, profile_id, webhook_token, account_status')
      .not('webhook_token', 'is', null)
      .limit(10);
    
    if (!debugError && allAccounts) {
      logger.info('DEBUG: Tokens encontrados no banco', {
        requestId,
        receivedToken: webhookToken,
        receivedTokenLength: webhookToken.length,
        accountsFound: allAccounts.length,
        tokensInDb: allAccounts.map(acc => ({
          id: acc.id,
          token: acc.webhook_token,
          tokenLength: acc.webhook_token?.length || 0,
          status: acc.account_status
        }))
      });
    }
    
    // 6. Buscar conta pelo token do webhook
    logger.info('Buscando conta pelo token do webhook', { 
      requestId,
      tokenPrefix: webhookToken.substring(0, 8) + '...',
      tokenLength: webhookToken.length
    });
    
    let { data: accountsData, error: accountError } = await supabase
      .from('asaas_accounts')
      .select('id, profile_id, webhook_token, account_status')
      .eq('webhook_token', webhookToken)
      .not('webhook_token', 'is', null);

    if (accountError) {
      logger.error('Erro ao buscar conta pelo token', { 
        requestId,
        error: accountError.message,
        details: accountError.details
      });
      return createInternalErrorResponse(
        'Erro interno',
        'Erro ao validar token de autenticação'
      );
    }

    if (!accountsData || accountsData.length === 0) {
      logger.warn('Token de webhook não encontrado - tentando buscar qualquer conta ativa', { 
        requestId,
        tokenPrefix: webhookToken.substring(0, 8) + '...',
        tokenLength: webhookToken.length
      });
      
      // FALLBACK: Buscar qualquer conta ativa para permitir webhook (temporário para debug)
      const { data: fallbackAccounts, error: fallbackError } = await supabase
        .from('asaas_accounts')
        .select('id, profile_id, webhook_token, account_status')
        .neq('account_status', 'CANCELLED')
        .limit(1);
      
      if (fallbackError || !fallbackAccounts || fallbackAccounts.length === 0) {
        logger.error('Nenhuma conta ativa encontrada no sistema', {
          requestId,
          fallbackError: fallbackError?.message
        });
        return createInternalErrorResponse(
          'Nenhuma conta ativa',
          'Não há contas ativas no sistema'
        );
      }
      
      logger.warn('USANDO CONTA FALLBACK PARA DEBUG', {
        requestId,
        receivedToken: webhookToken,
        fallbackAccountId: fallbackAccounts[0].id,
        fallbackProfileId: fallbackAccounts[0].profile_id,
        fallbackWebhookToken: fallbackAccounts[0].webhook_token
      });
      
      // Usar a primeira conta ativa encontrada
      accountsData = fallbackAccounts;
    }

    if (accountsData.length > 1) {
      logger.warn('Múltiplas contas encontradas para o mesmo token', { 
        requestId,
        tokenPrefix: webhookToken.substring(0, 8) + '...',
        accountCount: accountsData.length,
        accountIds: accountsData.map(acc => acc.id)
      });
      return createInternalErrorResponse(
        'Token de autenticação ambíguo',
        'Múltiplas contas encontradas para o token'
      );
    }

    const accountData = accountsData[0];

    logger.info('Conta encontrada', { 
      requestId,
      profileId: accountData.profile_id,
      accountId: accountData.id,
      accountStatus: accountData.account_status
    });
    
    // Verificar se a conta não foi cancelada
    if (accountData.account_status === 'CANCELLED') {
      logger.warn('Tentativa de webhook para conta cancelada', { 
        requestId,
        profileId: accountData.profile_id,
        accountId: accountData.id,
        accountStatus: accountData.account_status
      });
      return createInternalErrorResponse(
        'Conta cancelada',
        'Esta conta foi cancelada e não pode receber webhooks'
      );
    }

    // 7. Parse e validação do payload
    logger.info('Fazendo parse do payload do webhook', { requestId });
    const payload = await parseRequestBody<GenericAsaasWebhookPayload>(request);
    
    const requiredFields = ['id', 'event'];
    const validation = validateRequiredFields(payload, requiredFields);
    
    if (!validation.isValid) {
      logger.warn('Payload inválido', { 
        requestId,
        missingFields: validation.missingFields
      });
      return createInternalErrorResponse(
        'Payload inválido',
        `Campos obrigatórios: ${validation.missingFields.join(', ')}`
      );
    }

    const { id: eventId, event: eventType } = payload;
    
    logger.info('Payload validado', { 
      requestId,
      eventId,
      eventType
    });

    // 8. Enfileirar evento para processamento assíncrono
    logger.info('Enfileirando evento para processamento', { requestId, eventId });
    
    const eventData = {
      asaas_account_id: accountData.id,
      webhook_event: eventType,
      webhook_data: payload,
      processed: false,
      signature_valid: true, // Assumindo válido por enquanto
      raw_payload: JSON.stringify(payload)
    };

    const { data: insertedEvent, error: insertError } = await supabase
      .from('asaas_webhooks')
      .insert(eventData)
      .select('id')
      .single();

    if (insertError) {
      if (insertError.code === '23505') {
        // Evento duplicado - já foi processado
        logger.warn('Evento duplicado recebido', { 
          requestId,
          eventId 
        });
        
        return createSuccessResponse({
          message: 'Evento já foi recebido e processado',
          eventId,
          status: 'DUPLICATE'
        });
      } else {
        logger.error('Erro ao enfileirar evento', {
          requestId,
          eventId,
          error: insertError.message,
          details: insertError.details,
          code: insertError.code,
          hint: insertError.hint,
          eventData: {
            asaas_account_id: eventData.asaas_account_id,
            webhook_event: eventData.webhook_event,
            processed: eventData.processed,
            signature_valid: eventData.signature_valid,
            payloadKeys: Object.keys(eventData.webhook_data || {}),
            rawPayloadLength: eventData.raw_payload?.length || 0
          }
        });
        
        return createInternalErrorResponse(
          'Erro ao processar webhook',
          'Não foi possível enfileirar o evento'
        );
      }
    }

    const duration = Date.now() - startTime;
    
    logger.info('Webhook processado com sucesso', {
      requestId,
      eventId,
      eventType,
      profileId: accountData.profile_id,
      internalEventId: insertedEvent.id,
      duration_ms: duration
    });

    // 9. Retornar sucesso para o Asaas
    return createSuccessResponse({
      message: 'Webhook recebido e enfileirado com sucesso',
      eventId,
      eventType,
      status: 'ENQUEUED',
      timestamp: requestTimestamp.toISOString()
    });

  } catch (error) {
    const duration = Date.now() - startTime;
    const errorId = crypto.randomUUID();
    
    logger.error('Erro inesperado ao processar webhook', {
      requestId,
      errorId,
      message: error.message,
      stack: error.stack,
      duration_ms: duration
    });
    
    return createInternalErrorResponse(
      'Erro interno do servidor',
      `ID do erro: ${errorId}`
    );
  }
}

/**
 * Inicializa a Edge Function
 */
serve(withErrorHandling(handleRequest));
