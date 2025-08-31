/**********************************************************************************************************************
*   -- INFORMAÇÕES DO SCRIPT --
*   NOME DO ARQUIVO: 01_initial_settings.sql
*   VERSÃO: 1.0
*   CRIADO POR: Gemini
*   DATA DE CRIAÇÃO: 2025-07-25
*
*   -- SUMÁRIO --
*   Este script estabelece a configuração inicial do banco de dados para a aplicação. Inclui a configuração de
*   extensões essenciais do PostgreSQL, a criação de buckets de armazenamento para diversos ativos, a implementação
*   de uma função de atualização automática de timestamp para tabelas e a definição de todos os tipos ENUM
*   personalizados utilizados no esquema do banco de dados. Estas configurações são fundamentais para os objetos
*   de banco de dados e a lógica de negócios subsequentes.
*
**********************************************************************************************************************/

/**********************************************************************************************************************
*   SEÇÃO 1: EXTENSÕES
*   Descrição: Habilita as extensões necessárias do PostgreSQL para adicionar novas funcionalidades ao banco de dados.
**********************************************************************************************************************/

-- Habilita o pg_cron para agendamento de tarefas (ex: execução de rotinas periódicas).
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
COMMENT ON EXTENSION pg_cron IS 'Extensão para agendamento de tarefas no PostgreSQL. Utilizada para execução de tarefas agendadas no banco de dados.';

-- Habilita o PostGIS para suporte a dados espaciais e geográficos (ex: cálculos baseados em localização).
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
COMMENT ON EXTENSION postgis IS 'Extensão para suporte a dados espaciais e geográficos. Utilizada para cálculos geográficos e armazenamento de coordenadas.';


/**********************************************************************************************************************
*   SEÇÃO 2: AUTOMAÇÃO - TIMESTAMP `updated_at`
*   Descrição: Implementa uma função de gatilho (trigger) para atualizar automaticamente a coluna `updated_at`
*                em qualquer tabela que a utilize. Isso garante que os horários de modificação dos dados estejam sempre atualizados.
**********************************************************************************************************************/

-- Esta função é projetada para ser usada por um gatilho. Quando uma linha é atualizada,
-- ela define o valor da coluna `updated_at` para o timestamp atual.
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';
COMMENT ON FUNCTION public.handle_updated_at() IS 'Atualiza automaticamente a coluna updated_at para o timestamp atual sempre que uma linha é modificada.';

/**********************************************************************************************************************
*   SEÇÃO 3: TIPOS DE DADOS PERSONALIZADOS (ENUMs)
*   Descrição: Define todos os tipos enumerados (ENUMs) personalizados para a aplicação. ENUMs fornecem uma maneira
*                de criar um conjunto estático e ordenado de valores, garantindo a consistência dos dados para campos específicos.
**********************************************************************************************************************/

-- ENUM: element_type_enum
-- Diferencia elementos da UI para renderização dinâmica.
-- Uso: ui_elements.element_type
CREATE TYPE public.element_type_enum AS ENUM (
    'SIDEBAR_MENU', -- Um item no menu lateral principal.
    'PAGE_TAB'      -- Uma aba dentro de uma página específica.
);
COMMENT ON TYPE public.element_type_enum IS 'Diferencia os elementos da UI: um item do menu lateral ou uma aba dentro de uma página. Referenciado em: ui_elements.element_type.';

/**********************************************************************************************************************
*   SEÇÃO 1: ENUMS
*   Descrição: Tipos de dados enum para serem usados em várias tabelas.
**********************************************************************************************************************/

-- ENUM: profile_type_enum
-- Define os tipos de perfis de usuário disponíveis no sistema.
-- Uso: profiles.profile_type, profile_invitations.invited_as_profile_type
CREATE TYPE public.profile_type_enum AS ENUM (
    'INDIVIDUAL',   -- Representa um perfil de pessoa física.
    'ORGANIZATION',  -- Representa um perfil de pessoa jurídica/empresa.
    'MASTER'  -- Representa um perfil de pessoa jurídica/empresa.
);
COMMENT ON TYPE public.profile_type_enum IS 'Tipos de Perfil. Valores: INDIVIDUAL (Pessoa física), ORGANIZATION (Pessoa jurídica). Referenciado em: profiles.profile_type, profile_invitations.invited_as_profile_type.';

