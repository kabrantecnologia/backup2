# Tarefa 08 — Marketplace (Busca, Carrinho, Checkout)

- Branch sugerida: `feat/08-marketplace-carrinho-checkout`
- Objetivo: Implementar backend para busca/filters, carrinho com timeout e checkout usando saldo Tricket/Asaas.

## Checklist
- [ ] Criar branch a partir de `dev`.
- [ ] Modelos transacionais (se ainda não presentes): `marketplace_carts`, `marketplace_orders`, `marketplace_order_items`, `marketplace_payments`, etc. (conforme necessidade dos testes).
- [ ] Funções: cálculo de frete por distância (PostGIS) usando `iam_addresses` e regras; reserva de carrinho 15 min.
- [ ] RPCs: search, add-to-cart, checkout (gera pagamento Asaas, split/regras), captura/confirm.
- [ ] Policies e travas de concorrência (locks) para estoque.
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
- Fluxo de busca→carrinho→checkout passando na suíte de testes (PIX/saldo).

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 8)
- `docs/110-supabase_arquitetura.md`
- `docs/requisitos-sistema-tricket.md`
- `docs/rpc-functions-standard.md`
