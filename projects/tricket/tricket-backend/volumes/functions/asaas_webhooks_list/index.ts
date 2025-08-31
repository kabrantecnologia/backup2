/**
 * Edge Function: Asaas Webhooks List
 * 
 * Lista todos os webhooks cadastrados em uma conta Asaas
 * seguindo a documentação: https://docs.asaas.com/reference/list-webhooks
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

// Importações dos módulos compartilhados
import {
  loadConfig,
  validateConfig,
  createLogger,
  LogLevel,
  authMiddleware,
  decryptApiKey,
  withErrorHandling,
  createSuccessResponse,
  createValidationErrorResponse,
  createInternalErrorResponse,
  createNotFoundErrorResponse,
  parseRequestBody,
  validateRequiredFields
} from '../_shared/index.ts';

// Declaração para o ambiente Deno
declare const Deno: any;

/**
 * Interface para payload da requisição
 */
interface RequestPayload {
  asaas_account_id: string;
}

/**
 * Interface para dados da conta Asaas
 */
interface AsaasAccountData {
  id: string;
  profile_id: string;
  asaas_account_id: string;
  api_key: string;
  account_status: string;
}

/**
 * Interface para webhook do Asaas (baseada na documentação)
 */
interface AsaasWebhook {
  object: string;
  id: string;
  name: string;
  url: string;
  email: string;
  enabled: boolean;
  interrupted: boolean;
  authToken: string;
  events: string[];
  sendType: 'SEQUENTIALLY' | 'NON_SEQUENTIALLY';
  status: 'ACTIVE' | 'INACTIVE';
  deleted: boolean;
  dateCreated: string;
  dateUpdated: string;
}

/**
 * Interface para resposta da API Asaas
 */
interface AsaasWebhooksResponse {
  object: string;
  hasMore: boolean;
  totalCount: number;
  limit: number;
  offset: number;
  data: AsaasWebhook[];
}

/**
 * Busca dados da conta Asaas no banco
 */
async function fetchAsaasAccount(
  supabase: any,
  asaasAccountId: string,
  logger: any
): Promise<AsaasAccountData> {
  logger.info('Executando query no banco de dados', { 
    asaasAccountId,
    table: 'asaas_accounts',
    query_type: 'select_single'
  });

  const { data: accounts, error } = await supabase
    .from('asaas_accounts')
    .select('*')
    .eq('asaas_account_id', asaasAccountId)
    .limit(1);

  if (error) {
    logger.error('Erro na consulta ao banco de dados', { 
      asaasAccountId, 
      error_code: error.code,
      error_message: error.message,
      error_details: error.details,
      hint: error.hint
    });
    throw new Error(`Erro ao buscar conta: ${error.message}`);
  }

  if (!accounts || accounts.length === 0) {
    logger.warn('Nenhuma conta encontrada', { 
      asaasAccountId,
      result_count: 0,
      possible_issue: 'verificar se a conta foi criada corretamente'
    });
    throw new Error('Conta Asaas não encontrada');
  }

  const account = accounts[0];
  logger.info('Conta localizada com sucesso', {
    account_id: account.id,
    asaas_account_id: account.asaas_account_id,
    account_status: account.account_status,
    api_key_encrypted: !!account.api_key,
    created_at: account.created_at,
    updated_at: account.updated_at
  });

  return account;
}



/**
 * Lista webhooks da conta Asaas
 */
async function listAsaasWebhooks(
  asaasAccountId: string,
  apiKey: string,
  logger: any
): Promise<AsaasWebhooksResponse> {
  logger.info('Preparando requisição para API Asaas', { 
    asaasAccountId,
    endpoint: '/webhooks',
    method: 'GET',
    api_version: 'v3'
  });

  const apiUrl = Deno.env.get('ASAAS_API_URL') || 'https://api.asaas.com/v3';
  const requestUrl = `${apiUrl}/webhooks`;
  
  try {
    logger.info('Enviando requisição HTTP', { 
      url: requestUrl,
      headers: {
        'accept': 'application/json',
        'access_token': '[REDACTED]'
      }
    });

    const response = await fetch(requestUrl, {
      method: 'GET',
      headers: {
        'accept': 'application/json',
        'access_token': apiKey
      }
    });

    logger.info('Resposta recebida da API Asaas', {
      status: response.status,
      status_text: response.statusText,
      content_type: response.headers.get('content-type'),
      url: requestUrl
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ 
        message: 'Erro desconhecido',
        code: response.status 
      }));
      
      logger.error('Erro na resposta da API Asaas', { 
        status: response.status,
        status_text: response.statusText,
        error_message: errorData.message,
        error_code: errorData.code,
        asaas_account_id: asaasAccountId,
        possible_causes: [
          'API key inválida',
          'Conta não existe no Asaas',
          'Permissões insuficientes',
          'Limite de requisições excedido'
        ]
      });
      
      throw new Error(`API Asaas retornou erro ${response.status}: ${errorData.message || response.statusText}`);
    }

    const data: AsaasWebhooksResponse = await response.json();
    
    logger.info('Webhooks recuperados com sucesso', {
      asaas_account_id: asaasAccountId,
      total_webhooks: data.totalCount,
      has_more: data.hasMore,
      webhooks_in_response: data.data?.length || 0,
      response_structure: {
        object: data.object,
        limit: data.limit,
        offset: data.offset
      }
    });

    return data;
  } catch (error) {
    logger.error('Falha na comunicação com API Asaas', { 
      error_type: error.name,
      error_message: error.message,
      error_stack: error.stack,
      asaas_account_id: asaasAccountId,
      endpoint: requestUrl,
      troubleshooting: [
        'Verificar conectividade de rede',
        'Confirmar API key válida',
        'Verificar status do serviço Asaas',
        'Validar formato da URL da API'
      ]
    });
    throw new Error(`Falha na comunicação com Asaas: ${error.message}`);
  }
}

