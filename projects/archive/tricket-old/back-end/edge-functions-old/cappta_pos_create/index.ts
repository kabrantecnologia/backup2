import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.js'
import { createLogger, LogLevel } from '../_shared/logger.js'
import { getServiceRoleKey } from '../_shared/env.js'

// Inicializa o logger
const logger = createLogger({
  name: 'CapptaPOSCreate',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

serve(async (req) => {
  logger.info('Requisição de cadastro de POS recebida', { 
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
    
    // Obter dados do payload
    let payload;
    try {
      const rawBody = await req.text();
      payload = rawBody ? JSON.parse(rawBody) : {};
      logger.info('Payload recebido para cadastro de POS', {
        resellerDocument: payload.resellerDocument,
        serialKey: payload.serialKey,
        modelId: payload.modelId
      });
      
      // Validar campos obrigatórios
      if (!payload.resellerDocument) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'resellerDocument é obrigatório' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!payload.serialKey) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'serialKey é obrigatório' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!payload.modelId) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'modelId é obrigatório' }),
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
    
    // Fazer a requisição para a API da Cappta
    const capptaApiUrl = vaultKeys.CAPPTA_API_URL;
    const capptaApiKey = vaultKeys.CAPPTA_API_KEY;
    
    try {
      logger.info('Enviando requisição para API da Cappta', {
        endpoint: `${capptaApiUrl}/pos/device`,
        resellerDocument: payload.resellerDocument,
        serialKey: payload.serialKey
      });
      
      const response = await fetch(`${capptaApiUrl}/pos/device`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${capptaApiKey}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          resellerDocument: payload.resellerDocument,
          serialKey: payload.serialKey,
          modelId: payload.modelId,
          keys: payload.keys || undefined
        })
      });
      
      const responseData = await response.json();
      
      // Registrar o resultado da requisição
      if (response.ok) {
        const posId = responseData.id;
        logger.info('POS cadastrado com sucesso na Cappta', {
          status: response.status,
          posId,
          serialKey: payload.serialKey
        });
        
        // Armazenar os dados do POS no banco para referência futura
        const posData = {
          cappta_pos_id: posId,
          reseller_document: payload.resellerDocument,
          serial_key: payload.serialKey,
          model_id: payload.modelId,
          keys: payload.keys || null,
          created_at: new Date().toISOString(),
          created_by: user.id,
          status: 1, // Available
          status_description: "Available",
          merchant_document: null // Não vinculado inicialmente
        };
        
        const { error: insertError } = await supabase
          .from('cappta_pos_devices')
          .insert([posData]);
          
        if (insertError) {
          logger.error('Erro ao salvar POS no banco de dados', {
            error: insertError.message,
            posId,
            serialKey: payload.serialKey
          });
          // Não retornamos erro aqui pois o POS foi criado com sucesso na Cappta
        } else {
          logger.info('POS armazenado com sucesso no banco de dados', {
            posId,
            serialKey: payload.serialKey
          });
        }
        
        return new Response(
          JSON.stringify(responseData),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      } else {
        logger.error('Erro na requisição para API da Cappta', {
          status: response.status,
          responseData,
          serialKey: payload.serialKey
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
