/// <reference types="https://deno.land/x/deno/cli/types/dts/index.d.ts" />

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';
import {
  loadConfig,
  validateConfig,
  createLogger,
  LogLevel,
  withErrorHandling,
  createSuccessResponse,
  createInternalErrorResponse,
  createValidationErrorResponse,
  parseRequestBody,
  validateRequiredFields,
  createAuthErrorResponse,
  createNotFoundErrorResponse,
} from '../_shared/index.ts';

// Interface para os dados da conta Asaas, garantindo consistência
interface AsaasAccount {
  id: string;
  profile_id: string;
  webhook_token: string;
  account_status: string;
}

// Interface para o payload do webhook de transferência
interface TransferWebhookPayload {
  event: string;
  transfer: {
    id: string;
  };
}

/**
 * The main handler for the incoming webhook request.
 */
async function handleRequest(request: Request): Promise<Response> {
  const requestId = crypto.randomUUID();
  const logger = createLogger({ name: 'asaas-webhook-transfer', minLevel: LogLevel.INFO });

  logger.info('Request received', { requestId });

  // 1. Load and validate configuration
  const config = loadConfig();
  const configValidation = validateConfig(config);
  if (!configValidation.isValid) {
    logger.error('Invalid server configuration', { requestId, errors: configValidation.errors });
    return createInternalErrorResponse('Server configuration is invalid.', configValidation.errors.join(', '), requestId);
  }

  // 2. Initialize Supabase client
  const supabase: SupabaseClient = createClient(config.supabaseUrl, config.supabaseServiceRoleKey);

  // 3. Authenticate the webhook request
  const webhookToken = request.headers.get('asaas-access-token');
  if (!webhookToken) {
    logger.warn('Token de autenticação ausente', { requestId });
    return createAuthErrorResponse('Token de autenticação é obrigatório');
  }

  // Validação de tamanho do token
  if (webhookToken.length < 10) {
    logger.warn('Token de webhook muito curto', { 
      requestId,
      tokenLength: webhookToken.length,
      receivedToken: webhookToken
    });
    return createAuthErrorResponse('Token de autenticação inválido');
  }

  // 4. Find the Asaas account by the webhook token
  const { data: accounts, error: accountError } = await supabase
    .from('asaas_accounts')
    .select('id, profile_id, webhook_token, account_status')
    .eq('webhook_token', webhookToken)
    .not('webhook_token', 'is', null);

  if (accountError) {
    logger.error('Error fetching Asaas account', { requestId, error: accountError.message });
    return createInternalErrorResponse('Error querying account data.', accountError.message, requestId);
  }

  if (!accounts || accounts.length === 0) {
    logger.warn('No account found for the provided token', { requestId });
    return createNotFoundErrorResponse('Account not found for the provided token.');
  }

  if (accounts.length > 1) {
    logger.warn('Multiple accounts found for the same token', { requestId, count: accounts.length });
    return createInternalErrorResponse('Ambiguous authentication token.', `Multiple accounts (${accounts.length}) found.`, requestId);
  }

  const account = accounts[0] as AsaasAccount;

  // 5. Parse and validate the request payload
  let payload: TransferWebhookPayload;
  try {
    payload = await parseRequestBody<TransferWebhookPayload>(request);
    const { isValid, missingFields } = validateRequiredFields(payload, ['event', 'transfer']);

    if (!isValid) {
      const details = `Missing required fields: ${missingFields.join(', ')}`;
      logger.warn('Invalid payload', { requestId, missingFields });
      return createValidationErrorResponse('Invalid request payload.', details);
    }

    if (typeof payload.event !== 'string' || !payload.event.startsWith('TRANSFER_')) {
      logger.warn('Invalid transfer event type', { requestId, event: payload.event });
      return createValidationErrorResponse('Event type is invalid for this webhook.');
    }

  } catch (error) {
    logger.error('Error processing payload', { requestId, error: error.message });
    return createInternalErrorResponse('Error processing request body.', error.message, requestId);
  }

  // 6. Enqueue the event for asynchronous processing
  const eventData = {
    asaas_account_id: account.id,
    webhook_event: payload.event,
    webhook_data: payload,
    processed: false,
    signature_valid: true,
    raw_payload: JSON.stringify(payload)
  };

  const { error: insertError } = await supabase
    .from('asaas_webhooks')
    .insert(eventData);

  if (insertError) {
    if (insertError.code === '23505') { // Handle duplicate events
      logger.warn('Duplicate webhook event received', { requestId, event: payload.event, transferId: payload.transfer.id });
      return createSuccessResponse({ status: 'duplicate' }, 'Duplicate event received and ignored.');
    }
    logger.error('Error inserting webhook event', { requestId, error: insertError.message });
    return createInternalErrorResponse('Error registering webhook event.', insertError.message, requestId);
  }

  logger.info('Transfer webhook enqueued successfully', { requestId });

  // 7. Return a success response to Asaas
  return createSuccessResponse({ status: 'received' }, 'Webhook received successfully.');
}

// Start the server with the error-handling wrapper
serve(withErrorHandling(handleRequest));
