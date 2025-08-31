/**
 * Utilitário para ler variáveis de ambiente do arquivo .env
 */

// Declaração para o ambiente Deno
declare const Deno: any;

// Importa funções do sistema de arquivos do Deno
const decoder = new TextDecoder('utf-8');

/**
 * Lê o arquivo .env e extrai as variáveis de ambiente
 * @returns Um objeto com as variáveis de ambiente do arquivo .env
 */
export async function readEnvFile(): Promise<Record<string, string>> {
  try {
    // Caminho para o arquivo .env (um nível acima na estrutura plana)
    const envPath = '../.env';
    
    // Tenta ler o arquivo .env
    const envFile = await Deno.readFile(envPath);
    const envContent = decoder.decode(envFile);
    
    // Processa o conteúdo e extrai as variáveis
    const envVars: Record<string, string> = {};
    
    envContent.split('\n').forEach(line => {
      // Ignora linhas em branco e comentários
      if (!line || line.startsWith('#')) return;
      
      // Extrai a chave e o valor
      const match = line.match(/^\s*([\w.-]+)\s*=\s*(.*)?\s*$/);
      if (match) {
        const key = match[1];
        let value = match[2] || '';
        
        // Remove aspas se existirem
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.slice(1, -1);
        }
        
        envVars[key] = value;
      }
    });
    
    return envVars;
  } catch (error) {
    console.error('Erro ao ler arquivo .env:', error);
    return {};
  }
}

/**
 * Obtém uma variável específica do arquivo .env
 * @param key Nome da variável
 * @returns O valor da variável ou undefined se não encontrada
 */
export async function getEnvVar(key: string): Promise<string | undefined> {
  // Tenta primeiro via Deno.env, pois é mais rápido
  const envValue = Deno.env.get(key);
  if (envValue) return envValue;
  
  // Se não encontrou, tenta via arquivo .env
  try {
    const envVars = await readEnvFile();
    return envVars[key];
  } catch (error) {
    console.error(`Erro ao obter variável ${key} do arquivo .env:`, error);
    return undefined;
  }
}

/**
 * Obtém a SERVICE_ROLE_KEY do ambiente ou do arquivo .env
 * @returns A SERVICE_ROLE_KEY ou undefined se não encontrada
 */
export async function getServiceRoleKey(): Promise<string | undefined> {
  // Tenta obter do ambiente primeiro
  const fromEnv = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (fromEnv) return fromEnv;
  
  // Tenta obter do arquivo .env (pode estar com nome diferente)
  const envVars = await readEnvFile();
  
  // Tenta vários nomes possíveis para a chave
  const possibleKeys = [
    'SUPABASE_SERVICE_ROLE_KEY',
    'SERVICE_ROLE_KEY',
    'ANON_KEY',
    'SUPABASE_KEY'
  ];
  
  for (const key of possibleKeys) {
    if (envVars[key]) return envVars[key];
  }
  
  return undefined;
}
