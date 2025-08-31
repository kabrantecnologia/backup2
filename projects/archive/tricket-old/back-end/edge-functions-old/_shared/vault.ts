// Tipos para as chaves do vault
type VaultKey = 'ASAAS_MASTER_ACCESS_TOKEN' | 'ENCRYPTION_SECRET' | 'SERVICE_ROLE_KEY' | 'API_EXTERNAL_URL'

// Cache para armazenar as chaves em memória
const keyCache = new Map<VaultKey, string>()

/**
 * Obtém uma chave do vault do Supabase
 * @param keyName Nome da chave a ser obtida
 * @param supabase Cliente Supabase autenticado
 * @param useCache Se deve usar o cache em memória (padrão: true)
 * @returns Valor da chave ou undefined se não encontrada
 */
export async function getVaultKey(
  keyName: VaultKey,
  supabase: any,
  useCache = true
): Promise<string | undefined> {
  // Verifica o cache primeiro
  if (useCache && keyCache.has(keyName)) {
    console.log(`Utilizando chave ${keyName} em cache`)
    return keyCache.get(keyName)
  }

  try {
    console.log(`Tentando buscar chave ${keyName} do vault...`)
    
    // Verificar se o cliente supabase é válido
    if (!supabase || typeof supabase.rpc !== 'function') {
      console.error(`ERRO: Cliente Supabase inválido:`, supabase)
      return undefined
    }
    
    const { data, error } = await supabase.rpc('get_key', { p_key_name: keyName })
    
    if (error) {
      console.error(`ERRO DETALHADO ao buscar chave ${keyName} do vault:`, {
        mensagem: error.message,
        código: error.code,
        detalhes: error.details,
        hint: error.hint,
        statusCode: error.status || 'N/A'
      })
      return undefined
    }

    if (!data) {
      console.error(`Chave ${keyName} não encontrada no vault`)
      return undefined
    }

    console.log(`Chave ${keyName} recuperada com sucesso do vault`)
    
    // Armazena no cache
    keyCache.set(keyName, data)
    return data
  } catch (error) {
    console.error(`Erro inesperado ao buscar chave ${keyName}:`, error)
    return undefined
  }
}

/**
 * Obtém múltiplas chaves do vault de uma vez
 * @param keyNames Array com os nomes das chaves
 * @param supabase Cliente Supabase autenticado
 * @returns Objeto com as chaves e seus valores
 */
export async function getVaultKeys(
  keyNames: VaultKey[],
  supabase: any
): Promise<Record<VaultKey, string | undefined>> {
  const result: Partial<Record<VaultKey, string | undefined>> = {}
  
  // Busca cada chave em paralelo
  await Promise.all(
    keyNames.map(async (key) => {
      result[key] = await getVaultKey(key, supabase)
    })
  )
  
  return result as Record<VaultKey, string | undefined>
}

/**
 * Obtém todas as chaves necessárias para a aplicação
 * @param supabase Cliente Supabase autenticado
 * @returns Objeto com todas as chaves necessárias
 */
export async function getRequiredVaultKeys(supabase: any) {
  const requiredKeys: VaultKey[] = [
    'ASAAS_MASTER_ACCESS_TOKEN',
    'ENCRYPTION_SECRET',
    'SERVICE_ROLE_KEY',
    'API_EXTERNAL_URL'
  ]
  
  return getVaultKeys(requiredKeys, supabase)
}

/**
 * Verifica se todas as chaves necessárias estão disponíveis
 * @param keys Objeto com as chaves
 * @returns Objeto com as chaves e um booleano indicando se todas estão presentes
 */
export function validateRequiredKeys(keys: Record<string, string | undefined>) {
  const missingKeys = Object.entries(keys)
    .filter(([_, value]) => !value)
    .map(([key]) => key)
    
  return {
    isValid: missingKeys.length === 0,
    missingKeys
  }
}
