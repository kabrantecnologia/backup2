/**
 * Cliente para integração com a API Cappta (Simulador)
 * 
 * Este cliente implementa as operações necessárias para comunicação
 * com o simulador Cappta deployado em dev2.
 */

import { createLogger } from './logger.ts';

const logger = createLogger({ name: 'CapptaClient' });

export interface CapptaResponse<T = any> {
  success: boolean;
  data?: T;
  error?: any;
  statusCode?: number;
}

export interface CapptaWebhookRegistration {
  type: string;
  url: string;
  resellerDocument: string;
}

export interface CapptaPosDevice {
  serial_key: string;
  model_id: number;
  keys?: Record<string, any>;
}

/**
 * Cliente para comunicação com a API Cappta
 */
export class CapptaClient {
  private baseUrl: string;
  private apiToken: string;

  constructor(baseUrl: string, apiToken: string) {
    this.baseUrl = baseUrl.replace(/\/$/, ''); // Remove trailing slash
    this.apiToken = apiToken;
  }

  /**
   * Headers padrão para requisições
   */
  private getHeaders(): HeadersInit {
    return {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.apiToken}`,
      'User-Agent': 'Tricket-EdgeFunction/1.0',
    };
  }

  /**
   * Executa uma requisição HTTP
   */
  private async makeRequest<T>(
    method: string,
    endpoint: string,
    body?: any
  ): Promise<CapptaResponse<T>> {
    const url = `${this.baseUrl}${endpoint}`;
    
    try {
      logger.info(`Fazendo requisição ${method} para ${url}`);
      
      const response = await fetch(url, {
        method,
        headers: this.getHeaders(),
        body: body ? JSON.stringify(body) : undefined,
      });

      const responseData = await response.json();

      if (!response.ok) {
        logger.error(`Erro na requisição para Cappta`, {
          status: response.status,
          url,
          error: responseData
        });
        
        return {
          success: false,
          error: responseData,
          statusCode: response.status,
        };
      }

      logger.info(`Requisição bem-sucedida para ${url}`, { status: response.status });
      
      return {
        success: true,
        data: responseData,
        statusCode: response.status,
      };
    } catch (error) {
      logger.error(`Falha na comunicação com Captta`, { url, error: error.message });
      
      return {
        success: false,
        error: { message: error.message },
        statusCode: 500,
      };
    }
  }

  /**
   * Registra um webhook na API Cappta
   */
  async registerWebhook(
    resellerDocument: string,
    type: string,
    webhookUrl: string
  ): Promise<CapptaResponse> {
    const endpoint = '/api/webhooks/register';
    const payload: CapptaWebhookRegistration = {
      type,
      url: webhookUrl,
      resellerDocument,
    };

    return this.makeRequest('POST', endpoint, payload);
  }

  /**
   * Consulta o status de um webhook
   */
  async queryWebhook(
    resellerDocument: string,
    type: string
  ): Promise<CapptaResponse> {
    const endpoint = `/api/webhooks/query?resellerDocument=${resellerDocument}&type=${type}`;
    return this.makeRequest('GET', endpoint);
  }

  /**
   * Inativa um webhook
   */
  async inactivateWebhook(
    resellerDocument: string,
    type: string
  ): Promise<CapptaResponse> {
    const endpoint = '/api/webhooks/inactivate';
    const payload = {
      resellerDocument,
      type,
    };

    return this.makeRequest('POST', endpoint, payload);
  }

  /**
   * Cria um dispositivo POS
   */
  async createPosDevice(
    resellerDocument: string,
    deviceData: CapptaPosDevice
  ): Promise<CapptaResponse> {
    const endpoint = '/api/pos-devices';
    const payload = {
      resellerDocument,
      ...deviceData,
    };

    return this.makeRequest('POST', endpoint, payload);
  }

  /**
   * Lista dispositivos POS
   */
  async listPosDevices(resellerDocument: string): Promise<CapptaResponse> {
    const endpoint = `/api/pos-devices?resellerDocument=${resellerDocument}`;
    return this.makeRequest('GET', endpoint);
  }

  /**
   * Obtém informações de um terminal específico
   */
  async getTerminal(terminalId: string): Promise<CapptaResponse> {
    const endpoint = `/api/terminals/${terminalId}`;
    return this.makeRequest('GET', endpoint);
  }

  /**
   * Cria um novo merchant (lojista)
   */
  async createMerchant(merchantData: any): Promise<CapptaResponse> {
    const endpoint = '/api/merchants';
    return this.makeRequest('POST', endpoint, merchantData);
  }

  /**
   * Health check do simulador
   */
  async healthCheck(): Promise<CapptaResponse> {
    const endpoint = '/health/ready';
    return this.makeRequest('GET', endpoint);
  }
}

/**
 * Factory function para criar uma instância do cliente Cappta
 */
export function createCapptaClient(baseUrl: string, apiToken: string): CapptaClient {
  return new CapptaClient(baseUrl, apiToken);
}