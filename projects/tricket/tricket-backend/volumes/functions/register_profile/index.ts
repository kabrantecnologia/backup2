/**
 * Edge Function: register_profile
 *
 * Orquestra o cadastro de perfis (INDIVIDUAL | ORGANIZATION) no backend.
 * - Autentica o usuário (qualquer autenticado)
 * - Normaliza/valida payload
 * - Geocodifica endereço (Google Geocoding) se latitude/longitude não informados
 * - Calcula geolocation (WKB/POINT 4326) via RPC calculate_geolocation
 * - Chama RPCs transacionais de cadastro:
 *   - register_individual_profile(p_profile_data JSONB, p_address_data JSONB)
 *   - register_organization_profile(p_individual_data JSONB, p_organization_data JSONB, p_address_data JSONB)
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

import {
  authMiddleware,
  withErrorHandling,
  createSuccessResponse,
  createValidationErrorResponse,
  createInternalErrorResponse,
  parseRequestBody,
  validateRequiredFields,
} from '../_shared/index.ts';

// Declaração para Deno env
declare const Deno: any;

// Tipos de entrada
interface BaseAddressData {
  address_type?: 'MAIN' | string;
  is_default?: boolean;
  street: string;
  number?: string | null;
  complement?: string | null;
  neighborhood?: string;
  city_id: number;
  state_id: number;
  zip_code: string; // CEP (pode vir com máscara)
  country?: string;
  latitude?: number | null;
  longitude?: number | null;
  geolocation?: string | null; // WKB opcional se já fornecido
  notes?: string | null;
}

interface IndividualProfileData {
  full_name: string;
  birth_date?: string | null;
  income_value_cents?: string | number | null;
  contact_email?: string | null;
  cpf?: string;
  contact_phone?: string | null;
}

interface OrganizationData {
  platform_role: 'FORNECEDOR' | 'COMERCIANTE' | 'FORNECEDOR_COMERCIANTE' | string;
  company_name: string;
  trade_name?: string | null;
  cnpj: string;
  company_type?: string | null;
  income_value?: number | null;
  contact_email?: string | null;
  contact_phone?: string | null;
}

interface RegisterIndividualPayload {
  type: 'INDIVIDUAL';
  profile_data: IndividualProfileData;
  address_data: BaseAddressData;
}

interface RegisterOrganizationPayload {
  type: 'ORGANIZATION';
  individual_data: IndividualProfileData;
  organization_data: OrganizationData;
  address_data: BaseAddressData;
}

type RegisterPayload = RegisterIndividualPayload | RegisterOrganizationPayload;

// Utils de normalização
function onlyDigits(value?: string | null): string | null {
  if (!value) return null;
  return value.replace(/\D+/g, '') || null;
}

function normalizeCep(cep?: string | null): string | null {
  const digits = onlyDigits(cep);
  if (!digits) return null;
  return digits.padEnd(8, '0').slice(0, 8); // garante 8 dígitos
}

function normalizePhone(phone?: string | null): string | null {
  return onlyDigits(phone);
}

function normalizeCpf(cpf?: string | null): string | null {
  return onlyDigits(cpf);
}

function normalizeCnpj(cnpj?: string | null): string | null {
  return onlyDigits(cnpj);
}

// Promise timeout helper
async function withTimeout<T>(promise: Promise<T>, ms: number, label: string): Promise<T> {
  let timer: number | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => {
      console.warn(`[register_profile] Timeout após ${ms}ms em: ${label}`);
      reject(new Error(`Timeout em ${label}`));
    }, ms) as unknown as number;
  });
  try {
    // Race timeout vs original promise
    return await Promise.race([promise, timeout]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}

async function geocodeIfNeeded(address: BaseAddressData, googleApiKey?: string): Promise<{ lat: number; lng: number } | null> {
  const latNum = Number((address as any).latitude);
  const lngNum = Number((address as any).longitude);
  const hasLatLng = Number.isFinite(latNum) && Number.isFinite(lngNum);
  if (hasLatLng) {
    console.log('[register_profile] Lat/Lng fornecidos no payload, pulando geocoding');
    return { lat: latNum, lng: lngNum };
  }
  if (!googleApiKey) {
    return null; // sem key e sem lat/lng, não geocodifica
  }
  // Monta endereço legível para o Google (CEP + logradouro + número + bairro + Brasil)
  const parts = [
    normalizeCep(address.zip_code) || '',
    address.street || '',
    address.number || '',
    address.neighborhood || '',
    'Brasil'
  ].filter(Boolean);
  const addressStr = parts.join(', ');
  const params = new URLSearchParams({ address: addressStr, key: googleApiKey });
  const url = `https://maps.googleapis.com/maps/api/geocode/json?${params.toString()}`;

  // Timeout de 2.5s para evitar travas
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 2500);
  let resp: Response;
  try {
    console.log('[register_profile] Geocoding request ->', addressStr);
    resp = await fetch(url, { signal: controller.signal });
  } catch (err: any) {
    console.warn('[register_profile] Geocoding fetch error:', err?.message || String(err));
    clearTimeout(timeout);
    return null;
  }
  clearTimeout(timeout);
  if (!resp.ok) {
    console.warn('[register_profile] Geocoding HTTP not OK:', resp.status);
    return null;
  }
  const data = await resp.json();
  const loc = data?.results?.[0]?.geometry?.location;
  if (loc && typeof loc.lat === 'number' && typeof loc.lng === 'number') {
    return { lat: loc.lat, lng: loc.lng };
  }
  console.warn('[register_profile] Geocoding returned no results for:', addressStr);
  return null;
}

async function calculateGeolocationWkb(supabase: any, lat: number, lng: number): Promise<string> {
  console.log('[register_profile] RPC calculate_geolocation -> start', { lat, lng });
  const { data, error } = await withTimeout(
    supabase.rpc('calculate_geolocation', { p_latitude: lat, p_longitude: lng }),
    4000,
    'rpc calculate_geolocation'
  );
  if (error) {
    throw new Error(`Erro ao calcular geolocation: ${error.message}`);
  }
  console.log('[register_profile] RPC calculate_geolocation -> done');
  return data as string;
}

async function handleRegister(payload: RegisterPayload, authHeader: string): Promise<Response> {
  const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return createInternalErrorResponse('Configuração Supabase ausente');
  }
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
    global: { headers: { Authorization: authHeader } },
  });

  const GOOGLE_MAPS_API_KEY = Deno.env.get('GOOGLE_MAPS_API_KEY');
  const USE_BACKEND_GEOCODING = (Deno.env.get('USE_BACKEND_GEOCODING') || 'false').toLowerCase() === 'true';

  // Normalizações comuns de address
  const addr = payload.address_data;
  addr.zip_code = normalizeCep(addr.zip_code) || addr.zip_code;

  // Geocodificação (se necessário)
  const latCoerced = Number((addr as any).latitude);
  const lngCoerced = Number((addr as any).longitude);
  let latlng: { lat: number; lng: number } | null =
    (Number.isFinite(latCoerced) && Number.isFinite(lngCoerced)) ? { lat: latCoerced, lng: lngCoerced } : null;

  console.log('[register_profile] Geocoding gate', {
    hasLatLng: !!latlng,
    useBackendGeocoding: USE_BACKEND_GEOCODING,
  });

  if (!latlng && USE_BACKEND_GEOCODING) {
    latlng = await geocodeIfNeeded(addr, GOOGLE_MAPS_API_KEY);
  }
  if (!latlng) {
    console.warn('[register_profile] Sem lat/lng válidos e geocoding desabilitado/falhou');
    return createValidationErrorResponse('Latitude/longitude obrigatórios. Envie latitude/longitude no address_data ou habilite geocodificação no backend.');
  }

  // Calcula WKB via RPC
  const geolocationWkb = await calculateGeolocationWkb(supabase, latlng.lat, latlng.lng);

  // Preenche address_data final
  const address_data_final = {
    ...addr,
    address_type: addr.address_type || 'MAIN',
    is_default: addr.is_default ?? true,
    latitude: latlng.lat,
    longitude: latlng.lng,
    geolocation: geolocationWkb,
  };

  if (payload.type === 'INDIVIDUAL') {
    const p = payload as RegisterIndividualPayload;
    const profile = { ...p.profile_data };
    profile.cpf = normalizeCpf(profile.cpf) || profile.cpf;
    if (profile.contact_phone) profile.contact_phone = normalizePhone(profile.contact_phone);

    // Chama RPC de registro individual
    console.log('[register_profile] RPC register_individual_profile -> start');
    try {
      const { data, error } = await withTimeout(
        supabase.rpc('register_individual_profile', {
          profile_data: profile,
          address_data: address_data_final,
        }),
        4000,
        'rpc register_individual_profile'
      ) as { data: unknown; error: { message?: string } | null };
      if (error) {
        console.error('[register_profile] RPC register_individual_profile error', error);
        return createInternalErrorResponse('Erro ao registrar perfil individual', error.message);
      }
      console.log('[register_profile] RPC register_individual_profile -> done');
      return createSuccessResponse(data, 'Perfil individual registrado com sucesso');
    } catch (e: any) {
      console.error('[register_profile] RPC register_individual_profile exception', e?.message || String(e));
      return createInternalErrorResponse('Falha ao registrar perfil individual (timeout/exception)', e?.message);
    }
  }

  if (payload.type === 'ORGANIZATION') {
    const p = payload as RegisterOrganizationPayload;
    const individual = { ...p.individual_data };
    individual.cpf = normalizeCpf(individual.cpf) || individual.cpf;
    if (individual.contact_phone) individual.contact_phone = normalizePhone(individual.contact_phone);

    const org = { ...p.organization_data };
    org.cnpj = normalizeCnpj(org.cnpj) || org.cnpj;
    if (org.contact_phone) org.contact_phone = normalizePhone(org.contact_phone);

    console.log('[register_profile] RPC register_organization_profile -> start');
    try {
      const { data, error } = await withTimeout(
        supabase.rpc('register_organization_profile', {
          individual_data: individual,
          organization_data: org,
          address_data: address_data_final,
        }),
        5000,
        'rpc register_organization_profile'
      ) as { data: unknown; error: { message?: string } | null };
      if (error) {
        console.error('[register_profile] RPC register_organization_profile error', error);
        return createInternalErrorResponse('Erro ao registrar perfil organizacional', error.message);
      }
      console.log('[register_profile] RPC register_organization_profile -> done');
      return createSuccessResponse(data, 'Perfil organizacional registrado com sucesso');
    } catch (e: any) {
      console.error('[register_profile] RPC register_organization_profile exception', e?.message || String(e));
      return createInternalErrorResponse('Falha ao registrar perfil organizacional (timeout/exception)', e?.message);
    }
  }

  return createValidationErrorResponse('Tipo inválido. Use INDIVIDUAL ou ORGANIZATION');
}

async function handler(request: Request): Promise<Response> {
  // Inicial: autenticação básica (qualquer usuário autenticado)
  const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return createInternalErrorResponse('Configuração Supabase ausente');
  }
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, { auth: { persistSession: false } });

  const auth = await authMiddleware(request, supabase, console as any, []);
  if (!auth.success) return auth.response!;

  if (request.method !== 'POST') {
    return createValidationErrorResponse('Método não permitido. Use POST.');
  }

  let payload: RegisterPayload;
  try {
    payload = await parseRequestBody<RegisterPayload>(request);
  } catch (e: any) {
    return createValidationErrorResponse('Payload inválido', e?.message);
  }

  // Campos obrigatórios por tipo
  if (payload.type === 'INDIVIDUAL') {
    const v = validateRequiredFields(payload, ['type', 'profile_data', 'address_data']);
    if (!v.isValid) return createValidationErrorResponse('Campos obrigatórios ausentes', v.missingFields.join(', '));
  } else if (payload.type === 'ORGANIZATION') {
    const v = validateRequiredFields(payload as any, ['type', 'individual_data', 'organization_data', 'address_data']);
    if (!v.isValid) return createValidationErrorResponse('Campos obrigatórios ausentes', v.missingFields.join(', '));
  } else {
    return createValidationErrorResponse('Tipo inválido. Use INDIVIDUAL ou ORGANIZATION');
  }
  const authHeader = request.headers.get('Authorization') || request.headers.get('authorization') || '';
  if (!authHeader) {
    return createValidationErrorResponse('Cabeçalho Authorization ausente');
  }
  return await handleRegister(payload, authHeader);
}

serve(withErrorHandling(handler));