-- ENUM: onboarding_status_enum
-- Rastreia os vários estágios do processo de onboarding do usuário/perfil.
-- Uso: profiles.onboarding_status
CREATE TYPE public.onboarding_status_enum AS ENUM (
    'PENDING_PROFILE_COMPLETION',       -- Usuário confirmou email, precisa preencher detalhes do perfil.
    'PENDING_PROFILE_DOCUMENTATION',    -- Usuário confirmou email, precisa enviar documentos do perfil.
    'PENDING_ADMIN_APPROVAL',           -- Dados do perfil enviados, aguardando aprovação do administrador.
    'APPROVED_BY_TRICKET',              -- Aprovado pelo administrador, pronto para onboarding Asaas/Cappta.
    'PENDING_ASAAS_VERIFICATION',       -- Onboarding Asaas em andamento.
    'PENDING_CAPPTA_VERIFICATION',      -- Onboarding Cappta em andamento.
    'ACTIVE',                           -- Perfil totalmente ativo e aprovado.
    'REJECTED_BY_TRICKET',              -- Cadastro rejeitado pela Tricket.
    'REJECTED_BY_ASAAS',                -- Onboarding Asaas rejeitado.
    'REJECTED_BY_CAPPTA',               -- Onboarding Cappta rejeitado.
    'LIMITED_ACCESS_COLLABORATOR_ONLY', -- Acesso limitado para colaboradores que não transacionam.
    'SUSPENDED',                        -- Acesso suspenso temporariamente.
    'DISABLED'                          -- Acesso desabilitado permanentemente.
    'TRICKET_STAFF'                     -- Acesso desabilitado permanentemente.
);
COMMENT ON TYPE public.onboarding_status_enum IS 'Status de Onboarding. Referenciado em: profiles.onboarding_status.';

-- ENUM: invitation_status_enum
-- Representa o status de um convite enviado a um usuário.
-- Uso: profile_invitations.status
CREATE TYPE public.invitation_status_enum AS ENUM (
    'PENDING',  -- Convite aguardando uma resposta.
    'ACCEPTED', -- Convite foi aceito.
    'REJECTED', -- Convite foi recusado.
    'EXPIRED'   -- Convite expirou sem resposta.
);
COMMENT ON TYPE public.invitation_status_enum IS 'Status de Convite. Referenciado em: profile_invitations.status.';

-- ENUM: individual_profile_role_enum
-- Define os papéis que um perfil individual pode ter na plataforma.
-- Uso: individual_details.profile_role
CREATE TYPE public.individual_profile_role_enum AS ENUM (
    'CONSUMER',     -- Um usuário consumidor padrão.
    'COLLABORATOR'  -- Um funcionário ou membro de uma organização.
);
COMMENT ON TYPE public.individual_profile_role_enum IS 'Papéis de Perfil Individual. Referenciado em: individual_details.profile_role.';

-- ENUM: organization_platform_role_enum
-- Define os papéis funcionais que uma organização pode ter na plataforma.
-- Uso: organization_details.platform_role
CREATE TYPE public.organization_platform_role_enum AS ENUM (
    'COMERCIANTE',    -- Organização atua como Comerciante (usa POS).
    'FORNECEDOR',     -- Organização atua como Fornecedor (vende no marketplace).
    'CONSUMIDOR_PJ'  -- Organização atua como Consumidor PJ (compra no marketplace).
);
COMMENT ON TYPE public.organization_platform_role_enum IS 'Papéis da Organização na Plataforma. Referenciado em: organization_details.platform_role.';

