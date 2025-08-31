-- =================================================================
-- 950_seed_auth_iam_rbac.sql
-- Objetivo: Criar perfis IAM (PF e PJ) mínimos e vínculos de organização,
-- sem depender de criação de usuários em auth.users.
-- Estratégia: IDs determinísticos, upserts idempotentes.
-- =================================================================

-- PF perfis
INSERT INTO public.iam_profiles (id, profile_type, onboarding_status, active)
VALUES
    ('10000000-0000-0000-0000-0000000000b1', 'INDIVIDUAL', 'PENDING_ADMIN_APPROVAL', true),
    ('10000000-0000-0000-0000-0000000000b2', 'INDIVIDUAL', 'PENDING_ADMIN_APPROVAL', true)
ON CONFLICT (id) DO NOTHING;

-- Detalhes PF (sem auth_user_id para evitar FK com auth.users)
-- Se a coluna exigir NOT NULL para auth_user_id, este bloco será ignorado.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='iam_individual_details' AND column_name='auth_user_id' AND is_nullable='NO'
    ) THEN
        INSERT INTO public.iam_individual_details (profile_id, profile_role, full_name, cpf, birth_date, contact_email, contact_phone)
        VALUES
            ('10000000-0000-0000-0000-0000000000b1', 'CONSUMER', 'Fulano de Tal', '11122233344', '1990-01-01', 'pf1@tricket.dev', '+55 11 99999-0001'),
            ('10000000-0000-0000-0000-0000000000b2', 'CONSUMER', 'Ciclana de Tal', '55566677788', '1992-02-02', 'pf2@tricket.dev', '+55 11 99999-0002')
        ON CONFLICT (profile_id) DO NOTHING;
    END IF;
EXCEPTION WHEN others THEN
    -- Silencia erros caso constraints impeçam (ex.: unique cpf já existente)
    RAISE NOTICE 'Seed PF detalhes ignorado: %', SQLERRM;
END$$;

-- PJ perfis (organizações)
INSERT INTO public.iam_profiles (id, profile_type, onboarding_status, active)
VALUES
    ('20000000-0000-0000-0000-0000000000c1', 'ORGANIZATION', 'PENDING_ADMIN_APPROVAL', true),
    ('20000000-0000-0000-0000-0000000000c2', 'ORGANIZATION', 'PENDING_ADMIN_APPROVAL', true)
ON CONFLICT (id) DO NOTHING;

-- Detalhes PJ
INSERT INTO public.iam_organization_details (
    profile_id, platform_role, company_name, trade_name, cnpj, company_type,
    income_value_cents, contact_email, contact_phone, national_registry_for_legal_entities_status
)
VALUES
    ('20000000-0000-0000-0000-0000000000c1', 'FORNECEDOR', 'Fornecedor Alfa LTDA', 'Fornecedor Alfa', '11222333000181', 'LTDA',
     150000000, 'contato@fornecedor-alfa.dev', '+55 11 4000-1001', 'ATIVA'),
    ('20000000-0000-0000-0000-0000000000c2', 'FORNECEDOR', 'Fornecedor Beta S.A.', 'Fornecedor Beta', '22333444000172', 'SA',
     250000000, 'contato@fornecedor-beta.dev', '+55 11 4000-1002', 'ATIVA')
ON CONFLICT (profile_id) DO NOTHING;

-- Convida PF1 para ser OWNER da PJ1 se possível (apenas convite, sem FK obrigatório de auth.users)
INSERT INTO public.iam_profile_invitations (
    email, name, invited_as_profile_type, role, org_id, token, expires_at, status
)
VALUES (
    'pf1@tricket.dev', 'Fulano de Tal', 'INDIVIDUAL', 'OWNER', '20000000-0000-0000-0000-0000000000c1',
    'token-invite-pf1-owner-pj1', now() + interval '30 days', 'PENDING'
)
ON CONFLICT (token) DO NOTHING;
