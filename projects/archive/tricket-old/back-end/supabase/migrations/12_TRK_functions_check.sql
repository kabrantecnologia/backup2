/**********************************************************************************************************************
*   -- INFORMAÇÕES DO SCRIPT --
*   NOME DO ARQUIVO: 05_functions_check.sql
*   VERSÃO: 1.0
*   CRIADO POR: Gemini
*   DATA DE CRIAÇÃO: 2025-07-25
*
*   -- SUMÁRIO --
*   Este script cria um conjunto de funções PostgreSQL (RPC) para realizar verificações comuns e reutilizáveis
*   no banco de dados. As funções abrangem a checagem de existência e disponibilidade de e-mails e CPFs, além
*   de uma função auxiliar crucial para o sistema de Controle de Acesso Baseado em Funções (RBAC), que verifica
*   se um usuário possui um determinado papel. Essas funções são projetadas para serem seguras e eficientes,
*   sendo essenciais para a lógica de negócios e políticas de segurança de linha (RLS).
*
**********************************************************************************************************************/

/**********************************************************************************************************************
*   SEÇÃO 1: FUNÇÕES DE VERIFICAÇÃO DE E-MAIL
*   Descrição: Funções para consultar a existência, disponibilidade e detalhes de e-mails na base de usuários.
**********************************************************************************************************************/

