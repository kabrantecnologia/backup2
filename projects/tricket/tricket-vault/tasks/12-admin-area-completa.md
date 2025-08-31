# Tarefa 12 — Área Administrativa (Backend)

- Branch sugerida: `feat/12-admin-area-completa`
- Objetivo: Endpoints/RPCs/views para administração de usuários, aprovações, categorias, produtos, pedidos, disputas e financeiro.

## Checklist
- [ ] Criar branch a partir de `dev`.
- [ ] Views admin: `view_admin_profile_approval`, outras para pedidos/disputas.
- [ ] RPCs administrativas prefixadas `rpc_*` com `SECURITY DEFINER` + checks RBAC.
- [ ] Grants e policies consistentes.
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
- Operações administrativas cobertas por RPCs com RBAC robusto.

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 12)
- `docs/rpc-functions-standard.md`
