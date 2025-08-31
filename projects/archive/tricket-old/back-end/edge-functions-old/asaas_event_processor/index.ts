// supabase/functions/webhook_event_processor/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.js';
import { getServiceRoleKey } from '../_shared/env.js';

declare const Deno: any;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*', 
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS', // Embora seja agendado, permitir POST para testes manuais
};

interface AsaasWebhookEvent {
  id: string; // UUID interno do evento
  asaas_event_id: string;
  event_type: string;
  payload: any; 
  profile_id: string;
  received_at: string;
  // Outros campos como headers, processing_status, etc., podem ser adicionados se necessário aqui
}

interface AsaasAccountUpdatePayload {
  status_bank?: string;
  status_commercial?: string;
  status_document?: string;
  status_general?: string;
  status_reason?: string | null;
  last_webhook_event?: string;
  last_webhook_received_at?: string;
  // Adicione outros campos que podem ser atualizados conforme necessário
}

const EVENT_BATCH_SIZE = 10; // Quantos eventos processar por execução

async function processEvent(supabaseAdmin: SupabaseClient, event: AsaasWebhookEvent, logPrefix: string): Promise<{ success: boolean; error?: string }> {
  console.log(`${logPrefix} Processing event ID: ${event.id}, Asaas Event ID: ${event.asaas_event_id}, Type: ${event.event_type}`);
  
  const eventTimestampSource = event.payload?.eventDate || 
                             event.payload?.account?.eventDate || 
                             event.received_at; 

  const updatePayloadForAsaasAccounts: AsaasAccountUpdatePayload = {
    last_webhook_event: event.event_type,
    last_webhook_received_at: new Date(eventTimestampSource).toISOString(), 
  };
  let statusValue: string | null = null;

  // Mapeamento de eventos Asaas para status internos
  const asaasEvent = event.event_type;

  if (asaasEvent.endsWith('_AWAITING_APPROVAL')) statusValue = 'AWAITING_APPROVAL';
  else if (asaasEvent.endsWith('_PENDING')) statusValue = 'PENDING';
  else if (asaasEvent.endsWith('_APPROVED')) statusValue = 'APPROVED';
  else if (asaasEvent.endsWith('_REJECTED')) statusValue = 'REJECTED';
  // Adicionar outros mapeamentos conforme necessário (ex: _CREATED, _UPDATED, _DONE)
  // ACCOUNT_STATUS_BANK_ACCOUNT_INFO_CREATED -> pode ser PENDING ou AWAITING_APPROVAL dependendo do fluxo
  // ACCOUNT_STATUS_DOCUMENT_UPLOADED -> pode ser PENDING ou AWAITING_APPROVAL

  if (statusValue) {
    if (asaasEvent.startsWith('ACCOUNT_STATUS_BANK_ACCOUNT_INFO_')) {
      updatePayloadForAsaasAccounts.status_bank = statusValue;
    } else if (asaasEvent.startsWith('ACCOUNT_STATUS_COMMERCIAL_INFO_')) {
      updatePayloadForAsaasAccounts.status_commercial = statusValue;
    } else if (asaasEvent.startsWith('ACCOUNT_STATUS_DOCUMENT_')) {
      updatePayloadForAsaasAccounts.status_document = statusValue;
    } else if (asaasEvent.startsWith('ACCOUNT_STATUS_GENERAL_APPROVAL_')) {
      updatePayloadForAsaasAccounts.status_general = statusValue;
    }
    // Adicionar mais categorias de status se houver (ex: status_address, status_owner, etc.)
  }

  if (statusValue === 'REJECTED') {
    // Tentar extrair o motivo da rejeição do payload
    // A estrutura exata do payload.errors ou payload.refusalReason pode variar.
    const reason = event.payload?.account?.refusalReason || 
                   event.payload?.bankAccount?.refusalReason || 
                   event.payload?.description || 
                   (Array.isArray(event.payload?.errors) && event.payload.errors[0]?.description) ||
                   'No specific reason provided in webhook payload.';
    updatePayloadForAsaasAccounts.status_reason = String(reason).substring(0, 255); 
  } else if (statusValue && statusValue !== 'REJECTED') {
    // Limpar o status_reason se o novo status não for REJECTED
    updatePayloadForAsaasAccounts.status_reason = null;
  }

  let processingStatusUpdate: 'PROCESSED' | 'ERROR_PROCESSING' = 'PROCESSED';
  let processingErrorDetails: string | null = null;

  try {
    // Atualizar asaas_accounts se houver alguma alteração de status mapeada
    if (Object.keys(updatePayloadForAsaasAccounts).length > 2) { // Mais do que apenas last_event_*
      console.log(`${logPrefix} Updating asaas_accounts for profile_id: ${event.profile_id} with payload:`, updatePayloadForAsaasAccounts);
      const { error: updateAccountError } = await supabaseAdmin
        .from('asaas_accounts')
        .update(updatePayloadForAsaasAccounts)
        .eq('profile_id', event.profile_id);

      if (updateAccountError) {
        console.error(`${logPrefix} Error updating asaas_accounts for profile_id ${event.profile_id}, event ID ${event.id}:`, updateAccountError);
        throw new Error(`Failed to update asaas_accounts: ${updateAccountError.message}`);
      }
      console.log(`${logPrefix} Successfully updated asaas_accounts for profile_id: ${event.profile_id}`);
    } else {
      console.log(`${logPrefix} No specific status update mapped for event type: ${asaasEvent}. Only updating timestamps if applicable, or marking as processed.`);
      // Mesmo que não haja um status específico para atualizar, o evento foi 'visto'.
      // Se last_webhook_event e last_webhook_received_at são os únicos campos, ainda assim atualiza.
      if (updatePayloadForAsaasAccounts.last_webhook_event && updatePayloadForAsaasAccounts.last_webhook_received_at){
         const { error: updateTimeError } = await supabaseAdmin
          .from('asaas_accounts')
          .update({
            last_webhook_event: updatePayloadForAsaasAccounts.last_webhook_event,
            last_webhook_received_at: updatePayloadForAsaasAccounts.last_webhook_received_at
          })
          .eq('profile_id', event.profile_id);
        if (updateTimeError) {
           console.warn(`${logPrefix} Failed to update timestamps on asaas_accounts for profile_id ${event.profile_id}: ${updateTimeError.message}`);
        }
      }
    }
  } catch (error) {
    console.error(`${logPrefix} Error during event processing logic for event ID ${event.id}:`, error);
    processingStatusUpdate = 'ERROR_PROCESSING';
    processingErrorDetails = error.message;
    // Não relançar para permitir a atualização do status do evento na tabela de logs
  }

  // Atualizar o status do evento na tabela asaas_webhook_events
  console.log(`${logPrefix} Updating event ${event.id} to status: ${processingStatusUpdate}`);
  const { error: updateEventLogError } = await supabaseAdmin
    .from('asaas_webhook_events')
    .update({
      processing_status: processingStatusUpdate,
      processed_at: new Date().toISOString(),
      processing_error_details: processingErrorDetails,
    })
    .eq('id', event.id);

  if (updateEventLogError) {
    console.error(`${logPrefix} CRITICAL: Failed to update asaas_webhook_events for event ID ${event.id}:`, updateEventLogError);
    // Este é um erro grave, pois pode levar ao reprocessamento do evento.
    // Considerar uma estratégia de notificação ou retry aqui.
    return { success: false, error: `Failed to update event log: ${updateEventLogError.message}` };
  }

  console.log(`${logPrefix} Event ${event.id} processing complete. Status: ${processingStatusUpdate}`);
  return { success: processingStatusUpdate === 'PROCESSED', error: processingErrorDetails ?? undefined };
}

