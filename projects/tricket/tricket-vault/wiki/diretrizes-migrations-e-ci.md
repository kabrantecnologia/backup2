> Voltar ao resumo das regras: [Diretrizes para Agente de IA - Projeto Tricket](../../.windsurf/rules/tricket-rules.md)

# Diretrizes de Migrations e CI/CD (Ambiente Tricket)

Este documento complementa `/.windsurf/rules/tricket-rules.md` com regras operacionais sobre migrations do Supabase/Postgres e o pipeline de deploy com runner self-hosted.

---

## 1) Regras para Migrations

- **Ordem imutável (append-only)**
  - Novas migrations devem ser sempre adicionadas ao final da sequência em `tricket-backend/supabase/migrations/`.
  - **Nunca** reordenar, remover ou editar arquivos de migrations já aplicados.

- **Criação de migration**
  - Preferir o comando:
    ```bash
    cd ~/workspaces/projects/tricket/tricket-backend
    supabase migration new "descricao_curta"
    ```
  - Edite o SQL gerado no diretório `supabase/migrations/` e garanta idempotência quando possível (ex.: `create table if not exists`, `alter table ... add column if not exists`).

- **Política de alterações**
  - Se precisar corrigir algo já migrado, crie **nova** migration de correção. Não edite a antiga.
  - Evite `DROP` destrutivo sem plano de rollback.

- **Reset somente em DEV**
  - Quando a ordem/estado divergir e for inviável corrigir, use reset **apenas em desenvolvimento**:
    ```bash
    cd ~/workspaces/projects/tricket/tricket-backend
    supabase db reset --yes --db-url "postgresql://postgres.dev_tricket_tenant:***@localhost:5408/postgres"
    ```
  - O reset apaga dados; confirme que não há informações críticas.

- **Checklist antes do push**
  - SQL revisado e testado localmente (`supabase db push --dry-run` quando aplicável).
  - Testes de integração passando (`tricket-tests`).
  - Changelog/Plano atualizados em `tricket-vault/`.

---

## 2) Fluxo de Branch e Merge

- Crie branches a partir de `dev` (`feat/...`, `fix/...`).
- Abra PR para `dev` e garanta que os testes passam.
- Após merge em `dev`, o workflow de deploy é executado no runner self-hosted.

---

## 3) CI/CD no Runner Self-hosted

- Workflow: `.github/workflows/deploy-dev2.yml`
- Disparadores: `push` para `dev` e `workflow_dispatch` manual.
- Caminho do projeto no VPS: `/home/joaohenrique/workspaces/projects/tricket`
- Secret obrigatório: `SUPABASE_DB_URL_DEV2` (em GitHub → Settings → Secrets and variables → Actions).
- Passos principais do job:
  1. `git fetch/checkout/pull` da branch `dev` no VPS.
  2. Verificação do Supabase CLI (`supabase --version`).
  3. Execução de `supabase db push --yes --db-url "$SUPABASE_DB_URL_DEV2"` dentro de `tricket-backend/`.

- Troubleshooting comum:
  - Secret ausente/inválido → defina no GitHub, não no `.env` local.
  - CLI fora do PATH do serviço → instale para o usuário do runner e verifique `supabase --version` no job.
  - Erro SQL na migration → ajuste SQL e crie nova migration de correção.

---

## 4) Padrões de Nomenclatura

- Migrations: `YYYYMMDDHHMMSS_descricao.sql` (padrão do Supabase CLI).
- Branch: `feat/...`, `fix/...` concisos.
- Planos: `tricket-vault/plans/YYYY-MM-DD-HHMM-nome-da-tarefa.md`.
- Changelogs: `tricket-vault/changelogs/YYYY-MM-DD-HHMM-nome-da-tarefa.md`.

---

## 5) Segurança e Boas Práticas

- Nunca commit credenciais. Use `secrets` no GitHub.
- Evite `DROP` sem backup ou plano de rollback.
- Prefira migrações idempotentes quando possível.
- Documente breaking changes no changelog e no plano da tarefa.

---

## 6) Sugestão de Atualização do `.windsurf/rules/tricket-rules.md`

Adicionar a seção abaixo ao documento de regras do agente (resumo executivo):

```
### 2.x Diretrizes de Migrations (Supabase/Postgres)
- Adotar ordem imutável: novas migrations sempre ao final, nunca inserir no meio.
- Proibido editar migrations aplicadas; correções via nova migration.
- Usar `supabase migration new "descricao"` para criar; testar localmente antes do push.
- `supabase db reset` é permitido somente em DEV e com aviso de perda de dados.
- Antes de `push`: revisar SQL, rodar testes de integração e atualizar changelog/plano.

### 3.x CI/CD com Runner Self-hosted
- Workflow: `.github/workflows/deploy-dev2.yml` (gatilhos: push em `dev` e manual).
- Caminho do projeto no VPS: `/home/joaohenrique/workspaces/projects/tricket`.
- Secret obrigatório: `SUPABASE_DB_URL_DEV2` em GitHub Secrets.
- Passos: git pull → checar Supabase CLI → `supabase db push` em `tricket-backend/`.
```

Caso aprove, posso aplicar o patch diretamente no arquivo de regras.
