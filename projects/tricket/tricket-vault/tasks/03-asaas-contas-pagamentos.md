# Tarefa 03 — Asaas: Contas, Clientes, Pagamentos e Webhooks

- Branch sugerida: `feat/03-asaas-contas-pagamentos`
- Objetivo: Operacionalizar contas digitais, adicionar saldo, registrar pagamentos e processar webhooks.

## Checklist
- [ ] Criar branch a partir de `dev`.
- [ ] Tabelas: `asaas_accounts`, `asaas_customers`, `asaas_payments`, `asaas_webhooks` — revisar índices e FKs.
- [ ] Views: `view_asaas_accounts_*`, `view_asaas_webhook_logs`.
- [ ] Funções: `process_asaas_webhook(...)`, sync de customer/profile.
- [ ] Segurança de webhooks (tokens/assinatura); idempotência.
- [ ] RPCs: adicionar saldo e extrato (retornos JSONB padronizados).
- [ ] Jobs/retries (se aplicável) via triggers ou workers externos (anotar).
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
- Fluxo de adicionar saldo e registrar pagamentos funciona end-to-end nos testes.

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 3)
- `docs/110-supabase_arquitetura.md`
- `docs/requisitos-sistema-tricket.md`
- `docs/rpc-functions-standard.md`
