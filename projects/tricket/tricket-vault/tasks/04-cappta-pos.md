# Tarefa 04 — Integração POS (Cappta)

- Branch sugerida: `feat/04-cappta-pos`
- Objetivo: Habilitar Cappta accounts, ingestão de transações, cálculo de net amount e conciliação.

## Checklist
- [ ] Criar branch a partir de `dev`.
- [ ] Tabelas: `cappta_accounts`, `cappta_transactions`, `cappta_webhooks`, `cappta_api_responses` (+ opções `cappta_*_options`).
- [ ] Funções: `calculate_cappta_net_amount()`, `process_cappta_webhook(webhook_id uuid)`.
- [ ] Triggers de atualização/calculo; índices de performance.
- [ ] RPCs de consulta resumida por comerciante.
- [ ] Segurança de webhook; idempotência.
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
- Transações POS refletidas em saldo líquido e consultáveis por API.

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 4)
- `docs/110-supabase_arquitetura.md`
- `docs/rpc-functions-standard.md`
