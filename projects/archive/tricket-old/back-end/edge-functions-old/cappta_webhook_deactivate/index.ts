import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.js'
import { createLogger, LogLevel } from '../_shared/logger.js'
import { getServiceRoleKey } from '../_shared/env.js'

// Inicializa o logger
const logger = createLogger({
  name: 'CapptaWebhookDeactivate',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

serve(async (req) => {
  logger.info('Requisição de inativação de webhook recebida', { 
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
    
    // Obter as chaves necessárias do vault
    try {
      const vaultKeys = await getRequiredVaultKeys(supabase, [
        'CAPPTA_API_KEY', 
        'CAPPTA_API_URL'
      ]);
      
      const { isValid, missingKeys } = validateRequiredKeys(vaultKeys);
      
      if (!isValid) {
        logger.error('Algumas chaves obrigatórias não encontradas no vault', { missingKeys });
        return new Response(
          JSON.stringify({ 
            error: 'Configuração incompleta',
            details: `As seguintes chaves não foram encontradas: ${missingKeys.join(', ')}`
          }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        );
      }
    } catch (error) {
      logger.error('Erro ao buscar chaves do vault', { error: error.message });
      return new Response(
        JSON.stringify({ error: 'Erro de configuração', details: `Erro ao acessar o vault: ${error.message}` }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Verificação de autenticação e permissões
    const authHeader = req.headers.get('Authorization');
    const token = authHeader?.split(' ')[1];
    
    if (!token) {
      logger.warn('Token de autenticação não fornecido');
      return new Response(
        JSON.stringify({ error: 'Token de autenticação não fornecido' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Verificar se o usuário é ADMIN ou SUPER_ADMIN
    const { data: { user }, error: userError } = await supabase.auth.getUser(token);
    if (userError || !user) {
      logger.warn('Usuário não autenticado', { error: userError?.message });
      return new Response(
        JSON.stringify({ error: 'Não autenticado', details: userError?.message }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Verificar permissão de ADMIN ou SUPER_ADMIN
    const { data: roleData, error: roleError } = await supabase
      .from('role_check')
      .select('role_name')
      .eq('user_id', user.id)
      .in('role_name', ['ADMIN', 'SUPER_ADMIN'])
      .single();

    if (roleError || !roleData) {
      logger.warn('Usuário sem permissão de administrador', { userId: user.id, error: roleError?.message });
      return new Response(
        JSON.stringify({ error: 'Acesso negado', details: 'Você não tem permissão para executar esta ação' }),
        { status: 403, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Obter dados do payload
    let payload;
    try {
      const rawBody = await req.text();
      payload = rawBody ? JSON.parse(rawBody) : {};
      logger.info('Payload recebido', { payload });
      
      if (!payload.profile_id || !payload.webhook_type) {
        logger.warn('Dados inválidos no payload', { payload });
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'profile_id e webhook_type são obrigatórios' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
    } catch (error) {
      logger.error('Erro ao processar payload', { 
        error: error.message, 
        stack: error.stack 
      });
      return new Response(
        JSON.stringify({ error: 'Erro ao processar payload', details: error.message }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    const { profile_id, webhook_type } = payload;
    
    // Validar tipo de webhook
    if (webhook_type !== 'MERCHANT_ACCREDITATION' && webhook_type !== 'TRANSACTION') {
      logger.warn('Tipo de webhook inválido', { webhookType: webhook_type });
      return new Response(
        JSON.stringify({ error: 'Tipo de webhook inválido', details: 'O tipo deve ser MERCHANT_ACCREDITATION ou TRANSACTION' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Buscar webhook existente
    const { data: existingWebhook, error: findError } = await supabase
      .from('cappta_webhooks')
      .select('*')
      .eq('profile_id', profile_id)
      .eq('webhook_type', webhook_type)
      .single();
      
    if (findError || !existingWebhook) {
      logger.warn('Webhook não encontrado', { 
        profileId: profile_id, 
        webhookType: webhook_type,
        error: findError?.message
      });
      return new Response(
        JSON.stringify({ error: 'Webhook não encontrado' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Inativar webhook
    const { data: updatedWebhook, error: updateError } = await supabase
      .from('cappta_webhooks')
      .update({
        is_active: false,
        updated_at: new Date().toISOString()
      })
      .eq('id', existingWebhook.id)
      .select()
      .single();
      
    if (updateError) {
      logger.error('Erro ao inativar webhook', { error: updateError.message });
      return new Response(
        JSON.stringify({ error: 'Erro interno ao inativar webhook', details: updateError.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Formatar a resposta para o padrão da Cappta (mantendo compatibilidade)
    const formattedWebhook = {
      id: updatedWebhook.id,
      profile_id: updatedWebhook.profile_id,
      url: updatedWebhook.webhook_url,
      status: 0, // inativo
      created_at: updatedWebhook.created_at,
      updated_at: updatedWebhook.updated_at,
      type: updatedWebhook.webhook_type === 'MERCHANT_ACCREDITATION' ? 'merchantAccreditation' : 'transaction'
    };
    
    logger.info('Webhook inativado com sucesso', { 
      webhookId: updatedWebhook.id,
      profileId: profile_id,
      webhookType: webhook_type
    });
    
    return new Response(
      JSON.stringify({
        error: false,
        data: formattedWebhook
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    logger.error('Erro ao processar requisição', { 
      error: error.message, 
      stack: error.stack 
    });
    return new Response(
      JSON.stringify({ error: 'Erro interno', details: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
