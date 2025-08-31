import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.js'
import { createLogger, LogLevel } from '../_shared/logger.js'
import { getServiceRoleKey } from '../_shared/env.js'

// Inicializa o logger
const logger = createLogger({
  name: 'CapptaPlanDisassociate',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

serve(async (req) => {
  logger.info('Requisição de desassociação de plano recebida', { 
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
      
      logger.info('Payload recebido para desassociação de plano', {
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
        endpoint: `${capptaApiUrl}/plan/${planId}/disassociate`,
        planId,
        resellerDocument: payload.resellerDocument,
        merchantDocument: payload.merchantDocument
      });
      
      const response = await fetch(`${capptaApiUrl}/plan/${planId}/disassociate`, {
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
          // Tentar obter resposta como JSON, mas pode ser uma string vazia
          const text = await response.text();
          responseData = text ? JSON.parse(text) : { message: "Plano desassociado com sucesso" };
        } catch (error) {
          responseData = { message: "Plano desassociado com sucesso" };
        }
        
        logger.info('Plano desassociado com sucesso do lojista', {
          status: response.status,
          planId,
          merchantDocument: payload.merchantDocument
        });
        
        // Registrar a desassociação no banco de dados
        const { data: associationData, error: findError } = await supabase
          .from('cappta_plan_associations')
          .select('*')
          .eq('plan_id', planId)
          .eq('merchant_document', payload.merchantDocument)
          .eq('reseller_document', payload.resellerDocument)
          .order('associated_at', { ascending: false })
          .limit(1);
          
        if (findError || !associationData || associationData.length === 0) {
          logger.warn('Associação não encontrada no banco de dados', {
            planId,
            merchantDocument: payload.merchantDocument,
            resellerDocument: payload.resellerDocument
          });
        } else {
          // Atualizar o registro existente com a data de desassociação
          const { error: updateError } = await supabase
            .from('cappta_plan_associations')
            .update({
              disassociated_at: new Date().toISOString(),
              disassociated_by: user.id
            })
            .eq('id', associationData[0].id);
            
          if (updateError) {
            logger.error('Erro ao registrar desassociação no banco de dados', {
              error: updateError.message,
              planId,
              merchantDocument: payload.merchantDocument
            });
          } else {
            logger.info('Desassociação registrada com sucesso no banco de dados', {
              planId,
              merchantDocument: payload.merchantDocument
            });
          }
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
