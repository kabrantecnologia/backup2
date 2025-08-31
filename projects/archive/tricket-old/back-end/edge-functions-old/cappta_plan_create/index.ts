import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.js'
import { createLogger, LogLevel } from '../_shared/logger.js'
import { getServiceRoleKey } from '../_shared/env.js'

// Inicializa o logger
const logger = createLogger({
  name: 'CapptaPlanCreate',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

serve(async (req) => {
  logger.info('Requisição de criação de plano recebida', { 
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
      logger.info('Payload recebido para criação de plano', {
        name: payload.Name,
        type: payload.type,
        product: payload.product
      });
      
      // Validar campos obrigatórios
      if (!payload.Name) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'Name é obrigatório' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!payload.product) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'product é obrigatório' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!payload.type) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'type é obrigatório' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!payload.basePlanId) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'basePlanId é obrigatório' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!payload.settlementDays && payload.settlementDays !== 0) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'settlementDays é obrigatório' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!Array.isArray(payload.schemes) || payload.schemes.length === 0) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'schemes deve ser um array não vazio' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      // Validar cada scheme
      for (const scheme of payload.schemes) {
        if (!scheme.id) {
          return new Response(
            JSON.stringify({ error: 'Dados inválidos', details: 'Todos os schemes devem ter um id' }),
            { status: 400, headers: { 'Content-Type': 'application/json' } }
          );
        }
        
        if (!Array.isArray(scheme.fees) || scheme.fees.length === 0) {
          return new Response(
            JSON.stringify({ error: 'Dados inválidos', details: `O scheme ${scheme.id} deve ter fees não vazias` }),
            { status: 400, headers: { 'Content-Type': 'application/json' } }
          );
        }
        
        for (const fee of scheme.fees) {
          if (!fee.hasOwnProperty('installments') || !fee.hasOwnProperty('rate')) {
            return new Response(
              JSON.stringify({ error: 'Dados inválidos', details: 'Cada fee deve ter installments e rate' }),
              { status: 400, headers: { 'Content-Type': 'application/json' } }
            );
          }
        }
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
        endpoint: `${capptaApiUrl}/plan`,
        planName: payload.Name
      });
      
      const response = await fetch(`${capptaApiUrl}/plan`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${capptaApiKey}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });
      
      const responseData = await response.json();
      
      // Registrar o resultado da requisição
      if (response.ok) {
        const planId = responseData.id;
        logger.info('Plano criado com sucesso na Cappta', {
          status: response.status,
          planId,
          planName: payload.Name
        });
        
        // Armazenar os dados do plano no banco para referência futura
        const planData = {
          cappta_plan_id: planId,
          name: payload.Name,
          type: payload.type,
          product: payload.product,
          settlement_days: payload.settlementDays,
          base_plan_id: payload.basePlanId,
          created_at: new Date().toISOString(),
          created_by: user.id
        };
        
        const { error: insertError } = await supabase
          .from('cappta_plans')
          .insert([planData]);
          
        if (insertError) {
          logger.error('Erro ao salvar plano no banco de dados', {
            error: insertError.message,
            planId,
            planName: payload.Name
          });
          // Não retornamos erro aqui pois o plano foi criado com sucesso na Cappta
        } else {
          logger.info('Plano armazenado com sucesso no banco de dados', {
            planId,
            planName: payload.Name
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
          planName: payload.Name
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
