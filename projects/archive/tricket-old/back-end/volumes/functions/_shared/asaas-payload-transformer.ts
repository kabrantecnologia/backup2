/**
 * Transformador de Payload para API do Asaas
 * 
 * Converte dados de perfil do sistema interno para o formato
 * esperado pela API do Asaas para criação de contas.
 */

import { removeEmptyFields } from './validation.ts';
import { generateWebhookToken } from './crypto.ts';
import { Logger } from './logger.ts';

/**
 * Interface para dados de perfil do sistema interno
 */
export interface ProfileData {
  profile_id: string;
  profile_type: 'INDIVIDUAL' | 'ORGANIZATION';
  name: string;
  email: string;
  cpf_cnpj: string;
  birth_date?: string;
  company_type?: string;
  mobile_phone?: string;
  income_value_cents?: number;
  address?: string;
  address_number?: string;
  complement?: string;
  province?: string;
  postal_code?: string;
}

/**
 * Interface para configuração de webhook do Asaas
 */
export interface WebhookConfig {
  accountStatusUrl: string;
  transferStatusUrl: string;
  email: string;
}

/**
 * Converte tipos de empresa do sistema interno para os aceitos pelo Asaas
 */
export function convertCompanyTypeToAsaas(companyType: string): string {
  const typeMapping: Record<string, string> = {
    'MEI': 'MEI',
    'LTDA': 'LIMITED',
    'SA': 'LIMITED',
    'EIRELI': 'LIMITED',
    'ASSOCIATION': 'ASSOCIATION',
    'COOPERATIVE': 'ASSOCIATION'
  };

  return typeMapping[companyType] || 'LIMITED';
}

/**
 * Formata CPF/CNPJ removendo caracteres especiais e validando tamanho
 */
export function formatCpfCnpj(cpfCnpj: string, logger: Logger): string {
  if (!cpfCnpj) {
    throw new Error('CPF/CNPJ é obrigatório');
  }

  // Remove caracteres não numéricos
  const cleaned = cpfCnpj.replace(/\D/g, '');

  // Valida tamanho
  if (cleaned.length !== 11 && cleaned.length !== 14) {
    logger.error('CPF/CNPJ com tamanho inválido', { 
      original: cpfCnpj, 
      cleaned, 
      length: cleaned.length 
    });
    throw new Error('CPF deve ter 11 dígitos ou CNPJ deve ter 14 dígitos');
  }

  logger.debug('CPF/CNPJ formatado', { 
    original: cpfCnpj, 
    cleaned: cleaned.substring(0, 3) + '...',
    type: cleaned.length === 11 ? 'CPF' : 'CNPJ'
  });

  return cleaned;
}

/**
 * Formata telefone removendo caracteres especiais e código do país
 */
export function formatMobilePhone(phone: string, logger: Logger): string {
  if (!phone) {
    return '';
  }

  // Remove caracteres não numéricos
  let cleaned = phone.replace(/\D/g, '');

  // Remove código do país (55) se presente
  if (cleaned.startsWith('55') && cleaned.length > 11) {
    cleaned = cleaned.substring(2);
  }

  // Formata no padrão esperado pelo Asaas (sem separadores)
  if (cleaned.length >= 10 && cleaned.length <= 11) {
    logger.debug('Telefone formatado', { 
      original: phone, 
      cleaned: cleaned.substring(0, 2) + '...' 
    });
    return cleaned;
  }

  logger.warn('Telefone com formato inválido', { original: phone, cleaned });
  return '';
}

/**
 * Converte valor de renda/faturamento de centavos para reais
 */
export function formatIncomeValue(incomeValueCents: number | null | undefined, logger: Logger): number {
  // Se não fornecido ou inválido, usa valor mínimo aceito pelo Asaas
  if (!incomeValueCents || incomeValueCents <= 0) {
    const defaultValue = 1000; // R$ 10,00 como valor mínimo
    logger.warn('Valor de renda não fornecido ou inválido, usando valor padrão', { 
      incomeValueCents, 
      defaultValueReais: defaultValue 
    });
    return defaultValue;
  }

  const incomeInReais = Math.round(incomeValueCents / 100);
  
  // Garante valor mínimo de R$ 1,00
  const finalValue = Math.max(incomeInReais, 100);
  
  logger.debug('Valor de renda convertido', {
    originalCents: incomeValueCents,
    convertedReais: incomeInReais,
    finalValue
  });

  return finalValue;
}

