// supabase/functions/asaas_event_processor/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';
import {
  loadConfig,
  validateConfig,
  createLogger,
  withErrorHandling,
  createSuccessResponse,
  createInternalErrorResponse
} from '../_shared/index.ts';

type SupabaseClient = ReturnType<typeof createClient>;

// Interfaces para tipos de dados
interface AsaasWebhookEvent {
  id: string;
  asaas_account_id: string;
  webhook_event: string;
  webhook_data: any;
  processed: boolean;
  processed_at?: string;
  processing_error?: string;
  retry_count: number;
  signature_valid?: boolean;
  raw_payload?: string;
  created_at: string;
  updated_at: string;
}

interface AsaasAccountUpdatePayload {
  verification_status?: string;
  onboarding_status?: string;
  account_status?: string;
  onboarding_data?: any;
  last_webhook_event?: string;
  last_webhook_received_at?: string;
  updated_at: string;
}

// Interfaces
interface ProcessEventResult {
  success: boolean;
  error?: string;
}

// Constantes
const EVENT_BATCH_SIZE = 10;
const MAX_RETRY_COUNT = 3;

/**
 * Mapeia eventos do webhook para atualizações na conta
 */
function mapEventToAccountUpdate(eventType: string, eventData: any): any {
  const updatePayload: any = {
    updated_at: new Date().toISOString()
  };

  switch (eventType) {
    case 'ACCOUNT_STATUS_UPDATED':
      if (eventData.status) {
        updatePayload.account_status = eventData.status;
      }
      if (eventData.verificationStatus) {
        updatePayload.verification_status = eventData.verificationStatus;
      }
      break;

    case 'ACCOUNT_APPROVED':
      updatePayload.account_status = 'ACTIVE';
      updatePayload.verification_status = 'APPROVED';
      break;

    case 'ACCOUNT_REJECTED':
      updatePayload.account_status = 'SUSPENDED';
      updatePayload.verification_status = 'REJECTED';
      break;

    case 'ACCOUNT_SUSPENDED':
      updatePayload.account_status = 'SUSPENDED';
      break;

    case 'ACCOUNT_REACTIVATED':
      updatePayload.account_status = 'ACTIVE';
      break;

    default:
      // Para outros eventos, apenas atualizar timestamp
      break;
  }

  return updatePayload;
}

/**
 * Processa um evento de webhook do Asaas
 */
async function processEvent(
  supabase: any,
  event: AsaasWebhookEvent,
  logger: any
): Promise<ProcessEventResult> {
  const eventId = event.id;
  const eventType = event.webhook_event;
  
  logger.info('Processando evento', {
    eventId,
    eventType,
    asaasAccountId: event.asaas_account_id
  });

  try {
    // 1. Buscar a conta associada ao evento
    const { data: accountData, error: accountError } = await supabase
      .from('asaas_accounts')
      .select('*')
      .eq('id', event.asaas_account_id)
      .single();

    if (accountError || !accountData) {
      logger.error('Conta não encontrada para o evento', {
        eventId,
        asaasAccountId: event.asaas_account_id,
        error: accountError?.message
      });
      
      // Marcar evento como erro
      await markEventAsError(supabase, eventId, 'Conta não encontrada', logger);
      return { success: false, error: 'Conta não encontrada' };
    }

    // 2. Mapear evento para atualização da conta
    const eventData = typeof event.webhook_data === 'string' 
      ? JSON.parse(event.webhook_data) 
      : event.webhook_data;
    
    const updatePayload = mapEventToAccountUpdate(eventType, eventData);
    
    logger.info('Payload de atualização gerado', {
      eventId,
      accountId: accountData.id,
      updatePayload
    });

    // 3. Atualizar a conta no banco de dados
    const { error: updateError } = await supabase
      .from('asaas_accounts')
      .update(updatePayload)
      .eq('id', event.asaas_account_id);

    if (updateError) {
      logger.error('Erro ao atualizar conta', {
        eventId,
        accountId: event.asaas_account_id,
        error: updateError.message
      });
      
      // Marcar evento como erro
      await markEventAsError(supabase, eventId, updateError.message, logger);
      return { success: false, error: updateError.message };
    }

    // 4. Marcar evento como processado
    const { error: markProcessedError } = await supabase
      .from('asaas_webhooks')
      .update({
        processed: true,
        processed_at: new Date().toISOString()
      })
      .eq('id', eventId);

    if (markProcessedError) {
      logger.error('Erro ao marcar evento como processado', {
        eventId,
        error: markProcessedError.message
      });
      return { success: false, error: markProcessedError.message };
    }

    logger.info('Evento processado com sucesso', {
      eventId,
      accountId: event.asaas_account_id
    });

    return { success: true };

  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Erro desconhecido';
    
    logger.error('Erro inesperado ao processar evento', {
      eventId,
      error: errorMessage
    });
    
    // Marcar evento como erro
    await markEventAsError(supabase, eventId, errorMessage, logger);
    return { success: false, error: errorMessage };
  }
}

/**
 * Marca um evento como erro no banco de dados
 */
async function markEventAsError(
  supabase: any,
  eventId: string,
  errorMessage: string,
  logger: any
): Promise<void> {
  try {
    const { error } = await supabase
      .from('asaas_webhooks')
      .update({
        processing_error: errorMessage,
        retry_count: supabase.rpc('increment_retry_count', { event_id: eventId }),
        processed_at: new Date().toISOString()
      })
      .eq('id', eventId);

    if (error) {
      logger.error('Erro ao marcar evento como erro', {
        eventId,
        error: error.message
      });
    }
  } catch (error) {
    logger.error('Erro crítico ao marcar evento como erro', {
      eventId,
      error: error instanceof Error ? error.message : 'Erro desconhecido'
    });
  }
}

