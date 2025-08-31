import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.js'
import { createLogger, LogLevel } from '../_shared/logger.js'
import { getServiceRoleKey } from '../_shared/env.js'

// Inicializa o logger
const logger = createLogger({
  name: 'CapptaPlanAssociate',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

serve(async (req) => {
  logger.info('Requisição de associação de plano recebida', { 
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
    
    // Obter ID do plano da URL
    const url = new URL(req.url);
    const path = url.pathname;
    const planId = path.split('/').pop();

    if (!planId) {
      logger.warn('ID do plano não especificado');
      return new Response(
        JSON.stringify({ error: 'ID do plano não especificado' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Obter dados do payload
    let payload;
    try {
      const rawBody = await req.text();
      payload = rawBody ? JSON.parse(rawBody) : {};
      
      logger.info('Payload recebido para associação de plano', {
        planId,
        resellerDocument: payload.resellerDocument,
        merchantDocument: payload.merchantDocument
      });
      
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
        endpoint: `${capptaApiUrl}/plan/${planId}/associate`,
        planId,
        resellerDocument: payload.resellerDocument,
        merchantDocument: payload.merchantDocument
      });
      
      const response = await fetch(`${capptaApiUrl}/plan/${planId}/associate`, {
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
      
      // Registrar o resultado da requisição
      if (response.ok) {
        let responseData;
        try {
          responseData = await response.json();
        } catch (error) {
          responseData = { message: "Plano associado com sucesso" };
        }
        
        logger.info('Plano associado com sucesso ao lojista', {
          status: response.status,
          planId,
          merchantDocument: payload.merchantDocument,
          associationId: responseData.id || 'N/A'
        });
        
        // Registrar a associação no banco de dados
        const associationData = {
          plan_id: planId,
          merchant_document: payload.merchantDocument,
          reseller_document: payload.resellerDocument,
          association_id: responseData.id || null,
          associated_at: new Date().toISOString(),
          associated_by: user.id
        };
        
        const { error: insertError } = await supabase
          .from('cappta_plan_associations')
          .insert([associationData]);
          
        if (insertError) {
          logger.error('Erro ao registrar associação no banco de dados', {
            error: insertError.message,
            planId,
            merchantDocument: payload.merchantDocument
          });
          // Não retornamos erro aqui pois a associação foi feita com sucesso na Cappta
        } else {
          logger.info('Associação registrada com sucesso no banco de dados', {
            planId,
            merchantDocument: payload.merchantDocument
          });
        }
        
        return new Response(
          JSON.stringify(responseData),
          { status: response.status, headers: { 'Content-Type': 'application/json' } }
        );
      } else {
        // Obter o corpo da resposta de erro
        let responseData;
        try {
          responseData = await response.json();
        } catch (error) {
          responseData = { message: 'Erro desconhecido' };
        }
        
        logger.error('Erro na requisição para API da Cappta', {
          status: response.status,
          responseData,
          planId,
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
        planId
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
