import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { corsHeaders } from '../_shared/cors.ts';
import { createLogger } from '../_shared/logger.ts';
import { authMiddleware } from '../_shared/auth.ts';
import {
  createSuccessResponse,
  createErrorResponse,
  createInternalErrorResponse,
  parseRequestBody,
} from '../_shared/response.ts';

const logger = createLogger({ name: 'CapptaMerchantRegister' });

// Configurações do ambiente
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
const CAPPTA_SIMULATOR_URL = Deno.env.get('CAPPTA_SIMULATOR_URL') || 'https://simulador-cappta.kabran.com.br';
const CAPPTA_API_TOKEN = Deno.env.get('CAPPTA_API_TOKEN') || 'cappta_fake_token_dev_123';

interface MerchantRegistrationRequest {
  profile_id: string;
  document: string;
  business_name: string;
  trade_name?: string;
  mcc?: string;
  contact: {
    email: string;
    phone: string;
  };
  address: {
    street: string;
    number: string;
    city: string;
    state: string;
    zip: string;
    complement?: string;
  };
}

interface CapptaMerchantRequest {
  external_merchant_id: string;
  document: string;
  business_name: string;
  trade_name?: string;
  mcc?: string;
  contact: {
    email: string;
    phone: string;
  };
  address: {
    street: string;
    number: string;
    city: string;
    state: string;
    zip: string;
    complement?: string;
  };
}

serve(async (request) => {
  const startTime = Date.now();
  const errorId = crypto.randomUUID();

  // Log inicial
  logger.info('Requisição recebida para registro de merchant Cappta', {
    method: request.method,
    url: request.url,
    errorId,
    timestamp: new Date().toISOString()
  });

  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Criar cliente Supabase
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    // Log detalhado dos headers
    const authHeader = request.headers.get('Authorization');
    const contentType = request.headers.get('Content-Type');
    const userAgent = request.headers.get('User-Agent');

    logger.info('Headers da requisição', {
      hasAuthHeader: !!authHeader,
      authHeaderPrefix: authHeader ? authHeader.substring(0, 20) + '...' : 'null',
      contentType,
      userAgent,
      errorId
    });

    // Autenticação com múltiplas roles
    const authResult = await authMiddleware(request, supabase, logger, ['ADMIN', 'SUPER_ADMIN']);

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

    // Validar método HTTP
    if (request.method !== 'POST') {
      return createErrorResponse('Método não permitido', 405);
    }

    // Parse do body da requisição
    const merchantData = await parseRequestBody<MerchantRegistrationRequest>(request);

    logger.info('Dados do merchant recebidos', {
      profileId: merchantData.profile_id,
      businessName: merchantData.business_name,
      document: merchantData.document,
      errorId
    });

    // Validar dados obrigatórios
    if (!merchantData.profile_id || !merchantData.document || !merchantData.business_name) {
      return createErrorResponse('Campos obrigatórios ausentes: profile_id, document, business_name', 400);
    }

    if (!merchantData.contact?.email || !merchantData.contact?.phone) {
      return createErrorResponse('Dados de contato obrigatórios: email, phone', 400);
    }

    if (!merchantData.address?.street || !merchantData.address?.city || !merchantData.address?.state) {
      return createErrorResponse('Dados de endereço obrigatórios: street, city, state', 400);
    }

    // Chamar RPC para registrar no banco
    logger.info('Chamando RPC cappta_register_merchant', { errorId });

    const { data: rpcResult, error: rpcError } = await supabase.rpc('cappta_register_merchant', {
      p_profile_id: merchantData.profile_id,
      p_merchant_data: merchantData
    });

    if (rpcError) {
      logger.error('Erro na RPC cappta_register_merchant', {
        error: rpcError.message,
        errorId
      });
      return createInternalErrorResponse('Erro ao registrar merchant no banco de dados');
    }

    if (!rpcResult.success) {
      logger.error('RPC retornou erro', {
        rpcError: rpcResult.error,
        message: rpcResult.message,
        errorId
      });
      return createErrorResponse(rpcResult.message, 400);
    }

    logger.info('Merchant registrado no banco com sucesso', {
      accountId: rpcResult.account_id,
      action: rpcResult.action,
      errorId
    });

    // Preparar dados para API Cappta
    const capptaRequest: CapptaMerchantRequest = {
      external_merchant_id: merchantData.profile_id,
      document: merchantData.document,
      business_name: merchantData.business_name,
      trade_name: merchantData.trade_name,
      mcc: merchantData.mcc || '5399', // MCC padrão para estabelecimentos diversos
      contact: merchantData.contact,
      address: merchantData.address
    };

    logger.info('Chamando API Cappta para registrar merchant', {
      url: `${CAPPTA_SIMULATOR_URL}/merchants`,
      externalMerchantId: capptaRequest.external_merchant_id,
      errorId
    });

    // Chamar API do simulador Cappta
    const capptaResponse = await fetch(`${CAPPTA_SIMULATOR_URL}/merchants`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${CAPPTA_API_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(capptaRequest)
    });

    const capptaData = await capptaResponse.json();

    logger.info('Resposta da API Cappta recebida', {
      status: capptaResponse.status,
      merchantId: capptaData.merchant_id,
      errorId
    });

    if (!capptaResponse.ok) {
      logger.error('Erro na API Cappta', {
        status: capptaResponse.status,
        error: capptaData,
        errorId
      });

      // Mesmo com erro na Cappta, mantemos o registro no banco para retry posterior
      return createErrorResponse(
        `Erro na API Cappta: ${capptaData.error || 'Erro desconhecido'}`,
        capptaResponse.status
      );
    }

    // Atualizar banco com resposta da Cappta
    logger.info('Atualizando banco com resposta da Cappta', { errorId });

    const { data: updateResult, error: updateError } = await supabase.rpc('cappta_update_merchant_response', {
      p_profile_id: merchantData.profile_id,
      p_cappta_merchant_id: capptaData.merchant_id,
      p_api_response: capptaData
    });

    if (updateError) {
      logger.error('Erro ao atualizar resposta da Cappta', {
        error: updateError.message,
        errorId
      });
      // Não falha a operação, pois o merchant foi criado na Cappta
    }

    const duration = Date.now() - startTime;

    logger.info('Merchant registrado com sucesso', {
      profileId: merchantData.profile_id,
      capptaMerchantId: capptaData.merchant_id,
      duration_ms: duration,
      errorId
    });

    // Resposta de sucesso
    return createSuccessResponse({
      profile_id: merchantData.profile_id,
      cappta_merchant_id: capptaData.merchant_id,
      account_id: rpcResult.account_id,
      status: capptaData.status,
      created_at: capptaData.created_at,
      action: rpcResult.action
    }, 'Merchant registrado com sucesso na Cappta');

  } catch (error) {
    const duration = Date.now() - startTime;

    // Error handling detalhado
    logger.critical('Erro inesperado no registro de merchant Cappta', {
      errorId,
      message: error.message,
      stack: error.stack,
      duration_ms: duration,
      errorType: error.constructor.name,
      errorCode: error.code || 'unknown',
      timestamp: new Date().toISOString()
    });

    // Detecção de erros de conectividade
    if (error.message.includes('fetch') || error.message.includes('network') || error.message.includes('timeout')) {
      logger.error('Erro de conectividade detectado', {
        errorId,
        possibleCause: 'Network connectivity or Cappta API timeout',
        suggestion: 'Check network connection and Cappta API endpoints'
      });
    }

    return createInternalErrorResponse('Ocorreu um erro inesperado ao registrar merchant.', error.message, errorId);
  }
});
