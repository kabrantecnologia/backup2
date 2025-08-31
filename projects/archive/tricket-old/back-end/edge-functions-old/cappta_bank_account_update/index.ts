import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.js'
import { createLogger, LogLevel } from '../_shared/logger.js'
import { getServiceRoleKey } from '../_shared/env.js'

// Inicializa o logger
const logger = createLogger({
  name: 'CapptaBankAccountUpdate',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

serve(async (req) => {
  logger.info('Requisição de atualização de dados bancários recebida', { 
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
      logger.info('Payload recebido para atualização de dados bancários', payload);
      
      // Validar campos obrigatórios
      if (!payload.account) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'account é obrigatório' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!payload.bankCode) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'bankCode é obrigatório' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (!payload.branch) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'branch é obrigatório' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      if (payload.accountType === undefined) {
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'accountType é obrigatório' }),
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
      .select('cappta_merchant_document, cappta_status')
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
    
    // Verificar se o status permite atualização (Enabled ou InvalidBank)
    if (profileData.cappta_status !== 1 && profileData.cappta_status !== 3) {
      logger.warn('Status do lojista não permite atualização de dados bancários', { 
        status: profileData.cappta_status,
        profileId 
      });
      return new Response(
        JSON.stringify({ 
          error: 'Operação não permitida', 
          details: 'Só é possível atualizar dados bancários quando o status do lojista for Enabled (1) ou InvalidBank (3)'
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
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
      const requestUrl = `${capptaApiUrl}/onboarding/merchant/${merchantDocument}/bank-account?resellerDocument=${resellerDocument}`;
      
      logger.info('Enviando requisição para API da Cappta', {
        endpoint: requestUrl,
        resellerDocument,
        merchantDocument,
        payload
      });
      
      const response = await fetch(requestUrl, {
        method: 'PUT',
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
        logger.info('Atualização de dados bancários realizada com sucesso', {
          status: response.status,
          responseData,
          profileId,
          merchantDocument
        });
        
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
