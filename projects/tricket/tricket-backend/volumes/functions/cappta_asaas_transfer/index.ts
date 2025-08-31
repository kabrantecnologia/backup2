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

const logger = createLogger({ name: 'CapptaAsaasTransfer' });

// Configurações do ambiente
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
const ASAAS_API_KEY = Deno.env.get('ASAAS_API_KEY')!;
const ASAAS_BASE_URL = Deno.env.get('ASAAS_BASE_URL') || 'https://sandbox.asaas.com/api/v3';

interface TransferRequest {
  settlement_id: string;
  merchant_id: string;
  net_amount_cents: number;
  description?: string;
}

interface AsaasTransferRequest {
  value: number;
  pixAddressKey?: string;
  bankAccount?: {
    bank: string;
    accountName: string;
    ownerName: string;
    cpfCnpj: string;
    agency: string;
    account: string;
    accountDigit: string;
  };
  description: string;
  externalReference?: string;
}

/**
 * Busca dados da conta Asaas do merchant
 */
async function getMerchantAsaasAccount(supabase: any, merchantId: string): Promise<any> {
  const { data, error } = await supabase
    .from('cappta_accounts')
    .select(`
      profile_id,
      iam_profiles!inner(
        asaas_accounts!inner(
          asaas_customer_id,
          pix_key,
          bank_account_data
        )
      )
    `)
    .eq('merchant_id', merchantId)
    .single();

  if (error) {
    logger.error('Erro ao buscar conta Asaas do merchant', { 
      error: error.message, 
      merchantId 
    });
    throw new Error('Merchant não encontrado ou sem conta Asaas');
  }

  return data;
}

/**
 * Cria transferência via API Asaas
 */
