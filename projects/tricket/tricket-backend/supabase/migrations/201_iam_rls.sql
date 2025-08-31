/**********************************************************************************************************************
*  Arquivo: 201_iam_rls.sql
*  Objetivo: Habilitar RLS e criar políticas de acesso para entidades IAM.
*  Padrões:  - ENABLE ROW LEVEL SECURITY
*            - REVOKE INSERT/UPDATE/DELETE de authenticated
*            - GRANT SELECT a authenticated quando aplicável
*            - Políticas com checagem por vínculo de usuário e ADMIN via RBAC
**********************************************************************************************************************/

-- Helper inline para ADMIN: EXISTS (join rbac_user_roles -> rbac_roles.name = 'ADMIN')
-- Não cria função; usa subconsulta em cada policy para manter simplicidade.

/* 1) iam_profiles */
ALTER TABLE public.iam_profiles ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.iam_profiles FROM authenticated;
GRANT SELECT ON public.iam_profiles TO authenticated;

DROP POLICY IF EXISTS select_iam_profiles ON public.iam_profiles;
CREATE POLICY select_iam_profiles ON public.iam_profiles
FOR SELECT
USING (
  -- PF do próprio usuário
  EXISTS (
    SELECT 1 FROM public.iam_individual_details id
    WHERE id.profile_id = iam_profiles.id AND id.auth_user_id = auth.uid()
  )
  OR
  -- Membro da organização
  EXISTS (
    SELECT 1 FROM public.iam_organization_members m
    WHERE m.organization_profile_id = iam_profiles.id AND m.member_user_id = auth.uid()
  )
  OR
  -- ADMIN
  EXISTS (
    SELECT 1 FROM public.rbac_user_roles ur
    JOIN public.rbac_roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid() AND r.name = 'ADMIN'
  )
);

/* 2) iam_individual_details */
ALTER TABLE public.iam_individual_details ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.iam_individual_details FROM authenticated;
GRANT SELECT ON public.iam_individual_details TO authenticated;

DROP POLICY IF EXISTS select_iam_individual_details ON public.iam_individual_details;
CREATE POLICY select_iam_individual_details ON public.iam_individual_details
FOR SELECT
USING (
  auth_user_id = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM public.rbac_user_roles ur
    JOIN public.rbac_roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid() AND r.name = 'ADMIN'
  )
);

/* 3) iam_organization_details */
ALTER TABLE public.iam_organization_details ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.iam_organization_details FROM authenticated;
GRANT SELECT ON public.iam_organization_details TO authenticated;

DROP POLICY IF EXISTS select_iam_organization_details ON public.iam_organization_details;
CREATE POLICY select_iam_organization_details ON public.iam_organization_details
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.iam_organization_members m
    WHERE m.organization_profile_id = iam_organization_details.profile_id
      AND m.member_user_id = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.rbac_user_roles ur
    JOIN public.rbac_roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid() AND r.name = 'ADMIN'
  )
);

/* 4) iam_organization_members */
ALTER TABLE public.iam_organization_members ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.iam_organization_members FROM authenticated;
GRANT SELECT ON public.iam_organization_members TO authenticated;

DROP POLICY IF EXISTS select_iam_organization_members ON public.iam_organization_members;
CREATE POLICY select_iam_organization_members ON public.iam_organization_members
FOR SELECT
USING (
  member_user_id = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM public.iam_organization_members m
    WHERE m.organization_profile_id = iam_organization_members.organization_profile_id
      AND m.member_user_id = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.rbac_user_roles ur
    JOIN public.rbac_roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid() AND r.name = 'ADMIN'
  )
);

/* 5) iam_addresses */
ALTER TABLE public.iam_addresses ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.iam_addresses FROM authenticated;
GRANT SELECT ON public.iam_addresses TO authenticated;

DROP POLICY IF EXISTS select_iam_addresses ON public.iam_addresses;
CREATE POLICY select_iam_addresses ON public.iam_addresses
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.iam_profiles p
    WHERE p.id = iam_addresses.profile_id AND (
      EXISTS (
        SELECT 1 FROM public.iam_individual_details id
        WHERE id.profile_id = p.id AND id.auth_user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.iam_organization_members m
        WHERE m.organization_profile_id = p.id AND m.member_user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.rbac_user_roles ur
        JOIN public.rbac_roles r ON r.id = ur.role_id
        WHERE ur.user_id = auth.uid() AND r.name = 'ADMIN'
      )
    )
  )
);

/* 6) iam_contacts */
ALTER TABLE public.iam_contacts ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.iam_contacts FROM authenticated;
GRANT SELECT ON public.iam_contacts TO authenticated;

