-- Função: set_active_profile
-- Permite que um usuário defina qual de seus perfis (individual ou de organização) está ativo.
CREATE OR REPLACE FUNCTION public.set_active_profile(p_profile_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_auth_user_id UUID := auth.uid();
    v_is_member BOOLEAN;
BEGIN
    -- Verifica se o usuário autenticado tem permissão para acessar o perfil alvo.
    SELECT EXISTS (
        -- Verifica se é o perfil individual do próprio usuário.
        (SELECT 1 FROM public.iam_individual_details WHERE auth_user_id = v_auth_user_id AND profile_id = p_profile_id)
        UNION ALL
        -- Verifica se o usuário é membro da organização.
        (SELECT 1 FROM public.iam_organization_members WHERE member_user_id = v_auth_user_id AND organization_profile_id = p_profile_id)
    )
    INTO v_is_member;

    IF NOT v_is_member THEN
        RAISE EXCEPTION 'Permission denied: User does not belong to the specified profile.';
    END IF;

    -- Insere ou atualiza a preferência de perfil ativo para o usuário.
    INSERT INTO public.iam_user_preferences (user_id, active_profile_id)
    VALUES (v_auth_user_id, p_profile_id)
    ON CONFLICT (user_id)
    DO UPDATE SET active_profile_id = EXCLUDED.active_profile_id, updated_at = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_active_profile(UUID) TO authenticated;
COMMENT ON FUNCTION public.set_active_profile(UUID) IS 'Define o perfil ativo para o usuário autenticado, armazenando a preferência no banco de dados.';
