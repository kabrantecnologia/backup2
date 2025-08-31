import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.ts'
import { createLogger, LogLevel } from '../_shared/logger.ts'
import { getServiceRoleKey } from '../_shared/env.ts'

// Declaração para o ambiente Deno
declare const Deno: any;

// Inicializa o logger para esta função
const logger = createLogger({
  name: 'AsaasAccountCreate',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

// Função para remover campos vazios ou nulos de um objeto
function removeEmptyFields(obj: Record<string, any>): Record<string, any> {
  return Object.entries(obj).reduce((acc, [key, value]) => {
    if (value !== null && value !== undefined && value !== '') {
      acc[key] = value
    }
    return acc
  }, {} as Record<string, any>)
}

// Função para gerar token seguro para o webhook
const generateWebhookToken = (): string => {
  // Gera uma string aleatória de 14 caracteres
  return Array.from({length: 14}, () => 
    '0123456789abcdef'[Math.floor(Math.random() * 16)]
  ).join('')
}

// Constants for AES-GCM encryption
const PBKDF2_SALT_STRING = "4BGEdKWWwHuUvfrXjqu5iKCEQbo1aG7Mu9difS36UXzmtm9TRj0Y2oLMIkqep40q"
const PBKDF2_ITERATIONS = 100000
const ENCRYPTION_ALGORITHM = "AES-GCM"
const KEY_LENGTH = 256
const IV_LENGTH_BYTES = 12

// Helper function to convert ArrayBuffer to Base64 string
function arrayBufferToBase64(buffer: ArrayBuffer): string {
  let binary = ''
  const bytes = new Uint8Array(buffer)
  const len = bytes.byteLength
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i])
  }
  return btoa(binary)
}

// Função para criptografar a API Key usando AES-GCM com PBKDF2
async function encryptApiKey(apiKey: string, masterSecret: string): Promise<string> {
  try {
    const encoder = new TextEncoder()
    const salt = encoder.encode(PBKDF2_SALT_STRING)
    const secretData = encoder.encode(masterSecret)

    // Importa a chave mestre para PBKDF2
    const pbkdf2ImportedKey = await crypto.subtle.importKey(
      "raw",
      secretData,
      { name: "PBKDF2" },
      false,
      ["deriveKey"]
    )

    // Deriva a chave de criptografia usando PBKDF2
    const derivedEncryptionKey = await crypto.subtle.deriveKey(
      {
        name: "PBKDF2",
        salt: salt,
        iterations: PBKDF2_ITERATIONS,
        hash: "SHA-256",
      },
      pbkdf2ImportedKey,
      { name: ENCRYPTION_ALGORITHM, length: KEY_LENGTH },
      false,
      ["encrypt"]
    )

    // Gera um vetor de inicialização aleatório
    const iv = crypto.getRandomValues(new Uint8Array(IV_LENGTH_BYTES))

    // Codifica a chave da API para ArrayBuffer
    const apiKeyData = encoder.encode(apiKey)

    // Criptografa os dados
    const encryptedApiKeyBuffer = await crypto.subtle.encrypt(
      {
        name: ENCRYPTION_ALGORITHM,
        iv: iv,
      },
      derivedEncryptionKey,
      apiKeyData
    )

    // Combina IV e texto cifrado
    const combinedBuffer = new Uint8Array(iv.length + encryptedApiKeyBuffer.byteLength)
    combinedBuffer.set(iv, 0)
    combinedBuffer.set(new Uint8Array(encryptedApiKeyBuffer), iv.length)

    // Converte para Base64
    return arrayBufferToBase64(combinedBuffer.buffer)
  } catch (error) {
    logger.error('Erro ao criptografar API Key com AES-GCM', { error: error.message, stack: error.stack })
    throw new Error(`Falha na criptografia da API Key: ${error.message || error}`)
  }
}

