-- View: view_admin_profile_approval
-- Consolida dados de perfis individuais e de organização para o painel de aprovação de administradores.
CREATE OR REPLACE VIEW public.view_admin_profile_approval AS
-- Perfis Individuais (PF)
SELECT
    p.id AS profile_id, p.profile_type, p.onboarding_status, id.profile_role::text AS profile_role,
    id.full_name AS name, id.contact_email AS email, id.cpf AS cpf_cnpj, id.birth_date,
    NULL AS company_type, id.contact_phone AS mobile_phone, id.income_value_cents,
    a.street AS address, a.number AS address_number, a.complement, a.state_id AS province, a.zip_code AS postal_code
FROM public.iam_profiles p
JOIN public.iam_individual_details id ON p.id = id.profile_id
LEFT JOIN public.iam_addresses a ON p.id = a.profile_id AND a.is_default = true
WHERE p.profile_type = 'INDIVIDUAL' AND p.onboarding_status <> 'LIMITED_ACCESS_COLLABORATOR_ONLY'
UNION ALL
-- Perfis de Organização (PJ)
SELECT
    p.id AS profile_id, p.profile_type, p.onboarding_status, od.platform_role::text AS profile_role,
    od.company_name AS name, od.contact_email AS email, od.cnpj AS cpf_cnpj, NULL AS birth_date,
    od.company_type, od.contact_phone AS mobile_phone, od.income_value_cents,
    a.street AS address, a.number AS address_number, a.complement, a.state_id AS province, a.zip_code AS postal_code
FROM public.iam_profiles p
JOIN public.iam_organization_details od ON p.id = od.profile_id
LEFT JOIN public.iam_addresses a ON p.id = a.profile_id AND a.is_default = true
WHERE p.profile_type = 'ORGANIZATION' AND p.onboarding_status <> 'LIMITED_ACCESS_COLLABORATOR_ONLY';
COMMENT ON VIEW public.view_admin_profile_approval IS 'View otimizada para administradores aprovarem perfis, consolidando dados de PF e PJ e excluindo colaboradores de acesso limitado.';
