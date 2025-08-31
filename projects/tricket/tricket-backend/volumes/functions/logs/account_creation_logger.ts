/**
 * Logger para credenciais de criação de contas Asaas
 * 
 * OBJETIVO: Facilitar acesso às credenciais para operações manuais
 * ⚠️  REMOVER EM PRODUÇÃO - uso temporário para debugging
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

interface AccountCredentials {
  profile_id: string;
  asaas_account_id: string;
  webhook_token: string;
  api_key: string;
  wallet_id: string;
  created_at: string;
  environment: string;
}

interface LoggerConfig {
  supabaseUrl: string;
  supabaseServiceRoleKey: string;
}

/**
 * Salva credenciais da conta criada para acesso fácil
 * 
 * @param config Configuração do Supabase
 * @param credentials Credenciais da conta Asaas
 */
export async function logAccountCredentials(
  config: LoggerConfig,
  credentials: AccountCredentials
): Promise<void> {
  const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey);
  
  const logEntry = {
    ...credentials,
    logged_at: new Date().toISOString(),
    purpose: 'DEBUG_ACCOUNT_CREDENTIALS',
    warning: 'REMOVER_EM_PRODUCAO'
  };

  try {
    const { error } = await supabase
      .from('debug_account_credentials')
      .insert(logEntry);

    if (error) {
      console.error('Erro ao logar credenciais:', error.message);
    } else {
      console.log('✅ Credenciais salvas no log de debug');
    }
  } catch (error) {
    console.error('Erro crítico ao logar credenciais:', error);
  }
}

/**
 * Busca credenciais por profile_id ou asaas_account_id
 * 
 * @param config Configuração do Supabase
 * @param identifier profile_id ou asaas_account_id
 */
export async function getAccountCredentials(
  config: LoggerConfig,
  identifier: string
): Promise<AccountCredentials | null> {
  const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey);
  
  try {
    const { data, error } = await supabase
      .from('debug_account_credentials')
      .select('*')
      .or(`profile_id.eq.${identifier},asaas_account_id.eq.${identifier}`)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (error) {
      console.error('Erro ao buscar credenciais:', error.message);
      return null;
    }

    return data;
  } catch (error) {
    console.error('Erro crítico ao buscar credenciais:', error);
    return null;
  }
}

/**
 * Lista todas as credenciais salvas (útil para debugging)
 * 
 * @param config Configuração do Supabase
 */
export async function listAllCredentials(
  config: LoggerConfig,
  limit: number = 10
): Promise<AccountCredentials[]> {
  const supabase = createClient(config.supabaseUrl, config.supabaseServiceRoleKey);
  
  try {
    const { data, error } = await supabase
      .from('debug_account_credentials')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) {
      console.error('Erro ao listar credenciais:', error.message);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error('Erro crítico ao listar credenciais:', error);
    return [];
  }
}
