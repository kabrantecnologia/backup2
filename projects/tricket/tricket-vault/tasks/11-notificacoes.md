# Tarefa 11 — Notificações (Email / In-App)

- Branch sugerida: `feat/11-notificacoes`
- Objetivo: Eventos e preferências de notificação com retries/backoff.

## Checklist
- [ ] Criar branch a partir de `dev`.
- [ ] Tabelas/uso: `iam_contacts`, `iam_user_preferences` (+ fila/eventos se necessário).
- [ ] RPCs: salvar preferências; enviar notificação (email/in-app) para eventos (pedido, disputa, verificação).
- [ ] Templates de mensagens e logs de envio.
- [ ] Retentativas com backoff e marcação de falhas.
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
- Preferências persistidas e notificações entregues/registradas com retries.

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 11)
- `docs/110-supabase_arquitetura.md`
- `docs/rpc-functions-standard.md`
