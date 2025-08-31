/**
 * Módulo de Autenticação e Autorização
 * 
 * Fornece middleware e utilitários para autenticação JWT e verificação
 * de permissões baseadas em roles (RBAC).
 */

import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';
import { Logger } from './logger.ts';

/**
 * Interface para dados do usuário autenticado
 */
export interface AuthenticatedUser {
  id: string;
  email?: string;
  roles: string[];
}

/**
 * Interface para resultado de autenticação
 */
export interface AuthResult {
  success: boolean;
  user?: AuthenticatedUser;
  error?: string;
}

/**
 * Interface para verificação de permissões
 */
export interface PermissionCheck {
  hasPermission: boolean;
  userRoles: string[];
  requiredRoles: string[];
}

/**
 * Extrai o token JWT do cabeçalho Authorization
 */
export function extractTokenFromHeader(request: Request): string | null {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  return authHeader.substring(7); // Remove "Bearer "
}

/**
 * Autentica um usuário usando token JWT
 */
export async function authenticateUser(
  supabase: SupabaseClient,
  token: string,
  logger: Logger
): Promise<AuthResult> {
  try {
    logger.debug('Verificando token JWT', { tokenPrefix: token.substring(0, 10) + '...' });

    // Verifica o token com Supabase Auth
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      logger.warn('Token inválido ou usuário não encontrado', { error: error?.message });
      return {
        success: false,
        error: 'Token inválido ou expirado'
      };
    }

    logger.info('Usuário autenticado com sucesso', { userId: user.id, email: user.email });

    // Busca as roles do usuário
    const userRoles = await getUserRoles(supabase, user.id, logger);

    return {
      success: true,
      user: {
        id: user.id,
        email: user.email,
        roles: userRoles
      }
    };
  } catch (error) {
    logger.error('Erro durante autenticação', error);
    return {
      success: false,
      error: 'Erro interno durante autenticação'
    };
  }
}

/**
 * Busca as roles de um usuário
 */
export async function getUserRoles(
  supabase: SupabaseClient,
  userId: string,
  logger: Logger
): Promise<string[]> {
  try {
    const { data: roleData, error } = await supabase
      .from('rbac_user_roles')
      .select(`
        rbac_roles (
          name
        )
      `)
      .eq('user_id', userId);

    if (error) {
      logger.error('Erro ao buscar roles do usuário', { userId, error: error.message });
      return [];
    }

    const roles = roleData?.map((item: any) => item.rbac_roles?.name).filter(Boolean) || [];
    logger.debug('Roles do usuário obtidas', { userId, roles });

    return roles;
  } catch (error) {
    logger.error('Erro ao buscar roles do usuário', { userId, error });
    return [];
  }
}

/**
 * Verifica se um usuário tem pelo menos uma das roles especificadas
 */
export function checkUserPermissions(
  user: AuthenticatedUser,
  requiredRoles: string[]
): PermissionCheck {
  const hasPermission = requiredRoles.some(role => user.roles.includes(role));

  return {
    hasPermission,
    userRoles: user.roles,
    requiredRoles
  };
}

/**
 * Middleware de autenticação para Edge Functions
 */
export async function authMiddleware(
  request: Request,
  supabase: SupabaseClient,
  logger: Logger,
  requiredRoles: string[] = []
): Promise<{ success: boolean; user?: AuthenticatedUser; response?: Response }> {
  // Extrai token do cabeçalho
  const token = extractTokenFromHeader(request);
  
  if (!token) {
    logger.warn('Token de autenticação não fornecido');
    return {
      success: false,
      response: new Response(
        JSON.stringify({ 
          success: false,
          error: 'Token de autenticação obrigatório' 
        }),
        { 
          status: 401, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    };
  }

  // Autentica o usuário
  const authResult = await authenticateUser(supabase, token, logger);
  
  if (!authResult.success || !authResult.user) {
    return {
      success: false,
      response: new Response(
        JSON.stringify({ 
          success: false,
          error: authResult.error || 'Falha na autenticação' 
        }),
        { 
          status: 401, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    };
  }

  // Verifica permissões se roles foram especificadas
  if (requiredRoles.length > 0) {
    const permissionCheck = checkUserPermissions(authResult.user, requiredRoles);
    
    if (!permissionCheck.hasPermission) {
      logger.warn('Usuário sem permissão necessária', {
        userId: authResult.user.id,
        userRoles: permissionCheck.userRoles,
        requiredRoles: permissionCheck.requiredRoles
      });
      
      return {
        success: false,
        response: new Response(
          JSON.stringify({ 
            success: false,
            error: 'Permissões insuficientes' 
          }),
          { 
            status: 403, 
            headers: { 'Content-Type': 'application/json' } 
          }
        )
      };
    }
  }

  logger.info('Autenticação e autorização bem-sucedidas', {
    userId: authResult.user.id,
    roles: authResult.user.roles
  });

  return {
    success: true,
    user: authResult.user
  };
}
