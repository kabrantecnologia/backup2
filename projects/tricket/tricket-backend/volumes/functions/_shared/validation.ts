/**
 * Módulo de Validação
 * 
 * Fornece utilitários para validação de dados, incluindo
 * validação de CPF, CNPJ, email, telefone e outros campos comuns.
 */

/**
 * Remove caracteres não numéricos de uma string
 */
export function removeNonNumeric(value: string): string {
  return value.replace(/\D/g, '');
}

/**
 * Valida se um CPF é válido
 */
export function isValidCPF(cpf: string): boolean {
  const cleanCPF = removeNonNumeric(cpf);
  
  // Verifica se tem 11 dígitos
  if (cleanCPF.length !== 11) {
    return false;
  }
  
  // Verifica se todos os dígitos são iguais
  if (/^(\d)\1{10}$/.test(cleanCPF)) {
    return false;
  }
  
  // Valida primeiro dígito verificador
  let sum = 0;
  for (let i = 0; i < 9; i++) {
    sum += parseInt(cleanCPF.charAt(i)) * (10 - i);
  }
  let remainder = 11 - (sum % 11);
  let digit1 = remainder >= 10 ? 0 : remainder;
  
  if (digit1 !== parseInt(cleanCPF.charAt(9))) {
    return false;
  }
  
  // Valida segundo dígito verificador
  sum = 0;
  for (let i = 0; i < 10; i++) {
    sum += parseInt(cleanCPF.charAt(i)) * (11 - i);
  }
  remainder = 11 - (sum % 11);
  let digit2 = remainder >= 10 ? 0 : remainder;
  
  return digit2 === parseInt(cleanCPF.charAt(10));
}

/**
 * Valida se um CNPJ é válido
 */
export function isValidCNPJ(cnpj: string): boolean {
  const cleanCNPJ = removeNonNumeric(cnpj);
  
  // Verifica se tem 14 dígitos
  if (cleanCNPJ.length !== 14) {
    return false;
  }
  
  // Verifica se todos os dígitos são iguais
  if (/^(\d)\1{13}$/.test(cleanCNPJ)) {
    return false;
  }
  
  // Valida primeiro dígito verificador
  const weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  let sum = 0;
  for (let i = 0; i < 12; i++) {
    sum += parseInt(cleanCNPJ.charAt(i)) * weights1[i];
  }
  let remainder = sum % 11;
  let digit1 = remainder < 2 ? 0 : 11 - remainder;
  
  if (digit1 !== parseInt(cleanCNPJ.charAt(12))) {
    return false;
  }
  
  // Valida segundo dígito verificador
  const weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  sum = 0;
  for (let i = 0; i < 13; i++) {
    sum += parseInt(cleanCNPJ.charAt(i)) * weights2[i];
  }
  remainder = sum % 11;
  let digit2 = remainder < 2 ? 0 : 11 - remainder;
  
  return digit2 === parseInt(cleanCNPJ.charAt(13));
}

/**
 * Valida CPF ou CNPJ automaticamente baseado no tamanho
 */
export function isValidCPFOrCNPJ(document: string): boolean {
  const cleanDocument = removeNonNumeric(document);
  
  if (cleanDocument.length === 11) {
    return isValidCPF(cleanDocument);
  } else if (cleanDocument.length === 14) {
    return isValidCNPJ(cleanDocument);
  }
  
  return false;
}

/**
 * Valida se um email é válido
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Valida se um telefone brasileiro é válido
 */
export function isValidBrazilianPhone(phone: string): boolean {
  const cleanPhone = removeNonNumeric(phone);
  
  // Remove código do país se presente
  const phoneWithoutCountryCode = cleanPhone.startsWith('55') ? cleanPhone.substring(2) : cleanPhone;
  
  // Verifica se tem 10 ou 11 dígitos (com DDD)
  if (phoneWithoutCountryCode.length !== 10 && phoneWithoutCountryCode.length !== 11) {
    return false;
  }
  
  // Verifica se o DDD é válido (11-99)
  const ddd = parseInt(phoneWithoutCountryCode.substring(0, 2));
  if (ddd < 11 || ddd > 99) {
    return false;
  }
  
  return true;
}

/**
 * Valida se um CEP é válido
 */
export function isValidCEP(cep: string): boolean {
  const cleanCEP = removeNonNumeric(cep);
  return cleanCEP.length === 8 && !/^0{8}$/.test(cleanCEP);
}

/**
 * Valida se uma data está no formato ISO (YYYY-MM-DD)
 */