-- ENUM: organization_member_role_enum
-- Define os papéis que um membro pode ter dentro de uma organização.
-- Uso: organization_members.role, profile_invitations.role
CREATE TYPE public.organization_member_role_enum AS ENUM (
    'OWNER',   -- O proprietário principal da organização.
    'MANAGER', -- Um gerente com permissões amplas.
    'STAFF'    -- Um membro da equipe com permissões específicas e limitadas.
);
COMMENT ON TYPE public.organization_member_role_enum IS 'Papéis de Membro em Organização. Referenciado em: organization_members.role, profile_invitations.role.';

-- ENUM: company_type_enum
-- Lista os tipos societários de empresas ou entidades comerciais.
-- Uso: organization_details.company_type
CREATE TYPE public.company_type_enum AS ENUM (
    'MEI',          -- Microempreendedor Individual.
    'LTDA',         -- Sociedade Limitada.
    'SA',           -- Sociedade Anônima.
    'EIRELI',       -- Empresa Individual de Responsabilidade Limitada (obsoleto, mas mantido para dados legados).
    'ASSOCIATION',  -- Associação.
    'COOPERATIVE'   -- Cooperativa.
);
COMMENT ON TYPE public.company_type_enum IS 'Tipos de Empresa. Referenciado em: organization_details.company_type.';

-- ENUM: address_type_enum
-- Define os diferentes tipos de endereços que podem ser associados a um perfil.
-- Uso: addresses.address_type
CREATE TYPE public.address_type_enum AS ENUM (
    'SHIPPING', -- Endereço de entrega.
    'BILLING',  -- Endereço de cobrança.
    'MAIN'      -- Endereço principal (pode ser comercial ou residencial, dependendo do tipo de perfil).
);
COMMENT ON TYPE public.address_type_enum IS 'Tipos de Endereço. Referenciado em: addresses.address_type.';

-- ENUM: legal_document_type_enum
-- Especifica os tipos de documentos legais utilizados na plataforma.
-- Uso: platform_legal_documents.document_type, user_agreements.document_type
CREATE TYPE public.legal_document_type_enum AS ENUM (
    'TERMS_OF_SERVICE',   -- Termos de Uso Gerais.
    'PRIVACY_POLICY',     -- Política de Privacidade.
    'SUPPLIER_AGREEMENT', -- Contrato do Fornecedor.
    'MERCHANT_AGREEMENT'  -- Contrato do Comerciante (POS).
);
COMMENT ON TYPE public.legal_document_type_enum IS 'Tipos de Documento Legal. Referenciado em: platform_legal_documents.document_type, user_agreements.document_type.';

-- ENUM: bank_account_type_enum
-- Define os tipos de contas bancárias suportadas.
-- Uso: bank_accounts.account_type
CREATE TYPE public.bank_account_type_enum AS ENUM (
    'CONTA_CORRENTE',  -- Conta Corrente.
    'CONTA_POUPANCA',  -- Conta Poupança.
    'CONTA_PAGAMENTO'  -- Conta de Pagamento.
);
COMMENT ON TYPE public.bank_account_type_enum IS 'Tipos de Conta Bancária. Referenciado em: bank_accounts.account_type.';

-- ENUM: rejection_reason_category_enum
-- Categoriza os motivos de rejeição em vários processos (ex: onboarding).
-- Uso: rejection_reasons.category
CREATE TYPE public.rejection_reason_category_enum AS ENUM (
    'VALIDATION_ERROR',             -- Erros de validação de dados.
    'BUSINESS_RULES',               -- Violação de regras de negócio.
    'AUTH_ERROR',                   -- Erros de autenticação/autorização.
    'SYSTEM_ERROR',                 -- Erros internos do sistema ou de parceiros.
    'RATE_LIMIT',                   -- Limite de requisições excedido.
    'DOCUMENT_ISSUE',               -- Problemas com documentos enviados.
    'PROFILE_DATA_INCONSISTENCY',   -- Inconsistência nos dados do perfil.
    'OTHER'                         -- Outros motivos.
);
COMMENT ON TYPE public.rejection_reason_category_enum IS 'Categorias de Motivos de Rejeição. Referenciado em: rejection_reasons.category.';


