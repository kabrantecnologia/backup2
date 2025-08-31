import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.js'
import { createLogger, LogLevel } from '../_shared/logger.js'
import { getServiceRoleKey } from '../_shared/env.js'

// Inicializa o logger
const logger = createLogger({
  name: 'CapptaPOSList',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

serve(async (req) => {
  logger.info('Requisição de listagem de dispositivos POS recebida', { 
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

    // Obter parâmetros de consulta
    const url = new URL(req.url);
    const resellerDocument = url.searchParams.get('resellerDocument');
    const merchantDocument = url.searchParams.get('merchantDocument');
    const status = url.searchParams.get('status');
    const serialKey = url.searchParams.get('serialKey');
    
    // Construir URL da API Cappta com parâmetros
    let apiUrl = `${vaultKeys.CAPPTA_API_URL}/pos/device`;
    const queryParams = new URLSearchParams();
    
    if (resellerDocument) queryParams.append('resellerDocument', resellerDocument);
    if (merchantDocument) queryParams.append('merchantDocument', merchantDocument);
    if (status) queryParams.append('status', status);
    if (serialKey) queryParams.append('serialKey', serialKey);
    
    const queryString = queryParams.toString();
    if (queryString) {
      apiUrl = `${apiUrl}?${queryString}`;
    }
    
    // Fazer a requisição para a API da Cappta
    const capptaApiKey = vaultKeys.CAPPTA_API_KEY;
    
    try {
      logger.info('Enviando requisição para API da Cappta', {
        endpoint: apiUrl,
        hasResellerFilter: !!resellerDocument,
        hasMerchantFilter: !!merchantDocument,
        hasStatusFilter: !!status,
        hasSerialKeyFilter: !!serialKey
      });
      
      const response = await fetch(apiUrl, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${capptaApiKey}`,
          'Accept': 'application/json'
        }
      });
      
      const responseData = await response.json();
      
      // Registrar o resultado da requisição
      if (response.ok) {
        const deviceCount = Array.isArray(responseData) ? responseData.length : 0;
        
        logger.info('Listagem de dispositivos POS obtida com sucesso', {
          status: response.status,
          deviceCount
        });
        
        // Atualizar os registros locais com base nos dados recebidos
        if (deviceCount > 0) {
          try {
            // Processar em batch para evitar sobrecarregar a operação
            for (const device of responseData) {
              // Verificar se o dispositivo já existe no banco
              const { data: existingDevice } = await supabase
                .from('cappta_pos_devices')
                .select('id')
                .eq('cappta_pos_id', device.id)
                .maybeSingle();
                
              if (existingDevice) {
                // Atualizar o registro existente
                await supabase
                  .from('cappta_pos_devices')
                  .update({
                    reseller_document: device.resellerDocument,
                    model_id: device.modelId,
                    serial_key: device.serialKey,
                    status: device.status,
                    status_description: device.statusDescription,
                    merchant_document: device.merchantDocument || null,
                    updated_at: new Date().toISOString(),
                    updated_by: user.id
                  })
                  .eq('cappta_pos_id', device.id);
              } else {
                // Inserir novo registro
                await supabase
                  .from('cappta_pos_devices')
                  .insert([{
                    cappta_pos_id: device.id,
                    reseller_document: device.resellerDocument,
                    model_id: device.modelId,
                    serial_key: device.serialKey,
                    status: device.status,
                    status_description: device.statusDescription,
                    merchant_document: device.merchantDocument || null,
                    created_at: new Date().toISOString(),
                    created_by: user.id
                  }]);
              }
            }
            
            logger.info('Dados de dispositivos POS sincronizados com o banco de dados', {
              deviceCount
            });
          } catch (dbError) {
            logger.error('Erro ao sincronizar dispositivos POS com o banco de dados', {
              error: dbError.message,
              deviceCount
            });
            // Não retornamos erro aqui pois a listagem foi obtida com sucesso
          }
        }
        
        return new Response(
          JSON.stringify(responseData),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      } else {
        logger.error('Erro na requisição para API da Cappta', {
          status: response.status,
          responseData
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
