// supabase/functions/webhook_account_status/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2/dist/module/index.ts';
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.ts';
import { createLogger, LogLevel } from '../_shared/logger.ts';
import { getServiceRoleKey } from '../_shared/env.ts';

declare const Deno: any;

// Inicializa o logger para esta função
const logger = createLogger({
  name: 'WebhookAccountStatus',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

const corsHeaders = {
  'Access-Control-Allow-Origin': '*', // Permite qualquer origem
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, asaas-access-token',
  'Access-Control-Allow-Methods': 'POST, OPTIONS', // Métodos permitidos
};

interface GenericAsaasWebhookPayload {
  id: string; // ID do evento Asaas (evt_...)
  event: string; // Tipo do evento Asaas
  // Adicione outros campos comuns se souber, ou deixe genérico
  [key: string]: any; 
}

interface AsaasAccount {
  id: string;
  profile_id: string;
  webhook_auth_token: string;
}

serve(async (req: Request) => {
  const requestTimestamp = new Date();
  
  // Registra o início do processamento da requisição
  logger.info(`Requisição recebida`, {
    method: req.method,
    url: req.url,
    timestamp: requestTimestamp.toISOString()
  });

  // Handle OPTIONS request for CORS preflight
  if (req.method === 'OPTIONS') {
    logger.debug(`OPTIONS request recebida. Respondendo com headers CORS.`);
    return new Response('ok', { headers: corsHeaders });
  }

  // 1. Validar Método
  if (req.method !== 'POST') {
    logger.warn(`Método não permitido`, { method: req.method });
    return new Response(JSON.stringify({ error: 'Method Not Allowed' }), {
      status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    // Inicialização da conexão com o Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    
    // Obtém a SERVICE_ROLE_KEY do ambiente ou do arquivo .env
    logger.info(`Buscando SERVICE_ROLE_KEY do ambiente ou arquivo .env`);
    const serviceRoleKey = await getServiceRoleKey();
    
    if (!serviceRoleKey) {
      logger.error(`SERVICE_ROLE_KEY não encontrada no ambiente nem no arquivo .env`);
      return new Response(
        JSON.stringify({ 
          error: 'Configuração incompleta',
          details: 'SERVICE_ROLE_KEY não está disponível'
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    logger.info(`SERVICE_ROLE_KEY obtida com sucesso`);
    
    // Cria cliente Supabase com a chave de serviço obtida
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false }
    });
    
    // Obtém as chaves necessárias do vault usando o cliente com SERVICE_ROLE_KEY
    logger.info(`Buscando chaves adicionais do vault`);
    let vaultKeys;
    try {
      vaultKeys = await getRequiredVaultKeys(supabase);
      const { isValid, missingKeys } = validateRequiredKeys(vaultKeys);
    
      if (!isValid) {
        logger.error(`Chaves obrigatórias não encontradas no vault`, { missingKeys });
        return new Response(
          JSON.stringify({ 
            error: 'Configuração incompleta',
            details: `As seguintes chaves não foram encontradas: ${missingKeys.join(', ')}`
          }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      
      logger.info(`Chaves do vault obtidas com sucesso`);
    } catch (error) {
      logger.error(`Erro ao buscar chaves do vault`, { error: error.message });
      return new Response(
        JSON.stringify({ 
          error: 'Erro de configuração',
          details: `Erro ao acessar o vault: ${error.message}`
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Cria cliente Supabase com a SERVICE_ROLE_KEY do vault
    const supabaseAdmin = createClient(supabaseUrl, vaultKeys.SERVICE_ROLE_KEY!, {
      auth: { persistSession: false }
    });

    // 2. Validar Token de Autenticação
    const receivedToken = req.headers.get('asaas-access-token');
    logger.debug(`Headers recebidos`, { headers: Object.fromEntries(req.headers.entries()) });
    logger.info(`Token recebido`, { tokenPrefix: receivedToken ? receivedToken.substring(0,5) + '...' : 'não fornecido' });

    if (!receivedToken) {
      logger.warn(`Token de autenticação não encontrado no header asaas-access-token`);
      return new Response(JSON.stringify({ 
        error: 'Authentication token required',
        details: 'Missing asaas-access-token header'
      }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const cleanToken = receivedToken.trim();
    if (cleanToken.length < 10) { // Exemplo de validação mínima de tamanho
      logger.warn(`Formato de token inválido (muito curto)`, { tokenLength: cleanToken.length });
      return new Response(JSON.stringify({ error: 'Invalid token format' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 3. Buscar conta Asaas pelo token para obter profile_id
    logger.info(`Validando token`, { tokenPrefix: cleanToken.substring(0,5) + '...' });
    const { data: accountData, error: tokenError } = await supabaseAdmin
      .from('asaas_accounts')
      .select('id, profile_id, webhook_auth_token')
      .eq('webhook_auth_token', cleanToken)
      .single<AsaasAccount>();

    if (tokenError) {
      logger.error(`Erro ao validar token no banco de dados`, { error: tokenError.message });
      // Não revelar se o token existe ou não, apenas que é inválido
      return new Response(JSON.stringify({ error: 'Invalid or unknown token - db query failed' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (!accountData) {
      logger.warn(`Nenhuma conta encontrada para o token`, { tokenPrefix: cleanToken.substring(0,5) + '...' });
      return new Response(JSON.stringify({ error: 'Invalid or unknown token - no account found' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    logger.info(`Token validado com sucesso`, { profileId: accountData.profile_id });

    // 4. Parsear o Payload JSON
    let payload: GenericAsaasWebhookPayload;
    try {
      payload = await req.json();
      if (!payload.id || !payload.event) {
        logger.warn(`Payload inválido: faltando 'id' ou 'event'`, { payload });
        throw new Error("Missing 'id' or 'event' in webhook payload.");
      }
      logger.info(`Payload parseado com sucesso`, { eventId: payload.id, eventType: payload.event });
    } catch (e) {
      logger.error(`Falha ao analisar payload JSON ou estrutura inválida`, { error: e.message });
      return new Response(JSON.stringify({ error: 'Bad Request - Invalid JSON or malformed payload' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 5. Enfileirar o evento na tabela asaas_webhook_events
    logger.info(`Enfileirando evento`, { eventId: payload.id });
    const { data: logInsertData, error: insertError } = await supabaseAdmin
      .from('asaas_webhook_events')
      .insert({
        asaas_event_id: payload.id, // ID do evento Asaas
        event_type: payload.event,
        payload: payload, // O payload completo do webhook
        headers: Object.fromEntries(req.headers.entries()), // Cabeçalhos da requisição
        received_at: requestTimestamp.toISOString(),
        profile_id: accountData.profile_id, // Associar ao profile_id da conta Asaas
        processing_status: 'PENDING', // Marcar para processamento assíncrono
      })
      .select('id') // Selecionar o ID interno do log para referência, se necessário
      .single();

    if (insertError) {
      if (insertError.code === '23505') { // Código Postgres para 'unique_violation'
        logger.warn(`ID de evento Asaas duplicado recebido`, { eventId: payload.id });
        // Asaas espera 2xx para recebimento bem-sucedido, mesmo se duplicado e já processado.
        return new Response(JSON.stringify({ message: 'Event already received and enqueued/processed', eventId: payload.id }), {
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      } else {
        logger.critical(`Erro ao inserir evento de webhook na tabela asaas_webhook_events`, { 
          eventId: payload.id, 
          error: insertError.message, 
          details: insertError.details 
        });
        // Se não conseguimos nem enfileirar o evento, é um problema do nosso lado.
        // Asaas tentará reenviar, então um 500 é apropriado.
        return new Response(JSON.stringify({ error: 'Failed to record webhook event due to internal error' }), {
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    } else {
      logger.info(`Evento de webhook enfileirado com sucesso`, { 
        eventId: payload.id, 
        internalId: logInsertData?.id, 
        profileId: accountData.profile_id, 
        status: 'PENDING' 
      });
    }

    // 6. Retornar 200 OK para o Asaas imediatamente após enfileirar
    logger.info(`Respondendo 200 OK para o Asaas`, { eventId: payload.id });
    return new Response(JSON.stringify({ message: 'Webhook received and enqueued for processing', eventId: payload.id }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (e) {
    const errorId = crypto.randomUUID();
    logger.critical(`Exceção não tratada no receptor de webhook`, { 
      errorId, 
      message: e.message, 
      stack: e.stack 
    });
    // Este é um erro inesperado no próprio receptor.
    return new Response(JSON.stringify({ error: 'Internal server error during webhook reception', errorId }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
