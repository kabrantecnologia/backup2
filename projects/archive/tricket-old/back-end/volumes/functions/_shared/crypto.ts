/**
 * Módulo de Criptografia
 * 
 * Fornece utilitários para criptografia segura usando AES-GCM com PBKDF2,
 * especificamente para criptografar API Keys e dados sensíveis.
 */

// Declaração para o ambiente Deno
declare const Deno: any;

/**
 * Constantes para criptografia AES-GCM
 */
export const CRYPTO_CONSTANTS = {
  PBKDF2_SALT_STRING: "4BGEdKWWwHuUvfrXjqu5iKCEQbo1aG7Mu9difS36UXzmtm9TRj0Y2oLMIkqep40q",
  PBKDF2_ITERATIONS: 100000,
  ENCRYPTION_ALGORITHM: "AES-GCM",
  KEY_LENGTH: 256,
  IV_LENGTH_BYTES: 12
} as const;

/**
 * Converte ArrayBuffer para string Base64
 */
function arrayBufferToBase64(buffer: ArrayBuffer): string {
  let binary = '';
  const bytes = new Uint8Array(buffer);
  const len = bytes.byteLength;
  
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  
  return btoa(binary);
}

/**
 * Converte string Base64 para ArrayBuffer
 */
function base64ToArrayBuffer(base64: string): ArrayBuffer {
  const binaryString = atob(base64);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  
  return bytes.buffer;
}

/**
 * Criptografa uma string usando AES-GCM com chave derivada por PBKDF2
 */
export async function encryptData(data: string, masterSecret: string): Promise<string> {
  try {
    const encoder = new TextEncoder();
    const salt = encoder.encode(CRYPTO_CONSTANTS.PBKDF2_SALT_STRING);
    const secretData = encoder.encode(masterSecret);

    // Importa a chave mestre para PBKDF2
    const pbkdf2ImportedKey = await crypto.subtle.importKey(
      "raw",
      secretData,
      { name: "PBKDF2" },
      false,
      ["deriveKey"]
    );

    // Deriva a chave de criptografia usando PBKDF2
    const derivedEncryptionKey = await crypto.subtle.deriveKey(
      {
        name: "PBKDF2",
        salt: salt,
        iterations: CRYPTO_CONSTANTS.PBKDF2_ITERATIONS,
        hash: "SHA-256",
      },
      pbkdf2ImportedKey,
      { name: CRYPTO_CONSTANTS.ENCRYPTION_ALGORITHM, length: CRYPTO_CONSTANTS.KEY_LENGTH },
      false,
      ["encrypt"]
    );

    // Gera um vetor de inicialização aleatório
    const iv = crypto.getRandomValues(new Uint8Array(CRYPTO_CONSTANTS.IV_LENGTH_BYTES));

    // Codifica os dados para ArrayBuffer
    const dataBuffer = encoder.encode(data);

    // Criptografa os dados
    const encryptedBuffer = await crypto.subtle.encrypt(
      {
        name: CRYPTO_CONSTANTS.ENCRYPTION_ALGORITHM,
        iv: iv,
      },
      derivedEncryptionKey,
      dataBuffer
    );

    // Combina IV e texto cifrado
    const combinedBuffer = new Uint8Array(iv.length + encryptedBuffer.byteLength);
    combinedBuffer.set(iv, 0);
    combinedBuffer.set(new Uint8Array(encryptedBuffer), iv.length);

    // Converte para Base64
    return arrayBufferToBase64(combinedBuffer.buffer);
  } catch (error) {
    throw new Error(`Falha na criptografia: ${error.message || error}`);
  }
}

/**
 * Descriptografa uma string criptografada com AES-GCM
 */
export async function decryptData(encryptedData: string, masterSecret: string): Promise<string> {
  try {
    const encoder = new TextEncoder();
    const decoder = new TextDecoder();
    const salt = encoder.encode(CRYPTO_CONSTANTS.PBKDF2_SALT_STRING);
    const secretData = encoder.encode(masterSecret);

    // Converte dados criptografados de Base64 para ArrayBuffer
    const combinedBuffer = base64ToArrayBuffer(encryptedData);
    const combinedArray = new Uint8Array(combinedBuffer);

    // Extrai IV e dados criptografados
    const iv = combinedArray.slice(0, CRYPTO_CONSTANTS.IV_LENGTH_BYTES);
    const encryptedBuffer = combinedArray.slice(CRYPTO_CONSTANTS.IV_LENGTH_BYTES);

    // Importa a chave mestre para PBKDF2
    const pbkdf2ImportedKey = await crypto.subtle.importKey(
      "raw",
      secretData,
      { name: "PBKDF2" },
      false,
      ["deriveKey"]
    );

    // Deriva a chave de descriptografia usando PBKDF2
    const derivedDecryptionKey = await crypto.subtle.deriveKey(
      {
        name: "PBKDF2",
        salt: salt,
        iterations: CRYPTO_CONSTANTS.PBKDF2_ITERATIONS,
        hash: "SHA-256",
      },
      pbkdf2ImportedKey,
      { name: CRYPTO_CONSTANTS.ENCRYPTION_ALGORITHM, length: CRYPTO_CONSTANTS.KEY_LENGTH },
      false,
      ["decrypt"]
    );

    // Descriptografa os dados
    const decryptedBuffer = await crypto.subtle.decrypt(
      {
        name: CRYPTO_CONSTANTS.ENCRYPTION_ALGORITHM,
        iv: iv,
      },
      derivedDecryptionKey,
      encryptedBuffer
    );

    // Converte para string
    return decoder.decode(decryptedBuffer);
  } catch (error) {
    throw new Error(`Falha na descriptografia: ${error.message || error}`);
  }
}

/**
 * Função específica para criptografar API Keys (compatibilidade)
 */
export async function encryptApiKey(apiKey: string, masterSecret: string): Promise<string> {
  return encryptData(apiKey, masterSecret);
}

/**
 * Função específica para descriptografar API Keys
 */
export async function decryptApiKey(encryptedApiKey: string, masterSecret: string): Promise<string> {
  return decryptData(encryptedApiKey, masterSecret);
}

/**
 * Gera um token aleatório seguro
 */
export function generateSecureToken(length: number = 32): string {
  const chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  
  return Array.from(array, byte => chars[byte % chars.length]).join('');
}

/**
 * Gera um token de webhook (compatibilidade com função original)
 */
export function generateWebhookToken(): string {
  return Array.from({ length: 14 }, () => 
    '0123456789abcdef'[Math.floor(Math.random() * 16)]
  ).join('');
}