DROP POLICY IF EXISTS select_iam_contacts ON public.iam_contacts;
CREATE POLICY select_iam_contacts ON public.iam_contacts
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.iam_profiles p
    WHERE p.id = iam_contacts.profile_id AND (
      EXISTS (
        SELECT 1 FROM public.iam_individual_details id
        WHERE id.profile_id = p.id AND id.auth_user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.iam_organization_members m
        WHERE m.organization_profile_id = p.id AND m.member_user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.rbac_user_roles ur
        JOIN public.rbac_roles r ON r.id = ur.role_id
        WHERE ur.user_id = auth.uid() AND r.name = 'ADMIN'
      )
    )
  )
);

/* 7) iam_profile_uploaded_documents */
ALTER TABLE public.iam_profile_uploaded_documents ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.iam_profile_uploaded_documents FROM authenticated;
GRANT SELECT ON public.iam_profile_uploaded_documents TO authenticated;

DROP POLICY IF EXISTS select_iam_profile_uploaded_documents ON public.iam_profile_uploaded_documents;
CREATE POLICY select_iam_profile_uploaded_documents ON public.iam_profile_uploaded_documents
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.iam_profiles p
    WHERE p.id = public.iam_profile_uploaded_documents.profile_id AND (
      EXISTS (
        SELECT 1 FROM public.iam_individual_details id
        WHERE id.profile_id = p.id AND id.auth_user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.iam_organization_members m
        WHERE m.organization_profile_id = p.id AND m.member_user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.rbac_user_roles ur
        JOIN public.rbac_roles r ON r.id = ur.role_id
        WHERE ur.user_id = auth.uid() AND r.name = 'ADMIN'
      )
    )
  )
);

/* 8) iam_profile_rejections */
ALTER TABLE public.iam_profile_rejections ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.iam_profile_rejections FROM authenticated;
GRANT SELECT ON public.iam_profile_rejections TO authenticated;

DROP POLICY IF EXISTS select_iam_profile_rejections ON public.iam_profile_rejections;
CREATE POLICY select_iam_profile_rejections ON public.iam_profile_rejections
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.iam_profiles p
    WHERE p.id = iam_profile_rejections.profile_id AND (
      EXISTS (
        SELECT 1 FROM public.iam_individual_details id
        WHERE id.profile_id = p.id AND id.auth_user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.iam_organization_members m
        WHERE m.organization_profile_id = p.id AND m.member_user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.rbac_user_roles ur
        JOIN public.rbac_roles r ON r.id = ur.role_id
        WHERE ur.user_id = auth.uid() AND r.name = 'ADMIN'
      )
    )
  )
);

/* 9) iam_rejection_reasons (catálogo público autenticado, somente leitura) */
ALTER TABLE public.iam_rejection_reasons ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.iam_rejection_reasons FROM authenticated;
GRANT SELECT ON public.iam_rejection_reasons TO authenticated;

DROP POLICY IF EXISTS select_iam_rejection_reasons ON public.iam_rejection_reasons;
CREATE POLICY select_iam_rejection_reasons ON public.iam_rejection_reasons
FOR SELECT
USING (
  is_active IS TRUE
  OR EXISTS (
    SELECT 1 FROM public.rbac_user_roles ur
    JOIN public.rbac_roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid() AND r.name = 'ADMIN'
  )
);

/* 10) iam_user_preferences (somente o próprio usuário) */
ALTER TABLE public.iam_user_preferences ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.iam_user_preferences FROM authenticated;
GRANT SELECT ON public.iam_user_preferences TO authenticated;

DROP POLICY IF EXISTS select_iam_user_preferences ON public.iam_user_preferences;
CREATE POLICY select_iam_user_preferences ON public.iam_user_preferences
FOR SELECT
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.rbac_user_roles ur
    JOIN public.rbac_roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid() AND r.name = 'ADMIN'
  )
);

/* 11) iam_profile_invitations (regras básicas de leitura) */
ALTER TABLE public.iam_profile_invitations ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.iam_profile_invitations FROM authenticated;
GRANT SELECT ON public.iam_profile_invitations TO authenticated;

DROP POLICY IF EXISTS select_iam_profile_invitations ON public.iam_profile_invitations;
CREATE POLICY select_iam_profile_invitations ON public.iam_profile_invitations
FOR SELECT
USING (
  invited_by_user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.rbac_user_roles ur
    JOIN public.rbac_roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid() AND r.name = 'ADMIN'
  )
);

-- Observação: Não são criadas policies de INSERT/UPDATE/DELETE para authenticated nas tabelas IAM.
-- Toda escrita deve ocorrer por funções SECURITY DEFINER já presentes (ex.: register_* e set_active_profile).
