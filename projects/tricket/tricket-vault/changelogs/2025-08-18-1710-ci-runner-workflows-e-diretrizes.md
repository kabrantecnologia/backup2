# Changelog — CI/CD Runner, Workflows e Diretrizes

Data: 2025-08-18 17:10 BRT
Branch: dev
Autor: @joaohsandrade

## Resumo
- Configurado e validado o pipeline de deploy usando runner self-hosted no VPS.
- Adicionado workflow de deploy com diagnósticos e gatilho manual.
- Criado workflow manual para reset do banco (com opção de seed).
- Atualizadas as diretrizes do projeto (migrations append-only e CI/CD) e criada documentação detalhada na wiki.

## Detalhes
- `.github/workflows/deploy-dev2.yml`
  - Gatilhos: `push` em `dev` e `workflow_dispatch`.
  - Passos: `git fetch/checkout/pull`, checagem `supabase --version`, validação do Secret `SUPABASE_DB_URL_DEV2`, `supabase db push` em `tricket-backend/`.
  - Logs diagnósticos adicionados (pwd, remotes, mensagens claras de erro de Secret/CLI).

- `.github/workflows/reset-dev2.yml`
  - Gatilho: `workflow_dispatch` com confirmação (`RESET`) e opção `seed` (yes/no).
  - Execução: `supabase db reset --yes --db-url "$SUPABASE_DB_URL_DEV2"` e, opcionalmente, aplicação de `tricket-backend/dev/data.sql` via `psql`.
  - Avisos de segurança e validações (CLI e Secret).

- Diretrizes
  - `/.windsurf/rules/tricket-rules.md`: adicionadas seções de Migrations (ordem imutável, sem edições retroativas, reset só em DEV) e CI/CD (workflow, Secret, passos, troubleshooting).
  - `tricket-vault/wiki/diretrizes-migrations-e-ci.md`: guia detalhado com checklist, padrões de nomenclatura e troubleshooting.

## Dependências e Secrets
- Secret obrigatório: `SUPABASE_DB_URL_DEV2` (GitHub → Settings → Secrets and variables → Actions).
- Runner self-hosted: online e com Supabase CLI no PATH.

## Próximos Passos (sugestões)
- Adicionar smoke test pós-migração (ex.: `psql -c "select 1;"`).
- Template de PR com checklist de migrations/testes.

Links úteis:
- Guia: `tricket-vault/wiki/diretrizes-migrations-e-ci.md`
- Regras: `/.windsurf/rules/tricket-rules.md`
