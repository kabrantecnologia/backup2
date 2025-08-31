// supabase/functions/asaas_transfer_create/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.js';
import { getServiceRoleKey } from '../_shared/env.js';

// URL da API Asaas (sandbox ou produção)
const ASAAS_API_URL = 'https://api-sandbox.asaas.com/v3';

// Declare Deno para evitar erros de lint
declare const Deno: any;

// Headers para CORS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// Interface para payload de transferência
interface TransferPayload {
  value: number;
  payerProfileId: string;
  receiverProfileId: string;
  description?: string;
}

// Configuração de log simplificada
enum LogLevel {
  INFO = 'INFO',
  WARN = 'WARN',
  ERROR = 'ERROR',
  CRITICAL = 'CRITICAL',
  DEBUG = 'DEBUG'
}

// Constantes para AES-GCM de/criptografia
const PBKDF2_SALT_STRING = "4BGEdKWWwHuUvfrXjqu5iKCEQbo1aG7Mu9difS36UXzmtm9TRj0Y2oLMIkqep40q";
const PBKDF2_ITERATIONS = 100000;
const ENCRYPTION_ALGORITHM = "AES-GCM";
const KEY_LENGTH = 256;
const IV_LENGTH = 12; // AES-GCM standard IV length is 12 bytes

// Função para descriptografar a API Key do Asaas
async function decryptApiKey(encryptedBase64ApiKey: string, masterSecret: string): Promise<string> {
  if (!masterSecret) {
    throw new Error('Master secret is required for decryption.');
  }

  try {
    const encoder = new TextEncoder();
    const salt = encoder.encode(PBKDF2_SALT_STRING);
    const secretData = encoder.encode(masterSecret);

    // Importa a chave mestre para PBKDF2
    const pbkdf2ImportedKey = await crypto.subtle.importKey(
      "raw",
      secretData,
      { name: "PBKDF2" },
      false,
      ["deriveKey"]
    );

    // Deriva a chave de decriptografia usando PBKDF2
    const derivedDecryptionKey = await crypto.subtle.deriveKey(
      {
        name: "PBKDF2",
        salt: salt,
        iterations: PBKDF2_ITERATIONS,
        hash: "SHA-256",
      },
      pbkdf2ImportedKey,
      { name: ENCRYPTION_ALGORITHM, length: KEY_LENGTH },
      false,
      ["decrypt"]
    );

    // Decodifica o dado criptografado de Base64 para ArrayBuffer
    const encryptedData = Uint8Array.from(atob(encryptedBase64ApiKey), c => c.charCodeAt(0));
    
    // Extrai o IV e o texto cifrado
    const iv = encryptedData.slice(0, IV_LENGTH);
    const ciphertext = encryptedData.slice(IV_LENGTH);

    // Descriptografa os dados
    const decryptedBuffer = await crypto.subtle.decrypt(
      {
        name: ENCRYPTION_ALGORITHM,
        iv: iv,
      },
      derivedDecryptionKey,
      ciphertext
    );

    // Converte o buffer descriptografado para string
    return new TextDecoder().decode(decryptedBuffer);
  } catch (error) {
    logger.error('Erro ao descriptografar API key', { message: error.message, stack: error.stack });
    throw new Error('Failed to decrypt API key. Check encryption/decryption parameters and secrets.');
  }
}

// Inicialização do logger
const logger = {
  _formatMessage: (level: LogLevel, message: string, data?: any) => {
    const timestamp = new Date().toISOString();
    const dataStr = data ? ` | ${JSON.stringify(data)}` : '';
    return `[${timestamp}] [${level}] [AsaasTransferCreate] ${message}${dataStr}`;
  },
  info: (message: string, data?: any) => {
    console.log(logger._formatMessage(LogLevel.INFO, message, data));
  },
  warn: (message: string, data?: any) => {
    console.warn(logger._formatMessage(LogLevel.WARN, message, data));
  },
  error: (message: string, data?: any) => {
    console.error(logger._formatMessage(LogLevel.ERROR, message, data));
  },
  critical: (message: string, data?: any) => {
    console.error(logger._formatMessage(LogLevel.CRITICAL, message, data));
  },
  debug: (message: string, data?: any) => {
    console.debug(logger._formatMessage(LogLevel.DEBUG, message, data));
  }
};

// Função para remover campos vazios do objeto
const removeEmptyFields = (obj: any): any => {
  return Object.fromEntries(
    Object.entries(obj).filter(([_, v]) => v != null && v !== '')
  );
};

// Função para gerar um ID único para identificação de erros
const generateErrorId = (): string => {
  return crypto.randomUUID();
};

