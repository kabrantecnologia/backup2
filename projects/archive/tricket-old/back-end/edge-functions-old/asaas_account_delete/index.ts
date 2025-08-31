// @deno-types="https://deno.land/x/types/deno.d.ts"
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { getRequiredVaultKeys, validateRequiredKeys } from '../_shared/vault.ts';
import { createLogger, LogLevel } from '../_shared/logger.ts';
import { getServiceRoleKey } from '../_shared/env.ts';

declare const Deno: any;

// Inicializa o logger para esta função
const logger = createLogger({
  name: 'AsaasAccountDelete',
  logDir: './logs',
  writeToFile: true,
  minLevel: LogLevel.INFO
});

// Constants for AES-GCM decryption
const PBKDF2_SALT_STRING = "4BGEdKWWwHuUvfrXjqu5iKCEQbo1aG7Mu9difS36UXzmtm9TRj0Y2oLMIkqep40q";
const PBKDF2_ITERATIONS = 100000;
const ENCRYPTION_ALGORITHM = "AES-GCM";
const KEY_LENGTH = 256;
const IV_LENGTH = 12; // AES-GCM standard IV length is 12 bytes

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

serve(async (req) => {
  logger.info('Requisição recebida', { method: req.method, url: req.url });
  
  // Configuração do CORS
  if (req.method === 'OPTIONS') {
    logger.debug('OPTIONS request recebida. Respondendo com headers CORS.');
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    });
  }

  // 1. Validar método da requisição
  if (req.method !== 'POST') {
    logger.warn('Método não permitido', { method: req.method });
    return new Response(JSON.stringify({ error: 'Método não permitido' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    // 2. Extrair dados da requisição
    const { profile_id, remove_reason } = await req.json();
    
    logger.info('Dados recebidos na requisição', { profile_id, remove_reason });

    if (!profile_id || !remove_reason) {
      logger.warn('Requisição inválida: parâmetros obrigatórios ausentes', { profile_id, remove_reason });
      return new Response(JSON.stringify({ error: 'profile_id e remove_reason são obrigatórios' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 3. Inicializar cliente Supabase com SERVICE_ROLE_KEY
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    
    // Obtém a SERVICE_ROLE_KEY do ambiente ou do arquivo .env
    logger.info('Buscando SERVICE_ROLE_KEY do ambiente ou arquivo .env');
    const serviceRoleKey = await getServiceRoleKey();
    
    if (!serviceRoleKey) {
      logger.error('SERVICE_ROLE_KEY não encontrada no ambiente nem no arquivo .env');
      return new Response(
        JSON.stringify({ 
          error: 'Configuração incompleta',
          details: 'SERVICE_ROLE_KEY não está disponível'
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    logger.info('SERVICE_ROLE_KEY obtida com sucesso');
    
    // Cria cliente Supabase com a chave de serviço obtida
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false }
    });
    
    // Obtém as chaves necessárias do vault usando o cliente com SERVICE_ROLE_KEY
    logger.info('Buscando chaves adicionais do vault');
    let vaultKeys;
    try {
      vaultKeys = await getRequiredVaultKeys(supabase);
      const { isValid, missingKeys } = validateRequiredKeys(vaultKeys);
    
      if (!isValid) {
        logger.error('Chaves obrigatórias não encontradas no vault', { missingKeys });
        return new Response(
          JSON.stringify({ 
            error: 'Configuração incompleta',
            details: `As seguintes chaves não foram encontradas: ${missingKeys.join(', ')}`
          }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      logger.info('Chaves do vault obtidas com sucesso');
    } catch (error) {
      logger.error('Erro ao buscar chaves do vault', { error: error.message });
      return new Response(
        JSON.stringify({ 
          error: 'Erro de configuração',
          details: `Erro ao acessar o vault: ${error.message}`
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Não precisamos recriar o cliente Supabase, pois já temos um com SERVICE_ROLE_KEY
    logger.info('Usando cliente Supabase já inicializado com SERVICE_ROLE_KEY');
    
    // Extrai as chaves do vault para variáveis locais
    const {
      ENCRYPTION_SECRET: encryptionSecret
    } = vaultKeys;

    // 4. Buscar a conta no banco de dados
    const { data: accountData, error: accountError } = await supabase
      .from('asaas_accounts')
      .select('*')
      .eq('profile_id', profile_id)
      .single();

    if (accountError || !accountData) {
      logger.error('Erro ao buscar conta no banco de dados', { error: accountError?.message, profileId: profile_id });
      return new Response(JSON.stringify({ 
        error: 'Conta não encontrada',
        details: accountError
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }
    
    // 5. Descriptografar a API Key
    logger.info('Iniciando processo de descriptografia da API Key');
    const apiKey = await decryptApiKey(accountData.apikey, encryptionSecret!);
    
    // 6. Chamar API do Asaas para excluir a conta
    const url = 'https://api-sandbox.asaas.com/v3/myAccount/';
    const options = {
      method: 'DELETE',
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'access_token': apiKey.trim()
      },
      body: JSON.stringify({ removeReason: remove_reason })
    };
    
    logger.info('Enviando requisição para excluir conta no Asaas', { accountId: accountData.id, profileId: profile_id });
    const asaasResponse = await fetch(url, options);
    const responseData = await asaasResponse.json();
    
    if (!asaasResponse.ok) {
      logger.error('Erro ao excluir conta no Asaas', { 
        statusCode: asaasResponse.status, 
        response: responseData,
        profileId: profile_id 
      });
      return new Response(JSON.stringify({ 
        error: 'Erro ao excluir conta no Asaas', 
        details: responseData 
      }), {
        status: asaasResponse.status,
        headers: { 'Content-Type': 'application/json' },
      });
    }
    
    // 7. Atualizar registro no banco de dados
    const { error: updateError } = await supabase
      .from('asaas_accounts')
      .update({
        deleted_at: new Date().toISOString(),
        delete_reason: remove_reason
      })
      .eq('profile_id', profile_id);
    
    if (updateError) {
      logger.error('Erro ao atualizar conta no banco de dados', { 
        error: updateError.message, 
        details: updateError.details,
        profileId: profile_id 
      });
      // Mesmo com erro no banco, a conta foi excluída no Asaas, então retornamos sucesso parcial
      return new Response(JSON.stringify({ 
        warning: 'Conta excluída no Asaas, mas houve erro ao atualizar banco de dados',
        details: updateError,
        asaasResponse: responseData
      }), {
        status: 207, // Sucesso parcial
        headers: { 'Content-Type': 'application/json' },
      });
    }
    
    // 8. Retornar resposta de sucesso
    logger.info('Conta excluída com sucesso', { profileId: profile_id });
    
    return new Response(JSON.stringify({ 
      success: true, 
      message: 'Conta excluída com sucesso',
      data: responseData
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    const errorId = crypto.randomUUID();
    logger.critical('Erro inesperado ao processar exclusão de conta', {
      errorId,
      message: error.message,
      stack: error.stack
    });
    return new Response(JSON.stringify({ 
      success: false,
      error: 'Erro interno do servidor', 
      details: error.message 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
