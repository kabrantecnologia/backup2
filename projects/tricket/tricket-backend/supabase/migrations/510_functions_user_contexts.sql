/**********************************************************************************************************************
*   SEÇÃO 1: FUNÇÃO PRINCIPAL - GET_USER_CONTEXTS
*   Descrição: Função que consolida os dados de contexto do usuário em uma única chamada.
**********************************************************************************************************************/

-- Cria a nova versão da função, adaptada para a estrutura de perfis unificada.
CREATE OR REPLACE FUNCTION public.get_user_contexts()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_auth_user_id UUID := auth.uid();
    v_preferred_profile_id UUID;
    v_user_data JSONB;
    v_all_profiles JSONB;
    v_active_profile JSONB;
    v_individual_profile JSONB;
    v_first_org_profile JSONB;
    v_available_profiles JSONB;
BEGIN
    -- 1. Validação de Autenticação
    IF v_auth_user_id IS NULL THEN
        RETURN jsonb_build_object('error', 'Usuário não autenticado');
    END IF;

    -- 2. Coleta de Dados Básicos do Usuário
    SELECT jsonb_build_object(
        'user_id', u.id,
        'email', u.email,
        'email_confirmed', (u.email_confirmed_at IS NOT NULL),
        'is_team_member', EXISTS (
            SELECT 1 FROM public.rbac_user_roles ur
            JOIN public.rbac_roles r ON ur.role_id = r.id
            WHERE ur.user_id = u.id AND r.name IN ('ADMIN', 'SUPPORT')
        )
    ) INTO v_user_data
    FROM auth.users u
    WHERE u.id = v_auth_user_id;

    IF v_user_data IS NULL THEN 
        RETURN jsonb_build_object('error', 'Usuário não encontrado');
    END IF;

    -- 3. Coleta de Todos os Perfis Associados ao Usuário
    WITH all_user_profiles AS (
        -- Perfil Individual do usuário
        SELECT 
            p.id AS profile_id, 
            p.profile_type, 
            p.onboarding_status, 
            p.avatar_url, 
            p.time_zone, 
            id.full_name AS display_name, 
            COALESCE(id.profile_role::TEXT, 'INDIVIDUAL') AS role,
            p.created_at
        FROM public.iam_profiles p
        JOIN public.iam_individual_details id ON p.id = id.profile_id
        WHERE id.auth_user_id = v_auth_user_id AND p.profile_type = 'INDIVIDUAL'
        UNION ALL
        -- Perfis de Organizações das quais o usuário é membro
        SELECT 
            p_org.id AS profile_id, 
            p_org.profile_type, 
            p_org.onboarding_status, 
            p_org.avatar_url, 
            p_org.time_zone, 
            COALESCE(od.trade_name, od.company_name) AS display_name, 
            COALESCE(om.role::TEXT, 'MEMBER') AS role,
            p_org.created_at
        FROM public.iam_organization_members om 
        INNER JOIN public.iam_profiles p_org ON om.organization_profile_id = p_org.id
        INNER JOIN public.iam_organization_details od ON p_org.id = od.profile_id
        WHERE om.member_user_id = v_auth_user_id 
            AND om.is_active = true
    )
    SELECT jsonb_agg(jsonb_build_object(
        'profile_id', p.profile_id, 
        'profile_type', p.profile_type, 
        'onboarding_status', p.onboarding_status,
        'avatar_url', p.avatar_url, 
        'display_name', p.display_name, 
        'role', p.role, 
        'time_zone', p.time_zone,
        'created_at', p.created_at
    ) ORDER BY p.created_at ASC) INTO v_all_profiles 
    FROM all_user_profiles p;

    -- Se não houver perfis, retorna uma estrutura mínima.
    IF v_all_profiles IS NULL OR jsonb_array_length(v_all_profiles) = 0 THEN
        RETURN jsonb_build_object('user_data', v_user_data, 'active_profile', NULL, 'available_profiles', '[]'::jsonb);
    END IF;

    -- 4. Busca pela Preferência de Perfil Ativo do Usuário
    BEGIN
        SELECT active_profile_id INTO v_preferred_profile_id 
        FROM public.iam_user_preferences 
        WHERE user_id = v_auth_user_id;
    EXCEPTION
        WHEN undefined_table THEN 
            v_preferred_profile_id := NULL;
        WHEN OTHERS THEN 
            v_preferred_profile_id := NULL;
    END;

    -- 5. Determinação do Perfil Ativo
    -- Primeiro, tenta usar o perfil preferido se existir e for válido
    IF v_preferred_profile_id IS NOT NULL THEN
        SELECT p INTO v_active_profile 
        FROM jsonb_array_elements(v_all_profiles) p 
        WHERE (p->>'profile_id')::uuid = v_preferred_profile_id;
    END IF;

    -- Se não encontrou perfil preferido válido, aplica lógica de fallback
    IF v_active_profile IS NULL THEN
        -- Busca perfil individual primeiro
        SELECT p INTO v_individual_profile 
        FROM jsonb_array_elements(v_all_profiles) p 
        WHERE p->>'profile_type' = 'INDIVIDUAL'
        ORDER BY (p->>'created_at')::timestamptz ASC
        LIMIT 1;
        
        -- Busca primeiro perfil organizacional
        SELECT p INTO v_first_org_profile 
        FROM jsonb_array_elements(v_all_profiles) p 
        WHERE p->>'profile_type' = 'ORGANIZATION'
        ORDER BY (p->>'created_at')::timestamptz ASC
        LIMIT 1;

        -- Lógica de Fallback melhorada:
        -- 1. Perfil individual completo (não limitado)
        -- 2. Perfil organizacional com role de admin/owner
        -- 3. Qualquer perfil individual
        -- 4. Qualquer perfil organizacional
        -- 5. Primeiro perfil da lista
        IF v_individual_profile IS NOT NULL AND 
           v_individual_profile->>'onboarding_status' NOT IN ('LIMITED_ACCESS_COLLABORATOR_ONLY', 'BLOCKED') THEN
            v_active_profile := v_individual_profile;
        ELSIF v_first_org_profile IS NOT NULL AND 
              v_first_org_profile->>'role' IN ('OWNER', 'ADMIN') THEN
            v_active_profile := v_first_org_profile;
        ELSIF v_individual_profile IS NOT NULL THEN
            v_active_profile := v_individual_profile;
        ELSIF v_first_org_profile IS NOT NULL THEN
            v_active_profile := v_first_org_profile;
        ELSE
            -- Fallback final: primeiro perfil disponível
            SELECT p INTO v_active_profile 
            FROM jsonb_array_elements(v_all_profiles) p 
            ORDER BY (p->>'created_at')::timestamptz ASC
            LIMIT 1;
        END IF;
    END IF;

    -- 6. Construção da Lista de Perfis Disponíveis para o seletor da UI
    SELECT jsonb_agg(jsonb_build_object(
        'profile_id', p->'profile_id', 
        'profile_type', p->'profile_type',
        'display_name', p->'display_name', 
        'avatar_url', p->'avatar_url',
        'onboarding_status', p->'onboarding_status',
        'role', p->'role',
        'is_active', (p->>'profile_id')::uuid = (v_active_profile->>'profile_id')::uuid
    ) ORDER BY 
        -- Prioriza perfil ativo primeiro
        CASE WHEN (p->>'profile_id')::uuid = (v_active_profile->>'profile_id')::uuid THEN 0 ELSE 1 END,
        -- Depois por tipo (individual primeiro)
        CASE WHEN p->>'profile_type' = 'INDIVIDUAL' THEN 0 ELSE 1 END,
        -- Por último por data de criação
        (p->>'created_at')::timestamptz ASC
    ) INTO v_available_profiles
    FROM jsonb_array_elements(v_all_profiles) p
    WHERE p->>'onboarding_status' NOT IN ('BLOCKED', 'DELETED');

    -- 7. Validação Final e Retorno
    -- Garante que sempre temos um perfil ativo válido
    IF v_active_profile IS NULL AND jsonb_array_length(v_all_profiles) > 0 THEN
        SELECT p INTO v_active_profile 
        FROM jsonb_array_elements(v_all_profiles) p 
        WHERE p->>'onboarding_status' NOT IN ('BLOCKED', 'DELETED')
        ORDER BY (p->>'created_at')::timestamptz ASC
        LIMIT 1;
    END IF;

    -- Adiciona informações extras ao perfil ativo
    IF v_active_profile IS NOT NULL THEN
        v_active_profile := v_active_profile || jsonb_build_object(
            'is_individual', v_active_profile->>'profile_type' = 'INDIVIDUAL',
            'is_organization', v_active_profile->>'profile_type' = 'ORGANIZATION',
            'can_manage_organization', v_active_profile->>'role' IN ('OWNER', 'ADMIN'),
            'is_limited_access', v_active_profile->>'onboarding_status' = 'LIMITED_ACCESS_COLLABORATOR_ONLY'
        );
    END IF;

    -- 8. Retorno da Estrutura de Dados Final
    RETURN jsonb_build_object(
        'success', true,
        'user_data', v_user_data,
        'active_profile', v_active_profile,
        'available_profiles', COALESCE(v_available_profiles, '[]'::jsonb),
        'total_profiles', COALESCE(jsonb_array_length(v_all_profiles), 0),
        'has_individual_profile', EXISTS (
            SELECT 1 FROM jsonb_array_elements(v_all_profiles) p 
            WHERE p->>'profile_type' = 'INDIVIDUAL'
        ),
        'has_organization_profiles', EXISTS (
            SELECT 1 FROM jsonb_array_elements(v_all_profiles) p 
            WHERE p->>'profile_type' = 'ORGANIZATION'
        )
    );
