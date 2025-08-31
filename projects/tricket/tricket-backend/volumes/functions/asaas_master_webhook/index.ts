// supabase/functions/asaas_master_webhook/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

// Funções auxiliares de resposta (local implementation)
function createSuccessResponse(data: any = null, message = 'Success') {
  return new Response(
    JSON.stringify({ success: true, message, data }),
    {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    }
  );
}

function createBadRequestResponse(message: string, details?: any) {
  return new Response(
    JSON.stringify({ success: false, error: message, details }),
    {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    }
  );
}

function createInternalErrorResponse(message: string, details?: any) {
  return new Response(
    JSON.stringify({ success: false, error: message, details }),
    {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    }
  );
}

type SupabaseClient = ReturnType<typeof createClient>;

// Interfaces para tipos de dados
interface AsaasMasterWebhookPayload {
  event: string;
  payment?: {
    id: string;
    customer: string;
    value: number;
    netValue: number;
    originalValue?: number;
    interestValue?: number;
    discountValue?: number;
    status: string;
    billingType: string;
    invoiceUrl?: string;
    bankSlipUrl?: string;
    dueDate: string;
    originalDueDate?: string;
    paymentDate?: string;
    clientPaymentDate?: string;
    installment?: string;
    installmentCount?: number;
    creditCard?: {
      creditCardNumber: string;
      creditCardBrand: string;
      creditCardToken: string;
    };
    pixTransaction?: string;
    externalReference?: string;
    confirmedDate?: string;
  };
  transfer?: {
    id: string;
    value: number;
    netValue: number;
    transferFee: number;
    status: string;
    transferType: string;
    dateCreated: string;
    scheduledDate?: string;
    effectiveDate?: string;
    transactionReceiptUrl?: string;
    description?: string;
    externalReference?: string;
    operationType?: string;
    bankAccount?: {
      bank: {
        ispb: string;
        code: string;
        name: string;
      };
      accountName: string;
      ownerName: string;
      cpfCnpj: string;
      agency: string;
      account: string;
      accountDigit: string;
    };
  };
  subscription?: {
    id: string;
    customer: string;
    value: number;
    cycle: string;
    description: string;
    billingType: string;
    status: string;
    nextDueDate?: string;
    endDate?: string;
  };
  customer?: {
    id: string;
    name: string;
    email: string;
    cpfCnpj: string;
    phone?: string;
    mobilePhone?: string;
    address?: {
      address: string;
      complement?: string;
      province: string;
      postalCode: string;
      city: string;
      state: string;
    };
  };
  invoice?: {
    id: string;
    customer: string;
    value: number;
    status: string;
    description: string;
    invoiceUrl: string;
    pdfUrl: string;
  };
  financialTransaction?: {
    id: string;
    value: number;
    balance: number;
    type: string;
    description: string;
    date: string;
  };
}

interface MasterEventRecord {
  id: string;
  event_type: string;
  event_data: any;
  source: 'asaas_master';
  processed: boolean;
  processed_at?: string;
  processing_error?: string;
  created_at: string;
  updated_at: string;
}

interface EventProcessingResult {
  success: boolean;
  affected_accounts?: string[];
  error?: string;
}

/**
 * Valida a assinatura do webhook Asaas
 */
function validateAsaasSignature(payload: string, signature: string, secret: string): boolean {
  const crypto = globalThis.crypto;
  const encoder = new TextEncoder();
  
  // Implementar validação HMAC-SHA256
  // return signature === expectedSignature;
  
  // Por enquanto, retornar true para desenvolvimento
  return true;
}

/**
 * Mapeia eventos da conta master para ações específicas
 */
function mapMasterEventToAction(eventType: string, eventData: any): {
  action: string;
  affectedAccountsQuery?: any;
  updatePayload?: any;
} {
  switch (eventType) {
    case 'PAYMENT_RECEIVED':
      return {
        action: 'UPDATE_SUBACCOUNTS_BALANCE',
        affectedAccountsQuery: {
          table: 'asaas_accounts',
          conditions: { status: 'ACTIVE' }
        },
        updatePayload: {
          last_balance_update: new Date().toISOString()
        }
      };

    case 'TRANSFER_CREATED':
      return {
        action: 'LOG_MASTER_TRANSFER',
        affectedAccountsQuery: null,
        updatePayload: {
          transfer_id: eventData.transfer?.id,
          transfer_value: eventData.transfer?.value,
          transfer_status: eventData.transfer?.status,
          transfer_type: eventData.transfer?.type
        }
      };

    case 'TRANSFER_COMPLETED':
      return {
        action: 'LOG_MASTER_TRANSFER',
        affectedAccountsQuery: null,
        updatePayload: {
          transfer_id: eventData.transfer?.id,
          transfer_value: eventData.transfer?.value,
          transfer_status: eventData.transfer?.status
        }
      };

    case 'SUBSCRIPTION_CREATED':
      return {
        action: 'PROPAGATE_SUBSCRIPTION',
        affectedAccountsQuery: {
          table: 'asaas_accounts',
          conditions: { customer_id: eventData.customer?.id }
        },
        updatePayload: {
          subscription_id: eventData.subscription?.id,
          subscription_status: eventData.subscription?.status
        }
      };

    case 'CUSTOMER_CREATED':
      return {
        action: 'SETUP_SUBACCOUNT',
        affectedAccountsQuery: null,
        updatePayload: {
          customer_id: eventData.customer?.id,
          setup_date: new Date().toISOString()
        }
      };

    default:
      return {
        action: 'LOG_EVENT',
        affectedAccountsQuery: null,
        updatePayload: null
      };
  }
}

