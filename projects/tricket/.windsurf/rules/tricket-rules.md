---
trigger: always_on
---

> Leitura detalhada: [Diretrizes de Migrations e CI/CD](../../tricket-vault/wiki/diretrizes-migrations-e-ci.md)

# Diretrizes para Agente de IA - Projeto Tricket

## 1. Visão Geral

Este documento estabelece as regras e o fluxo de trabalho que você, como agente de IA integrado à IDE, deve seguir para auxiliar no desenvolvimento do projeto "Tricket". Seu objetivo é automatizar tarefas, garantir a qualidade do código e manter a consistência do projeto, seguindo rigorosamente as etapas aqui descritas.

## 2. Contexto do Projeto

Você deve ter pleno conhecimento da arquitetura e dos objetivos do projeto, com base nos seguintes documentos:

- `tricket-vault/docs/project-overview.md`
- `tricket-vault/docs/PRD-tricket-e.md`
- `tricket-vault/docs/product-plan-epics-user-stories.md`

A stack tecnológica consiste em:

- **Backend**: Supabase (self-hosted) com banco de dados PostgreSQL.
- **Frontend**: WeWeb (low-code).
- **Testes**: Suíte de integração com Pytest.
- **Repositórios**: Estrutura monorepo em `/tricket/`.
    

## 3. Fluxo de Trabalho Obrigatório

Toda nova tarefa de desenvolvimento deve seguir estritamente o fluxo abaixo.

### Etapa 1: Iniciar a Tarefa

1. **Criar a Branch**: A partir da branch `dev`, crie uma nova branch para a tarefa atual. O nome deve ser conciso e relacionado à funcionalidade (ex: `feat/user-authentication` ou `fix/report-submission-bug`).
    
2. **Criar o Plano**: Crie um novo arquivo de plano em `tricket-vault/plans/`. O nome do arquivo deve seguir o padrão `YYYY-MM-DD-HHMM-nome-da-tarefa.md`. Este documento deve detalhar as implementações que serão realizadas.
    

### Etapa 2: Implementação

1. **Desenvolver as Alterações**: Realize as modificações de código (SQL, Edge Functions, etc.) conforme o plano definido.
    
2. **Aplicar Migrations (Push)**: Para sincronizar as alterações do banco de dados com o ambiente de desenvolvimento, execute o comando **exato**:
    
    ```
cd ~/workspaces/projects/tricket/tricket-backend
supabase db push --yes --db-url "postgresql://postgres.dev_tricket_tenant:yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH@localhost:5408/postgres"
    ```
    

### Etapa 3: Validação e Testes

1. **Executar a Suíte de Testes**: Rode a suíte de testes de integração para validar as alterações. O comando para executar os testes é:
    
    ```
    cd ~/workspaces/projects/tricket/tricket-tests
    pytest
    ```
    
2. **Analisar o Resultado**:
    
    - **Se os testes falharem**: Inicie um ciclo de depuração. Analise os logs de erro, corrija o código, aplique as migrations (`supabase db push`) novamente e re-execute os testes até que 100% deles passem.
        
    - **Se os testes passarem com sucesso**: Prossiga para a próxima etapa.
        

### Etapa 4: Finalização

1. **Criar o Changelog**: Após a validação bem-sucedida, crie um novo registro de changelog em `tricket-vault/changelogs/`. O nome do arquivo deve seguir o padrão `YYYY-MM-DD-hhmm-nome-da-tarefa.md`. O conteúdo deve resumir as mudanças implementadas.
    
2. **Preparar para o Commit**: Adicione os arquivos modificados ao stage do Git.
    
3. **Confirmar e Enviar**: Realize o commit das alterações com uma mensagem clara e descritiva e, em seguida, envie a branch para o repositório remoto (`git push`).
    

## 4. Comandos Específicos

Utilize apenas os comandos abaixo para interagir com o ambiente Supabase. A execução incorreta pode levar a inconsistências no ambiente de desenvolvimento.

- **Para aplicar alterações (push)**:
    
    ```
    cd ~/workspaces/projects/tricket/tricket-backend
    supabase db push --yes --db-url "postgresql://postgres.dev_tricket_tenant:yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH@localhost:5408/postgres"
    ```
    
- Para resetar o banco de dados (reset):
    
    Atenção: Use este comando com cautela, pois ele apagará todos os dados.
    
    ```
    cd ~/workspaces/projects/tricket/tricket-backend
    supabase db reset --yes --db-url "postgresql://postgres.dev_tricket_tenant:yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH@localhost:5408/postgres"
    ```
    

## 5. Regras Adicionais

- **Comunicação**: Seja proativo. Informe o desenvolvedor sobre cada etapa concluída, especialmente sobre os resultados dos testes.
    
- **Estrutura de Arquivos**: Respeite rigorosamente a arquitetura de repositórios definida. Não crie arquivos ou diretórios fora dos locais especificados.
    
- **Autonomia**: Execute o fluxo de trabalho de forma autônoma, mas solicite a intervenção do desenvolvedor se encontrar um problema que não consiga resolver (ex: falhas de infraestrutura, erros de teste persistentes e complexos).

### 5.1 Diretrizes de Migrations (Supabase/Postgres)
- Ordem imutável (append-only): novas migrations sempre ao final; nunca inserir no meio.
- Não editar migrations já aplicadas; correções devem ser feitas via nova migration.
- Criar com: `cd ~/workspaces/projects/tricket/tricket-backend && supabase migration new "descricao"`.
- Antes do push: revisar SQL, preferir comandos idempotentes (`... if not exists`), e rodar testes de integração.
- Reset apenas em DEV e ciente de perda de dados:
cd ~/workspaces/projects/tricket/tricket-backend supabase db reset --yes --db-url "postgresql://postgres.dev_tricket_tenant:***@localhost:5408/postgres"


### 5.2 CI/CD com Runner Self-hosted
- Workflow: [.github/workflows/deploy-dev2.yml](cci:7://file:///home/joaohenrique/workspaces/projects/tricket/.github/workflows/deploy-dev2.yml:0:0-0:0) (gatilhos: push em `dev` e `workflow_dispatch`).
- Caminho do projeto no VPS: `/home/joaohenrique/workspaces/projects/tricket`.
- Secret obrigatório no GitHub: `SUPABASE_DB_URL_DEV2`. Não usar `.env` local para o workflow.
- Passos do job: git fetch/checkout/pull → checar `supabase --version` → `supabase db push` em `tricket-backend/`.
- Troubleshooting: se falhar, verificar Secret, PATH do CLI no serviço do runner e erros SQL nas migrations.