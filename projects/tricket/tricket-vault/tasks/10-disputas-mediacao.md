# Tarefa 10 — Disputas e Mediação

- Branch sugerida: `feat/10-disputas-mediacao`
- Objetivo: Implementar abertura e mediação de disputas com decisão administrativa e efeitos financeiros.

## Checklist
- [ ] Criar branch a partir de `dev`.
- [ ] Tabelas: `marketplace_disputes`, `marketplace_dispute_messages`, `marketplace_dispute_evidences`, `marketplace_dispute_events`.
- [ ] RPCs: comprador abre, fornecedor responde, admin decide (reembolso total/parcial, sem reembolso, acordo) + justificativa.
- [ ] Integração financeira: ajustar pagamentos/repasse via Asaas conforme decisão.
- [ ] SLAs e alertas; trilha de auditoria completa.
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
- Fluxo de disputa completo com decisão refletindo nos registros financeiros.

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 10)
- `docs/requisitos-sistema-tricket.md`
- `docs/rpc-functions-standard.md`
