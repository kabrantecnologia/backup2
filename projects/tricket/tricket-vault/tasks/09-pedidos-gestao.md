# Tarefa 09 — Gestão de Pedidos (Fornecedor/Admin)

- Branch sugerida: `feat/09-pedidos-gestao`
- Objetivo: Implementar ciclo de pedidos com confirmações, expedição e visualização administrativa.

## Checklist
- [ ] Criar branch a partir de `dev`.
- [ ] Tabelas: `marketplace_orders`, `marketplace_order_items`, `marketplace_shipments` (NF, tracking), estados e timestamps.
- [ ] RPCs: fornecedor confirma/rejeita (com motivo, SLA 4h úteis), atualiza expedição, tracking; admin lista todos.
- [ ] Webhooks/Jobs para confirmação de pagamento e liberação de pedido.
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
- Fornecedor opera pedidos e admin visualiza todos os pedidos com estados consistentes.

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 9)
- `docs/requisitos-sistema-tricket.md`
- `docs/rpc-functions-standard.md`