-- ENUM: notification_type_enum
-- Define categorias para as notificações do usuário.
-- Uso: notifications.notification_type
CREATE TYPE public.notification_type_enum AS ENUM (
    'SYSTEM_ALERT',     -- Alertas importantes de todo o sistema.
    'NEW_FEATURE',      -- Anúncios sobre novas funcionalidades.
    'DOCUMENT_STATUS',  -- Atualizações sobre o status dos documentos enviados pelo usuário.
    'GENERAL_INFO'      -- Informações gerais ou anúncios.
);
COMMENT ON TYPE public.notification_type_enum IS 'Define categorias para as notificações, permitindo filtragem e ícones diferentes no front-end.';


-- =================================================================
-- TIPOS ENUMERADOS (ENUMS) - CMS
-- =================================================================

-- Define os tipos de conteúdo possíveis na plataforma.
CREATE TYPE cms_post_type AS ENUM (
    'BLOG_POST',
    'LEGAL_DOCUMENT'
);

-- Define os status possíveis para um post ou documento.
CREATE TYPE cms_post_status AS ENUM (
    'DRAFT',      -- Rascunho, não visível para o público.
    'PUBLISHED',  -- Publicado, visível para o público.
    'ARCHIVED'    -- Arquivado, não mais ativo, mas mantido para histórico.
);


/**********************************************************************************************************************
*   SEÇÃO 1: TABELAS DE LOOKUP GENÉRICAS
*   Descrição: Criação das tabelas que armazenam dados de referência, como códigos de bancos, estados e cidades.
*              Essas tabelas servem como fonte única de verdade para dados que raramente mudam.
**********************************************************************************************************************/

-- Tabela: generic_bank_codes
-- Armazena uma lista de códigos e nomes de bancos brasileiros, utilizada em integrações financeiras.
CREATE TABLE public.generic_bank_codes (
    id TEXT PRIMARY KEY,
    description TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.generic_bank_codes IS 'Tabela de lookup para códigos de banco. Pode ser usada por diversas integrações financeiras.';
COMMENT ON COLUMN public.generic_bank_codes.id IS 'PK - Código do banco (ex: "001", "341").';
COMMENT ON COLUMN public.generic_bank_codes.description IS 'Nome do banco (ex: "Banco do Brasil S.A.").';

-- Tabela: generic_states
-- Armazena os estados (unidades federativas) do Brasil.
CREATE TABLE public.generic_states (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    country_code TEXT DEFAULT 'BR',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.generic_states IS 'Tabela de lookup para os estados brasileiros.';
COMMENT ON COLUMN public.generic_states.id IS 'PK - Código numérico do estado (IBGE).';
COMMENT ON COLUMN public.generic_states.name IS 'Nome do estado (ex: "São Paulo").';
COMMENT ON COLUMN public.generic_states.country_code IS 'Código do país (padrão: "BR").';

-- Tabela: generic_cities
-- Armazena as cidades (municípios) do Brasil, relacionadas aos seus respectivos estados.
CREATE TABLE public.generic_cities (
    id INTEGER PRIMARY KEY,
    name TEXT,
    state_id INTEGER NOT NULL REFERENCES public.generic_states(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_name_state_id UNIQUE (name, state_id)
);
COMMENT ON TABLE public.generic_cities IS 'Tabela de lookup para os municípios brasileiros.';
COMMENT ON COLUMN public.generic_cities.id IS 'PK - Código numérico da cidade (IBGE).';
COMMENT ON COLUMN public.generic_cities.name IS 'Nome da cidade (ex: "Rio de Janeiro").';
COMMENT ON COLUMN public.generic_cities.state_id IS 'FK - Referência ao ID do estado na tabela generic_states.';
COMMENT ON CONSTRAINT unique_name_state_id ON public.generic_cities IS 'Garante que não existam cidades com o mesmo nome no mesmo estado.';