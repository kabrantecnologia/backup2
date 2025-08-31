/**********************************************************************************************************************
* -- INFORMAÇÕES DO SCRIPT --
* NOME DO ARQUIVO: 10_function_e_triggers_aceite_termos_cms.sql
* VERSÃO: 2.1
* CRIADO POR: Gemini
* DATA DE CRIAÇÃO: 2025-07-27
*
* -- SUMÁRIO --
* Este script implementa a lógica de automação para registrar o aceite dos Termos de Uso e da Política de
* Privacidade, utilizando a nova arquitetura do Módulo de Conteúdo (CMS).
* Uma única função de gatilho (`handle_user_confirmation_agreement`) é criada para ser disparada quando um
* usuário confirma seu e-mail ou já é inserido com o e-mail confirmado.
* A função busca dinamicamente a versão mais recente dos documentos legais na tabela `cms_post_versions`
* e registra o aceite na tabela `cms_post_user_agreements`.
*
* -- LOG DE ALTERAÇÕES (v2.1) --
* - CORREÇÃO: Adicionado o prefixo de esquema 'public.' às tabelas 'cms_posts' e 'cms_post_versions'
* dentro da função. Isso é necessário porque a função é definida com 'SECURITY DEFINER' e um 'search_path'
* vazio, o que exige que todas as referências a tabelas sejam totalmente qualificadas para evitar erros.
*
**********************************************************************************************************************/

/**********************************************************************************************************************
* SEÇÃO 1: FUNÇÃO DE GATILHO (TRIGGER FUNCTION)
* Descrição: Função que contém a lógica para registrar o aceite dos documentos legais.
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.handle_user_confirmation_agreement()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_terms_version_id uuid;
    v_privacy_version_id uuid;
    v_registration_ip inet;
BEGIN
    -- Busca o ID da versão mais recente dos "Termos de Uso".
    -- CORREÇÃO: Qualificando a tabela com o esquema 'public'.
    SELECT pv.id INTO v_terms_version_id
    FROM public.cms_posts p
    JOIN LATERAL (
        SELECT pv_inner.id
        FROM public.cms_post_versions pv_inner
        WHERE pv_inner.post_id = p.id
        ORDER BY pv_inner.version DESC
        LIMIT 1
    ) pv ON true
    WHERE p.slug = 'termos-de-uso' AND p.status = 'PUBLISHED';

    -- Busca o ID da versão mais recente da "Política de Privacidade".
    -- CORREÇÃO: Qualificando a tabela com o esquema 'public'.
    SELECT pv.id INTO v_privacy_version_id
    FROM public.cms_posts p
    JOIN LATERAL (
        SELECT pv_inner.id
        FROM public.cms_post_versions pv_inner
        WHERE pv_inner.post_id = p.id
        ORDER BY pv_inner.version DESC
        LIMIT 1
    ) pv ON true
    WHERE p.slug = 'politica-de-privacidade' AND p.status = 'PUBLISHED';

    -- Tenta extrair o endereço IP do registro do usuário.
    BEGIN
        v_registration_ip := (NEW.raw_user_meta_data->>'registration_ip')::INET;
    EXCEPTION WHEN OTHERS THEN
        v_registration_ip := NULL;
    END;

    -- Se encontrou uma versão válida dos Termos de Uso, insere o registro de aceite.
    IF v_terms_version_id IS NOT NULL THEN
        INSERT INTO public.cms_post_user_agreements (profile_id, post_version_id, ip_address)
        VALUES (NEW.id, v_terms_version_id, v_registration_ip)
        ON CONFLICT (profile_id, post_version_id) DO NOTHING;
    END IF;

    -- Se encontrou uma versão válida da Política de Privacidade, insere o registro de aceite.
    IF v_privacy_version_id IS NOT NULL THEN
        INSERT INTO public.cms_post_user_agreements (profile_id, post_version_id, ip_address)
        VALUES (NEW.id, v_privacy_version_id, v_registration_ip)
        ON CONFLICT (profile_id, post_version_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;
COMMENT ON FUNCTION public.handle_user_confirmation_agreement() IS 'Gatilho para registrar o aceite dos documentos legais (Termos e Privacidade) quando o e-mail do usuário é confirmado.';
GRANT EXECUTE ON FUNCTION public.handle_user_confirmation_agreement() TO supabase_auth_admin;


/**********************************************************************************************************************
* SEÇÃO 2: GATILHOS (TRIGGERS)
* Descrição: Associa a função de gatilho aos eventos correspondentes na tabela `auth.users`.
**********************************************************************************************************************/

-- Remove os gatilhos antigos, se existirem, para evitar duplicidade.
DROP TRIGGER IF EXISTS zz_email_confirmed_acceptances ON auth.users;
DROP TRIGGER IF EXISTS zz_new_user_confirmed_email_acceptance ON auth.users;

-- Gatilho 1: Para usuários existentes que confirmam o e-mail.
-- Dispara a função `handle_user_confirmation_agreement` após a coluna `email_confirmed_at` ser atualizada.
CREATE TRIGGER zz_user_email_confirmation_agreement
AFTER UPDATE OF email_confirmed_at ON auth.users
FOR EACH ROW
WHEN (OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL)
EXECUTE FUNCTION public.handle_user_confirmation_agreement();

-- Gatilho 2: Para novos usuários que já chegam com e-mail confirmado (ex: login social).
-- Dispara a mesma função `handle_user_confirmation_agreement` após a inserção de um novo usuário.
CREATE TRIGGER zz_new_confirmed_user_agreement
AFTER INSERT ON auth.users
FOR EACH ROW
WHEN (NEW.email_confirmed_at IS NOT NULL)
EXECUTE FUNCTION public.handle_user_confirmation_agreement();