/**
 * Handler principal da função
 */
async function handleRequest(request: Request): Promise<Response> {
  const requestTimestamp = new Date();
  const requestId = crypto.randomUUID();
  
  // 1. Carregar configurações
  const config = loadConfig();
  const configValidation = validateConfig(config);
  
  if (!configValidation.isValid) {
    return createInternalErrorResponse(
      'Configuração inválida',
      `Erros: ${configValidation.errors.join(', ')}`
    );
  }
  
  // 2. Inicializar logger e cliente Supabase
  const logger = createLogger({
    name: `AsaasEventProcessor-${requestId}`
  });
  const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey, {
    auth: { persistSession: false }
  });
  
  logger.info('Processador de eventos iniciado', {
    requestId,
    timestamp: requestTimestamp.toISOString(),
    batchSize: EVENT_BATCH_SIZE
  });
  
  try {
    // 3. Buscar eventos pendentes ordenados por data (mais antigos primeiro)
    logger.info('Buscando eventos pendentes para processamento', {
      batchSize: EVENT_BATCH_SIZE,
      maxRetryCount: MAX_RETRY_COUNT
    });
    
    const { data: events, error: fetchError } = await supabase
      .from('asaas_webhooks')
      .select('*')
      .eq('processed', false)
      .lt('retry_count', MAX_RETRY_COUNT)
      .order('created_at', { ascending: true })  // Mais antigos primeiro
      .order('id', { ascending: true })          // Desempate por ID
      .limit(EVENT_BATCH_SIZE);

    if (fetchError) {
      logger.error('Erro ao buscar eventos pendentes', {
        error: fetchError.message,
        details: fetchError.details
      });
      return createInternalErrorResponse(
        'Erro ao buscar eventos',
        fetchError.message
      );
    }

    if (!events || events.length === 0) {
      logger.info('Nenhum evento pendente encontrado');
      return createSuccessResponse({
        message: 'Nenhum evento pendente para processar',
        processed: 0,
        success: 0,
        errors: 0
      });
    }

    // Log detalhado dos eventos encontrados com ordem cronológica
    const eventsInfo = events.map((e, index) => ({
      position: index + 1,
      id: e.id,
      webhook_event: e.webhook_event,
      created_at: e.created_at,
      retry_count: e.retry_count,
      asaas_account_id: e.asaas_account_id
    }));
    
    logger.info('Eventos encontrados para processamento (ordenados por data)', {
      count: events.length,
      oldestEvent: events[0]?.created_at,
      newestEvent: events[events.length - 1]?.created_at,
      events: eventsInfo
    });

    // 4. Processar eventos sequencialmente
    let processedCount = 0;
    let successCount = 0;
    let errorCount = 0;
    const results: Array<{
      event_id: string;
      webhook_event: string;
      success: boolean;
      error?: string;
    }> = [];

    for (let i = 0; i < events.length; i++) {
      const event = events[i];
      const position = i + 1;
      
      logger.info('Processando evento em sequência', {
        position: `${position}/${events.length}`,
        eventId: event.id,
        webhookEvent: event.webhook_event,
        createdAt: event.created_at,
        retryCount: event.retry_count
      });
      
      try {
        const result = await processEvent(supabase, event, logger);
        processedCount++;
        
        if (result.success) {
          successCount++;
          logger.info('Evento processado com sucesso', {
            position: `${position}/${events.length}`,
            eventId: event.id,
            webhookEvent: event.webhook_event
          });
        } else {
          errorCount++;
          logger.warn('Evento processado com erro', {
            position: `${position}/${events.length}`,
            eventId: event.id,
            webhookEvent: event.webhook_event,
            error: result.error
          });
        }
        
        results.push({
          event_id: event.id,
          webhook_event: event.webhook_event,
          success: result.success,
          error: result.error
        });
        
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Erro desconhecido';
        
        logger.error('Erro não tratado ao processar evento', {
          eventId: event.id,
          error: errorMessage
        });
        
        errorCount++;
        results.push({
          event_id: event.id,
          webhook_event: event.webhook_event,
          success: false,
          error: errorMessage
        });
      }
    }

    // 5. Retornar resultado do processamento
    const processingDuration = Date.now() - requestTimestamp.getTime();
    
    logger.info('Processamento concluído com ordem cronológica', {
      total: processedCount,
      success: successCount,
      errors: errorCount,
      durationMs: processingDuration,
      oldestProcessed: events[0]?.created_at,
      newestProcessed: events[events.length - 1]?.created_at,
      processingOrder: 'Eventos processados do mais antigo para o mais recente'
    });
    
    return createSuccessResponse({
      message: `Processamento concluído. Total: ${processedCount}, Sucesso: ${successCount}, Erros: ${errorCount}`,
      processed: processedCount,
      success: successCount,
      errors: errorCount,
      results
    });
    
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Erro desconhecido';
    
    logger.error('Erro inesperado no processador de eventos', {
      error: errorMessage
    });
    
    return createInternalErrorResponse(
      'Erro interno do servidor',
      errorMessage
    );
  }
}

// Inicializar servidor
serve(withErrorHandling(handleRequest));
