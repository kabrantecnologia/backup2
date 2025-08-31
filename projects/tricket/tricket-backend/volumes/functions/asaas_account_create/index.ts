/**
 * Edge Function: Asaas Account Create (Refatorada)
 * 
 * Cria uma nova conta de cliente (subconta) na plataforma Asaas
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
  createAsaasClient,
  transformProfileToAsaasPayload,
  validateProfileData,
  encryptApiKey,
  withErrorHandling,
  createSuccessResponse,
  createValidationErrorResponse,
  createNotFoundErrorResponse,
  createInternalErrorResponse,
  parseRequestBody,
  validateRequiredFields
} from '../_shared/index.ts';

// Importação do logger de debug (REMOVER EM PRODUÇÃO)
import { logAccountCredentials } from '../logs/account_creation_logger.ts';

// Declaração para o ambiente Deno
declare const Deno: any;

/**
 * Interface para payload da requisição
 */
interface RequestPayload {
  profile_id: string;
  profile_type: 'INDIVIDUAL' | 'ORGANIZATION';
}

/**
 * Interface para dados de perfil da view
 */
interface ProfileViewData {
  profile_id: string;
  profile_type: string;
  name: string;
  email: string;
  cpf_cnpj: string;
  birth_date?: string;
  company_type?: string;
  mobile_phone?: string;
  income_value_cents?: number;
  address?: string;
  address_number?: string;
  complement?: string;
  province?: string;
  postal_code?: string;
}

/**
 * Busca dados do perfil na view de aprovação
 */
async function fetchProfileData(
  supabase: any,
  profileId: string,
  logger: any
): Promise<ProfileViewData> {
  logger.info('Buscando dados do perfil', { profileId });

  const { data: profiles, error } = await supabase
    .from('view_admin_profile_approval')
    .select('*')
    .eq('profile_id', profileId)
    .order('profile_type', { ascending: false });

  if (error) {
    logger.error('Erro ao buscar dados do perfil', { 
      profileId, 
      error: error.message 
    });
    throw new Error(`Erro ao buscar perfil: ${error.message}`);
  }

  if (!profiles || profiles.length === 0) {
    logger.warn('Perfil não encontrado', { profileId });
    throw new Error('Perfil não encontrado');
  }

  // Prioriza ORGANIZATION se múltiplos perfis forem retornados
  const profile = profiles[0];
  
  logger.info('Dados do perfil obtidos', {
    profileId: profile.profile_id,
    profileType: profile.profile_type,
    name: profile.name,
    email: profile.email
  });

  return profile;
}

/**
 * Salva dados da conta criada no banco de dados
 */
async function saveAccountData(
  supabase: any,
  profileId: string,
  asaasAccountData: any,
  encryptedApiKey: string,
  webhookAuthToken: string,
  logger: any
): Promise<any> {
  logger.info('Salvando dados da conta no banco', { 
    profileId, 
    asaasId: asaasAccountData.id 
  });

  const { data: insertedAccount, error } = await supabase
    .from('asaas_accounts')
    .insert({
      profile_id: profileId,
      asaas_account_id: asaasAccountData.id,
      api_key: encryptedApiKey,
      wallet_id: asaasAccountData.walletId,
      webhook_token: webhookAuthToken,
      account_status: 'PENDING',
      account_type: 'MERCHANT',
      onboarding_status: 'PENDING',
      verification_status: 'AWAITING_DOCUMENTATION',
      onboarding_data: {
        bankAccount: asaasAccountData.bankAccount || null,
        createdAt: new Date().toISOString(),
        initialStatus: asaasAccountData.status
      },
      account_settings: {
        webhookEnabled: true,
        notificationsEnabled: true
      }
    })
    .select('*')
    .single();

  if (error) {
    logger.error('Erro ao salvar conta no banco', { 
      error: error.message,
      details: error.details,
      code: error.code
    });
    throw new Error(`Erro ao salvar conta: ${error.message}`);
  }

  logger.info('Conta salva com sucesso no banco', { 
    accountId: insertedAccount.id,
    asaasId: asaasAccountData.id
  });

  return insertedAccount;
}

