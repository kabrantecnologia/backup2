import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.js'
import { createLogger, LogLevel } from '../_shared/logger.js'
import { getServiceRoleKey } from '../_shared/env.js'

// Inicializa o logger
const logger = createLogger({
  name: 'CapptaPOSBind',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

serve(async (req) => {
  logger.info('Requisição de vinculação de POS recebida', { 
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
    
    // Extrair ID do POS da URL
    const url = new URL(req.url);
    const pathParts = url.pathname.split('/');
    // O ID estará antes de "bind" no caminho
    const posId = pathParts[pathParts.length - 2];
    
    if (!posId) {
      logger.warn('ID do dispositivo POS não especificado');
      return new Response(
        JSON.stringify({ error: 'ID do dispositivo POS não especificado' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Obter dados do payload
    let payload;
    try {
      const rawBody = await req.text();
      payload = rawBody ? JSON.parse(rawBody) : {};
      
      // Validar campos obrigatórios
      if (!payload.resellerDocument) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'resellerDocument é obrigatório' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!payload.merchantDocument) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'merchantDocument é obrigatório' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      logger.info('Payload recebido para vinculação de POS', {
        resellerDocument: payload.resellerDocument,
        merchantDocument: payload.merchantDocument,
        posId
      });
      
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
    
    // Fazer a requisição para a API da Cappta
    const capptaApiUrl = vaultKeys.CAPPTA_API_URL;
    const capptaApiKey = vaultKeys.CAPPTA_API_KEY;
    
    try {
      logger.info('Enviando requisição para API da Cappta', {
        endpoint: `${capptaApiUrl}/pos/device/${posId}/bind`,
        posId,
        resellerDocument: payload.resellerDocument,
        merchantDocument: payload.merchantDocument
      });
      
      const response = await fetch(`${capptaApiUrl}/pos/device/${posId}/bind`, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${capptaApiKey}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          resellerDocument: payload.resellerDocument,
          merchantDocument: payload.merchantDocument
        })
      });
      
      const responseData = await response.json();
      
      // Registrar o resultado da requisição
      if (response.ok) {
        logger.info('POS vinculado com sucesso ao lojista', {
          status: response.status,
          posId,
          merchantDocument: payload.merchantDocument,
          token: responseData.token
        });
        
        // Atualizar o registro no banco de dados
        try {
          const { data: existingPOS } = await supabase
            .from('cappta_pos_devices')
            .select('*')
            .eq('cappta_pos_id', posId)
            .maybeSingle();
            
          if (existingPOS) {
            // Atualizar registro existente
            await supabase
              .from('cappta_pos_devices')
              .update({
                merchant_document: payload.merchantDocument,
                status: 2, // Associated
                status_description: "Associated",
                token: responseData.token,
                updated_at: new Date().toISOString(),
                updated_by: user.id
              })
              .eq('cappta_pos_id', posId);
              
            logger.info('Registro de POS atualizado no banco de dados após vinculação', {
              posId,
              merchantDocument: payload.merchantDocument
            });
          } else {
            // Buscar informações do POS e inserir
            const posResponse = await fetch(`${capptaApiUrl}/pos/device/${posId}`, {
              method: 'GET',
              headers: {
                'Authorization': `Bearer ${capptaApiKey}`,
                'Accept': 'application/json'
              }
            });
            
            if (posResponse.ok) {
              const posData = await posResponse.json();
              
              await supabase
                .from('cappta_pos_devices')
                .insert([{
                  cappta_pos_id: posId,
                  reseller_document: payload.resellerDocument,
                  model_id: posData.modelId,
                  serial_key: posData.serialKey,
                  status: 2, // Associated
                  status_description: "Associated",
                  merchant_document: payload.merchantDocument,
                  token: responseData.token,
                  created_at: new Date().toISOString(),
                  created_by: user.id
                }]);
                
              logger.info('Registro de POS criado no banco de dados após vinculação', {
                posId,
                merchantDocument: payload.merchantDocument
              });
            } else {
              logger.error('Erro ao obter detalhes do POS para inserção no banco', {
                posId,
                status: posResponse.status
              });
            }
          }
          
          // Registrar o histórico de vinculação
          await supabase
            .from('cappta_pos_merchant_bindings')
            .insert([{
              pos_id: posId,
              reseller_document: payload.resellerDocument,
              merchant_document: payload.merchantDocument,
              token: responseData.token,
              bound_at: new Date().toISOString(),
              bound_by: user.id
            }]);
            
        } catch (dbError) {
          logger.error('Erro ao atualizar POS no banco de dados após vinculação', {
            error: dbError.message,
            posId,
            merchantDocument: payload.merchantDocument
          });
          // Não retornamos erro aqui pois a vinculação foi realizada com sucesso na Cappta
        }
        
        return new Response(
          JSON.stringify(responseData),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      } else {
        logger.error('Erro na requisição para API da Cappta', {
          status: response.status,
          responseData,
          posId,
          merchantDocument: payload.merchantDocument
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