/**
 * Processa o evento da conta master do Asaas
 */
async function processMasterEvent(
  supabase: SupabaseClient,
  eventData: AsaasMasterWebhookPayload,
  logger: any
): Promise<EventProcessingResult> {
  const eventId = crypto.randomUUID();
  const eventType = eventData.event;
  
  logger.info('Processando evento da conta master Asaas', {
    eventId,
    eventType,
    hasPayment: !!eventData.payment,
    hasTransfer: !!eventData.transfer,
    hasCustomer: !!eventData.customer
  });

  try {
    // 1. Registrar o evento no banco
    const { error: insertError } = await supabase
      .from('master_webhook_events')
      .insert({
        id: eventId,
        event_type: eventType,
        event_data: eventData,
        source: 'asaas_master',
        processed: false,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      });

    if (insertError) {
      logger.error('Erro ao registrar evento master', {
        eventId,
        error: insertError.message
      });
      return { success: false, error: insertError.message };
    }

    // 2. Mapear evento para ação
    const actionMapping = mapMasterEventToAction(eventType, eventData);
    
    logger.info('Mapeamento de evento para ação', {
      eventId,
      action: actionMapping.action,
      affectedQuery: actionMapping.affectedAccountsQuery
    });

    // 3. Executar ação específica
    let affectedAccounts: string[] = [];
    
    switch (actionMapping.action) {
      case 'LOG_MASTER_TRANSFER':
        await logMasterTransfer(supabase, eventData, logger);
        break;
        
      case 'PROPAGATE_SUBSCRIPTION':
        affectedAccounts = await propagateSubscription(supabase, eventData, logger);
        break;
        
      case 'SETUP_SUBACCOUNT':
        affectedAccounts = await setupSubaccount(supabase, eventData, logger);
        break;
        
      default:
        logger.info('Ação não implementada', { action: actionMapping.action });
    }

    // 4. Marcar evento como processado
    const { error: updateError } = await supabase
      .from('master_webhook_events')
      .update({
        processed: true,
        processed_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', eventId);

    if (updateError) {
      logger.error('Erro ao marcar evento como processado', {
        eventId,
        error: updateError.message
      });
    }

    logger.info('Evento master processado com sucesso', {
      eventId,
      action: actionMapping.action,
      affectedAccountsCount: affectedAccounts.length
    });

    return {
      success: true,
      affected_accounts: affectedAccounts
    };

  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Erro desconhecido';
    logger.error('Erro ao processar evento master', {
      eventId,
      error: errorMessage
    });
    return { success: false, error: errorMessage };
  }
}



/**
 * Registra transferência da conta master
 */
async function logMasterTransfer(
  supabase: SupabaseClient,
  eventData: AsaasMasterWebhookPayload,
  logger: any
): Promise<void> {
  const transfer = eventData.transfer;
  if (!transfer) return;

  const { error } = await supabase
    .from('master_financial_transactions')
    .insert({
      id: crypto.randomUUID(),
      transfer_id: transfer.id,
      value: transfer.value,
      net_value: transfer.netValue,
      transfer_fee: transfer.transferFee,
      status: transfer.status,
      transfer_type: transfer.transferType,
      transfer_date: transfer.dateCreated,
      scheduled_date: transfer.scheduledDate,
      effective_date: transfer.effectiveDate,
      description: transfer.description || null,
      external_reference: transfer.externalReference || null,
      bank_account_name: transfer.bankAccount?.accountName,
      bank_account_cpf_cnpj: transfer.bankAccount?.cpfCnpj,
      bank_code: transfer.bankAccount?.bank?.code,
      bank_name: transfer.bankAccount?.bank?.name,
      agency: transfer.bankAccount?.agency,
      account: transfer.bankAccount?.account,
      account_digit: transfer.bankAccount?.accountDigit,
      created_at: new Date().toISOString()
    });

  if (error) {
    logger.error('Erro ao registrar transferência master', { error: error.message });
  } else {
    logger.info('Transferência master registrada', {
      transferId: eventData.transfer?.id,
      value: eventData.transfer?.value
    });
  }
}

/**
 * Propaga assinatura para subcontas
 */
async function propagateSubscription(
  supabase: SupabaseClient,
  eventData: AsaasMasterWebhookPayload,
  logger: any
): Promise<string[]> {
  const { data: accounts, error } = await supabase
    .from('asaas_accounts')
    .select('id, customer_id')
    .eq('customer_id', eventData.customer?.id);

  if (error) {
    logger.error('Erro ao buscar subcontas do cliente', { error: error.message });
    return [];
  }

  const affectedAccounts: string[] = [];
  
  for (const account of accounts || []) {
    const { error: updateError } = await supabase
      .from('asaas_accounts')
      .update({
        subscription_id: eventData.subscription?.id,
        subscription_status: eventData.subscription?.status,
        subscription_cycle: eventData.subscription?.cycle,
        subscription_value: eventData.subscription?.value,
        updated_at: new Date().toISOString()
      })
      .eq('id', account.id);

    if (!updateError) {
      affectedAccounts.push(account.id);
      logger.info('Assinatura propagada', {
        accountId: account.id,
        subscriptionId: eventData.subscription?.id
      });
    }
  }

  return affectedAccounts;
}

/**
 * Configura nova subconta
 */
async function setupSubaccount(
  supabase: SupabaseClient,
  eventData: AsaasMasterWebhookPayload,
  logger: any
): Promise<string[]> {
  const customer = eventData.customer;
  if (!customer) return [];

  // Verificar se já existe subconta para este cliente
  const { data: existingAccount, error: checkError } = await supabase
    .from('asaas_accounts')
    .select('id')
    .eq('customer_id', customer.id)
    .single();

  if (existingAccount) {
    logger.info('Subconta já existe', { customerId: customer.id });
    return [existingAccount.id];
  }

  // Criar nova subconta
  const { data: newAccount, error: insertError } = await supabase
    .from('asaas_accounts')
    .insert({
      id: crypto.randomUUID(),
      customer_id: customer.id,
      name: customer.name,
      email: customer.email,
      cpf_cnpj: customer.cpfCnpj,
      phone: customer.phone || customer.mobilePhone,
      status: 'PENDING_SETUP',
      balance: 0,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    })
    .select()
    .single();

  if (insertError) {
    logger.error('Erro ao criar subconta', { error: insertError.message });
    return [];
  }

  logger.info('Nova subconta criada', {
    accountId: newAccount.id,
    customerId: customer.id,
    customerName: customer.name
  });

  return [newAccount.id];
}

/**
 * Handler principal da função
 */
async function handleRequest(request: Request): Promise<Response> {
  const startTime = Date.now();
  const config = {
    supabaseUrl: Deno.env.get('SUPABASE_URL') || '',
    supabaseServiceKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '',
    webhookSecret: Deno.env.get('ASAAS_WEBHOOK_SECRET') || ''
  };

  // Logger simples
  const logger = {
    info: (message: string, data?: any) => {
      console.log(`[INFO] ${new Date().toISOString()} - ${message}`, data ? JSON.stringify(data) : '');
    },
    error: (message: string, error?: any) => {
      console.error(`[ERROR] ${new Date().toISOString()} - ${message}`, error);
    },
    warn: (message: string, data?: any) => {
      console.warn(`[WARN] ${new Date().toISOString()} - ${message}`, data ? JSON.stringify(data) : '');
    }
  };
  
  try {
    // Validação de configuração
    if (!config.supabaseUrl || !config.supabaseServiceKey) {
      logger.error('Invalid configuration: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY required');
      return createInternalErrorResponse(
        'Invalid configuration',
        'SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required'
      );
    }

    // Validar método HTTP
    if (request.method !== 'POST') {
      return createBadRequestResponse('Método não permitido');
    }

    // Parse do payload
    let webhookData: AsaasMasterWebhookPayload;
    try {
      webhookData = await request.json();
    } catch (error) {
      logger.error('JSON inválido no payload', { error: error.message });
      return createBadRequestResponse('JSON inválido no payload');
    }

    // Validar estrutura básica
    if (!webhookData.event) {
      logger.error('Campo "event" ausente no payload', { payload: webhookData });
      return createBadRequestResponse('Campo "event" é obrigatório');
    }

    // Inicializar Supabase
    const supabase = createClient(
      config.supabaseUrl,
      config.supabaseServiceKey
    );

    // Processar evento
    const result = await processMasterEvent(supabase, webhookData, logger);

    const processingTime = Date.now() - startTime;
    
    if (result.success) {
      logger.info('Webhook master processado com sucesso', {
        event: webhookData.event,
        affected_accounts: result.affected_accounts?.length || 0,
        processingTimeMs: processingTime
      });

      return createSuccessResponse({
        message: 'Webhook processado com sucesso',
        event: webhookData.event,
        affected_accounts: result.affected_accounts || [],
        processingTimeMs: processingTime
      });
    } else {
      logger.error('Erro ao processar webhook master', {
        event: webhookData.event,
        error: result.error,
        affected_accounts: result.affected_accounts?.length || 0,
        processingTimeMs: processingTime
      });

      return createInternalErrorResponse(
        'Erro ao processar webhook',
        result.error
      );
    }

  } catch (error) {
    const processingTime = Date.now() - startTime;
    logger.error('Erro no handler principal', { 
      error: error instanceof Error ? error.message : String(error), 
      processingTimeMs: processingTime 
    });
    return createInternalErrorResponse('Erro interno do servidor', error instanceof Error ? error.message : 'Erro desconhecido');
  }
}

// Servidor HTTP
serve(handleRequest);