export function isValidISODate(date: string): boolean {
  const isoDateRegex = /^\d{4}-\d{2}-\d{2}$/;
  if (!isoDateRegex.test(date)) {
    return false;
  }
  
  const parsedDate = new Date(date);
  return parsedDate instanceof Date && !isNaN(parsedDate.getTime());
}

/**
 * Valida se um UUID é válido
 */
export function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

/**
 * Formata CPF para exibição
 */
export function formatCPF(cpf: string): string {
  const cleanCPF = removeNonNumeric(cpf);
  if (cleanCPF.length !== 11) {
    return cpf;
  }
  return cleanCPF.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
}

/**
 * Formata CNPJ para exibição
 */
export function formatCNPJ(cnpj: string): string {
  const cleanCNPJ = removeNonNumeric(cnpj);
  if (cleanCNPJ.length !== 14) {
    return cnpj;
  }
  return cleanCNPJ.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5');
}

/**
 * Formata telefone brasileiro para exibição
 */
export function formatBrazilianPhone(phone: string): string {
  const cleanPhone = removeNonNumeric(phone);
  
  // Remove código do país se presente
  const phoneWithoutCountryCode = cleanPhone.startsWith('55') ? cleanPhone.substring(2) : cleanPhone;
  
  if (phoneWithoutCountryCode.length === 10) {
    // Formato: (11) 1234-5678
    return phoneWithoutCountryCode.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3');
  } else if (phoneWithoutCountryCode.length === 11) {
    // Formato: (11) 91234-5678
    return phoneWithoutCountryCode.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
  }
  
  return phone;
}

/**
 * Formata CEP para exibição
 */
export function formatCEP(cep: string): string {
  const cleanCEP = removeNonNumeric(cep);
  if (cleanCEP.length !== 8) {
    return cep;
  }
  return cleanCEP.replace(/(\d{5})(\d{3})/, '$1-$2');
}

/**
 * Remove campos vazios de um objeto
 */
export function removeEmptyFields(obj: Record<string, any>): Record<string, any> {
  return Object.entries(obj).reduce((acc, [key, value]) => {
    if (value !== null && value !== undefined && value !== '') {
      acc[key] = value;
    }
    return acc;
  }, {} as Record<string, any>);
}

/**
 * Valida múltiplos campos de uma vez
 */
export interface ValidationRule {
  field: string;
  value: any;
  rules: string[];
  customMessage?: string;
}

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

/**
 * Executa validação baseada em regras
 */
export function validateFields(rules: ValidationRule[]): ValidationResult {
  const errors: string[] = [];

  for (const rule of rules) {
    const { field, value, rules: validationRules, customMessage } = rule;

    for (const validationRule of validationRules) {
      let isValid = true;
      let errorMessage = customMessage || `Campo ${field} é inválido`;

      switch (validationRule) {
        case 'required':
          isValid = value !== null && value !== undefined && value !== '';
          errorMessage = customMessage || `Campo ${field} é obrigatório`;
          break;
        case 'email':
          isValid = !value || isValidEmail(value);
          errorMessage = customMessage || `Campo ${field} deve ser um email válido`;
          break;
        case 'cpf':
          isValid = !value || isValidCPF(value);
          errorMessage = customMessage || `Campo ${field} deve ser um CPF válido`;
          break;
        case 'cnpj':
          isValid = !value || isValidCNPJ(value);
          errorMessage = customMessage || `Campo ${field} deve ser um CNPJ válido`;
          break;
        case 'cpf_cnpj':
          isValid = !value || isValidCPFOrCNPJ(value);
          errorMessage = customMessage || `Campo ${field} deve ser um CPF ou CNPJ válido`;
          break;
        case 'phone':
          isValid = !value || isValidBrazilianPhone(value);
          errorMessage = customMessage || `Campo ${field} deve ser um telefone válido`;
          break;
        case 'cep':
          isValid = !value || isValidCEP(value);
          errorMessage = customMessage || `Campo ${field} deve ser um CEP válido`;
          break;
        case 'uuid':
          isValid = !value || isValidUUID(value);
          errorMessage = customMessage || `Campo ${field} deve ser um UUID válido`;
          break;
        case 'iso_date':
          isValid = !value || isValidISODate(value);
          errorMessage = customMessage || `Campo ${field} deve ser uma data válida (YYYY-MM-DD)`;
          break;
      }

      if (!isValid) {
        errors.push(errorMessage);
        break; // Para na primeira regra que falhar para este campo
      }
    }
  }

  return {
    isValid: errors.length === 0,
    errors
  };
}
