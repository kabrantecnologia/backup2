# Tarefa 07 — Ofertas de Fornecedor

- Branch sugerida: `feat/07-ofertas-fornecedor`
- Objetivo: CRUD de ofertas por fornecedor com regras de preço/promoção/quantidade.

## Checklist
- [ ] Criar branch a partir de `dev`.
- [ ] Tabela: `marketplace_supplier_products` (unicidade produto×fornecedor, promo window, min/max).
- [ ] RPCs: criar/editar/ativar/desativar oferta; importação CSV (parsing e validação lato banco quando possível).
- [ ] Views: `view_supplier_products` para grids.
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
- Ofertas funcionais e consistentes com catálogo base.

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 7)
- `docs/110-supabase_arquitetura.md`
- `docs/rpc-functions-standard.md`