END;
$$;

/**********************************************************************************************************************
*   SEÇÃO 2: PERMISSÕES E METADADOS
*   Descrição: Concede as permissões necessárias e adiciona comentários à função.
**********************************************************************************************************************/

-- Concede permissão de execução para qualquer usuário autenticado.
GRANT EXECUTE ON FUNCTION public.get_user_contexts() TO authenticated;

-- Adiciona um comentário descritivo à função.
COMMENT ON FUNCTION public.get_user_contexts() IS 'Retorna um objeto JSONB otimizado para o frontend, contendo o perfil ativo do usuário (baseado em preferências ou lógica de fallback) e a lista de todos os perfis disponíveis para ele.';

-- =====================================================================
-- SEÇÃO 4: FUNÇÃO DE NAVEGAÇÃO DA UI
-- Descrição: Constrói a estrutura de navegação completa para o usuário.
-- Esta função é genérica e não precisa de alterações.
-- =====================================================================

CREATE OR REPLACE FUNCTION public.get_navigation_for_user()
RETURNS JSONB AS $$
DECLARE
    user_roles_ids UUID[];
    result_json JSONB;
BEGIN
    -- 1. Obtém os IDs dos papéis (roles) do usuário logado.
    SELECT ARRAY_AGG(role_id) INTO user_roles_ids
    FROM public.rbac_user_roles
    WHERE user_id = auth.uid();

    -- 2. Constrói a estrutura de navegação de forma recursiva e hierárquica.
    WITH RECURSIVE accessible_elements AS (
        SELECT el.*
        FROM public.ui_app_elements el
        JOIN public.ui_role_element_permissions rep ON el.id = rep.element_id
        WHERE rep.role_id = ANY(user_roles_ids)
        UNION
        SELECT el.*
        FROM public.ui_app_elements el
        INNER JOIN accessible_elements ae ON el.id = ae.parent_id
    ),
    page_menus AS (
        SELECT
            p.id AS page_id,
            jsonb_agg(jsonb_build_object('id', el.id, 'label', el.label, 'icon', el.icon, 'path', el.path) ORDER BY el.position) AS tabs
        FROM accessible_elements el
        JOIN public.ui_app_pages p ON el.page_id = p.id
        WHERE el.element_type = 'PAGE_TAB'
        GROUP BY p.id
    ),
    grid_configs AS (
        SELECT
            g.page_id,
            jsonb_build_object(
                'id', g.id,
                'collection_id', g.collection_id,
                'description', g.description,
                'columns', COALESCE(gc.columns_agg, '[]'::jsonb)
            ) AS grid_config
        FROM public.ui_grids g
        LEFT JOIN (
            SELECT
                grid_id,
                jsonb_agg(jsonb_build_object(
                    'data_key', data_key,
                    'label', label,
                    'size', size,
                    'position', position,
                    'is_visible', is_visible
                ) ORDER BY position) AS columns_agg
            FROM public.ui_grid_columns
            GROUP BY grid_id
        ) gc ON g.id = gc.grid_id
    ),
    menu_tree AS (
        SELECT
            el.id, el.label, el.icon, el.path, el.parent_id, el.position, el.page_id,
            pm.tabs AS page_menu,
            gc.grid_config AS grid,
            (SELECT jsonb_agg(sub_items ORDER BY (sub_items->>'position')::int) FROM (
                SELECT jsonb_build_object(
                    'id', sub.id,
                    'label', sub.label,
                    'icon', sub.icon,
                    'path', sub.path,
                    'position', sub.position,
                    'pageMenu', COALESCE(sub_pm.tabs, '[]'::jsonb),
                    'grid', sub_gc.grid_config
                ) AS sub_items
                FROM accessible_elements sub
                LEFT JOIN page_menus sub_pm ON sub_pm.page_id = sub.page_id
                LEFT JOIN grid_configs sub_gc ON sub_gc.page_id = sub.page_id
                WHERE sub.parent_id = el.id AND sub.element_type = 'SIDEBAR_MENU'
            ) AS sub_query) AS "subItems"
        FROM accessible_elements el
        LEFT JOIN page_menus pm ON pm.page_id = el.page_id
        LEFT JOIN grid_configs gc ON gc.page_id = el.page_id
        WHERE el.parent_id IS NULL AND el.element_type = 'SIDEBAR_MENU'
    )
    -- 3. Agrega o resultado final em um único array JSON.
    SELECT jsonb_agg(jsonb_build_object(
        'id', mt.id,
        'icon', mt.icon,
        'label', mt.label,
        'path', mt.path,
        'isOpened', false,
        'pageMenu', COALESCE(mt.page_menu, '[]'::jsonb),
        'grid', mt.grid,
        'subItems', COALESCE(mt."subItems", '[]'::jsonb)
    ) ORDER BY mt.position) INTO result_json
    FROM menu_tree mt;

    RETURN COALESCE(result_json, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';
COMMENT ON FUNCTION public.get_navigation_for_user() IS 'Retorna uma estrutura JSON completa com o menu principal, menus de página (abas) e configurações de grid, de acordo com as permissões do usuário.';
