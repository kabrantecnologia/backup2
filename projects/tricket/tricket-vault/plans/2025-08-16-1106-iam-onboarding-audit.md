# Plano: Auditoria IAM Onboarding

Data: 2025-08-16 11:06
Branch: feat/01-iam-onboarding

## Escopo
- Auditar RPCs e estruturas usadas pela suíte de testes para onboarding (PF e PJ).
- Verificar presença de funções auxiliares e GRANTs.
- Identificar lacunas de RLS/Policies nas tabelas IAM e correlatas.
- Definir plano de implementação (sem executar testes nesta etapa).

## Achados
- RPCs esperadas pelos testes (`tricket-tests/operations/`):
  - `register_individual_profile(profile_data jsonb, address_data jsonb)`
  - `register_organization_profile(individual_data jsonb, organization_data jsonb, address_data jsonb)`
  - Ambas chamadas via `client.rpc('<nome>', params)`.
- Presença em migrações:
  - `supabase/migrations/550_functions_register_profiles.sql` define ambas as funções acima com `SECURITY DEFINER`, `SET search_path=''` e `GRANT EXECUTE TO authenticated`.
  - `supabase/migrations/560_iam_functions.sql` define `set_active_profile(uuid)` com `SECURITY DEFINER` e `GRANT EXECUTE TO authenticated`.
  - `supabase/migrations/310_views_admin.sql` define `view_admin_profile_approval`.
- Tabelas IAM em `200_iam_tables.sql` criadas corretamente (`iam_profiles`, `iam_individual_details`, `iam_organization_details`, `iam_organization_members`, `iam_addresses`, `iam_contacts`, `iam_profile_uploaded_documents`, `iam_rejection_reasons`, `iam_profile_rejections`, `iam_user_preferences`).
- RBAC base em `120_rbac.sql` (roles e user_roles) presente.
- Lacuna: Não foi encontrada nenhuma instrução de RLS/Policies nas tabelas IAM (nenhum `ENABLE ROW LEVEL SECURITY` ou `CREATE POLICY`).

## Riscos
- Sem RLS, qualquer usuário com `authenticated` e privilégios de tabela pode ler ou modificar dados sensíveis via `from()` ignorando a via segura de RPCs.
- As funções de registro já usam `SECURITY DEFINER` e validam `auth.uid()`, mas devemos bloquear escrita direta nas tabelas e restringir leitura.

## Diretrizes de RLS propostas
- Padrão: RLS habilitada em todas as tabelas IAM. Revogar privilégios diretos de `INSERT/UPDATE/DELETE` de `authenticated`; uso somente via funções seguras.
- Seleção restrita conforme vínculo e papel:
  1. `iam_profiles` (SELECT):
     - PF: `EXISTS (SELECT 1 FROM iam_individual_details WHERE profile_id = iam_profiles.id AND auth_user_id = auth.uid())`.
     - PJ: `EXISTS (SELECT 1 FROM iam_organization_members WHERE organization_profile_id = iam_profiles.id AND member_user_id = auth.uid())`.
     - ADMIN: permitir via join `rbac_user_roles -> rbac_roles.name = 'ADMIN'`.
  2. `iam_individual_details` (SELECT): mesma regra da PF acima.
  3. `iam_organization_details` (SELECT): membros da organização ou ADMIN.
  4. `iam_organization_members` (SELECT): membros da organização, e ADMIN.
  5. `iam_addresses`, `iam_contacts`, `iam_profile_uploaded_documents`, `iam_profile_rejections` (SELECT): usuário deve poder ver registros cujo `profile_id` esteja visível conforme regra de `iam_profiles`; ADMIN vê tudo.
  6. `iam_rejection_reasons` (SELECT): público autenticado (somente leitura).
  7. `iam_user_preferences` (SELECT/UPSERT): somente o próprio usuário em `user_id = auth.uid()`. (Função `set_active_profile` já faz UPSERT; restringir operações diretas).
- Escrita
  - `INSERT/UPDATE/DELETE` para tabelas IAM: negar por padrão a `authenticated`. Qualquer escrita deve ocorrer por RPC `SECURITY DEFINER`.

## Alterações a implementar (nova migration 201_iam_rls.sql)
1. `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`
2. `REVOKE INSERT, UPDATE, DELETE ON TABLE ... FROM authenticated;` (manter `SELECT` com RLS ativo quando aplicável).
3. `CREATE POLICY` de SELECT para cada tabela conforme regras acima.
4. `CREATE POLICY` de UPDATE/DELETE apenas para ADMIN quando for necessário fazer manutenção via API (se não houver endpoints, manter negado).
5. Garantir que funções `register_*` e `set_active_profile` já tenham `GRANT EXECUTE TO authenticated` (ok).

## Checklist de Implementação
- [ ] Criar `supabase/migrations/201_iam_rls.sql` com todas as instruções.
- [ ] `supabase db push` (ver regras do projeto).
- [ ] Validar rapidamente (manual) acesso via `client.from()` lendo apenas dados do próprio perfil.
- [ ] Executar suíte de testes (etapa posterior).

## Considerações
- `view_admin_profile_approval` será utilizável por ADMIN; se for consumida via REST, assegurar `rpc/get_profiles_for_approval` já exige ADMIN.
- Manter consistência de `SET search_path=''` e qualificação `public.` em policies que usam funções.
