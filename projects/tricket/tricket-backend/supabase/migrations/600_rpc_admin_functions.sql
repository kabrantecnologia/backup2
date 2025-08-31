/**********************************************************************************************************************
*   SEÇÃO 6: FUNÇÕES RPC PARA ADMINISTRAÇÃO
*   Descrição: Funções remotas (RPC) para serem chamadas pelo front-end por usuários administradores da Tricket.
**********************************************************************************************************************/

-- Função: rpc_approve_user_profile
-- Permite que um administrador da Tricket aprove o perfil de um usuário, alterando seu status de onboarding.
CREATE OR REPLACE FUNCTION public.rpc_approve_user_profile(p_profile_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_caller_auth_id UUID := auth.uid();
    v_caller_is_admin BOOLEAN;
    v_profile_to_approve_id UUID := p_profile_id;
    v_current_status public.onboarding_status_enum;
BEGIN
    -- 1. Validar se o chamador está autenticado
    IF v_caller_auth_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required: User is not logged in.';
    END IF;

    -- 2. Validar se o chamador é um administrador, usando o sistema RBAC
    SELECT EXISTS (
        SELECT 1
        FROM public.rbac_user_roles ur
        JOIN public.rbac_roles r ON ur.role_id = r.id
        WHERE ur.user_id = v_caller_auth_id AND r.name = 'ADMIN'
    ) INTO v_caller_is_admin;

    IF NOT v_caller_is_admin THEN
        RAISE EXCEPTION 'Permission denied: Caller is not an administrator.';
    END IF;

    -- 3. Buscar o status atual do perfil para garantir que ele está no estado correto para aprovação.
    SELECT onboarding_status INTO v_current_status
    FROM public.iam_profiles
    WHERE id = v_profile_to_approve_id;

    IF NOT FOUND THEN
        RETURN json_build_object('status', 'error', 'message', 'Profile not found.');
    END IF;

    -- 4. A aprovação só é permitida se o status atual for 'PENDING_ADMIN_APPROVAL'.
    IF v_current_status <> 'PENDING_ADMIN_APPROVAL' THEN
        RETURN json_build_object('status', 'error', 'message', 'Profile is not in a state that can be approved. Current status: ' || v_current_status);
    END IF;

    -- 5. Atualiza o status do perfil para 'APPROVED_BY_TRICKET'.
    UPDATE public.iam_profiles
    SET onboarding_status = 'APPROVED_BY_TRICKET',
        updated_at = now()
    WHERE id = v_profile_to_approve_id;

    -- 6. Retorna uma resposta de sucesso.
    RETURN json_build_object('status', 'success', 'message', 'Profile approved successfully.');
EXCEPTION
    WHEN OTHERS THEN
        -- Em caso de qualquer outro erro, retorna uma mensagem genérica.
        RETURN json_build_object('status', 'error', 'message', 'An unexpected error occurred: ' || SQLERRM);
END;
$$;

COMMENT ON FUNCTION public.rpc_approve_user_profile(UUID) IS 'Permite que um administrador aprove o cadastro de um perfil, mudando o onboarding_status para APPROVED_BY_TRICKET.';

-- Concede permissão de execução para usuários autenticados (a lógica interna da função verifica se é admin).
GRANT EXECUTE ON FUNCTION public.rpc_approve_user_profile(UUID) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 7: FUNÇÕES RPC PARA LEITURA DE DADOS (ADMIN)
*   Descrição: Funções remotas (RPC) para obter dados consolidados para os painéis de administração.
**********************************************************************************************************************/

-- Função: get_profiles_for_approval
-- Retorna uma lista de todos os perfis da view `view_admin_profile_approval`.
-- Apenas usuários com a role 'ADMIN' podem executar esta função.
-- 2. Cria a nova versão da função com a lógica de permissão validada
CREATE OR REPLACE FUNCTION public.get_profiles_for_approval()
RETURNS JSONB
LANGUAGE plpgsql
-- Revertendo para SECURITY DEFINER, que funcionou na outra função admin
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller_auth_id UUID := auth.uid();
    v_caller_is_admin BOOLEAN;
BEGIN
    -- 1. Validar se o chamador está autenticado
    IF v_caller_auth_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required: User is not logged in.';
    END IF;

    -- 2. Validar se o chamador é um administrador usando a lógica que funcionou no arquivo 36
    SELECT EXISTS (
        SELECT 1
        FROM public.rbac_user_roles ur
        JOIN public.rbac_roles r ON ur.role_id = r.id
        WHERE ur.user_id = v_caller_auth_id AND r.name = 'ADMIN'
    ) INTO v_caller_is_admin;

    -- 3. Se não for admin, lançar uma exceção de permissão negada
    IF NOT v_caller_is_admin THEN
        RAISE EXCEPTION 'Permission denied: Caller is not an admin.';
    END IF;

    -- 4. Se for admin, buscar os dados da view e retornar como um array JSON
    RETURN (SELECT jsonb_agg(t)
            FROM public.view_admin_profile_approval t);

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('error', SQLERRM);
END;
$$;

COMMENT ON FUNCTION public.get_profiles_for_approval() IS 'Retorna todos os perfis para o painel de aprovação de administradores. Requer privilégios de ADMIN. Usa lógica de permissão explícita com SECURITY DEFINER.';

GRANT EXECUTE ON FUNCTION public.get_profiles_for_approval() TO authenticated;