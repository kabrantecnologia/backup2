# Plano: Análise e Melhoria da Documentação do Tricket

- id: plan-docs-2025-08-18
- status: draft
- created: 2025-08-18
- owner: docs
- scope: tricket-vault/docs/

## Objetivos
- Consolidar e remover redundâncias entre documentos.
- Melhorar a rastreabilidade entre requisitos, épicos/histórias e roadmap.
- Padronizar metadados e estrutura de arquivos.
- Propor automações para manter a documentação sincronizada com o banco (Supabase) e fluxo de desenvolvimento.

## Contexto (fonte)
Documentos analisados em `tricket-vault/docs/`:
- `100-visao-geral-tricket.md`
- `110-supabase_arquitetura.md`
- `120_dicionario_de_dados.md`
- `130-plano-epicos-e-historias-tricket.md`
- `a2-requisitos-do-sistema.md`
- `requisitos-sistema-tricket.md`
- `estrutura-de-paginas-e-links.md`
- `Estrutura de URLs e SEO.md`
- `analise-compatibilidade-gs1.md`
- `rpc-functions-standard.md`

## Achados Principais
- Redundância de requisitos entre `a2-requisitos-do-sistema.md` e `requisitos-sistema-tricket.md`.
- Roadmap e backlog em `130-plano-epicos-e-historias-tricket.md` pouco vinculados a IDs de requisitos.
- `120_dicionario_de_dados.md` é extenso e tende a desatualizar sem automação.
- Metadados inconsistentes (campos como `id`, `status`, `created`).
- Padrões de RPC definidos, mas falta processo/checagem de conformidade no dev/CI.
- SEO/URLs poderiam ser referenciados diretamente nas rotas de `estrutura-de-paginas-e-links.md`.

## Ações Propostas
1) Consolidação de Requisitos
- Fonte única: manter apenas `requisitos-sistema-tricket.md` (renomear para `200-requisitos-sistema.md`) e arquivar/redirect de `a2-requisitos-do-sistema.md`.
- Unificar IDs (RF/ RNF) e Acceptance Criteria; criar índice por domínio (IAM, RBAC, Marketplace...).

2) Rastreabilidade Roadmap ↔ Épicos ↔ Requisitos
- Em `130-plano-epicos-e-historias-tricket.md`, referenciar requisitos por ID (ex.: RF-XXX) em cada épico/história.
- Tabela de traçabilidade no topo do arquivo com colunas: Épico | Histórias | Requisitos | Fase/Roadmap.

3) Automação do Dicionário de Dados
- Script de geração a partir do catálogo do Postgres (views `pg_catalog`), incluindo:
  - tabelas, colunas, tipos, FKs/PKs, índices, RLS, comentários e origem da migration.
- Pipeline: gerar Markdown para `120_dicionario_de_dados.md` a partir de template.
- Opcional: badge no topo "gerado em <data>" e seção manual apenas para notas de modelagem.

4) Padronização de Metadados
- Criar front-matter padrão:
```
- id: <slug-do-arquivo>
- status: draft|active|archived
- created: YYYY-MM-DD
- updated: YYYY-MM-DD
- owner: team/area
```
- Aplicar a todos os arquivos em `docs/` gradualmente.

5) Integração SEO/Rotas
- Em `estrutura-de-paginas-e-links.md`, adicionar coluna/trecho com recomendações de SEO (title, description, canonical, breadcrumbs) e linkar para trechos de `Estrutura de URLs e SEO.md`.
- Em `Estrutura de URLs e SEO.md`, referenciar rotas correspondentes para facilitar implementação.

6) Padrões de RPC e Qualidade
- Expandir `rpc-functions-standard.md` com checklist de PR.
- Adicionar orientação de lint estático (ex.: verificação de `search_path`, `SECURITY DEFINER`, formatos de retorno) e exemplos de testes de autorização (RLS/RBAC).

7) Índice e Navegação de Documentos
- Adicionar `docs/README.md` com:
  - Mapa dos documentos, propósito e dono.
  - Convenções de nomeação e numeração (100-199 visão/arquitetura, 200-299 requisitos, 300-399 plano/roadmap, etc.).
  - Como atualizar (governança de docs).

## Critérios de Aceite
- Remoção de duplicidades de requisitos com preservação de IDs e critérios.
- Épicos e histórias referenciam requisitos por ID.
- Dicionário com etiqueta "gerado em" e instrução clara de geração.
- Todos os arquivos-chave com front-matter padronizado.
- SEO e Rotas referenciadas bilateralmente.
- Checklist de PR para RPC anexado.
- Novo `docs/README.md` publicado.

## Impacto
- Diretório `tricket-vault/docs/` (estrutura, conteúdo e referência cruzada).
- Contribui para menor atrito de onboarding e menor dívida de documentação.

## Riscos e Mitigações
- Risco de links quebrados após renomeações. Mitigar com redirects/alias e revisão de links.
- Adoção parcial do front-matter. Mitigar com checklist em PRs e exemplo pronto.

## Tarefas
- [ ] Consolidar requisitos em arquivo único (arquivar o duplicado).
- [ ] Inserir tabela de traçabilidade em `130-plano-epicos-e-historias-tricket.md`.
- [ ] Especificar e publicar script de geração do dicionário.
- [ ] Aplicar front-matter padrão nos principais arquivos.
- [ ] Bidirecionar referências SEO ⇄ Rotas.
- [ ] Incluir checklist de RPCs.
- [ ] Criar `docs/README.md` com índice e governança.

## Observações
- Esta etapa é apenas planejamento. Implementações serão feitas em branch dedicada, conforme governança do repositório.