/**
 * Formata CEP removendo caracteres especiais
 */
export function formatPostalCode(postalCode: string): string {
  if (!postalCode) {
    return '00000000';
  }
  return postalCode.replace(/\D/g, '').padStart(8, '0');
}

/**
 * Cria configuração de webhooks para o Asaas
 */
export function createWebhookConfiguration(
  config: WebhookConfig,
  webhookToken: string
): any[] {
  return [
    {
      name: "AccountStatus",
      url: config.accountStatusUrl,
      email: config.email,
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
      url: config.transferStatusUrl,
      email: config.email,
      enabled: true,
      interrupted: false,
      authToken: webhookToken,
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
  ];
}

/**
 * Transforma dados de perfil para payload do Asaas
 */
export function transformProfileToAsaasPayload(
  profile: ProfileData,
  webhookConfig: WebhookConfig,
  logger: Logger
): any {
  logger.info('Iniciando transformação de dados para payload Asaas', {
    profileId: profile.profile_id,
    profileType: profile.profile_type,
    name: profile.name,
    email: profile.email
  });

  const isOrganization = profile.profile_type === 'ORGANIZATION';

  // Gera token para webhooks
  const webhookToken = generateWebhookToken();
  logger.info('Token de webhook gerado', { 
    tokenPrefix: webhookToken.substring(0, 4) + '...' 
  });

  // Constrói payload base
  const basePayload = {
    name: profile.name,
    email: profile.email,
    cpfCnpj: formatCpfCnpj(profile.cpf_cnpj, logger),
    mobilePhone: formatMobilePhone(profile.mobile_phone || '', logger),
    incomeValue: formatIncomeValue(profile.income_value_cents || 0, logger),
    address: profile.address || '',
    addressNumber: profile.address_number || 'S/N',
    province: profile.province || 'Centro',
    postalCode: formatPostalCode(profile.postal_code || '')
  };

  // Adiciona complement se fornecido
  if (profile.complement) {
    (basePayload as any).complement = profile.complement;
  }

  // Adiciona campos específicos para PJ ou PF
  if (isOrganization && profile.company_type) {
    (basePayload as any).companyType = convertCompanyTypeToAsaas(profile.company_type);
    logger.debug('Tipo de empresa convertido', {
      original: profile.company_type,
      converted: (basePayload as any).companyType
    });
  } else if (!isOrganization && profile.birth_date) {
    (basePayload as any).birthDate = profile.birth_date.split('T')[0]; // Remove time part
    logger.debug('Data de nascimento formatada', {
      original: profile.birth_date,
      formatted: (basePayload as any).birthDate
    });
  }

  // Adiciona configuração de webhooks
  const webhooks = createWebhookConfiguration(webhookConfig, webhookToken);
  (basePayload as any).webhooks = webhooks;

  logger.info('URLs de webhook configuradas', {
    accountStatusUrl: webhookConfig.accountStatusUrl,
    transferStatusUrl: webhookConfig.transferStatusUrl
  });

  // Remove campos vazios
  const finalPayload = removeEmptyFields(basePayload);

  logger.info('Payload Asaas criado com sucesso', {
    fieldsCount: Object.keys(finalPayload).length,
    hasWebhooks: !!finalPayload.webhooks?.length,
    webhookToken: webhookToken.substring(0, 4) + '...'
  });

  return {
    payload: finalPayload,
    webhookToken
  };
}

/**
 * Valida dados de perfil antes da transformação
 */
export function validateProfileData(profile: ProfileData): { isValid: boolean; errors: string[] } {
  const errors: string[] = [];

  // Campos obrigatórios
  if (!profile.name?.trim()) {
    errors.push('Nome é obrigatório');
  }

  if (!profile.email?.trim()) {
    errors.push('Email é obrigatório');
  }

  if (!profile.cpf_cnpj?.trim()) {
    errors.push('CPF/CNPJ é obrigatório');
  }

  // Validações específicas por tipo
  if (profile.profile_type === 'ORGANIZATION') {
    if (!profile.company_type?.trim()) {
      errors.push('Tipo de empresa é obrigatório para organizações');
    }
  } else if (profile.profile_type === 'INDIVIDUAL') {
    if (!profile.birth_date?.trim()) {
      errors.push('Data de nascimento é obrigatória para pessoas físicas');
    }
  }

  return {
    isValid: errors.length === 0,
    errors
  };
}
