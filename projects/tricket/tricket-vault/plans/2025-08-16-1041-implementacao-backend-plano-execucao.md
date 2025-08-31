---
id: 
status: draft
version: 1
source: internal
type: plan
action: create
space: tricket
summary: Plano de execução backend para implementar os 13 épicos do documento 130-plano-epicos-e-historias-tricket.md.
---

# Plano de Execução — Backend Tricket (MVP→Scale)

Este plano orquestra a implementação backend (Supabase) dos 13 épicos definidos em `tricket-vault/docs/130-plano-epicos-e-historias-tricket.md`.

- Escopo: apenas backend (migrations, RPCs, webhooks, views, RLS, seeds). Sem tarefas frontend.
- Fluxo obrigatório: ver `tricket-vault/rules/tricket-rules.md`.
- Comandos padrão:
  - Supabase push:
    ```bash
    cd ~/workspaces/projects/tricket/tricket-backend
    supabase db push --yes --db-url "postgresql://postgres.dev_tricket_tenant:yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH@localhost:5408/postgres"
    ```
  - Testes:
    ```bash
    cd ~/workspaces/projects/tricket/tricket-tests
    pytest
    ```

## Convenções
- Branch base: `dev` → criar feature branches por épico/tarefa.
- Nomenclatura de branch: `feat/<numero>-<slug-epico>` (ex.: `feat/01-iam-onboarding`).
- Migrações: seguir faixas e padrões de `tricket-backend/supabase/migrations/` e `rpc-functions-standard.md`.
- Artefatos por épico: 1 arquivo em `tricket-vault/tasks/` com checklist detalhado.

## Tarefas por Épico (arquivos)
1. `tricket-vault/tasks/01-iam-onboarding.md`
2. `tricket-vault/tasks/02-rbac-ui-navegacao.md`
3. `tricket-vault/tasks/03-asaas-contas-pagamentos.md`
4. `tricket-vault/tasks/04-cappta-pos.md`
5. `tricket-vault/tasks/05-marketplace-catalogo-base.md`
6. `tricket-vault/tasks/06-gs1-integracao.md`
7. `tricket-vault/tasks/07-ofertas-fornecedor.md`
8. `tricket-vault/tasks/08-marketplace-carrinho-checkout.md`
9. `tricket-vault/tasks/09-pedidos-gestao.md`
10. `tricket-vault/tasks/10-disputas-mediacao.md`
11. `tricket-vault/tasks/11-notificacoes.md`
12. `tricket-vault/tasks/12-admin-area-completa.md`
13. `tricket-vault/tasks/13-seguranca-observabilidade.md`

## Processo por Tarefa
- Criar branch → Implementar → `supabase db push` → `pytest` → corrigir até 100% verde → atualizar changelog.

## Referências
- `tricket-vault/docs/130-plano-epicos-e-historias-tricket.md`
- `tricket-vault/docs/110-supabase_arquitetura.md`
- `tricket-vault/docs/rpc-functions-standard.md`
- `tricket-vault/docs/requisitos-sistema-tricket.md`
