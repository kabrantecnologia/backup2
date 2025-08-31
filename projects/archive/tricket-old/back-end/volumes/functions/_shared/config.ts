/**
 * Módulo de Configuração
 * 
 * Centraliza o carregamento e validação de variáveis de ambiente
 * para as Edge Functions do Supabase.
 */

// Declaração para o ambiente Deno
declare const Deno: any;

/**
 * Interface para as configurações da aplicação
 */
export interface AppConfig {
  // Supabase
  supabaseUrl: string;
  supabaseServiceRoleKey: string;
  
  // Asaas
  asaasApiUrl: string;
  asaasMasterAccessToken: string;
  
  // Segurança
  encryptionSecret: string;
  
  // URLs externas
  apiExternalUrl: string;
}

/**
 * Lista de variáveis obrigatórias
 */
const REQUIRED_ENV_VARS = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'ASAAS_API_URL',
  'ASAAS_MASTER_ACCESS_TOKEN',
  'ENCRYPTION_SECRET',
  'API_EXTERNAL_URL'
] as const;

/**
 * Carrega e valida as configurações do ambiente
 */
export function loadConfig(): AppConfig {
  const config: Partial<AppConfig> = {};
  const missingVars: string[] = [];

  // Carrega variáveis obrigatórias
  for (const varName of REQUIRED_ENV_VARS) {
    const value = Deno.env.get(varName);
    if (!value) {
      missingVars.push(varName);
    }
  }

  // Valida se todas as variáveis obrigatórias estão presentes
  if (missingVars.length > 0) {
    throw new Error(`Variáveis de ambiente obrigatórias não encontradas: ${missingVars.join(', ')}`);
  }

  // Retorna configuração validada
  return {
    supabaseUrl: Deno.env.get('SUPABASE_URL')!,
    supabaseServiceRoleKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    asaasApiUrl: Deno.env.get('ASAAS_API_URL')!,
    asaasMasterAccessToken: Deno.env.get('ASAAS_MASTER_ACCESS_TOKEN')!,
    encryptionSecret: Deno.env.get('ENCRYPTION_SECRET')!,
    apiExternalUrl: Deno.env.get('API_EXTERNAL_URL')!
  };
}

/**
 * Verifica se uma variável de ambiente específica existe
 */
export function hasEnvVar(varName: string): boolean {
  return !!Deno.env.get(varName);
}

/**
 * Obtém uma variável de ambiente com valor padrão
 */
export function getEnvVar(varName: string, defaultValue?: string): string {
  return Deno.env.get(varName) || defaultValue || '';
}

/**
 * Valida se todas as configurações necessárias estão presentes
 */
export function validateConfig(config: AppConfig): { isValid: boolean; errors: string[] } {
  const errors: string[] = [];

  // Valida URLs
  try {
    new URL(config.supabaseUrl);
  } catch {
    errors.push('SUPABASE_URL deve ser uma URL válida');
  }

  try {
    new URL(config.asaasApiUrl);
  } catch {
    errors.push('ASAAS_API_URL deve ser uma URL válida');
  }

  try {
    new URL(config.apiExternalUrl);
  } catch {
    errors.push('API_EXTERNAL_URL deve ser uma URL válida');
  }

  // Valida tokens
  if (config.asaasMasterAccessToken.length < 10) {
    errors.push('ASAAS_MASTER_ACCESS_TOKEN parece inválido');
  }

  if (config.encryptionSecret.length < 32) {
    errors.push('ENCRYPTION_SECRET deve ter pelo menos 32 caracteres');
  }

  return {
    isValid: errors.length === 0,
    errors
  };
}
