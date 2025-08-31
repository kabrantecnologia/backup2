/**
 * Edge Function: Cappta POS Create (Refatorada)
 * 
 * Cria um novo dispositivo Point of Sale (POS) na plataforma Cappta e o registra no banco de dados.
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

// Importações dos módulos compartilhados
import {
  loadConfig,
  validateConfig,
  createLogger,
  authMiddleware,
  createCapptaClient,
  withErrorHandling,
  createSuccessResponse,
  createValidationErrorResponse,
  createInternalErrorResponse,
  parseRequestBody,
  validateRequiredFields,
} from '../_shared/index.ts';

// Declaração para o ambiente Deno
declare const Deno: any;

/**
 * Interface para o payload da requisição de criação de POS.
 */
interface RequestPayload {
  p_serial_key: string;
  p_model_id: number;
  p_keys?: any; // Opcional
}

/**
 * Salva os dados do POS criado no banco de dados Supabase.
 */
async function savePosData(
  supabase: any,
  posData: any,
  dbPayload: { serial_key: string; model_id: number; keys?: any },
  logger: any
): Promise<any> {
  const dbData = {
    cappta_pos_id: posData.id,
    serial_key: dbPayload.serial_key,
    model_id: dbPayload.model_id,
    keys: dbPayload.keys || null,
    status: 1, // Available
    status_description: 'Available',
  };

  logger.info('Salvando dados do POS no banco de dados', { capptaPosId: posData.id });

  const { data: insertedData, error } = await supabase
    .from('cappta_pos_devices')
    .insert(dbData)
    .select()
    .single();

  if (error) {
    logger.error('Erro ao salvar POS no banco de dados', {
      error: error.message,
      details: error.details,
    });
    // Não lançamos um erro aqui, pois a operação principal na Cappta foi bem-sucedida.
    // A falha no registro pode ser tratada separadamente (ex: logs, alertas).
    return { success: false, error };
  }

  logger.info('POS salvo com sucesso no banco de dados', { internalId: insertedData.id });
  return { success: true, data: insertedData };
}

/**
 * Handler principal da Edge Function.
 */
