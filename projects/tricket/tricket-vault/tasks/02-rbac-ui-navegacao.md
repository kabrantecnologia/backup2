# Tarefa 02 — RBAC e Navegação de UI (Backend)

- Branch sugerida: `feat/02-rbac-ui-navegacao`
- Objetivo: Garantir papéis, vínculo usuário↔papéis e derivar navegação por função (backend/views/RPC).

## Checklist
- [ ] Criar branch a partir de `dev`.
- [ ] Confirmar tabelas: `rbac_roles`, `rbac_user_roles`, `ui_app_pages`, `ui_app_elements`, `ui_role_element_permissions`, `ui_grids`, `ui_grid_columns`, `ui_app_collors`.
- [ ] Funções: `get_navigation_for_user()` — validar escopo por `auth.uid()`.
- [ ] Grants: `GRANT EXECUTE ... TO authenticated` conforme padrão RPC.
- [ ] Policies: acesso somente ao que o usuário pode ver.
- [ ] Seeds de roles e elementos essenciais para MVP.
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
- Navegação derivada de backend por role e perfil ativo.

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 2)
- `docs/110-supabase_arquitetura.md`
- `docs/rpc-functions-standard.md`