// Função para converter os tipos de empresa do Tricket para os tipos aceitos pelo Asaas
function convertCompanyTypeToAsaas(companyType: string): string {
  // Tipos aceitos pelo Asaas: LIMITED, ASSOCIATION, INDIVIDUAL, MEI
  switch (companyType) {
    case 'MEI':
      return 'MEI';
    case 'LTDA':
      return 'LIMITED';
    case 'SA':
      return 'LIMITED';
    case 'EIRELI':
      return 'LIMITED';
    case 'ASSOCIATION':
      return 'ASSOCIATION';
    case 'COOPERATIVE':
      return 'ASSOCIATION';
    default:
      logger.warn('Tipo de empresa desconhecido, usando LIMITED como padrão', { originalType: companyType });
      return 'LIMITED';
  }
}

// Função principal do Edge Function
serve(async (req) => {
  logger.info('Requisição recebida', { method: req.method, url: req.url })
  
  try {
    // Configuração inicial do cliente Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    
    // Obtém a SERVICE_ROLE_KEY do ambiente ou do arquivo .env
    logger.info('Buscando SERVICE_ROLE_KEY do ambiente ou arquivo .env')
    const serviceRoleKey = await getServiceRoleKey()
    
    if (!serviceRoleKey) {
      logger.error('SERVICE_ROLE_KEY não encontrada no ambiente nem no arquivo .env')
      return new Response(
        JSON.stringify({ 
          error: 'Configuração incompleta',
          details: 'SERVICE_ROLE_KEY não está disponível'
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    logger.info('SERVICE_ROLE_KEY obtida com sucesso')
    
    // Cria cliente Supabase com a chave de serviço obtida
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false }
    })
    
    // Obtém as chaves necessárias do vault usando o cliente com SERVICE_ROLE_KEY
    logger.info('Buscando chaves adicionais do vault')
    let vaultKeys;
    try {
      vaultKeys = await getRequiredVaultKeys(supabase)
      const { isValid, missingKeys } = validateRequiredKeys(vaultKeys)
      
      if (!isValid) {
        logger.error('Algumas chaves obrigatórias não encontradas no vault', { missingKeys })
        return new Response(
          JSON.stringify({ 
            error: 'Configuração incompleta',
            details: `As seguintes chaves não foram encontradas: ${missingKeys.join(', ')}`
          }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
      }
      
      logger.info('Chaves do vault obtidas com sucesso')
    } catch (error) {
      logger.error('Erro ao buscar chaves do vault', { error: error.message })
      return new Response(
        JSON.stringify({ 
          error: 'Erro de configuração',
          details: `Erro ao acessar o vault: ${error.message}`
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    // Extrai as chaves do vault para variáveis locais
    const {
      ASAAS_MASTER_ACCESS_TOKEN: asaasToken,
      ENCRYPTION_SECRET: encryptionSecret,
      API_EXTERNAL_URL: apiExternalUrl
    } = vaultKeys
    
    logger.info('Criando cliente Supabase com SERVICE_ROLE_KEY')
    
    // Verificação de autenticação e permissões
    const authHeader = req.headers.get('Authorization')
    const token = authHeader?.split(' ')[1]
    
    logger.debug('Verificando autenticação', { headerPresent: !!authHeader, tokenPresent: !!token })
    
    if (!token) {
      logger.warn('Token de autenticação não fornecido')
      return new Response(
        JSON.stringify({ error: 'Token de autenticação não fornecido' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 1. Verificar se o usuário é ADMIN
    logger.info('Verificando autenticação do usuário')
    const { data: { user }, error: userError } = await supabase.auth.getUser(token)
    if (userError || !user) {
      logger.warn('Usuário não autenticado', { error: userError?.message })
      return new Response(
        JSON.stringify({ error: 'Não autenticado', details: userError?.message }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 2. Verificar permissão de ADMIN
    const { data: roleData, error: roleError } = await supabase
      .from('role_check')
      .select('role_name')
      .eq('user_id', user.id)
      .in('role_name', ['ADMIN', 'SUPER_ADMIN'])
      .single()

    if (roleError || !roleData) {
      logger.warn('Usuário sem permissão de administrador', { userId: user.id, error: roleError?.message })
      return new Response(
        JSON.stringify({ error: 'Acesso negado', details: 'Você não tem permissão para executar esta ação' }),
        { status: 403, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 3. Obter dados do perfil
    logger.info('Obtendo dados do payload')
    
    let payload;
    let profile_id;
    let profile_type;
    
    try {
      // Armazena o corpo da requisição para debug
      const rawBody = await req.text();
      logger.debug('Corpo bruto da requisição', { rawBody });
      
      // Tenta fazer parse do JSON
      payload = rawBody ? JSON.parse(rawBody) : {};
      logger.info('Payload recebido', { payload, contentType: req.headers.get('content-type') });
      
      profile_id = payload.profile_id;
      profile_type = payload.profile_type;
      
      if (!profile_id || !profile_type) {
        logger.warn('Dados inválidos no payload', { 
          payload,
          headers: Object.fromEntries(req.headers.entries()),
          method: req.method,
          url: req.url
        });
        return new Response(
          JSON.stringify({ error: 'Dados inválidos', details: 'profile_id e profile_type são obrigatórios' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
    } catch (error) {
      logger.error('Erro ao processar payload', { 
        error: error.message, 
        stack: error.stack,
        headers: Object.fromEntries(req.headers.entries()),
        method: req.method
      });
      return new Response(
        JSON.stringify({ error: 'Erro ao processar payload', details: error.message }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 4. Buscar dados do perfil
    const { data: profiles, error: profilesError } = await supabase
      .from('view_admin_profile_approval')
      .select('*')
      .eq('profile_id', profile_id)
      .order('profile_type', { ascending: false })

    if (profilesError || !profiles || profiles.length === 0) {
      logger.error('Perfil não encontrado', { profileId: profile_id, error: profilesError?.message })
      return new Response(
        JSON.stringify({ 
          error: 'Perfil não encontrado', 
          details: profilesError?.message || 'Nenhum perfil encontrado com o ID fornecido' 
        }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 5. Processar o perfil
    const profile = profiles.find(p => p.profile_type === 'ORGANIZATION') || profiles[0]
    const isOrganization = profile.profile_type === 'ORGANIZATION'
    
    logger.info('Processando perfil', { 
      profileId: profile_id, 
      profileType: profile.profile_type, 
      isOrganization 
    })

    // 6. Gerar token único para o webhook
    const webhookToken = generateWebhookToken()
    logger.info('Token de webhook gerado', { tokenPrefix: webhookToken.substring(0, 4) + '...' })

    // 7. Criar payload para o Asaas
    const asaasPayload: any = removeEmptyFields({
      name: profile.name,
      email: profile.email,
      // Formatar e validar CPF/CNPJ - deve ter 11 dígitos (CPF) ou 14 dígitos (CNPJ)
      cpfCnpj: (() => {
        if (!profile.cpf_cnpj) {
          logger.error('CPF/CNPJ não informado');
          throw new Error('CPF/CNPJ não informado');
        }

        const cleaned = profile.cpf_cnpj.replace(/\D/g, '');
        const expectedLength = isOrganization ? 14 : 11;

        // Validar se tem o número correto de dígitos baseado no tipo
        if (cleaned.length !== expectedLength) {
          const message = `CPF/CNPJ com formato inválido: esperado ${expectedLength} dígitos, recebido ${cleaned.length}`;
          logger.error(message, { 
            expected: expectedLength,
            actual: cleaned.length, 
            masked: cleaned.substring(0, 3) + '...' 
          });
          throw new Error(message);
        }

        // Documentação da API Asaas:
        // CPF: apenas números, 11 dígitos
        // CNPJ: apenas números, 14 dígitos
        logger.info('CPF/CNPJ validado com sucesso', { type: isOrganization ? 'CNPJ' : 'CPF', length: cleaned.length });
        return cleaned;
      })(),
      mobilePhone: (profile.mobile_phone || '')
        .replace(/\D/g, '')
        .replace(/^55/, '')
        .replace(/^(\d{2})(\d{4,5})(\d{4})$/, '$1$2$3'),
      incomeValue: (() => {
        // Log para debug do valor original
        logger.info('Valor de renda/faturamento:', {
          income_value_cents: profile.income_value_cents,
          tipo: typeof profile.income_value_cents
        });
        
        // Corrigir o nome do campo e garantir que seja um número válido maior que zero
        const valorCents = parseInt(profile.income_value_cents || '0', 10);
        
        if (isNaN(valorCents) || valorCents <= 0) {
          // Se for inválido ou zero, usar um valor mínimo
          logger.info('Usando valor padrão para incomeValue pois o valor original é inválido ou zero');
          return 1000;
        }
        
        // Converter de centavos para reais
        return valorCents / 100;
      })(),
      address: profile.address || 'Endereço não informado',
      addressNumber: profile.address_number || 'S/N',
      ...(profile.complement && { complement: profile.complement }),
      province: profile.province || 'Centro',
      postalCode: (profile.postal_code || '00000000').replace(/\D/g, '')
    })

    // Adicionar campos específicos para PJ ou PF
    if (isOrganization && profile.company_type) {
      asaasPayload.companyType = convertCompanyTypeToAsaas(profile.company_type);
    } else if (!isOrganization && profile.birth_date) {
      asaasPayload.birthDate = profile.birth_date.split('T')[0]
    }

    // Configurar webhooks
    const webhookAccountStatusUrl = `${apiExternalUrl}/functions/v1/asaas_webhook_account_status`
    const webhookTransferStatusUrl = `${apiExternalUrl}/functions/v1/asaas_webhook_transfer_status`
    
    logger.info('URLs de webhook configuradas', { 
      webhookAccountStatusUrl, 
      webhookTransferStatusUrl 
    })
    
    asaasPayload.webhooks = [
      {
        name: "AccountStatus",
        url: webhookAccountStatusUrl,
        email: "baas@tricket.com.br",
        enabled: true,
        interrupted: false,
        authToken: webhookToken,
        sendType: "SEQUENTIALLY",
        events: [
          "ACCOUNT_STATUS_BANK_ACCOUNT_INFO_APPROVED",
          "ACCOUNT_STATUS_BANK_ACCOUNT_INFO_AWAITING_APPROVAL",
          "ACCOUNT_STATUS_BANK_ACCOUNT_INFO_PENDING",
          "ACCOUNT_STATUS_BANK_ACCOUNT_INFO_REJECTED",
          "ACCOUNT_STATUS_COMMERCIAL_INFO_APPROVED",
          "ACCOUNT_STATUS_COMMERCIAL_INFO_AWAITING_APPROVAL",
          "ACCOUNT_STATUS_COMMERCIAL_INFO_PENDING",
          "ACCOUNT_STATUS_COMMERCIAL_INFO_REJECTED",
          "ACCOUNT_STATUS_DOCUMENT_APPROVED",
          "ACCOUNT_STATUS_DOCUMENT_AWAITING_APPROVAL",
          "ACCOUNT_STATUS_DOCUMENT_PENDING",
          "ACCOUNT_STATUS_DOCUMENT_REJECTED",
          "ACCOUNT_STATUS_GENERAL_APPROVAL_APPROVED",
          "ACCOUNT_STATUS_GENERAL_APPROVAL_AWAITING_APPROVAL",
          "ACCOUNT_STATUS_GENERAL_APPROVAL_PENDING",
          "ACCOUNT_STATUS_GENERAL_APPROVAL_REJECTED"
        ]
      },
      {
        name: "TransferStatus",
        url: webhookTransferStatusUrl,
        email: "baas@tricket.com.br",
        enabled: true,
        interrupted: false,
        authToken: webhookToken, // Usa o mesmo token para ambos os webhooks
        sendType: "SEQUENTIALLY",
        events: [
          "TRANSFER_CREATED",
          "TRANSFER_PENDING",
          "TRANSFER_IN_BANK_PROCESSING",
          "TRANSFER_BLOCKED",
          "TRANSFER_DONE",
          "TRANSFER_FAILED",
          "TRANSFER_CANCELLED"
        ]
      }
    ]

    logger.info('Enviando requisição para a API Asaas', {
      name: asaasPayload.name,
      email: asaasPayload.email,
      cpfCnpj: asaasPayload.cpfCnpj?.substring(0, 3) + '...',
      webhooks: asaasPayload.webhooks.map(w => w.name)
    })

    // 8. Chamar API do Asaas para criar a conta
    let asaasResponse: Response
    let responseData: any
    
    try {
      asaasResponse = await fetch('https://api-sandbox.asaas.com/v3/accounts', {
        method: 'POST',
        headers: {
          'accept': 'application/json',
          'access_token': asaasToken!,
          'content-type': 'application/json'
        },
        body: JSON.stringify(asaasPayload)
      })
      
      responseData = await asaasResponse.json()
      
      if (!asaasResponse.ok) {
        logger.error('Erro na resposta da API Asaas', { 
          status: asaasResponse.status, 
          response: responseData 
        })
        throw new Error(`Erro ao criar conta no Asaas (${asaasResponse.status}): ${JSON.stringify(responseData)}`)
      }
      
      logger.info('Conta criada com sucesso no Asaas', { 
        asaasId: responseData.id, 
        walletId: responseData.walletId, 
        status: responseData.status 
      })
      
      // Extrair dados bancários da resposta, se disponíveis
      logger.info('Verificando dados bancários na resposta', {
        hasBankData: !!responseData.bankAccount
      });
      
      // 9. Criptografar a API Key retornada
      logger.info('Iniciando processo de criptografia da API Key')
      const encryptedApiKey = await encryptApiKey(responseData.apiKey, encryptionSecret!)
      
      // 10. Salvar os dados da conta no banco de dados
      logger.info('Inserindo dados da conta no banco de dados', { profileId: profile_id, asaasId: responseData.id });
      
      // Gerar um token único para autenticação de webhooks
      const webhookAuthToken = crypto.randomUUID();
      
      // Inserir os dados da conta no banco
      const { data: insertedAccount, error: insertError } = await supabase
        .from('asaas_accounts')
        .insert({
          profile_id: profile_id,
          asaas_id: responseData.id,
          wallet_id: responseData.walletId,
          apikey: encryptedApiKey,
          agency: responseData.bankAccount?.agency || '',  // Usar dados bancários da resposta
          account: responseData.bankAccount?.account || '', 
          account_digit: responseData.bankAccount?.accountDigit || '',
          webhook_auth_token: webhookAuthToken,
          status_general: 'PENDING',
          status_bank: 'PENDING',
          status_commercial: 'PENDING',
          status_document: 'PENDING'
        })
        .select('*')
        .single();

      if (insertError) {
        logger.error('Erro ao salvar conta no banco de dados', { 
          error: insertError.message, 
          details: insertError.details, 
          code: insertError.code 
        })
        throw new Error(`Erro ao salvar conta: ${insertError.message}`)
      }

      // 11. Retornar resposta de sucesso
      logger.info('Processo de criação de conta finalizado com sucesso', { 
        profileId: profile_id, 
        asaasId: responseData.id, 
        accountDataId: insertedAccount?.id 
      })
      
      return new Response(
        JSON.stringify({ 
          success: true,
          message: 'Conta criada com sucesso',
          data: {
            profile_id: profile_id,
            profile_type: profile_type,
            asaas_account_id: responseData.id,
            wallet_id: responseData.walletId,
            status: responseData.status,
            webhook_url: webhookAccountStatusUrl,
            webhook_auth_token: webhookAuthToken,
            account_data: insertedAccount
          }
        }),
        { 
          status: 200,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
          } 
        }
      )
    } catch (error) {
      logger.error('Erro na requisição para a API Asaas', { 
        error: error.message, 
        stack: error.stack 
      })
      throw new Error(`Falha ao se comunicar com a API do Asaas: ${error.message}`)
    }
  } catch (error) {
    const errorId = crypto.randomUUID()
    logger.critical('Erro inesperado ao processar requisição', {
      errorId,
      message: error.message,
      stack: error.stack
    })
    return new Response(
      JSON.stringify({ 
        success: false,
        error: 'Erro interno do servidor', 
        details: error.message 
      }),
      { 
        status: 500, 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
        } 
      }
    )
  }
})
