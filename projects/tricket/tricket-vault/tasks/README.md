# Tasks Backend — Tricket

Este diretório contém tarefas sequenciais (01→13) para implementação backend do plano em `../docs/130-plano-epicos-e-historias-tricket.md`.

Fluxo por tarefa:
1) Criar nova branch a partir de `dev` (ex: `feat/01-iam-onboarding`).
2) Implementar migrações/RPCs/views/policies conforme checklist da tarefa.
3) Aplicar migrations:
```bash
cd ~/workspaces/projects/tricket/tricket-backend
supabase db push --yes --db-url "postgresql://postgres.dev_tricket_tenant:yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH@localhost:5408/postgres"
```
4) Executar a suíte de testes:
```bash
cd ~/workspaces/projects/tricket/tricket-tests
pytest
```
5) Se falhar, depurar → repetir push/testes até 100% verde.
6) Criar changelog em `tricket-vault/changelogs/` com resumo.
7) Commit e push da branch.
