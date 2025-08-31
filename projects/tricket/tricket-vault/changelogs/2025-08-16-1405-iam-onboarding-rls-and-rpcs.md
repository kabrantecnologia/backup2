# Changelog — IAM Onboarding (RLS e RPCs)

Data: 2025-08-16 14:05 (BRT)
Branch: feat/01-iam-onboarding

## Resumo
- Auditoria de onboarding (PF e PJ) concluída.
- Migração criada para habilitar RLS e policies nas tabelas IAM.
- Confirmação de RPCs necessárias já existentes e com GRANT apropriado.
- Migrações aplicadas com `supabase db push`.
- Suíte de testes de integração executada com sucesso (3 passed, 2 warnings).

## Detalhes
- RPCs confirmadas:
  - `public.register_individual_profile(profile_data jsonb, address_data jsonb)`
  - `public.register_organization_profile(individual_data jsonb, organization_data jsonb, address_data jsonb)`
  - `public.set_active_profile(p_profile_id uuid)`
- Migration adicionada:
  - `supabase/migrations/201_iam_rls.sql`
    - ENABLE RLS em: `iam_profiles`, `iam_individual_details`, `iam_organization_details`, `iam_organization_members`, `iam_addresses`, `iam_contacts`, `iam_profile_uploaded_documents`, `iam_profile_rejections`, `iam_profile_invitations`, `iam_rejection_reasons`, `iam_user_preferences`.
    - Policies de SELECT baseadas em vínculo do usuário (PF própria, membro de PJ) e ADMIN via `rbac_roles`.
    - Revogação de INSERT/UPDATE/DELETE para `authenticated` nas tabelas IAM (escrita apenas via funções `SECURITY DEFINER`).
- Plano criado:
  - `tricket-vault/plans/2025-08-16-1106-iam-onboarding-audit.md`

## Testes
- Comando: `PYTHONPATH=. pytest -q` em `tricket-tests/`.
- Resultado: 3 passed, 2 warnings (retornos em testes informativos).

## Próximos passos
- Opcional: adicionar `pytest.ini` em `tricket-tests/` para setar `pythonpath = .` e evitar precisar exportar variável.
- Revisar/atualizar docs no `tricket-tests/README.md` sobre execução (`PYTHONPATH=.`).