// Função principal para processar a requisição
serve(async (req: Request) => {
  // Log da requisição recebida
  logger.info('Requisição recebida', { 
    method: req.method, 
    url: req.url 
  });

  // Verificar se é uma requisição OPTIONS (pré-voo CORS)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Verificar se a requisição é POST
    if (req.method !== 'POST') {
      logger.warn('Método não permitido', { method: req.method });
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 2. Obter a SERVICE_ROLE_KEY
    logger.info('Buscando SERVICE_ROLE_KEY do ambiente ou arquivo .env');
    const serviceRoleKey = await getServiceRoleKey();
    logger.info('SERVICE_ROLE_KEY obtida com sucesso');

    // 3. Configurar cliente Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    
    // Inicializa cliente Supabase com a SERVICE_ROLE_KEY obtida
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false }
    });

    // 4. Buscar chaves adicionais do vault
    logger.info('Buscando chaves adicionais do vault');
    const vaultKeys = await getRequiredVaultKeys(supabase);
    const { isValid, missingKeys } = validateRequiredKeys(vaultKeys);
    
    if (!isValid) {
      logger.error('Chaves obrigatórias não encontradas no vault', { missingKeys });
      return new Response(
        JSON.stringify({ 
          error: 'Configuração incompleta',
          details: `As seguintes chaves não foram encontradas: ${missingKeys.join(', ')}`
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    logger.info('Chaves do vault obtidas com sucesso');

    // 5. Verificar autenticação do usuário
    logger.info('Verificando autenticação do usuário');
    const token = req.headers.get('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      logger.warn('Token de autenticação não fornecido');
      return new Response(
        JSON.stringify({ error: 'Unauthorized: Bearer token is required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Verificar token JWT
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      logger.warn('Usuário não autenticado', { error: authError?.message });
      return new Response(
        JSON.stringify({ error: 'Unauthorized: Invalid token', details: authError?.message }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 6. Obter o payload da requisição
    logger.info('Obtendo dados do payload');
    let payload: TransferPayload;
    
    try {
      payload = await req.json();
    } catch (error) {
      logger.error('Erro ao processar o JSON do payload', { error: error.message });
      return new Response(
        JSON.stringify({ error: 'Invalid request payload' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 7. Validar os campos obrigatórios
    const { value, payerProfileId, receiverProfileId, description } = payload;
    
    if (!value || value <= 0) {
      logger.error('Valor de transferência inválido', { value });
      return new Response(
        JSON.stringify({ error: 'Invalid transfer value' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!payerProfileId) {
      logger.error('ID do perfil pagador não informado');
      return new Response(
        JSON.stringify({ error: 'Payer profile ID is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!receiverProfileId) {
      logger.error('ID do perfil recebedor não informado');
      return new Response(
        JSON.stringify({ error: 'Receiver profile ID is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 8. Verificar se o usuário tem permissão para usar o perfil pagador
    logger.info('Verificando permissões para o perfil pagador', { payerProfileId });
    const { data: payerPermission, error: payerPermissionError } = await supabase
      .rpc('check_profile_permission', { 
        p_profile_id: payerProfileId, 
        p_user_id: user.id 
      });

    if (payerPermissionError || !payerPermission) {
      logger.error('Usuário não tem permissão para o perfil pagador', { 
        userId: user.id, 
        profileId: payerProfileId, 
        error: payerPermissionError?.message 
      });
      return new Response(
        JSON.stringify({ error: 'No permission for payer profile', details: payerPermissionError?.message }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 9. Buscar informações das contas Asaas do pagador e recebedor
    logger.info('Buscando conta Asaas do pagador', { profileId: payerProfileId });
    const { data: payerAccountData, error: payerAccountError } = await supabase
      .from('asaas_accounts')
      .select('asaas_id, apikey, wallet_id')
      .eq('profile_id', payerProfileId)
      .single();

    if (payerAccountError || !payerAccountData) {
      logger.error('Conta Asaas do pagador não encontrada', { 
        profileId: payerProfileId, 
        error: payerAccountError?.message 
      });
      return new Response(
        JSON.stringify({ error: 'Payer Asaas account not found', details: payerAccountError?.message }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    logger.info('Buscando conta Asaas do recebedor', { profileId: receiverProfileId });
    const { data: receiverAccountData, error: receiverAccountError } = await supabase
      .from('asaas_accounts')
      .select('wallet_id')
      .eq('profile_id', receiverProfileId)
      .single();

    if (receiverAccountError || !receiverAccountData) {
      logger.error('Conta Asaas do recebedor não encontrada', { 
        profileId: receiverProfileId, 
        error: receiverAccountError?.message 
      });
      return new Response(
        JSON.stringify({ error: 'Receiver Asaas account not found', details: receiverAccountError?.message }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 10. Decriptografar a API key do pagador
    let asaasApiKey = payerAccountData.apikey;
    
    try {
      // Descriptografar a API key usando a função implementada
      asaasApiKey = await decryptApiKey(payerAccountData.apikey, vaultKeys.ENCRYPTION_SECRET!);
      logger.info('API key do pagador descriptografada com sucesso');
    } catch (error) {
      logger.error('Erro ao descriptografar API key do pagador', { error: error.message });
      return new Response(
        JSON.stringify({ error: 'Failed to decrypt API key', details: error.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Obter o wallet_id do recebedor
    const receiverWalletId = receiverAccountData.wallet_id;
    logger.info('Wallet ID do recebedor obtido com sucesso', { 
      walletIdPrefix: receiverWalletId.substring(0, 8) + '...' 
    });

    // 10. Preparar payload para a requisição à API Asaas
    const referenceCode = `transfer-${Date.now()}`;
    const transferPayload = removeEmptyFields({
      value,
      walletId: receiverWalletId,
      externalReference: referenceCode,
      description: description || 'Transferência entre contas'
    });

    // 11. Realizar a transferência via API Asaas
    try {
      // Log detalhado do payload completo (redacted para valores sensíveis)
      logger.info('Enviando solicitação de transferência para a API Asaas', { 
        payload: {
          value: transferPayload.value,
          walletId: transferPayload.walletId ? transferPayload.walletId.substring(0, 8) + '...' : null,
          description: transferPayload.description,
          externalReference: transferPayload.externalReference
        },
        url: `${ASAAS_API_URL}/transfers`,
        apiKeyFirstChars: asaasApiKey ? asaasApiKey.substring(0, 5) + '...' : 'null'
      });

      // Log do payload JSON para debug
      logger.debug('JSON payload', { 
        json: JSON.stringify(transferPayload, null, 2)
      });

      // Faz a requisição para a API Asaas
      const asaasResponse = await fetch(
        `${ASAAS_API_URL}/transfers`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'access_token': asaasApiKey
          },
          body: JSON.stringify(transferPayload)
        }
      );
      
      // Log detalhado da resposta HTTP antes de processar o JSON
      logger.info('Resposta recebida da API Asaas', { 
        status: asaasResponse.status, 
        statusText: asaasResponse.statusText,
        headers: Object.fromEntries(asaasResponse.headers.entries())
      });
      
      // Obter o texto da resposta primeiro para diagnóstico
      const responseText = await asaasResponse.text();
      logger.debug('Corpo da resposta (texto)', { responseText });
      
      let asaasData;
      try {
        // Tentar fazer parse do JSON apenas se houver conteúdo
        asaasData = responseText ? JSON.parse(responseText) : null;
      } catch (parseError) {
        logger.error('Erro ao fazer parse do JSON da resposta', { 
          error: parseError.message,
          responseText: responseText ? (responseText.length > 100 ? responseText.substring(0, 100) + '...' : responseText) : null,
          responseLength: responseText ? responseText.length : 0
        });
        return new Response(
          JSON.stringify({ error: 'Erro ao processar resposta da API Asaas', details: parseError.message }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      
      if (!asaasResponse.ok) {
        logger.error('Erro na resposta da API Asaas', { 
          status: asaasResponse.status,
          statusText: asaasResponse.statusText,
          data: asaasData
        });
        return new Response(
          JSON.stringify({ error: 'Asaas API error', details: asaasData }),
          { status: asaasResponse.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      
      logger.info('Transferência criada com sucesso na API Asaas', { 
        id: asaasData.id,
        status: asaasData.status 
      });

      // 12. Registrar a transferência no banco de dados com a nova estrutura
      const { data: transferData, error: transferError } = await supabase
        .from('asaas_transfers')
        .insert({
          asaas_transfer_id: asaasData.id,
          payer_profile_id: payerProfileId,
          receiver_profile_id: receiverProfileId,
          value: asaasData.value,
          description: description || 'Transferência entre contas',
          status: asaasData.status
        })
        .select()
        .single();

      if (transferError) {
        logger.error('Erro ao salvar transferência no banco de dados', { 
          error: transferError.message,
          details: transferError 
        });
        // Não retornar erro para o usuário, pois a transferência já foi realizada na API
        // Apenas registrar o erro para investigação posterior
      } else {
        logger.info('Transferência registrada com sucesso no banco de dados', { 
          id: transferData.id 
        });
      }

      // 13. Retornar resposta de sucesso
      return new Response(
        JSON.stringify({
          success: true,
          transferId: asaasData.id,
          status: asaasData.status,
          message: 'Transferência criada com sucesso'
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    } catch (error) {
      logger.error('Erro na requisição para a API Asaas', { 
        error: error.message
      });
      return new Response(
        JSON.stringify({ error: 'Failed to create transfer', details: error.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
  } catch (error) {
    // Tratamento de erros inesperados
    const errorId = generateErrorId();
    logger.critical('Erro inesperado ao processar requisição', { 
      errorId, 
      message: error.message,
      stack: error.stack
    });

    return new Response(
      JSON.stringify({ 
        error: 'Internal server error', 
        errorId,
        message: 'Ocorreu um erro inesperado ao processar a requisição.'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
