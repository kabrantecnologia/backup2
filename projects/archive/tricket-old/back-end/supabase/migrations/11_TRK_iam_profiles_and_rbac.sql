/**********************************************************************************************************************
*   -- INFORMAÇÕES DO SCRIPT --
*   NOME DO ARQUIVO: 06_iam_profiles_and_rbac.sql
*   VERSÃO: 1.0
*
*   -- SUMÁRIO --
*   Este script define a arquitetura central de Gerenciamento de Identidade e Acesso (IAM). Ele cria as tabelas
*   para perfis de usuários (tanto individuais quanto de organizações), implementa um sistema de Controle de Acesso
*   Baseado em Funções (RBAC) com papéis e permissões, e estabelece as entidades relacionadas, como endereços,
*   contatos, documentos legais e convites. O objetivo é criar uma estrutura segura e flexível para gerenciar
*   quem são os usuários e o que eles podem fazer no sistema.
*
**********************************************************************************************************************/

/**********************************************************************************************************************
*   SEÇÃO 2: ESTRUTURA PRINCIPAL DE PERFIS
*   Descrição: Tabela central que define a existência de um perfil, seja ele individual ou de uma organização.
**********************************************************************************************************************/

-- Tabela: iam_profiles
-- Armazena informações básicas e comuns a todos os tipos de perfis.
CREATE TABLE public.iam_profiles (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    profile_type public.profile_type_enum NOT NULL,
    avatar_url TEXT,
    onboarding_status public.onboarding_status_enum NOT NULL,
    time_zone TEXT DEFAULT 'America/Sao_Paulo',
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.iam_profiles IS 'Tabela principal de perfis, armazenando informações básicas comuns a todos os tipos de perfil.';
COMMENT ON COLUMN public.iam_profiles.profile_type IS 'Define se o perfil é de uma pessoa física (INDIVIDUAL) ou jurídica (ORGANIZATION).';
COMMENT ON COLUMN public.iam_profiles.avatar_url IS 'URL para a imagem de perfil (avatar).';
COMMENT ON COLUMN public.iam_profiles.onboarding_status IS 'Status atual do processo de cadastro e verificação do perfil.';
COMMENT ON COLUMN public.iam_profiles.time_zone IS 'Fuso horário do perfil (padrão: "America/Sao_Paulo").';
COMMENT ON COLUMN public.iam_profiles.active IS 'Indica se o perfil está ativo ou inativo no sistema.';

-- Gatilho para atualizar o campo `updated_at` na tabela `iam_profiles`.
CREATE TRIGGER on_iam_profiles_update
BEFORE UPDATE ON public.iam_profiles
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

/**********************************************************************************************************************
*   SEÇÃO 3: DETALHES DOS PERFIS E MEMBROS
*   Descrição: Tabelas que estendem `iam_profiles` com informações específicas para cada tipo de perfil
*              (individual e organização) e a relação de membros em uma organização.
**********************************************************************************************************************/

-- Tabela: iam_individual_details
-- Contém informações detalhadas e exclusivas de perfis de pessoa física.
CREATE TABLE public.iam_individual_details (
    profile_id UUID PRIMARY KEY REFERENCES public.iam_profiles(id) ON DELETE CASCADE,
    auth_user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE RESTRICT,
    profile_role public.individual_profile_role_enum NOT NULL,
    full_name TEXT NOT NULL,
    cpf TEXT UNIQUE NOT NULL,
    birth_date DATE NOT NULL,
    gender TEXT,
    income_value_cents BIGINT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.iam_individual_details IS 'Armazena informações específicas para perfis de pessoa física (INDIVIDUAL).';
COMMENT ON COLUMN public.iam_individual_details.profile_id IS 'FK para iam_profiles.id, estabelecendo a relação 1-para-1.';
COMMENT ON COLUMN public.iam_individual_details.auth_user_id IS 'FK para auth.users.id. Vincula o perfil ao usuário de autenticação do Supabase.';
COMMENT ON COLUMN public.iam_individual_details.profile_role IS 'Papel do perfil individual (ex: CONSUMER, COLLABORATOR).';
COMMENT ON COLUMN public.iam_individual_details.income_value_cents IS 'Renda mensal declarada, em centavos.';
COMMENT ON COLUMN public.iam_individual_details.contact_email IS 'Email de contato opcional, pode ser diferente do email de autenticação.';

-- Tabela: iam_organization_details
-- Contém informações detalhadas e exclusivas de perfis de pessoa jurídica.
CREATE TABLE public.iam_organization_details (
    profile_id UUID PRIMARY KEY REFERENCES public.iam_profiles(id) ON DELETE CASCADE,
    platform_role public.organization_platform_role_enum NOT NULL,
    company_name TEXT NOT NULL,
    trade_name TEXT,
    cnpj TEXT UNIQUE NOT NULL,
    company_type public.company_type_enum NOT NULL,
    income_value_cents BIGINT,
    contact_email TEXT UNIQUE,
    contact_phone TEXT,
    national_registry_for_legal_entities_status TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.iam_organization_details IS 'Armazena informações específicas para perfis de pessoa jurídica (ORGANIZATION).';
COMMENT ON COLUMN public.iam_organization_details.platform_role IS 'Papel da organização na plataforma (ex: COMERCIANTE, FORNECEDOR).';
COMMENT ON COLUMN public.iam_organization_details.company_name IS 'Razão Social da empresa.';
COMMENT ON COLUMN public.iam_organization_details.trade_name IS 'Nome Fantasia da empresa.';
COMMENT ON COLUMN public.iam_organization_details.income_value_cents IS 'Faturamento mensal estimado, em centavos.';
COMMENT ON COLUMN public.iam_organization_details.national_registry_for_legal_entities_status IS 'Situação cadastral do CNPJ na Receita Federal (ex: ATIVA).';

-- Tabela: iam_organization_members
-- Associa usuários a organizações, definindo seus papéis (ex: OWNER, MANAGER).
CREATE TABLE public.iam_organization_members (
    organization_profile_id UUID NOT NULL REFERENCES public.iam_profiles(id) ON DELETE CASCADE,
    member_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role public.organization_member_role_enum NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (organization_profile_id, member_user_id)
);
COMMENT ON TABLE public.iam_organization_members IS 'Relaciona usuários (membros) a perfis de organização, definindo seus papéis.';
COMMENT ON COLUMN public.iam_organization_members.organization_profile_id IS 'FK para o perfil da organização.';
COMMENT ON COLUMN public.iam_organization_members.member_user_id IS 'FK para o usuário (auth.users) que é membro.';
COMMENT ON COLUMN public.iam_organization_members.role IS 'Papel do membro dentro da organização (ex: OWNER, MANAGER, STAFF).';

/**********************************************************************************************************************
*   SEÇÃO 4: ENTIDADES RELACIONADAS A PERFIS
*   Descrição: Tabelas que armazenam dados diretamente ligados aos perfis, como convites, endereços, contatos,
*              documentos e registros de aceites legais.
**********************************************************************************************************************/

-- Tabela: iam_profile_invitations
-- Gerencia convites para novos usuários se juntarem à plataforma ou a uma organização.
CREATE TABLE public.iam_profile_invitations (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    email TEXT NOT NULL,
    name TEXT,
    invited_as_profile_type public.profile_type_enum NOT NULL,
    role public.organization_member_role_enum,
    invited_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    org_id UUID REFERENCES public.iam_profiles(id) ON DELETE CASCADE,
    token TEXT UNIQUE NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    status public.invitation_status_enum NOT NULL DEFAULT 'PENDING',
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT chk_role_org_id_type CHECK (role IS NULL OR (org_id IS NOT NULL AND invited_as_profile_type = 'INDIVIDUAL'))
);
COMMENT ON TABLE public.iam_profile_invitations IS 'Gerencia os convites para criação de novos perfis ou associação a organizações existentes.';
COMMENT ON COLUMN public.iam_profile_invitations.role IS 'Define o papel que o convidado terá na organização (se aplicável).';
COMMENT ON COLUMN public.iam_profile_invitations.invited_by_user_id IS 'ID do usuário que enviou o convite.';
COMMENT ON COLUMN public.iam_profile_invitations.org_id IS 'ID da organização para a qual o usuário está sendo convidado.';
COMMENT ON COLUMN public.iam_profile_invitations.token IS 'Token único e seguro para validar o aceite do convite.';
COMMENT ON CONSTRAINT chk_role_org_id_type ON public.iam_profile_invitations IS 'Garante que um papel só seja definido em convites para um indivíduo se juntar a uma organização.';

-- Tabela: iam_addresses
-- Armazena endereços físicos associados aos perfis.
CREATE TABLE public.iam_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.iam_profiles(id) ON DELETE CASCADE,
    address_type public.address_type_enum NOT NULL,
    is_default BOOLEAN DEFAULT false,
    street TEXT NOT NULL,
    number TEXT NOT NULL,
    complement TEXT,
    neighborhood TEXT NOT NULL,
    city_id INTEGER NOT NULL REFERENCES public.generic_cities(id) ON DELETE RESTRICT,
    state_id INTEGER NOT NULL REFERENCES public.generic_states(id) ON DELETE RESTRICT,
    zip_code TEXT NOT NULL,
    country TEXT NOT NULL DEFAULT 'Brasil',
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    geolocation GEOGRAPHY(POINT, 4326),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.iam_addresses IS 'Armazena os endereços associados aos perfis (comercial, entrega, cobrança).';
COMMENT ON COLUMN public.iam_addresses.address_type IS 'Tipo do endereço (ex: SHIPPING, BILLING, MAIN).';
COMMENT ON COLUMN public.iam_addresses.is_default IS 'Indica se este é o endereço padrão para o seu tipo.';
COMMENT ON COLUMN public.iam_addresses.geolocation IS 'Coordenadas geográficas para uso com PostGIS (SRID 4326).';

-- Tabela: iam_contacts
-- Armazena informações de contato (email, telefone) associadas aos perfis.
CREATE TABLE public.iam_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.iam_profiles(id) ON DELETE CASCADE,
    name TEXT,
    label TEXT,
    email TEXT,
    phone TEXT,
    whatsapp BOOLEAN DEFAULT false,
    is_default BOOLEAN DEFAULT false,
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT at_least_one_contact_info CHECK (email IS NOT NULL OR phone IS NOT NULL)
);
COMMENT ON TABLE public.iam_contacts IS 'Armazena informações de contato (email, telefone) associadas aos perfis.';
COMMENT ON COLUMN public.iam_contacts.name IS 'Nome para identificar o contato (ex: "Contato Financeiro").';
COMMENT ON COLUMN public.iam_contacts.label IS 'Rótulo para o contato (ex: "Principal", "Emergência").';
COMMENT ON CONSTRAINT at_least_one_contact_info ON public.iam_contacts IS 'Garante que cada registro de contato tenha pelo menos um email ou um telefone.';

-- Tabela: iam_profile_uploaded_documents
-- Gerencia os arquivos enviados pelos perfis para verificação.
CREATE TABLE public.iam_profile_uploaded_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.iam_profiles(id) ON DELETE CASCADE,
    document_name TEXT NOT NULL,
    status TEXT NOT NULL,
    file_path TEXT NOT NULL,
    storage_bucket TEXT NOT NULL,
    verified_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    verification_date TIMESTAMPTZ,
    rejection_reason_id UUID,
    rejection_notes TEXT,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.iam_profile_uploaded_documents IS 'Gerencia documentos enviados pelos perfis (ex: CNH, Contrato Social).';
COMMENT ON COLUMN public.iam_profile_uploaded_documents.document_name IS 'Tipo do documento (ex: "ID_FRENTE", "COMPROVANTE_ENDERECO").';
COMMENT ON COLUMN public.iam_profile_uploaded_documents.status IS 'Status do documento (ex: "PENDING_REVIEW", "VERIFIED", "REJECTED").';
COMMENT ON COLUMN public.iam_profile_uploaded_documents.file_path IS 'Caminho do arquivo no bucket de armazenamento.';

-- Tabela: iam_rejection_reasons
-- Catálogo de motivos de rejeição padronizados para diversos processos.
CREATE TABLE public.iam_rejection_reasons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reason_code VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    category public.rejection_reason_category_enum NOT NULL,
    source_system TEXT,
    user_action_required TEXT,
    internal_notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.iam_rejection_reasons IS 'Catálogo de motivos de rejeição padronizados para processos como onboarding e verificação de documentos.';
COMMENT ON COLUMN public.iam_rejection_reasons.reason_code IS 'Código único para o motivo (ex: "DOCUMENTO_ILEGIVEL").';
COMMENT ON COLUMN public.iam_rejection_reasons.user_action_required IS 'Instrução clara para o usuário sobre como corrigir o problema.';

-- Adiciona a chave estrangeira de `iam_profile_uploaded_documents` para `iam_rejection_reasons`.
ALTER TABLE public.iam_profile_uploaded_documents
ADD CONSTRAINT fk_rejection_reason
FOREIGN KEY (rejection_reason_id) REFERENCES public.iam_rejection_reasons(id) ON DELETE SET NULL;

-- Tabela: iam_profile_rejections
-- Registra o histórico de rejeições ocorridas em um perfil.
CREATE TABLE public.iam_profile_rejections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.iam_profiles(id) ON DELETE CASCADE,
    rejection_reason_id UUID NOT NULL REFERENCES public.iam_rejection_reasons(id) ON DELETE RESTRICT,
    related_entity_id UUID,
    related_entity_type TEXT,
    rejected_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    rejected_at TIMESTAMPTZ DEFAULT now(),
    notes TEXT,
    is_resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,
    resolved_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.iam_profile_rejections IS 'Registra o histórico de rejeições de um perfil ou de entidades relacionadas a ele.';
COMMENT ON COLUMN public.iam_profile_rejections.related_entity_type IS 'Tipo da entidade que foi rejeitada (ex: "DOCUMENTO", "CONTA_BANCARIA").';
COMMENT ON COLUMN public.iam_profile_rejections.is_resolved IS 'Indica se o problema que causou a rejeição foi resolvido.';

/**********************************************************************************************************************
*   SEÇÃO 5: PREFERÊNCIAS DE USUÁRIO E FUNÇÕES
*   Descrição: Tabela e função para gerenciar o contexto de perfil ativo do usuário.
**********************************************************************************************************************/

-- Tabela: iam_user_preferences
-- Armazena preferências do usuário, como qual perfil está ativo na sessão.
CREATE TABLE IF NOT EXISTS public.iam_user_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    active_profile_id UUID REFERENCES public.iam_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE public.iam_user_preferences IS 'Armazena preferências do usuário, como o perfil ativo selecionado para a sessão atual.';

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
