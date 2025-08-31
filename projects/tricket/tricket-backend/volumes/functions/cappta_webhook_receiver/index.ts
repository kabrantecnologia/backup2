import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { createLogger } from '../_shared/logger.ts';
import { corsHeaders } from '../_shared/cors.ts';
import {
  createSuccessResponse,
  createInternalErrorResponse,
  parseRequestBody,
} from '../_shared/response.ts';

const logger = createLogger({ name: 'CapptaWebhookReceiver' });

// Configurações do ambiente
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
const CAPPTA_WEBHOOK_SECRET = Deno.env.get('CAPPTA_WEBHOOK_SECRET') || 'webhook_secret_dev_123';

/**
 * Interface para payload de webhook da Cappta
 */
interface CapptaWebhookPayload {
  event: string;
  data: {
    transaction_id?: string;
    merchant_id?: string;
    settlement_id?: string;
    amount?: number;
    amount_cents?: number;
    status?: string;
    payment_method?: string;
    card_brand?: string;
    authorization_code?: string;
    nsu?: string;
    installments?: number;
    merchant_fee_cents?: number;
    net_amount_cents?: number;
    settlement_date?: string;
    transaction_refs?: string[];
    [key: string]: any;
  };
  timestamp: string;
}

/**
 * Valida assinatura HMAC do webhook
 */
async function validateWebhookSignature(
  payload: string,
  signature: string | null,
  secret: string
): Promise<boolean> {
  if (!signature) {
    logger.warn('Webhook recebido sem assinatura');
    return false;
  }

  try {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );

    const expectedSignature = await crypto.subtle.sign('HMAC', key, encoder.encode(payload));
    const expectedHex = Array.from(new Uint8Array(expectedSignature))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');

    const receivedSignature = signature.replace('sha256=', '');
    return expectedHex === receivedSignature;
  } catch (error) {
    logger.error('Erro ao validar assinatura do webhook', { error: error.message });
    return false;
  }
}

/**
 * Processa webhook de transação
 */
async function processTransactionWebhook(supabase: any, webhookData: any): Promise<any> {
  logger.info('Processando webhook de transação', {
    transactionId: webhookData.transaction_id,
    merchantId: webhookData.merchant_id,
    status: webhookData.status
  });

  const { data, error } = await supabase.rpc('cappta_process_transaction_webhook', {
    p_webhook_data: webhookData
  });

  if (error) {
    logger.error('Erro ao processar webhook de transação', { error: error.message });
    throw error;
  }

  return data;
}

/**
 * Processa webhook de liquidação
 */
async function processSettlementWebhook(supabase: any, webhookData: any): Promise<any> {
  logger.info('Processando webhook de liquidação', {
    settlementId: webhookData.settlement_id,
    merchantId: webhookData.merchant_id
  });

  const { data, error } = await supabase.rpc('cappta_process_settlement', {
    p_merchant_id: webhookData.merchant_id,
    p_settlement_data: webhookData
  });

  if (error) {
    logger.error('Erro ao processar webhook de liquidação', { error: error.message });
    throw error;
  }

  return data;
}

serve(async (req) => {
  const startTime = Date.now();
  const errorId = crypto.randomUUID();

  logger.info('Webhook da Cappta recebido', {
    method: req.method,
    url: req.url,
    errorId,
    timestamp: new Date().toISOString()
  });

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Criar cliente Supabase
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    // Obter payload bruto para validação de assinatura
    const rawPayload = await req.text();
    const signature = req.headers.get('X-Cappta-Signature');

    logger.info('Headers do webhook', {
      hasSignature: !!signature,
      contentType: req.headers.get('Content-Type'),
      userAgent: req.headers.get('User-Agent'),
      errorId
    });

    // Validar assinatura do webhook
    const isValidSignature = await validateWebhookSignature(rawPayload, signature, CAPPTA_WEBHOOK_SECRET);
    
    if (!isValidSignature) {
      logger.warn('Assinatura do webhook inválida', { errorId });
      // Em produção, deveria rejeitar webhooks com assinatura inválida
      // Por enquanto, apenas logamos o aviso
    }

    // Parse do payload
    let payload: CapptaWebhookPayload;
    try {
      payload = JSON.parse(rawPayload);
    } catch (parseError) {
      logger.error('Erro ao fazer parse do payload do webhook', {
        error: parseError.message,
        rawPayload: rawPayload.substring(0, 500),
        errorId
      });
      return createInternalErrorResponse('Payload inválido');
    }

    logger.info('Payload do webhook processado', {
      event: payload.event,
      merchantId: payload.data.merchant_id,
      transactionId: payload.data.transaction_id,
      settlementId: payload.data.settlement_id,
      errorId
    });

    let result: any;

    // Processar webhook baseado no tipo de evento
    switch (payload.event) {
      case 'transaction.approved':
      case 'transaction.declined':
      case 'transaction.cancelled':
        result = await processTransactionWebhook(supabase, payload.data);
        break;

      case 'settlement.completed':
      case 'settlement.failed':
        result = await processSettlementWebhook(supabase, payload.data);
        break;

      case 'test_integration':
        // Evento de teste - apenas log
        logger.info('Webhook de teste recebido', {
          data: payload.data,
          errorId
        });
        result = { success: true, message: 'Teste processado' };
        break;

      default:
        logger.warn('Tipo de evento não reconhecido', {
          event: payload.event,
          errorId
        });
        result = { success: false, error: 'UNKNOWN_EVENT', event: payload.event };
    }

    const duration = Date.now() - startTime;

    logger.info('Webhook processado com sucesso', {
      event: payload.event,
      result: result,
      duration_ms: duration,
      errorId
    });

    // Sempre responder 200 OK para webhooks processados
    return createSuccessResponse({
      received: true,
      processed: true,
      event: payload.event,
      result: result,
      signature_valid: isValidSignature
    }, 'Webhook processado com sucesso.');

  } catch (error) {
    const duration = Date.now() - startTime;

    logger.critical('Erro inesperado ao processar webhook da Cappta', {
      errorId,
      message: error.message,
      stack: error.stack,
      duration_ms: duration,
      errorType: error.constructor.name,
      timestamp: new Date().toISOString()
    });

    // Responder 200 OK mesmo com erro para evitar reenvios desnecessários
    // O erro foi logado para investigação posterior
    return createSuccessResponse({
      received: true,
      processed: false,
      error: 'PROCESSING_ERROR',
      error_id: errorId
    }, 'Webhook recebido mas houve erro no processamento.');
  }
});