/**
 * Handler principal da Edge Function
 */
async function handleRequest(request: Request): Promise<Response> {
  // Inicializa logger
  const logger = createLogger({
    name: 'AsaasAccountCreate',
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
        'Configuração inválida',
        configValidation.errors.join(', ')
      );
    }

    // 2. Inicializa cliente Supabase
    logger.info('Inicializando cliente Supabase');
    const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey, {
      auth: { persistSession: false }
    });

    // 3. Autenticação e autorização
    logger.info('Verificando autenticação e autorização');
    
    // Log detalhado dos headers para debugging
    const authHeader = request.headers.get('Authorization');
    const contentType = request.headers.get('Content-Type');
    const userAgent = request.headers.get('User-Agent');
    
    logger.info('Headers da requisição', {
      hasAuthHeader: !!authHeader,
      authHeaderPrefix: authHeader ? authHeader.substring(0, 20) + '...' : 'null',
      contentType,
      userAgent,
      method: request.method,
      url: request.url
    });
    
    const authResult = await authMiddleware(
      request,
      supabase,
      logger,
      ['ADMIN', 'SUPER_ADMIN']
    );

    if (!authResult.success) {
      return authResult.response!;
    }

    const authenticatedUser = authResult.user!;
    logger.info('Usuário autenticado', { 
      userId: authenticatedUser.id,
      roles: authenticatedUser.roles
    });

    // 4. Valida payload da requisição
    logger.info('Validando payload da requisição');
    
    let payload: RequestPayload;
    try {
      payload = await parseRequestBody<RequestPayload>(request);
      logger.info('Payload parseado com sucesso', {
        hasProfileId: !!payload.profile_id,
        hasProfileType: !!payload.profile_type,
        profileType: payload.profile_type,
        payloadKeys: Object.keys(payload || {})
      });
    } catch (error) {
      logger.error('Erro ao fazer parse do payload', {
        error: error.message,
        stack: error.stack
      });
      return createValidationErrorResponse(
        'Payload inválido',
        `Erro ao processar dados da requisição: ${error.message}`
      );
    }
    
    const fieldValidation = validateRequiredFields(payload, ['profile_id', 'profile_type']);
    if (!fieldValidation.isValid) {
      logger.warn('Campos obrigatórios ausentes', { 
        missingFields: fieldValidation.missingFields,
        receivedPayload: payload
      });
      return createValidationErrorResponse(
        'Campos obrigatórios ausentes',
        `Os seguintes campos são obrigatórios: ${fieldValidation.missingFields.join(', ')}`
      );
    }

    // 5. Busca dados do perfil
    let profileData: ProfileViewData;
    try {
      profileData = await fetchProfileData(supabase, payload.profile_id, logger);
    } catch (error) {
      if (error.message.includes('não encontrado')) {
        return createNotFoundErrorResponse('Perfil não encontrado');
      }
      throw error;
    }

    // 6. Valida dados do perfil
    const profileValidation = validateProfileData(profileData);
    if (!profileValidation.isValid) {
      logger.error('Dados do perfil inválidos', { 
        errors: profileValidation.errors 
      });
      return createValidationErrorResponse(
        'Dados do perfil inválidos',
        profileValidation.errors.join(', ')
      );
    }

    // 7. Cria cliente Asaas
    logger.info('Inicializando cliente Asaas', {
      apiUrl: config.asaasApiUrl,
      hasAccessToken: !!config.asaasMasterAccessToken,
      tokenPrefix: config.asaasMasterAccessToken ? config.asaasMasterAccessToken.substring(0, 10) + '...' : 'null'
    });
    
    const asaasClient = createAsaasClient({
      apiUrl: config.asaasApiUrl,
      accessToken: config.asaasMasterAccessToken,
      logger
    });

    // 8. Transforma dados para payload Asaas
    logger.info('Transformando dados para payload Asaas', {
      profileName: profileData.name,
      profileEmail: profileData.email,
      profileType: profileData.profile_type,
      hasCpfCnpj: !!profileData.cpf_cnpj
    });
    
    const webhookConfig = {
      accountStatusUrl: `${config.apiExternalUrl}/functions/v1/asaas_webhook_account_status`,
      transferStatusUrl: `${config.apiExternalUrl}/functions/v1/asaas_webhook_transfer_status`,
      email: 'baas@tricket.com.br'
    };
    
    logger.info('Configuração de webhooks', webhookConfig);

    const { payload: asaasPayload, webhookToken } = transformProfileToAsaasPayload(
      profileData,
      webhookConfig,
      logger
    );
    
    logger.info('Payload Asaas gerado', {
      payloadKeys: Object.keys(asaasPayload),
      hasWebhooks: !!asaasPayload.webhooks,
      webhooksCount: asaasPayload.webhooks?.length || 0,
      webhookTokenGenerated: !!webhookToken
    });

    // 9. Cria conta no Asaas
    logger.info('Criando conta no Asaas');
    const asaasResponse = await asaasClient.createAccount(asaasPayload);

    if (!asaasResponse.success) {
      logger.error('Falha ao criar conta no Asaas', { 
        error: asaasResponse.error,
        statusCode: asaasResponse.statusCode
      });
      return createInternalErrorResponse(
        'Falha ao criar conta no Asaas',
        asaasResponse.error
      );
    }

    const asaasAccountData = asaasResponse.data!;
    logger.info('Conta criada com sucesso no Asaas', {
      asaasId: asaasAccountData.id,
      walletId: asaasAccountData.walletId,
      status: asaasAccountData.status
    });

    // 10. Criptografa API Key
    logger.info('Criptografando API Key');
    const encryptedApiKey = await encryptApiKey(
      asaasAccountData.apiKey,
      config.encryptionSecret
    );

    // 11. Salva dados no banco
    const webhookAuthToken = crypto.randomUUID();
    const savedAccount = await saveAccountData(
      supabase,
      payload.profile_id,
      asaasAccountData,
      encryptedApiKey,
      webhookAuthToken,
      logger
    );

    // 12. Log de credenciais para debugging (REMOVER EM PRODUÇÃO)
    try {
      await logAccountCredentials(
        {
          supabaseUrl: config.supabaseUrl,
          supabaseServiceRoleKey: config.supabaseServiceRoleKey
        },
        {
          profile_id: payload.profile_id,
          asaas_account_id: asaasAccountData.id,
          webhook_token: webhookAuthToken,
          api_key: asaasAccountData.apiKey, // API key original (será criptografada no banco)
          wallet_id: asaasAccountData.walletId,
          created_at: new Date().toISOString(),
          environment: 'development'
        }
      );
      logger.info('Credenciais salvas no log de debug', { 
        profileId: payload.profile_id,
        webhookToken: webhookAuthToken 
      });
    } catch (logError) {
      logger.warn('Erro ao logar credenciais (não crítico)', { 
        error: logError.message 
      });
    }

    // 13. Retorna resposta de sucesso
    const duration = Date.now() - startTime;
    logger.info('Processo concluído com sucesso', {
      profileId: payload.profile_id,
      asaasId: asaasAccountData.id,
      duration_ms: duration
    });

    return createSuccessResponse(
      {
        profile_id: payload.profile_id,
        profile_type: payload.profile_type,
        asaas_account_id: asaasAccountData.id,
        wallet_id: asaasAccountData.walletId,
        account_status: asaasAccountData.status,
        onboarding_status: 'PENDING',
        verification_status: 'AWAITING_DOCUMENTATION',
        webhook_urls: {
          account_status: webhookConfig.accountStatusUrl,
          transfer_status: webhookConfig.transferStatusUrl
        },
        webhook_token: webhookAuthToken,
        account_data: savedAccount
      },
      'Conta criada com sucesso no Asaas'
    );

  } catch (error) {
    const duration = Date.now() - startTime;
    const errorId = crypto.randomUUID();
    
    // Log detalhado do erro para debugging
    logger.critical('Erro inesperado', {
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

    return createInternalErrorResponse(
      'Erro interno do servidor',
      error.message,
      errorId
    );
  }
}

// Inicia o servidor com tratamento de erros
serve(withErrorHandling(handleRequest));