async function createAsaasTransfer(transferData: AsaasTransferRequest): Promise<any> {
  logger.info('Criando transferência no Asaas', {
    value: transferData.value,
    description: transferData.description,
    hasPixKey: !!transferData.pixAddressKey,
    hasBankAccount: !!transferData.bankAccount
  });

  const response = await fetch(`${ASAAS_BASE_URL}/transfers`, {
    method: 'POST',
    headers: {
      'access_token': ASAAS_API_KEY,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(transferData)
  });

  const responseData = await response.json();

  if (!response.ok) {
    logger.error('Erro na API Asaas', {
      status: response.status,
      error: responseData
    });
    throw new Error(`Erro Asaas: ${responseData.errors?.[0]?.description || 'Erro desconhecido'}`);
  }

  return responseData;
}

/**
 * Atualiza transações com ID da transferência
 */
async function updateTransactionsWithTransfer(
  supabase: any, 
  merchantId: string, 
  settlementId: string, 
  transferId: string
): Promise<void> {
  const { error } = await supabase
    .from('cappta_transactions')
    .update({ 
      asaas_transfer_id: transferId,
      updated_at: new Date().toISOString()
    })
    .eq('cappta_account_id', merchantId)
    .eq('settlement_id', settlementId);

  if (error) {
    logger.error('Erro ao atualizar transações com transfer_id', {
      error: error.message,
      transferId,
      settlementId
    });
    throw error;
  }
}

serve(async (request) => {
  const startTime = Date.now();
  const errorId = crypto.randomUUID();

  logger.info('Requisição recebida para transferência Asaas', {
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

    // Autenticação
    const authResult = await authMiddleware(request, supabase, logger, ['ADMIN', 'SUPER_ADMIN']);

    if (!authResult.success || !authResult.user) {
      logger.error('Falha na autenticação', { errorId });
      return authResult.response || createInternalErrorResponse('Falha na autenticação');
    }

    logger.info('Usuário autenticado', {
      userId: authResult.user.id,
      errorId
    });

    // Validar método HTTP
    if (request.method !== 'POST') {
      return createErrorResponse('Método não permitido', 405);
    }

    // Parse do body
    const transferRequest = await parseRequestBody<TransferRequest>(request);

    logger.info('Dados da transferência recebidos', {
      settlementId: transferRequest.settlement_id,
      merchantId: transferRequest.merchant_id,
      netAmountCents: transferRequest.net_amount_cents,
      errorId
    });

    // Validar dados obrigatórios
    if (!transferRequest.settlement_id || !transferRequest.merchant_id || !transferRequest.net_amount_cents) {
      return createErrorResponse('Campos obrigatórios: settlement_id, merchant_id, net_amount_cents', 400);
    }

    if (transferRequest.net_amount_cents <= 0) {
      return createErrorResponse('Valor deve ser maior que zero', 400);
    }

    // Converter centavos para reais
    const transferValueReais = transferRequest.net_amount_cents / 100;

    // Buscar dados da conta Asaas do merchant
    const merchantData = await getMerchantAsaasAccount(supabase, transferRequest.merchant_id);
    const asaasAccount = merchantData.iam_profiles.asaas_accounts;

    logger.info('Conta Asaas encontrada', {
      customerId: asaasAccount.asaas_customer_id,
      hasPixKey: !!asaasAccount.pix_key,
      hasBankAccount: !!asaasAccount.bank_account_data,
      errorId
    });

    // Preparar dados da transferência
    const asaasTransferData: AsaasTransferRequest = {
      value: transferValueReais,
      description: transferRequest.description || `Liquidação Cappta - ${transferRequest.settlement_id}`,
      externalReference: transferRequest.settlement_id
    };

    // Priorizar PIX se disponível, senão usar conta bancária
    if (asaasAccount.pix_key) {
      asaasTransferData.pixAddressKey = asaasAccount.pix_key;
      logger.info('Transferência via PIX', { pixKey: asaasAccount.pix_key, errorId });
    } else if (asaasAccount.bank_account_data) {
      asaasTransferData.bankAccount = asaasAccount.bank_account_data;
      logger.info('Transferência via TED', { bank: asaasAccount.bank_account_data.bank, errorId });
    } else {
      return createErrorResponse('Merchant não possui PIX ou conta bancária cadastrada', 400);
    }

    // Criar transferência no Asaas
    const asaasTransfer = await createAsaasTransfer(asaasTransferData);

    logger.info('Transferência criada no Asaas', {
      transferId: asaasTransfer.id,
      status: asaasTransfer.status,
      value: asaasTransfer.value,
      errorId
    });

    // Atualizar transações com ID da transferência
    await updateTransactionsWithTransfer(
      supabase,
      transferRequest.merchant_id,
      transferRequest.settlement_id,
      asaasTransfer.id
    );

    // Registrar log da operação
    await supabase
      .from('cappta_api_responses')
      .insert({
        endpoint: '/transfers',
        http_method: 'POST',
        request_data: asaasTransferData,
        response_status: 200,
        response_data: asaasTransfer,
        created_at: new Date().toISOString()
      });

    const duration = Date.now() - startTime;

    logger.info('Transferência processada com sucesso', {
      transferId: asaasTransfer.id,
      settlementId: transferRequest.settlement_id,
      merchantId: transferRequest.merchant_id,
      value: transferValueReais,
      duration_ms: duration,
      errorId
    });

    return createSuccessResponse({
      transfer_id: asaasTransfer.id,
      settlement_id: transferRequest.settlement_id,
      merchant_id: transferRequest.merchant_id,
      value_reais: transferValueReais,
      status: asaasTransfer.status,
      transfer_method: asaasAccount.pix_key ? 'PIX' : 'TED',
      created_at: asaasTransfer.dateCreated,
      estimated_date: asaasTransfer.estimatedDate
    }, 'Transferência criada com sucesso');

  } catch (error) {
    const duration = Date.now() - startTime;

    logger.critical('Erro inesperado na transferência Asaas', {
      errorId,
      message: error.message,
      stack: error.stack,
      duration_ms: duration,
      errorType: error.constructor.name,
      timestamp: new Date().toISOString()
    });

    // Detectar tipos específicos de erro
    if (error.message.includes('Merchant não encontrado')) {
      return createErrorResponse('Merchant não encontrado ou sem conta Asaas', 404);
    }

    if (error.message.includes('Erro Asaas:')) {
      return createErrorResponse(error.message, 400);
    }

    return createInternalErrorResponse('Erro inesperado ao processar transferência', error.message, errorId);
  }
});
