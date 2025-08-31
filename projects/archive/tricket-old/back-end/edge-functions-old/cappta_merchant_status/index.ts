import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.js'
import { createLogger, LogLevel } from '../_shared/logger.js'
import { getServiceRoleKey } from '../_shared/env.js'

// Inicializa o logger
const logger = createLogger({
  name: 'CapptaMerchantStatus',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

serve(async (req) => {
  logger.info('Requisição de consulta de status de lojista recebida', { 
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
    let vaultKeys;
    try {
      vaultKeys = await getRequiredVaultKeys(supabase, [
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
    
    // Verificação de autenticação
    const authHeader = req.headers.get('Authorization');
    const token = authHeader?.split(' ')[1];
    
    if (!token) {
      logger.warn('Token de autenticação não fornecido');
      return new Response(
        JSON.stringify({ error: 'Token de autenticação não fornecido' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Verificar autenticação do usuário
    const { data: { user }, error: userError } = await supabase.auth.getUser(token);
    if (userError || !user) {
      logger.warn('Usuário não autenticado', { error: userError?.message });
      return new Response(
        JSON.stringify({ error: 'Não autenticado', details: userError?.message }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Obter parâmetros da URL
    const url = new URL(req.url);
    const profileId = url.searchParams.get('profile_id');
    
    if (!profileId) {
      logger.warn('profile_id não especificado');
      return new Response(
        JSON.stringify({ error: 'Dados inválidos', details: 'profile_id é obrigatório' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Buscar dados do merchant document no profile
    const { data: profileData, error: profileError } = await supabase
      .from('profiles')
      .select('cappta_merchant_document, cappta_status, cappta_status_description')
      .eq('id', profileId)
      .maybeSingle();
      
    if (profileError) {
      logger.error('Erro ao buscar dados do profile', { 
        error: profileError.message, 
        profileId 
      });
      return new Response(
        JSON.stringify({ error: 'Erro interno', details: 'Erro ao buscar dados do perfil' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    if (!profileData || !profileData.cappta_merchant_document) {
      logger.warn('Profile não encontrado ou sem merchant document da Cappta', { profileId });
      return new Response(
        JSON.stringify({ 
          error: 'Merchant document não encontrado', 
          details: `Não há merchant document da Cappta registrado para o profile: ${profileId}` 
        }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Obter documento do revendedor
    // Para este exemplo, estamos usando um documento de revendedor fixo (deveria vir de configuração)
    // Na produção deve ser obtido de uma tabela de configuração ou de variável de ambiente
    const resellerDocument = url.searchParams.get('reseller_document') || "46946632000143";
    
    // Fazer a requisição para a API da Cappta
    const capptaApiUrl = vaultKeys.CAPPTA_API_URL;
    const capptaApiKey = vaultKeys.CAPPTA_API_KEY;
    const merchantDocument = profileData.cappta_merchant_document;
    
    try {
      logger.info('Enviando requisição para API da Cappta', {
        endpoint: `${capptaApiUrl}/onboarding/merchant/${merchantDocument}/status`,
        resellerDocument,
        merchantDocument
      });
      
      const response = await fetch(
        `${capptaApiUrl}/onboarding/merchant/${merchantDocument}/status?resellerDocument=${resellerDocument}`, 
        {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${capptaApiKey}`,
            'Accept': 'application/json'
          }
        }
      );
      
      const responseData = await response.json();
      
      // Registrar o resultado da requisição
      if (response.ok) {
        logger.info('Consulta de status de lojista na Cappta realizada com sucesso', {
          status: response.status,
          responseData,
          profileId,
          merchantDocument
        });
        
        // Atualizar o status do merchant no perfil
        if (responseData.status !== profileData.cappta_status || 
            responseData.statusDescription !== profileData.cappta_status_description) {
          
          const { error: updateError } = await supabase
            .from('profiles')
            .update({
              cappta_status: responseData.status,
              cappta_status_description: responseData.statusDescription,
              updated_at: new Date().toISOString()
            })
            .eq('id', profileId);
            
          if (updateError) {
            logger.error('Erro ao atualizar status do merchant no profile', {
              error: updateError.message,
              profileId
            });
            // Não retornamos erro aqui pois a consulta foi realizada com sucesso
          } else {
            logger.info('Status do merchant atualizado com sucesso no profile', {
              profileId,
              oldStatus: profileData.cappta_status,
              newStatus: responseData.status
            });
          }
        }
        
        return new Response(
          JSON.stringify(responseData),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      } else {
        logger.error('Erro na requisição para API da Cappta', {
          status: response.status,
          responseData,
          profileId
        });
        
        return new Response(
          JSON.stringify({ error: 'Erro na requisição para API da Cappta', details: responseData }),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      }
    } catch (error) {
      logger.error('Erro ao realizar requisição para API da Cappta', {
        error: error.message,
        stack: error.stack
      });
      
      return new Response(
        JSON.stringify({ error: 'Erro de comunicação com a API da Cappta', details: error.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
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
