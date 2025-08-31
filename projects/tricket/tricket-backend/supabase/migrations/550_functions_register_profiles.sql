/**********************************************************************************************************************
*   SEÇÃO 1: FUNÇÃO DE REGISTRO DE PERFIL DE ORGANIZAÇÃO
*   Descrição: Função completa para registrar uma nova organização, incluindo seu representante legal.
**********************************************************************************************************************/

-- Funções auxiliares para normalização
CREATE OR REPLACE FUNCTION public.normalize_cpf_cnpj(input_text TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN REGEXP_REPLACE(input_text, '[^0-9]', '', 'g');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.normalize_phone(input_text TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN REGEXP_REPLACE(input_text, '[^0-9]', '', 'g');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.normalize_name(input_text TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN UPPER(TRIM(input_text));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.register_organization_profile(
    individual_data JSONB,    -- Dados do representante legal (PF)
    organization_data JSONB,  -- Dados da organização (PJ)
    address_data JSONB        -- Dados do endereço principal da organização
)
RETURNS UUID -- Retorna o ID do novo perfil da organização
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_auth_user_id UUID := auth.uid();
    v_representative_pf_profile_id UUID;
    v_organization_profile_id UUID;
    v_address_geolocation extensions.geography(Point, 4326);
    v_normalized_cpf TEXT;
    v_normalized_cnpj TEXT;
    v_normalized_phone TEXT;
    v_normalized_company_name TEXT;
    v_normalized_trade_name TEXT;
    v_normalized_full_name TEXT;
    v_normalized_contact_phone TEXT;
BEGIN
    IF v_auth_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuário não autenticado.';
    END IF;

    -- Normalizar dados do representante
    v_normalized_cpf := public.normalize_cpf_cnpj(individual_data->>'cpf');
    v_normalized_full_name := public.normalize_name(individual_data->>'full_name');
    v_normalized_contact_phone := public.normalize_phone(individual_data->>'contact_phone');

    -- Etapa 1: Criar ou atualizar o perfil individual (PF) do representante.
    SELECT id.profile_id INTO v_representative_pf_profile_id FROM public.iam_individual_details id WHERE id.auth_user_id = v_auth_user_id;

    IF NOT FOUND THEN
        INSERT INTO public.iam_profiles (profile_type, onboarding_status) VALUES ('INDIVIDUAL', 'LIMITED_ACCESS_COLLABORATOR_ONLY') RETURNING id INTO v_representative_pf_profile_id;
        INSERT INTO public.iam_individual_details (profile_id, auth_user_id, profile_role, full_name, cpf, birth_date, contact_phone, contact_email)
        VALUES (v_representative_pf_profile_id, v_auth_user_id, (COALESCE(individual_data->>'profile_role', 'COLLABORATOR'))::public.individual_profile_role_enum, v_normalized_full_name, v_normalized_cpf, (individual_data->>'birth_date')::DATE, v_normalized_contact_phone, individual_data->>'contact_email');
    ELSE
        UPDATE public.iam_profiles SET onboarding_status = 'PENDING_ADMIN_APPROVAL', updated_at = now() WHERE id = v_representative_pf_profile_id;
        UPDATE public.iam_individual_details SET profile_role = (COALESCE(individual_data->>'profile_role', profile_role::TEXT))::public.individual_profile_role_enum, full_name = COALESCE(v_normalized_full_name, full_name), cpf = COALESCE(v_normalized_cpf, cpf), birth_date = COALESCE((individual_data->>'birth_date')::DATE, birth_date), contact_phone = COALESCE(v_normalized_contact_phone, contact_phone), contact_email = COALESCE(individual_data->>'contact_email', contact_email), updated_at = now() WHERE profile_id = v_representative_pf_profile_id;
    END IF;

    -- Normalizar dados da organização
    v_normalized_cnpj := public.normalize_cpf_cnpj(organization_data->>'cnpj');
    v_normalized_company_name := public.normalize_name(organization_data->>'company_name');
    v_normalized_trade_name := public.normalize_name(organization_data->>'trade_name');
    v_normalized_contact_phone := public.normalize_phone(organization_data->>'contact_phone');

    -- Etapa 2: Criar o perfil da Organização (PJ).
    INSERT INTO public.iam_profiles (profile_type, onboarding_status, avatar_url) VALUES ('ORGANIZATION', 'PENDING_ADMIN_APPROVAL', organization_data->>'avatar_url') RETURNING id INTO v_organization_profile_id;

    -- Etapa 3: Inserir os detalhes da Organização.
    INSERT INTO public.iam_organization_details (profile_id, platform_role, company_name, trade_name, cnpj, company_type, income_value_cents, contact_email, contact_phone)
    VALUES (v_organization_profile_id, (organization_data->>'platform_role')::public.organization_platform_role_enum, v_normalized_company_name, v_normalized_trade_name, v_normalized_cnpj, (organization_data->>'company_type')::public.company_type_enum, COALESCE((organization_data->>'income_value_cents')::BIGINT, ((organization_data->>'income_value')::NUMERIC(15,2) * 100)::BIGINT), organization_data->>'contact_email', v_normalized_contact_phone);

    -- Etapa 4: Inserir o endereço da Organização.
    IF address_data IS NOT NULL AND address_data != 'null'::JSONB AND address_data != '{}'::JSONB THEN
        IF address_data->>'latitude' IS NOT NULL AND address_data->>'longitude' IS NOT NULL THEN
            v_address_geolocation := public.calculate_geolocation((address_data->>'latitude')::NUMERIC, (address_data->>'longitude')::NUMERIC);
        ELSE
            v_address_geolocation := NULL;
        END IF;
        INSERT INTO public.iam_addresses (profile_id, address_type, is_default, street, number, complement, neighborhood, city_id, state_id, zip_code, country, notes, latitude, longitude, geolocation)
        VALUES (v_organization_profile_id, (COALESCE(address_data->>'address_type', 'MAIN'))::public.address_type_enum, COALESCE((address_data->>'is_default')::BOOLEAN, true), address_data->>'street', address_data->>'number', address_data->>'complement', address_data->>'neighborhood', COALESCE((address_data->>'city_id')::INTEGER, (address_data->>'city')::INTEGER), COALESCE((address_data->>'state_id')::INTEGER, (address_data->>'state')::INTEGER), address_data->>'zip_code', COALESCE(address_data->>'country', 'Brasil'), address_data->>'notes', (address_data->>'latitude')::NUMERIC(10,7), (address_data->>'longitude')::NUMERIC(10,7), v_address_geolocation);
    END IF;

    -- Etapa 5: Vincular o representante como 'OWNER' da Organização.
    INSERT INTO public.iam_organization_members (member_user_id, organization_profile_id, role) VALUES (v_auth_user_id, v_organization_profile_id, 'OWNER'::public.organization_member_role_enum);

    -- Etapa 6: Definir o perfil da organização recém-criado como ativo para o usuário autenticado
    -- Depende da função: public.set_active_profile(UUID)
    PERFORM public.set_active_profile(v_organization_profile_id);

    RETURN v_organization_profile_id;

EXCEPTION
    WHEN unique_violation THEN RAISE EXCEPTION 'Erro de cadastro: Dados duplicados (CPF, CNPJ ou Email). Detalhe: %', SQLERRM;
    WHEN others THEN RAISE EXCEPTION 'Erro inesperado ao cadastrar organização (SQLSTATE: %): %', SQLSTATE, SQLERRM;
END;
$$;
COMMENT ON FUNCTION public.register_organization_profile(JSONB, JSONB, JSONB) IS 'Registra um novo perfil de organização, incluindo seu representante, detalhes, endereço e o vínculo de membro.';
GRANT EXECUTE ON FUNCTION public.register_organization_profile(JSONB, JSONB, JSONB) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 2: FUNÇÃO DE REGISTRO DE PERFIL INDIVIDUAL
*   Descrição: Função completa para registrar um novo usuário pessoa física.
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.register_individual_profile(
    profile_data JSONB,   -- Dados do perfil (nome, cpf, etc.)
    address_data JSONB    -- Dados do endereço principal
)
RETURNS UUID -- Retorna o ID do novo perfil
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_auth_user_id UUID := auth.uid();
    v_new_profile_id UUID;
    v_address_geolocation extensions.geography(Point, 4326);
    v_normalized_cpf TEXT;
    v_normalized_full_name TEXT;
    v_normalized_contact_phone TEXT;
BEGIN
    IF v_auth_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuário não autenticado.';
    END IF;

    -- Etapa 1: Verificar se o usuário já possui um perfil individual para evitar duplicidade.
    IF EXISTS (SELECT 1 FROM public.iam_individual_details WHERE auth_user_id = v_auth_user_id) THEN
        RAISE EXCEPTION 'Perfil individual já existente para este usuário.';
    END IF;

    -- Etapa 2: Inserir o registro base na tabela `iam_profiles`.
    INSERT INTO public.iam_profiles (avatar_url, profile_type, onboarding_status) VALUES (profile_data->'avatar_url', 'INDIVIDUAL', 'PENDING_ADMIN_APPROVAL') RETURNING id INTO v_new_profile_id;

    -- Normalizar dados do perfil individual
    v_normalized_cpf := public.normalize_cpf_cnpj(profile_data->>'cpf');
    v_normalized_full_name := public.normalize_name(profile_data->>'full_name');
    v_normalized_contact_phone := public.normalize_phone(profile_data->>'contact_phone');

    -- Etapa 3: Inserir os detalhes específicos na tabela `iam_individual_details`.
    INSERT INTO public.iam_individual_details (profile_id, auth_user_id, full_name, cpf, birth_date, contact_email, contact_phone, profile_role, income_value_cents)
    VALUES (v_new_profile_id, v_auth_user_id, v_normalized_full_name, v_normalized_cpf, (profile_data->>'birth_date')::DATE, profile_data->>'contact_email', v_normalized_contact_phone, (COALESCE(profile_data->>'profile_role', 'CONSUMER'))::public.individual_profile_role_enum, (profile_data->>'income_value_cents')::BIGINT);

    -- Etapa 4: Inserir o endereço, se fornecido.
    IF address_data IS NOT NULL AND address_data != 'null'::JSONB AND address_data != '{}'::JSONB THEN
        IF (address_data->>'latitude') IS NOT NULL AND (address_data->>'longitude') IS NOT NULL THEN
            v_address_geolocation := public.calculate_geolocation((address_data->>'latitude')::NUMERIC, (address_data->>'longitude')::NUMERIC);
        END IF;
        INSERT INTO public.iam_addresses (profile_id, address_type, is_default, street, number, complement, neighborhood, city_id, state_id, zip_code, country, notes, latitude, longitude, geolocation)
        VALUES (v_new_profile_id, (COALESCE(address_data->>'address_type', 'MAIN'))::public.address_type_enum, COALESCE((address_data->>'is_default')::BOOLEAN, TRUE), address_data->>'street', address_data->>'number', address_data->>'complement', address_data->>'neighborhood', (address_data->>'city_id')::INTEGER, (address_data->>'state_id')::INTEGER, address_data->>'zip_code', COALESCE(address_data->>'country', 'Brasil'), address_data->>'notes', (address_data->>'latitude')::NUMERIC(10,7), (address_data->>'longitude')::NUMERIC(10,7), v_address_geolocation);
    END IF;

    RETURN v_new_profile_id;

EXCEPTION
    WHEN unique_violation THEN RAISE EXCEPTION 'Erro de cadastro: CPF ou Email já cadastrado. Detalhe: %', SQLERRM;
    WHEN others THEN RAISE EXCEPTION 'Erro inesperado ao cadastrar perfil individual (SQLSTATE: %): %', SQLSTATE, SQLERRM;
END;
$$;
COMMENT ON FUNCTION public.register_individual_profile(JSONB, JSONB) IS 'Registra um novo perfil individual, incluindo dados pessoais e endereço, de forma atômica.';
GRANT EXECUTE ON FUNCTION public.register_individual_profile(JSONB, JSONB) TO authenticated;