/**
 * Handler principal da Edge Function
 */
async function handleRequest(request: Request): Promise<Response> {
  // Inicializa logger
  const logger = createLogger({
    name: 'AsaasWebhooksList',
    minLevel: LogLevel.INFO
  });

  logger.info('Requisição recebida', { 
    method: request.method, 
    url: request.url 
  });

  const startTime = Date.now();

  try {
    // 1. Carrega e valida configurações
    logger.info('Carregando configurações');
    const config = loadConfig();
    const configValidation = validateConfig(config);
    
    if (!configValidation.isValid) {
      logger.error('Configuração inválida', { errors: configValidation.errors });
      return createInternalErrorResponse(
        'Configuração do servidor inválida',
        configValidation.errors.join(', ')
      );
    }

    // 2. Valida método HTTP
    if (request.method !== 'POST') {
      logger.warn('Método HTTP inválido', { method: request.method });
      return createValidationErrorResponse(
        'Método não permitido',
        'Apenas método POST é aceito'
      );
    }

    // 3. Parse e valida payload
    const payload = await parseRequestBody<RequestPayload>(request);
    const { isValid, missingFields } = validateRequiredFields(payload, ['asaas_account_id']);

    if (!isValid) {
      logger.warn('Payload inválido', { missingFields });
      return createValidationErrorResponse(
        'Dados de entrada inválidos',
        `Campos obrigatórios: ${missingFields.join(', ')}`
      );
    }

    // 4. Inicializa cliente Supabase
    const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey);

    // 5. Busca dados da conta
    logger.info('Iniciando busca de conta Asaas', { 
      asaas_account_id: payload.asaas_account_id,
      step: 'database_query' 
    });
    const account = await fetchAsaasAccount(supabase, payload.asaas_account_id, logger);
    logger.info('Conta recuperada com sucesso', { 
      account_id: account.id,
      asaas_account_id: account.asaas_account_id,
      account_status: account.account_status,
      step: 'account_found' 
    });

    // 6. Descriptografa API key
    logger.info('Iniciando descriptografia da API key', { 
      account_id: account.id,
      step: 'decryption_start' 
    });
    const apiKey = await decryptApiKey(account.api_key, config.encryptionSecret);
    logger.info('API key descriptografada com sucesso', { 
      account_id: account.id,
      api_key_length: apiKey.length,
      step: 'decryption_complete' 
    });

    // 7. Lista webhooks da conta
    logger.info('Iniciando chamada à API Asaas', { 
      asaas_account_id: payload.asaas_account_id,
      api_url: `${config.asaasApiUrl}/webhooks`,
      step: 'api_call_start' 
    });
    const webhooks = await listAsaasWebhooks(
      payload.asaas_account_id,
      apiKey,
      logger
    );

    // 8. Retorna resposta de sucesso
    const duration = Date.now() - startTime;
    logger.info('Processo concluído com sucesso', {
      accountId: payload.asaas_account_id,
      webhooksCount: webhooks.data.length,
      duration_ms: duration
    });

    return createSuccessResponse(
      {
        account_id: account.id,
        asaas_account_id: payload.asaas_account_id,
        webhooks: webhooks.data,
        total_count: webhooks.totalCount,
        has_more: webhooks.hasMore
      },
      'Webhooks listados com sucesso'
    );

  } catch (error) {
    const duration = Date.now() - startTime;
    const errorId = crypto.randomUUID();
    
    logger.error('Erro inesperado', {
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

// Inicia o servidor com tratamento de erros
serve(withErrorHandling(handleRequest));
