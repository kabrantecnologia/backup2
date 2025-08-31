# Tarefa 13 — Segurança, Compliance e Observabilidade

- Branch sugerida: `feat/13-seguranca-observabilidade`
- Objetivo: Reforçar segurança (RLS, grants, search_path), compliance (LGPD) e observabilidade (logs, índices críticos).

## Checklist
- [ ] Criar branch a partir de `dev`.
- [ ] Revisar RLS por tabela (habilitação e policies por operação/role).
- [ ] Garantir `SECURITY DEFINER/INVOKER` adequado e `SET search_path` fixo em funções.
- [ ] Grants mínimos necessários a `authenticated`/`anon`.
- [ ] Índices críticos conferidos (consultar `110-supabase_arquitetura.md`).
- [ ] Logs e auditoria para webhooks e pagamentos.
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
- Auditoria e segurança verificadas; testes de permissão passam.

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 13)
- `docs/110-supabase_arquitetura.md`
- `docs/rpc-functions-standard.md`
