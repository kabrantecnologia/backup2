import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.js'
import { createLogger, LogLevel } from '../_shared/logger.js'
import { getServiceRoleKey } from '../_shared/env.js'

// Inicializa o logger
const logger = createLogger({
  name: 'CapptaPOSDetails',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

serve(async (req) => {
  logger.info('Requisição de detalhes de dispositivo POS recebida', { 
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
    
    // Extrair ID do POS da URL
    const url = new URL(req.url);
    const pathParts = url.pathname.split('/');
    const posId = pathParts[pathParts.length - 1];
    
    if (!posId) {
      logger.warn('ID do dispositivo POS não especificado');
      return new Response(
        JSON.stringify({ error: 'ID do dispositivo POS não especificado' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Fazer a requisição para a API da Cappta
    const capptaApiUrl = vaultKeys.CAPPTA_API_URL;
    const capptaApiKey = vaultKeys.CAPPTA_API_KEY;
    
    try {
      logger.info('Enviando requisição para API da Cappta', {
        endpoint: `${capptaApiUrl}/pos/device/${posId}`,
        posId
      });
      
      const response = await fetch(`${capptaApiUrl}/pos/device/${posId}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${capptaApiKey}`,
          'Accept': 'application/json'
        }
      });
      
      const responseData = await response.json();
      
      // Registrar o resultado da requisição
      if (response.ok) {
        logger.info('Detalhes do dispositivo POS obtidos com sucesso', {
          status: response.status,
          posId,
          serialKey: responseData.serialKey
        });
        
        // Atualizar ou inserir registro no banco de dados
        try {
          // Verificar se o dispositivo já existe no banco
          const { data: existingDevice } = await supabase
            .from('cappta_pos_devices')
            .select('id')
            .eq('cappta_pos_id', responseData.id)
            .maybeSingle();
            
          if (existingDevice) {
            // Atualizar o registro existente
            await supabase
              .from('cappta_pos_devices')
              .update({
                reseller_document: responseData.resellerDocument,
                model_id: responseData.modelId,
                serial_key: responseData.serialKey,
                status: responseData.status,
                status_description: responseData.statusDescription,
                merchant_document: responseData.merchantDocument || null,
                updated_at: new Date().toISOString(),
                updated_by: user.id
              })
              .eq('cappta_pos_id', responseData.id);
              
            logger.info('Registro do dispositivo POS atualizado no banco de dados', {
              posId
            });
          } else {
            // Inserir novo registro
            await supabase
              .from('cappta_pos_devices')
              .insert([{
                cappta_pos_id: responseData.id,
                reseller_document: responseData.resellerDocument,
                model_id: responseData.modelId,
                serial_key: responseData.serialKey,
                status: responseData.status,
                status_description: responseData.statusDescription,
                merchant_document: responseData.merchantDocument || null,
                created_at: new Date().toISOString(),
                created_by: user.id
              }]);
              
            logger.info('Dispositivo POS inserido no banco de dados', {
              posId
            });
          }
        } catch (dbError) {
          logger.error('Erro ao atualizar dispositivo POS no banco de dados', {
            error: dbError.message,
            posId
          });
          // Não retornamos erro aqui pois os detalhes foram obtidos com sucesso
        }
        
        return new Response(
          JSON.stringify(responseData),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      } else {
        logger.error('Erro na requisição para API da Cappta', {
          status: response.status,
          responseData,
          posId
        });
        
        return new Response(
          JSON.stringify({ error: 'Erro na requisição para API da Cappta', details: responseData }),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      }
    } catch (error) {
      logger.error('Erro ao realizar requisição para API da Cappta', {
        error: error.message,
        stack: error.stack,
        posId
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
