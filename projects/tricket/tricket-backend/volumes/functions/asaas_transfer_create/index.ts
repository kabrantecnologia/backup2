// NOTE: The Deno-related errors below (e.g., "Cannot find module") are typically IDE-specific and can be resolved by configuring the editor to use the Deno language server.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';
import {
  AppConfig,
  loadConfig,
  validateConfig,
  createLogger,
  Logger,
  LogLevel,
  authMiddleware,
  AuthResult,
  createAsaasClient,
  AsaasClient,
  decryptApiKey,
  withErrorHandling,
  createSuccessResponse,
  createValidationErrorResponse,
  createNotFoundErrorResponse,
  createInternalErrorResponse,
  createAuthErrorResponse,
  parseRequestBody,
  validateRequiredFields,
} from '../_shared/index.ts';

// Interface for the request payload
interface TransferPayload {
  value: number;
  payer_profile_id: string;
  receiver_profile_id: string;
  description?: string;
}

// Interface for Asaas account data from the database
interface AsaasAccountData {
  id: string;
  asaas_account_id: string;
  api_key: string;
  wallet_id: string;
  account_status: string;
}

/**
 * Fetches Asaas account data for a given profile ID.
 */
async function fetchAsaasAccount(
  supabase: SupabaseClient,
  profileId: string,
  logger: Logger,
  requestId: string
): Promise<AsaasAccountData> {
  logger.info('Fetching Asaas account data', { requestId, profileId });

  const { data, error } = await supabase
    .from('asaas_accounts')
    .select('id, asaas_account_id, api_key, wallet_id, account_status')
    .eq('profile_id', profileId)
    .single();

  if (error) {
    logger.error('Error fetching Asaas account', { requestId, profileId, error: error.message });
    throw new Error(`Account for profile ${profileId} not found.`);
  }



  logger.info('Asaas account data fetched successfully', { requestId, profileId });
  return data;
}

/**
 * The main handler for the incoming request.
 */
async function handleRequest(request: Request): Promise<Response> {
  const requestId = crypto.randomUUID();
  const logger = createLogger({ name: 'asaas-transfer-create', minLevel: LogLevel.INFO });

  logger.info('Request received', { requestId });

  // 1. Configuration and Supabase Client
  const config = loadConfig();
  const configValidation = validateConfig(config);
  if (!configValidation.isValid) {
    logger.error('Invalid server configuration', { requestId, errors: configValidation.errors });
    return createInternalErrorResponse('Server configuration is invalid.', configValidation.errors.join(', '), requestId);
  }
  const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey);

  // 2. Authentication
  const authResult = await authMiddleware(request, supabase, logger, ['ADMIN', 'SUPER_ADMIN']);
  if (!authResult.success) {
    logger.warn('Authentication failed', { requestId, error: authResult.response?.statusText });
    return authResult.response || createAuthErrorResponse('Authentication failed.');
  }

  // 3. Payload validation
  const payload = await parseRequestBody<TransferPayload>(request);
  const { isValid, missingFields } = validateRequiredFields(payload, ['value', 'payer_profile_id', 'receiver_profile_id']);
  if (!isValid) {
    const details = `Missing required fields: ${missingFields.join(', ')}`;
    logger.warn('Invalid payload', { requestId, missingFields });
    return createValidationErrorResponse('Invalid request payload.', details);
  }

  // 4. Fetch payer and receiver accounts
  const [payerAccount, receiverAccount] = await Promise.all([
    fetchAsaasAccount(supabase, payload.payer_profile_id, logger, requestId),
    fetchAsaasAccount(supabase, payload.receiver_profile_id, logger, requestId),
  ]).catch(error => {
    logger.error('Error fetching accounts', { requestId, error: error.message });
    return [];
  });

  if (!payerAccount || !receiverAccount) {
    return createNotFoundErrorResponse('One or both profiles could not be found or are not active.');
  }

  // 5. Decrypt payer's API key
  const payerApiKey = await decryptApiKey(payerAccount.api_key, config.encryptionSecret);
  if (!payerApiKey) {
    logger.error('Failed to decrypt payer API key', { requestId, payerProfileId: payload.payer_profile_id });
    return createInternalErrorResponse('Could not process payer credentials.', undefined, requestId);
  }

  // 6. Execute Asaas transfer
  const asaasClient = createAsaasClient({ apiUrl: config.asaasApiUrl, accessToken: payerApiKey, logger });
  const transferResponse = await asaasClient.createTransfer({
    walletId: receiverAccount.wallet_id,
    value: payload.value,
    description: payload.description || `Transfer from ${payload.payer_profile_id} to ${payload.receiver_profile_id}`,
  });

  if (!transferResponse.success || !transferResponse.data) {
    logger.error('Asaas transfer failed', { requestId, error: transferResponse.error });
    return createInternalErrorResponse('Failed to execute transfer with Asaas.', transferResponse.error, requestId);
  }

  // 7. Log the transfer in the database
  const { error: insertError } = await supabase.from('asaas_transfers').insert({
    asaas_transfer_id: transferResponse.data.id,
    payer_profile_id: payload.payer_profile_id,
    receiver_profile_id: payload.receiver_profile_id,
    value: transferResponse.data.value,
    status: transferResponse.data.status,
  });

  if (insertError) {
    // Log the error but don't fail the request, as the transfer was successful
    logger.error('Failed to log transfer in database', { requestId, error: insertError.message });
  }

  // 8. Return success response
  logger.info('Transfer completed successfully', { requestId, transferId: transferResponse.data.id });
  return createSuccessResponse({ ...transferResponse.data });
}

// Start the server
serve(withErrorHandling(handleRequest));