serve(async (req: Request) => {
  const runTimestamp = new Date();
  const logPrefix = `[EventProcessor-${runTimestamp.toISOString()}]`;

  if (req.method === 'OPTIONS') {
    console.log(`${logPrefix} OPTIONS request received.`);
    return new Response('ok', { headers: corsHeaders });
  }

  console.log(`${logPrefix} Event processor function invoked.`);

  try {
    // Inicialização da conexão com o Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    
    // Obtém a SERVICE_ROLE_KEY do ambiente ou arquivo .env
    console.log(`${logPrefix} Buscando SERVICE_ROLE_KEY do ambiente ou arquivo .env`);
    const serviceRoleKey = await getServiceRoleKey();
    console.log(`${logPrefix} SERVICE_ROLE_KEY obtida com sucesso`);
    
    // Cria cliente Supabase temporário para buscar as chaves
    const tempSupabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false }
    });
    console.log(`${logPrefix} Buscando chaves adicionais do vault`);
    
    // Obtém todas as chaves necessárias do vault
    const vaultKeys = await getRequiredVaultKeys(tempSupabase);
    const { isValid, missingKeys } = validateRequiredKeys(vaultKeys);
    
    if (!isValid) {
      console.error(`${logPrefix} Chaves obrigatórias não encontradas no vault:`, missingKeys.join(', '));
      return new Response(
        JSON.stringify({ 
          error: 'Configuração incompleta',
          details: `As seguintes chaves não foram encontradas: ${missingKeys.join(', ')}`
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Cria cliente Supabase com a SERVICE_ROLE_KEY do vault
    const supabaseAdmin = createClient(supabaseUrl, vaultKeys.SERVICE_ROLE_KEY!, {
      auth: { persistSession: false }
    });

    console.log(`${logPrefix} Fetching up to ${EVENT_BATCH_SIZE} pending events.`);
    const { data: events, error: fetchError } = await supabaseAdmin
      .from('asaas_webhook_events')
      .select('*') // Selecionar todos os campos necessários para processEvent
      .eq('processing_status', 'PENDING')
      .order('received_at', { ascending: true }) // Processar os mais antigos primeiro
      .limit(EVENT_BATCH_SIZE);

    if (fetchError) {
      console.error(`${logPrefix} Error fetching pending events:`, fetchError);
      return new Response(JSON.stringify({ error: 'Failed to fetch events' }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!events || events.length === 0) {
      console.log(`${logPrefix} No pending events to process.`);
      return new Response(JSON.stringify({ message: 'No pending events' }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    console.log(`${logPrefix} Found ${events.length} pending events to process.`);
    let processedCount = 0;
    let successCount = 0;
    let errorCount = 0;
    const results = [];

    // Processar cada evento sequencialmente
    for (const event of events) {
      try {
        const result = await processEvent(supabaseAdmin, event, logPrefix);
        processedCount++;
        if (result.success) {
          successCount++;
        } else {
          errorCount++;
        }
        results.push({
          event_id: event.id,
          asaas_event_id: event.asaas_event_id,
          success: result.success,
          error: result.error
        });
      } catch (error) {
        console.error(`${logPrefix} Unhandled error processing event ${event.id}:`, error);
        errorCount++;
        results.push({
          event_id: event.id,
          asaas_event_id: event.asaas_event_id,
          success: false,
          error: error.message
        });
      }
    }

    console.log(`${logPrefix} Processing complete. Total: ${processedCount}, Success: ${successCount}, Errors: ${errorCount}`);
    return new Response(JSON.stringify({
      message: `Processing complete. Total: ${processedCount}, Success: ${successCount}, Errors: ${errorCount}`,
      results
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error(`${logPrefix} Unhandled exception in event processor:`, error);
    return new Response(JSON.stringify({ error: 'Internal server error during event processing', details: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
