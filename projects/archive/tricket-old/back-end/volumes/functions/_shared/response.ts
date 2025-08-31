/**
 * Módulo de Respostas HTTP
 * 
 * Fornece utilitários para criar respostas HTTP padronizadas
 * com headers CORS apropriados.
 */

/**
 * Headers CORS padrão para todas as respostas
 */
const CORS_HEADERS = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
};

/**
 * Interface para resposta de sucesso
 */
export interface SuccessResponse<T = any> {
  success: true;
  message?: string;
  data?: T;
}

/**
 * Interface para resposta de erro
 */
export interface ErrorResponse {
  success: false;
  error: string;
  details?: string;
  errorId?: string;
}

/**
 * Cria uma resposta de sucesso padronizada
 */
export function createSuccessResponse<T>(
  data?: T,
  message?: string,
  status: number = 200
): Response {
  const responseBody: SuccessResponse<T> = {
    success: true,
    ...(message && { message }),
    ...(data && { data })
  };

  return new Response(
    JSON.stringify(responseBody),
    {
      status,
      headers: CORS_HEADERS
    }
  );
}

/**
 * Cria uma resposta de erro padronizada
 */
export function createErrorResponse(
  error: string,
  status: number = 500,
  details?: string,
  errorId?: string
): Response {
  const responseBody: ErrorResponse = {
    success: false,
    error,
    ...(details && { details }),
    ...(errorId && { errorId })
  };

  return new Response(
    JSON.stringify(responseBody),
    {
      status,
      headers: CORS_HEADERS
    }
  );
}

/**
 * Cria uma resposta de erro de validação (400)
 */
export function createValidationErrorResponse(
  error: string,
  details?: string
): Response {
  return createErrorResponse(error, 400, details);
}

/**
 * Cria uma resposta de erro de autenticação (401)
 */
export function createAuthErrorResponse(
  error: string = 'Token de autenticação obrigatório',
  details?: string
): Response {
  return createErrorResponse(error, 401, details);
}

/**
 * Cria uma resposta de erro de autorização (403)
 */
export function createForbiddenErrorResponse(
  error: string = 'Permissões insuficientes',
  details?: string
): Response {
  return createErrorResponse(error, 403, details);
}

/**
 * Cria uma resposta de erro de não encontrado (404)
 */
export function createNotFoundErrorResponse(
  error: string = 'Recurso não encontrado',
  details?: string
): Response {
  return createErrorResponse(error, 404, details);
}

/**
 * Cria uma resposta de erro interno do servidor (500)
 */
export function createInternalErrorResponse(
  error: string = 'Erro interno do servidor',
  details?: string,
  errorId?: string
): Response {
  return createErrorResponse(error, 500, details, errorId);
}

/**
 * Cria uma resposta para requisições OPTIONS (CORS preflight)
 */
export function createOptionsResponse(): Response {
  return new Response(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Max-Age': '86400'
    }
  });
}

/**
 * Manipula requisições OPTIONS automaticamente
 */
export function handleOptionsRequest(request: Request): Response | null {
  if (request.method === 'OPTIONS') {
    return createOptionsResponse();
  }
  return null;
}

/**
 * Wrapper para capturar erros não tratados e retornar resposta padronizada
 */
export function withErrorHandling(
  handler: (request: Request) => Promise<Response>
): (request: Request) => Promise<Response> {
  return async (request: Request): Promise<Response> => {
    try {
      // Trata requisições OPTIONS
      const optionsResponse = handleOptionsRequest(request);
      if (optionsResponse) {
        return optionsResponse;
      }

      // Executa o handler principal
      return await handler(request);
    } catch (error) {
      // Gera ID único para o erro
      const errorId = crypto.randomUUID();
      
      // Log do erro (se console estiver disponível)
      if (typeof console !== 'undefined') {
        console.error('Erro não tratado na Edge Function', {
          errorId,
          message: error.message,
          stack: error.stack
        });
      }

      // Retorna resposta de erro padronizada
      return createInternalErrorResponse(
        'Erro interno do servidor',
        error.message,
        errorId
      );
    }
  };
}

/**
 * Utilitário para extrair dados JSON do corpo da requisição com validação
 */
export async function parseRequestBody<T>(request: Request): Promise<T> {
  try {
    const body = await request.text();
    
    if (!body.trim()) {
      throw new Error('Corpo da requisição está vazio');
    }

    return JSON.parse(body) as T;
  } catch (error) {
    if (error instanceof SyntaxError) {
      throw new Error('Formato JSON inválido no corpo da requisição');
    }
    throw error;
  }
}

/**
 * Valida se campos obrigatórios estão presentes no payload
 */
export function validateRequiredFields(
  payload: Record<string, any>,
  requiredFields: string[]
): { isValid: boolean; missingFields: string[] } {
  const missingFields = requiredFields.filter(field => {
    const value = payload[field];
    return value === undefined || value === null || value === '';
  });

  return {
    isValid: missingFields.length === 0,
    missingFields
  };
}
