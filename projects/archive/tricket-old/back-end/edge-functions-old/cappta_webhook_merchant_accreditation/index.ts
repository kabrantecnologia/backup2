import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { createLogger, LogLevel } from '../_shared/logger.js'
import { getServiceRoleKey } from '../_shared/env.js'

// Inicializa o logger
const logger = createLogger({
  name: 'CapptaWebhookMerchantAccreditation',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

serve(async (req) => {
  logger.info('Requisição de webhook de credenciamento recebida', { 
    method: req.method, 
    url: req.url 
  });
  
  try {
    // Configuração inicial do cliente Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const serviceRoleKey = await getServiceRoleKey();
    
    if (!serviceRoleKey) {
      logger.error('SERVICE_ROLE_KEY não encontrada');
      return new Response(
        JSON.stringify({ error: 'Configuração incompleta' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Cria cliente Supabase com a chave de serviço
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false }
    });
    
    // Verificar token de autenticação
    const authToken = req.headers.get('X-Webhook-Token');
    if (!authToken) {
      logger.warn('Token de autenticação não fornecido');
      return new Response(
        JSON.stringify({ error: 'Token de autenticação não fornecido' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Verificar o perfil associado ao token
    const { data: webhookConfig, error: webhookError } = await supabase
      .from('cappta_webhooks')
      .select('profile_id')
      .eq('webhook_token', authToken)
      .eq('webhook_type', 'MERCHANT_ACCREDITATION')
      .eq('is_active', true)
      .single();
      
    if (webhookError || !webhookConfig) {
      logger.warn('Token de webhook inválido ou webhook inativo', { error: webhookError?.message });
      return new Response(
        JSON.stringify({ error: 'Token de webhook inválido ou webhook inativo' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Processar o payload do webhook
    const rawBody = await req.text();
    
    try {
      // Processar JSON
      const payload = rawBody ? JSON.parse(rawBody) : {};
      logger.info('Payload do webhook recebido', { 
        payload: payload,
        contentType: req.headers.get('content-type')
      });
      
      // Salvar o evento no banco de dados para processamento assíncrono
      const { data: insertedEvent, error: insertError } = await supabase
        .from('cappta_webhook_events')
        .insert({
          profile_id: webhookConfig.profile_id,
          event_type: 'MERCHANT_ACCREDITATION',
          event_id: payload.id || null,
          payload: payload,
          processing_status: 'PENDING'
        })
        .select()
        .single();
        
      if (insertError) {
        logger.error('Erro ao salvar evento de webhook', { error: insertError.message });
        return new Response(
          JSON.stringify({ error: 'Erro interno ao processar webhook' }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      logger.info('Evento de webhook salvo com sucesso', { eventId: insertedEvent.id });
      
      return new Response(
        JSON.stringify({ success: true, message: 'Webhook recebido com sucesso' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    
    } catch (parseError) {
      logger.error('Erro ao processar payload JSON', { 
        error: parseError.message,
        rawBody: rawBody.substring(0, 500) // Limita para não logar payloads muito grandes
      });
      
      return new Response(
        JSON.stringify({ error: 'Formato de payload inválido', details: parseError.message }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
  } catch (error) {
    logger.error('Erro ao processar webhook', { 
      error: error.message, 
      stack: error.stack 
    });
    
    return new Response(
      JSON.stringify({ error: 'Erro interno', details: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