-- Função: check_if_email_exists
-- Verifica se um e-mail já está cadastrado em `auth.users` e retorna dados da requisição.
CREATE OR REPLACE FUNCTION public.check_if_email_exists(email_to_check TEXT)
RETURNS TABLE (email_exists BOOLEAN, client_ip TEXT, user_agent TEXT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    _client_ip TEXT;
    _user_agent TEXT;
    _raw_ip TEXT;
BEGIN
    -- Tenta obter o IP e User-Agent do cabeçalho da requisição HTTP.
    BEGIN
        _raw_ip := nullif(current_setting('request.headers', true)::json->>'x-forwarded-for', '')::text;
        IF _raw_ip IS NOT NULL AND position(',' in _raw_ip) > 0 THEN
            _client_ip := trim(split_part(_raw_ip, ',', 1));
        ELSE
            _client_ip := _raw_ip;
        END IF;
        IF _client_ip IS NULL THEN
            _client_ip := nullif(current_setting('request.headers', true)::json->>'remote-addr', '')::text;
        END IF;
        _user_agent := nullif(current_setting('request.headers', true)::json->>'user-agent', '')::text;
    EXCEPTION
        WHEN OTHERS THEN
            _client_ip := NULL;
            _user_agent := NULL;
    END;

    -- Retorna o resultado da verificação junto com os dados do cliente.
    RETURN QUERY
    SELECT EXISTS (SELECT 1 FROM auth.users WHERE email = email_to_check) AS email_exists, _client_ip, _user_agent;
END;
$$;
COMMENT ON FUNCTION public.check_if_email_exists(TEXT) IS 'Verifica se um e-mail já existe em auth.users e retorna o IP e User-Agent do cliente.';
GRANT EXECUTE ON FUNCTION public.check_if_email_exists(TEXT) TO authenticated;

-- Função: check_email_details
-- Verifica um e-mail e retorna detalhes adicionais da conta, se existir.
CREATE OR REPLACE FUNCTION public.check_email_details(p_email TEXT)
RETURNS TABLE(email_exists BOOLEAN, user_id UUID, is_verified BOOLEAN, created_at TIMESTAMPTZ, last_sign_in_at TIMESTAMPTZ)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
    RETURN QUERY
    SELECT TRUE, u.id, u.email_confirmed_at IS NOT NULL, u.created_at, u.last_sign_in_at
    FROM auth.users u WHERE u.email = p_email LIMIT 1;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::BOOLEAN, NULL::TIMESTAMPTZ, NULL::TIMESTAMPTZ;
    END IF;
END;
$$;
COMMENT ON FUNCTION public.check_email_details(TEXT) IS 'Verifica se um e-mail existe e retorna detalhes como ID do usuário, status de verificação e datas.';
GRANT EXECUTE ON FUNCTION public.check_email_details(TEXT) TO authenticated;

-- Função: is_email_available
-- Verifica se um e-mail está disponível para um novo cadastro.
CREATE OR REPLACE FUNCTION public.is_email_available(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
    RETURN NOT EXISTS (SELECT 1 FROM auth.users WHERE email = p_email);
END;
$$;
COMMENT ON FUNCTION public.is_email_available(TEXT) IS 'Verifica se um e-mail está disponível para cadastro (ou seja, não existe em auth.users).';
GRANT EXECUTE ON FUNCTION public.is_email_available(TEXT) TO authenticated;

-- Função: check_multiple_emails
-- Verifica a disponibilidade de uma lista de e-mails de uma só vez.
CREATE OR REPLACE FUNCTION public.check_multiple_emails(p_emails TEXT[])
RETURNS TABLE(email TEXT, is_available BOOLEAN)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
    RETURN QUERY
    WITH email_list AS (SELECT unnest(p_emails) AS email)
    SELECT e.email, NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.email = e.email) AS is_available
    FROM email_list e;
END;
$$;
COMMENT ON FUNCTION public.check_multiple_emails(TEXT[]) IS 'Verifica a disponibilidade de um array de e-mails de forma otimizada.';
GRANT EXECUTE ON FUNCTION public.check_multiple_emails(TEXT[]) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 2: FUNÇÕES DE VERIFICAÇÃO DE DOCUMENTOS
*   Descrição: Funções para validar a existência de documentos (CPF) na base de dados.
**********************************************************************************************************************/

-- Função: check_cpf_exists
-- Verifica se um CPF, após limpeza de caracteres não numéricos, já existe na tabela de perfis individuais.
CREATE OR REPLACE FUNCTION public.check_cpf_exists(p_cpf TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    cleaned_cpf TEXT;
BEGIN
    -- Remove caracteres não numéricos do CPF para uma busca consistente.
    cleaned_cpf := regexp_replace(p_cpf, '[^0-9]', '', 'g');

    -- Verifica a existência do CPF limpo na tabela de detalhes individuais.
    RETURN EXISTS (SELECT 1 FROM public.iam_individual_details WHERE cpf = cleaned_cpf);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '';
COMMENT ON FUNCTION public.check_cpf_exists(TEXT) IS 'Verifica se um CPF (limpando a formatação) já existe na tabela iam_individual_details.';

/**********************************************************************************************************************
*   SEÇÃO 3: FUNÇÕES AUXILIARES DE CONTROLE DE ACESSO (RBAC)
*   Descrição: Funções essenciais para a implementação de políticas de segurança (RLS).
**********************************************************************************************************************/

-- Função: check_user_has_role
-- Verifica de forma segura se o usuário autenticado possui um determinado papel (role).
CREATE OR REPLACE FUNCTION public.check_user_has_role(p_role_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    has_role BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM public.rbac_user_roles ur
        JOIN public.rbac_roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid()
          AND r.name = p_role_name
    ) INTO has_role;
    RETURN has_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';
COMMENT ON FUNCTION public.check_user_has_role(TEXT) IS 'Função de segurança que verifica se o usuário autenticado possui um papel específico. Essencial para uso em políticas de RLS.';

-- Habilita a Segurança em Nível de Linha (RLS) para a tabela de papéis.
ALTER TABLE public.rbac_roles ENABLE ROW LEVEL SECURITY;

-- Política de Segurança: Allow authenticated read access to profile_roles
-- Permite que usuários autenticados leiam a lista de papéis disponíveis no sistema.
CREATE POLICY "Allow authenticated read access to profile_roles"
ON public.rbac_roles FOR SELECT
TO authenticated
USING (true);
