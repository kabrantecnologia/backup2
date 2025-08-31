/**
 * Configuração de CORS para Edge Functions
 * 
 * Define os cabeçalhos necessários para permitir requisições cross-origin
 * das aplicações front-end e ferramentas de teste.
 */

/**
 * Headers padrão para CORS
 */
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Max-Age': '86400', // 24 horas
} as const;

/**
 * Headers específicos para desenvolvimento
 */
export const corsHeadersDev = {
  ...corsHeaders,
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Credentials': 'true',
  'Access-Control-Expose-Headers': 'x-request-id, x-processing-time',
} as const;

/**
 * Headers específicos para produção
 */
export const corsHeadersProd = {
  ...corsHeaders,
  'Access-Control-Allow-Origin': 'https://app-tricket.kabran.com.br',
  'Access-Control-Allow-Credentials': 'true',
} as const;

/**
 * Retorna os headers CORS apropriados baseado no ambiente
 */
export function getCorsHeaders(): Record<string, string> {
  const isDev = Deno.env.get('ENVIRONMENT') === 'development' || 
                Deno.env.get('DEBUG') === 'true';
  
  return isDev ? corsHeadersDev : corsHeadersProd;
}