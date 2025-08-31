-- ENUM: profile_type_enum
-- Define os tipos de perfis de usuário disponíveis no sistema.
-- Uso: profiles.profile_type, profile_invitations.invited_as_profile_type
CREATE TYPE public.profile_type_enum AS ENUM (
    'INDIVIDUAL',   -- Representa um perfil de pessoa física.
    'ORGANIZATION'  -- Representa um perfil de pessoa jurídica/empresa.
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