# CI/CD: Deploy automático no VPS com Runner Self-hosted e Supabase CLI

Este guia documenta como configurar e operar o pipeline que realiza `git pull` e `supabase db push` automaticamente no VPS quando há merges na branch `dev`.

- Repositório: `joaohsandrade/tricket`
- Runner: self-hosted (Linux x64) no VPS
- Caminho do projeto no VPS: `/home/joaohenrique/workspaces/projects/tricket`
- Workflow: `.github/workflows/deploy-dev2.yml`
- Banco: Supabase (self-hosted) PostgreSQL (porta `5408` no VPS, conforme exemplo)

---

## 1) Pré-requisitos
- Acesso de admin ao repositório no GitHub (para criar Runner e Secrets)
- VPS Linux com:
  - `git` instalado
  - Supabase CLI disponível no PATH do usuário do runner (`supabase --version`)
- Repositório clonado na VPS em `/home/joaohenrique/workspaces/projects/tricket` (ou ajuste o caminho no workflow)

---

## 2) Criar o Runner self-hosted no GitHub
1. GitHub → Repo → Settings → Actions → Runners → "New self-hosted runner" → Linux.
2. Na VPS, execute os comandos exibidos na página (exemplo):
   ```bash
   mkdir -p ~/actions-runner && cd ~/actions-runner
   curl -o actions-runner-linux-x64-<versao>.tar.gz -L https://github.com/actions/runner/releases/download/v<versao>/actions-runner-linux-x64-<versao>.tar.gz
   tar xzf actions-runner-linux-x64-<versao>.tar.gz
   ./config.sh --url https://github.com/joaohsandrade/tricket --token <TOKEN_DA_PAGINA>
   sudo ./svc.sh install
   sudo ./svc.sh start
   ```
3. Confirme que o status aparece como "Idle" na página de Runners do repositório.

Observação: o runner é instalado tipicamente em `~/actions-runner` e roda como serviço.

---

## 3) Configurar o Secret de conexão com o banco
O workflow usa a variável `secrets.SUPABASE_DB_URL_DEV2`. Ela precisa ser criada no GitHub, não no `.env` local.

- GitHub → Repo → Settings → Secrets and variables → Actions → New repository secret
  - Name: `SUPABASE_DB_URL_DEV2`
  - Value: `postgresql://<usuario>:<senha>@localhost:5408/postgres`

> Dica: mantenha o hostname/porta de acordo com a topologia do VPS. O runner executa localmente, então `localhost` costuma funcionar.

---

## 4) Workflow de deploy
Arquivo: `.github/workflows/deploy-dev2.yml`

Funções:
- Dispara em `push` para `dev` e manualmente via `workflow_dispatch`.
- Entra na pasta do projeto, faz `git fetch/checkout/pull`.
- Verifica Supabase CLI e Secret.
- Executa `supabase db push` no diretório `tricket-backend`.

Conteúdo atual:
```yaml
name: Deploy Dev2 VPS (Self-hosted)

on:
  push:
    branches: [ dev ]
  workflow_dispatch: {}

jobs:
  deploy:
    runs-on: self-hosted
    steps:
      - name: Pull and migrate
        env:
          SUPABASE_DB_URL_DEV2: ${{ secrets.SUPABASE_DB_URL_DEV2 }}
        run: |
          set -e
          echo "pwd: $(pwd)"
          cd /home/joaohenrique/workspaces/projects/tricket
          echo "Repo remote URLs:"
          git remote -v || true
          git fetch --all --prune
          git checkout dev
          git pull --ff-only

          echo "Checking Supabase CLI..."
          if ! command -v supabase >/dev/null 2>&1; then
            echo "ERRO: Supabase CLI não encontrado no PATH do runner" >&2
            exit 1
          fi
          supabase --version

          if [ -z "${SUPABASE_DB_URL_DEV2}" ]; then
            echo "ERRO: Secret SUPABASE_DB_URL_DEV2 não definido" >&2
            exit 1
          fi

          cd tricket-backend
          echo "Executando supabase db push..."
          supabase db push --yes --db-url "${SUPABASE_DB_URL_DEV2}"
```

> Se o repositório não estiver clonado previamente na pasta indicada, adapte o workflow para clonar, ou garanta o clone manualmente.

---

## 5) Como disparar e acompanhar
- Automático: push/merge na branch `dev`.
- Manual: GitHub → Actions → "Deploy Dev2 VPS (Self-hosted)" → "Run workflow" → escolha `dev`.
- Acompanhe logs no job:
  - `pwd` inicial e `cd /home/.../tricket`
  - `git remote -v`, `git pull`
  - `supabase --version`
  - `supabase db push` (retorna "No changes" se não há novas migrations)

---

## 6) Troubleshooting
- **Erro: Secret SUPABASE_DB_URL_DEV2 não definido**
  - Defina o Secret no GitHub (não basta `.env` local).
- **Supabase CLI não encontrado**
  - Instale o CLI no usuário do runner e verifique o PATH do serviço (`supabase --version`).
- **DB inacessível**
  - Valide host/porta no Secret. Se o DB roda em containers, confirme a rede e a porta exposta.
- **Falhas de migração**
  - Verifique o output do `supabase db push` e corrija o SQL na pasta `tricket-backend/supabase/migrations/`.

---

## 7) Boas práticas e segurança
- Use Secrets do GitHub para credenciais.
- Restrinja o runner a este repositório.
- Atualize o Supabase CLI periodicamente.
- Log mínimo necessário no workflow (evitar vazar credenciais).

---

## 8) Manutenção
- Atualizar o caminho do projeto no workflow se a pasta mudar.
- Revisar labels ou atualização do runner quando necessário.
- Monitorar Actions para detectar falhas recorrentes.

---

## 9) Comandos úteis
- Status do runner (na VPS):
  ```bash
  sudo systemctl status actions.runner.*
  sudo ~/actions-runner/svc.sh status
  ```
- Reiniciar runner:
  ```bash
  sudo ~/actions-runner/svc.sh restart
  ```
- Testar Supabase CLI:
  ```bash
  supabase --version
  supabase db push --db-url "${SUPABASE_DB_URL_DEV2}" --dry-run
  ```
