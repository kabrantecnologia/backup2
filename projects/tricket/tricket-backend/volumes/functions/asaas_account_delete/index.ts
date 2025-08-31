/**
 * Edge Function: Asaas Account Delete (Refatorada)
 * 
 * Exclui uma conta de cliente (subconta) na plataforma Asaas
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
  authMiddleware,
  decryptApiKey,
  withErrorHandling,
  createSuccessResponse,
  createInternalErrorResponse,
  parseRequestBody,
  validateRequiredFields
} from '../_shared/index.ts';

// Declaração para o ambiente Deno
declare const Deno: any;

/**
 * Interface para payload da requisição
 */
interface DeleteAccountPayload {
  profile_id: string;
  remove_reason: string;
}

/**
 * Handler principal da Edge Function
 */
async function handleRequest(request: Request): Promise<Response> {
  // Inicializa logger
  const logger = createLogger({
    name: 'AsaasAccountDelete',
    minLevel: LogLevel.INFO
  });

  logger.info('Requisição recebida para exclusão de conta Asaas', { 
    method: request.method, 
    url: request.url 
  });

  const startTime = Date.now();
  const requestId = crypto.randomUUID();

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

    const authResult = await authMiddleware(request, supabase, logger, ['ADMIN', 'SUPER_ADMIN']);
    
    if (!authResult.success || !authResult.user) {
      logger.warn('Falha na autenticação ou autorização', { 
        requestId,
        success: authResult.success
      });
      return authResult.response!;
    }
    
    logger.info('Usuário autenticado e autorizado com sucesso', { 
      requestId,
      userId: authResult.user.id,
      userRoles: authResult.user.roles
    });

    // 4. Parse e validação do payload
    logger.info('Fazendo parse do payload da requisição', { requestId });
    const payload = await parseRequestBody<DeleteAccountPayload>(request);
    
    const requiredFields = ['profile_id', 'remove_reason'];
    const validation = validateRequiredFields(payload, requiredFields);
    
    if (!validation.isValid) {
      logger.warn('Campos obrigatórios ausentes', { 
        requestId,
        missingFields: validation.missingFields
      });
      return createInternalErrorResponse(
        'Campos obrigatórios ausentes',
        `Campos obrigatórios: ${validation.missingFields.join(', ')}`
      );
    }
    
    const { profile_id, remove_reason } = payload;
    
    logger.info('Payload validado com sucesso', { 
      requestId,
      profile_id,
      remove_reason
    });

    // 5. Buscar a conta no banco de dados
    logger.info('Buscando conta no banco de dados', { requestId, profile_id });
    const { data: accountData, error: accountError } = await supabase
      .from('asaas_accounts')
      .select('*')
      .eq('profile_id', profile_id)
      .single();

    if (accountError || !accountData) {
      logger.error('Conta não encontrada no banco de dados', { 
        requestId,
        profile_id,
        error: accountError?.message,
        errorDetails: accountError
      });
      return createInternalErrorResponse(
        'Conta não encontrada',
        `Nenhuma conta encontrada para o profile_id: ${profile_id}`
      );
    }
    
    logger.info('Conta encontrada no banco de dados', {
      requestId,
      accountId: accountData.id,
      asaasAccountId: accountData.asaas_account_id,
      accountStatus: accountData.account_status,
      hasApiKey: !!accountData.api_key
    });
    
    // 6. Descriptografar a API Key
    logger.info('Iniciando processo de descriptografia da API Key', { requestId });
    
    if (!accountData.api_key) {
      logger.error('API Key não encontrada na conta', { 
        requestId, 
        accountId: accountData.id 
      });
      return createInternalErrorResponse(
        'API Key não encontrada',
        'Esta conta não possui uma API Key válida'
      );
    }
    
    let apiKey: string;
    try {
      apiKey = await decryptApiKey(accountData.api_key, config.encryptionSecret);
      logger.info('API Key descriptografada com sucesso', { 
        requestId,
        apiKeyPrefix: apiKey.substring(0, 10) + '...'
      });
    } catch (decryptError) {
      logger.error('Erro ao descriptografar API Key', {
        requestId,
        error: decryptError.message,
        stack: decryptError.stack
      });
      return createInternalErrorResponse(
        'Erro ao descriptografar API Key',
        'Não foi possível descriptografar a API Key armazenada'
      );
    }
    
    // 7. Chamar API do Asaas para excluir a conta
    const asaasUrl = `${config.asaasApiUrl}/myAccount/`;
    const deletePayload = { removeReason: remove_reason };
    
    logger.info('Preparando requisição para API do Asaas', {
      requestId,
      asaasUrl,
      asaasAccountId: accountData.asaas_account_id,
      removeReason: remove_reason
    });
    
    const options = {
      method: 'DELETE',
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'access_token': apiKey.trim()
      },
      body: JSON.stringify(deletePayload)
    };
    
    let asaasResponse: Response;
    let responseData: any;
    
    try {
      logger.info('Enviando requisição DELETE para Asaas', { requestId, asaasUrl });
      asaasResponse = await fetch(asaasUrl, options);
      responseData = await asaasResponse.json();
      
      logger.info('Resposta recebida da API Asaas', {
        requestId,
        status: asaasResponse.status,
        statusText: asaasResponse.statusText,
        responseKeys: Object.keys(responseData || {})
      });
    } catch (fetchError) {
      logger.error('Erro na requisição para API do Asaas', {
        requestId,
        error: fetchError.message,
        stack: fetchError.stack
      });
      return createInternalErrorResponse(
        'Erro de conectividade com API do Asaas',
        'Não foi possível conectar com a API do Asaas'
      );
    }
    
    if (!asaasResponse.ok) {
      logger.error('API do Asaas retornou erro', { 
        requestId,
        status: asaasResponse.status,
        statusText: asaasResponse.statusText,
        response: responseData,
        asaasAccountId: accountData.asaas_account_id
      });
      return createInternalErrorResponse(
        'Erro ao excluir conta no Asaas',
        `API retornou erro: ${responseData?.message || 'Erro desconhecido'}`
      );
    }
    
    logger.info('Conta excluída com sucesso no Asaas', {
      requestId,
      asaasAccountId: accountData.asaas_account_id,
      responseData
    });
    
    // 8. Atualizar registro no banco de dados
    logger.info('Atualizando registro no banco de dados', { requestId, profile_id });
    
    const updateData = {
      account_status: 'CANCELLED',
      updated_at: new Date().toISOString(),
      // Armazenar informações de exclusão no onboarding_data
      onboarding_data: {
        ...accountData.onboarding_data,
        deleted_at: new Date().toISOString(),
        delete_reason: remove_reason,
        asaas_response: responseData
      }
    };
    
    const { error: updateError } = await supabase
      .from('asaas_accounts')
      .update(updateData)
      .eq('profile_id', profile_id);
    
    if (updateError) {
      logger.error('Erro ao atualizar conta no banco de dados', { 
        requestId,
        profile_id,
        error: updateError.message, 
        details: updateError.details,
        updateData
      });
      
      // Mesmo com erro no banco, a conta foi excluída no Asaas
      const duration = Date.now() - startTime;
      logger.warn('Exclusão parcialmente bem-sucedida', {
        requestId,
        duration_ms: duration,
        asaasDeleted: true,
        databaseUpdated: false
      });
      
      return createSuccessResponse({
        success: true,
        warning: 'Conta excluída no Asaas, mas houve erro ao atualizar banco de dados',
        asaas_response: responseData,
        database_error: updateError.message
      });
    }
    
    // 9. Retornar resposta de sucesso completo
    const duration = Date.now() - startTime;
    
    logger.info('Conta excluída com sucesso completo', { 
      requestId,
      profile_id,
      asaasAccountId: accountData.asaas_account_id,
      duration_ms: duration
    });
    
    return createSuccessResponse({
      success: true,
      message: 'Conta excluída com sucesso',
      profile_id,
      asaas_account_id: accountData.asaas_account_id,
      deleted_at: updateData.onboarding_data.deleted_at,
      remove_reason,
      asaas_response: responseData
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    const errorId = crypto.randomUUID();
    
    logger.error('Erro inesperado ao processar exclusão de conta', {
      requestId,
      errorId,
      message: error.message,
      stack: error.stack,
      duration_ms: duration,
      timestamp: new Date().toISOString()
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