async function handleRequest(request: Request): Promise<Response> {
  const startTime = Date.now();
  const config = loadConfig();
  const logger = createLogger({ name: 'CapptaPosCreate' });
  logger.info('Iniciando requisição para criar POS Cappta');

  const validation = validateConfig(config);
  if (!validation.isValid) {
    logger.error('Configuração inválida', { errors: validation.errors });
    return createInternalErrorResponse(`Configuração do servidor inválida: ${validation.errors.join(', ')}`);
  }

  const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey, {
    auth: { persistSession: false },
  });

  // 3. Autenticação e Autorização
  // Log detalhado dos headers para debugging
  const authHeader = request.headers.get('Authorization');
  const contentType = request.headers.get('Content-Type');
  const userAgent = request.headers.get('User-Agent');
  
  logger.info('Headers da requisição', {
    hasAuthHeader: !!authHeader,
    authHeaderPrefix: authHeader ? authHeader.substring(0, 20) + '...' : 'null',
    contentType,
    userAgent,
    method: request.method,
    url: request.url
  });
  
  const requiredRoles = ['ADMIN', 'SUPER_ADMIN', 'pos_operator'];
  logger.info('Iniciando autenticação com papéis requeridos', { requiredRoles });
  const authResult = await authMiddleware(request, supabase, logger, requiredRoles);
  if (!authResult.success || !authResult.user) {
    logger.error('Falha na autenticação - detalhes completos', {
      authResultSuccess: authResult.success,
      hasUser: !!authResult.user,
      hasResponse: !!authResult.response,
      authHeader: authHeader ? 'presente' : 'ausente'
    });
    return authResult.response || createInternalErrorResponse('Falha na autenticação');
  }
  logger.info('Usuário autenticado e autorizado com sucesso', { 
    userId: authResult.user.id,
    roles: authResult.user.roles
  });
  const { user } = authResult;
  logger.info('Iniciando criação de POS', { userId: user.id });

  // 2. Parse e Validação do Corpo da Requisição
  logger.debug('Iniciando parse do corpo da requisição.');
  const payload = await parseRequestBody<RequestPayload>(request);
  logger.debug('Payload recebido', { payload });
  const { isValid: isPayloadValid, missingFields } = validateRequiredFields(payload, [
    'p_serial_key',
    'p_model_id',
  ]);

  if (!isPayloadValid) {
    logger.warn('Payload da requisição inválido', { missingFields });
    return createValidationErrorResponse('Dados da requisição inválidos.', `Campos obrigatórios ausentes: ${missingFields.join(', ')}`);
  }
  logger.debug('Payload validado com sucesso.');

  // 3. Inicialização do Cliente Cappta com as configurações do ambiente
  logger.info('Utilizando configurações do ambiente para Cappta');
  
  // Usar valores do arquivo de configuração
  const capptaClient = createCapptaClient(config.capptaApiUrl, config.capptaApiToken);
  
  logger.info('Cliente Cappta inicializado', {
    tokenLength: config.capptaApiToken.length,
    tokenStart: config.capptaApiToken.substring(0, 20) + '...',
    apiUrl: config.capptaApiUrl
  });

  // 4. Criação do POS
  const capptaPayload = {
    resellerDocument: config.resellerDocument, // Usando valor da configuração
    serialKey: payload.p_serial_key,
    modelId: "1" // Usando o valor como string conforme solicitado
  };
  
  logger.debug('Payload formatado conforme especificação', {
    body: {
      resellerDocument: config.resellerDocument,
      serialKey: payload.p_serial_key,
      modelId: "1"
    }
  });
  
  logger.info('Enviando requisição para criar POS', { 
    serialKey: capptaPayload.serialKey,
    targetUrl: config.capptaApiUrl
  });
  
  logger.debug('Payload completo da requisição', { 
    payload: capptaPayload,
    tokenLength: config.capptaApiToken.length
  });
  
  let capptaResponse;
  try {
    capptaResponse = await capptaClient.createPos(capptaPayload);
    
    if (!capptaResponse.success) {
      // Log detalhado do erro
      logger.error('Falha ao criar POS', {
      error: capptaResponse.error,
      statusCode: capptaResponse.statusCode,
      responseHeaders: capptaResponse.responseHeaders,
      apiUrl: config.capptaApiUrl,
      errorDetails: capptaResponse.errorDetails || {}
    });
      
      // Mensagem de erro mais descritiva para ajudar na depuração
      const errorMessage = `Falha ao criar POS na plataforma externa (HTTP ${capptaResponse.statusCode}): ${JSON.stringify(capptaResponse.error)}`;
      return createInternalErrorResponse(errorMessage);
    }

    logger.debug('Resposta recebida da API', { response: capptaResponse.data });
  } catch (error) {
    logger.error('Exceção ao chamar a API', {
      errorMessage: error.message,
      errorStack: error.stack,
      apiUrl: config.capptaApiUrl
    });
    
    const errorMessage = `Erro ao processar a requisição: ${error.message}`;
    return createInternalErrorResponse(errorMessage);
  }

  // Se chegou aqui, capptaResponse está definido e tem dados
  const capptaPosData = capptaResponse.data!;
  logger.info('POS criado com sucesso na Cappta', { capptaPosId: capptaPosData.id });

  // 5. Salvamento no Banco de Dados
  const dbPayload = {
    serial_key: payload.p_serial_key,
    model_id: payload.p_model_id,
    keys: payload.p_keys,
  };
  logger.debug('Iniciando salvamento no banco de dados', { dbPayload });
  await savePosData(supabase, capptaPosData, dbPayload, logger);
  logger.debug('Dados salvos no banco de dados com sucesso.');

  // 6. Resposta de Sucesso
  const duration = Date.now() - startTime;
  logger.info('Processo de criação de POS concluído com sucesso', { duration_ms: duration });

  const responsePayload = {
    cappta_pos_id: capptaPosData.id,
    p_serial_key: payload.p_serial_key,
    p_model_id: payload.p_model_id,
    status: 'CREATED',
  };
  logger.info(`Requisição finalizada em ${duration}ms`, { status: 200 });
  logger.debug('Enviando resposta de sucesso.', { responsePayload });

  return createSuccessResponse(
    responsePayload,
    'Dispositivo POS criado e registrado com sucesso.'
  );
}

// Inicia o servidor com tratamento de erros
serve(withErrorHandling(handleRequest));
