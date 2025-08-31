/**
 * Cliente para API do Asaas
 * 
 * Fornece uma interface consistente para interagir com a API do Asaas,
 * incluindo criação de contas, transferências e outras operações.
 */

import { Logger } from './logger.ts';

/**
 * Interface para configuração do cliente Asaas
 */
export interface AsaasClientConfig {
  apiUrl: string;
  accessToken: string;
  logger: Logger;
}

/**
 * Interface para payload de criação de conta
 */
export interface AsaasAccountPayload {
  name: string;
  email: string;
  cpfCnpj: string;
  mobilePhone?: string;
  incomeValue?: number;
  address?: string;
  addressNumber?: string;
  complement?: string;
  province?: string;
  postalCode?: string;
  companyType?: string;
  birthDate?: string;
  webhooks?: AsaasWebhookConfig[];
}

/**
 * Interface para configuração de webhook
 */
export interface AsaasWebhookConfig {
  name: string;
  url: string;
  email: string;
  enabled: boolean;
  interrupted: boolean;
  authToken: string;
  sendType: string;
  events: string[];
}

/**
 * Interface para resposta da API do Asaas
 */
export interface AsaasApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  statusCode: number;
}

/**
 * Interface para dados de conta criada no Asaas
 */
export interface AsaasAccountData {
  id: string;
  walletId: string;
  apiKey: string;
  status: string;
  bankAccount?: {
    agency: string;
    account: string;
    accountDigit: string;
  };
}

/**
 * Cliente para interagir com a API do Asaas
 */
export class AsaasClient {
  private apiUrl: string;
  private accessToken: string;
  private logger: Logger;

  constructor(config: AsaasClientConfig) {
    this.apiUrl = config.apiUrl.replace(/\/$/, ''); // Remove trailing slash
    this.accessToken = config.accessToken;
    this.logger = config.logger;
  }

  /**
   * Realiza uma requisição HTTP para a API do Asaas
   */
  private async makeRequest<T>(
    endpoint: string,
    method: string = 'GET',
    body?: any
  ): Promise<AsaasApiResponse<T>> {
    const url = `${this.apiUrl}${endpoint}`;
    
    this.logger.debug('Fazendo requisição para API Asaas', {
      method,
      url,
      hasBody: !!body
    });

    try {
      const response = await fetch(url, {
        method,
        headers: {
          'accept': 'application/json',
          'access_token': this.accessToken,
          'content-type': 'application/json'
        },
        body: body ? JSON.stringify(body) : undefined
      });

      const responseData = await response.json();

      if (!response.ok) {
        this.logger.error('Erro na resposta da API Asaas', {
          status: response.status,
          statusText: response.statusText,
          response: responseData
        });

        return {
          success: false,
          error: `Erro ${response.status}: ${JSON.stringify(responseData)}`,
          statusCode: response.status
        };
      }

      this.logger.info('Requisição para API Asaas bem-sucedida', {
        method,
        endpoint,
        status: response.status
      });

      return {
        success: true,
        data: responseData,
        statusCode: response.status
      };
    } catch (error) {
      this.logger.error('Erro ao fazer requisição para API Asaas', {
        error: error.message,
        stack: error.stack
      });

      return {
        success: false,
        error: `Falha na comunicação com API: ${error.message}`,
        statusCode: 500
      };
    }
  }

  /**
   * Cria uma nova conta no Asaas
   */
  async createAccount(payload: AsaasAccountPayload): Promise<AsaasApiResponse<AsaasAccountData>> {
    this.logger.info('Criando conta no Asaas', {
      name: payload.name,
      email: payload.email,
      cpfCnpj: payload.cpfCnpj?.substring(0, 3) + '...',
      hasWebhooks: !!payload.webhooks?.length
    });

    return this.makeRequest<AsaasAccountData>('/accounts', 'POST', payload);
  }

  /**
   * Busca detalhes de uma conta
   */
  async getAccount(accountId: string): Promise<AsaasApiResponse<AsaasAccountData>> {
    this.logger.info('Buscando detalhes da conta', { accountId });
    return this.makeRequest<AsaasAccountData>(`/accounts/${accountId}`, 'GET');
  }

  /**
   * Atualiza uma conta existente
   */
  async updateAccount(accountId: string, payload: Partial<AsaasAccountPayload>): Promise<AsaasApiResponse<AsaasAccountData>> {
    this.logger.info('Atualizando conta no Asaas', { accountId });
    return this.makeRequest<AsaasAccountData>(`/accounts/${accountId}`, 'PUT', payload);
  }

  /**
   * Deleta uma conta
   */
  async deleteAccount(accountId: string): Promise<AsaasApiResponse<void>> {
    this.logger.info('Deletando conta no Asaas', { accountId });
    return this.makeRequest<void>(`/accounts/${accountId}`, 'DELETE');
  }

  /**
   * Lista contas
   */
  async listAccounts(params?: Record<string, any>): Promise<AsaasApiResponse<any>> {
    const queryString = params ? '?' + new URLSearchParams(params).toString() : '';
    this.logger.info('Listando contas do Asaas', { params });
    return this.makeRequest<any>(`/accounts${queryString}`, 'GET');
  }

  /**
   * Cria uma transferência
   */
  async createTransfer(payload: any): Promise<AsaasApiResponse<any>> {
    this.logger.info('Criando transferência no Asaas');
    return this.makeRequest<any>('/transfers', 'POST', payload);
  }

  /**
   * Busca detalhes de uma transferência
   */
  async getTransfer(transferId: string): Promise<AsaasApiResponse<any>> {
    this.logger.info('Buscando detalhes da transferência', { transferId });
    return this.makeRequest<any>(`/transfers/${transferId}`, 'GET');
  }

  /**
   * Valida a configuração do cliente
   */
  validateConfig(): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (!this.apiUrl) {
      errors.push('URL da API é obrigatória');
    }

    if (!this.accessToken) {
      errors.push('Token de acesso é obrigatório');
    }

    try {
      new URL(this.apiUrl);
    } catch {
      errors.push('URL da API deve ser válida');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

/**
 * Factory function para criar cliente Asaas
 */
export function createAsaasClient(config: AsaasClientConfig): AsaasClient {
  const client = new AsaasClient(config);
  
  // Valida configuração
  const validation = client.validateConfig();
  if (!validation.isValid) {
    throw new Error(`Configuração inválida do cliente Asaas: ${validation.errors.join(', ')}`);
  }

  return client;
}
