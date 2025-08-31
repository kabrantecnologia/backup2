# Tarefa 01 — IAM, Cadastro e Onboarding

- Branch sugerida: `feat/01-iam-onboarding`
- Objetivo: Implementar cadastro PF/PJ, convites, seletor de perfil ativo, aprovações e verificações básicas.

## Checklist
- [x] Criar branch a partir de `dev`.
- [x] Migrações IAM (se faltantes ou ajustes):
  - `iam_profiles`, `iam_individual_details`, `iam_organization_details`, `iam_organization_members`, `iam_profile_invitations`, `iam_user_preferences`, `iam_profile_rejections`, `iam_rejection_reasons`, `iam_contacts`, `iam_addresses` (geoloc PostGIS), `iam_profile_uploaded_documents`.
  - Índices e constraints pendentes (conferir `110-supabase_arquitetura.md`).
- [ ] Funções:
  - [x] `set_active_profile(p_profile_id uuid)` (grants a `authenticated` confirmados).
  - RPCs de apoio (se necessário): `rpc_register_individual`, `rpc_register_organization` (ou usar `register_*` existentes com wrappers RPC padronizados).
- [ ] Policies/RLS: revisar/ajustar acesso autenticado às tabelas IAM conforme fluxos.
- [x] Views de apoio (admin): `view_admin_profile_approval` (existente).
- [ ] Comandos:
  ```bash
  cd ~/workspaces/projects/tricket/tricket-backend
  supabase db push --yes --db-url "postgresql://postgres.dev_tricket_tenant:yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH@localhost:5408/postgres"
  cd ~/workspaces/projects/tricket/tricket-tests
  pytest
  ```
- [ ] Correções até 100% dos testes.
- [ ] Atualizar changelog.

## Aceite
- Usuário pode registrar PF/PJ, ativar perfil, receber convites e ser aprovado por admin.

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 1)
- `docs/110-supabase_arquitetura.md`
- `docs/requisitos-sistema-tricket.md`
- `docs/rpc-functions-standard.md`
