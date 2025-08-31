# Changelog: Análise da Documentação e Recomendações de Melhoria

- id: changelog-docs-2025-08-18
- status: completed
- created: 2025-08-18 00:05
- owner: docs
- scope: tricket-vault/docs/

## Resumo
Foi realizada uma revisão abrangente dos documentos em `tricket-vault/docs/` para identificar inconsistências, redundâncias e oportunidades de melhoria na organização e manutenção da documentação do projeto Tricket.

## Itens analisados
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

## Achados
- Redundância entre `a2-requisitos-do-sistema.md` e `requisitos-sistema-tricket.md` (conteúdo e IDs similares).
- Roadmap/épicos em `130-plano-epicos-e-historias-tricket.md` pouco conectados a IDs de requisitos, reduzindo rastreabilidade.
- `120_dicionario_de_dados.md` é detalhado, porém propenso à desatualização sem geração automatizada a partir do catálogo do Postgres/Supabase.
- Metadados inconsistentes (campos `id`, `status`, `created`, `updated` ausentes ou divergentes entre arquivos).
- Padrões de RPC bem definidos, mas sem checklist/processo de validação em PR/CI.
- Documentos de SEO/URLs e rotas front-end mantidos separados sem referências cruzadas claras.

## Recomendações
1. Consolidar requisitos em um único arquivo (sugerido: `200-requisitos-sistema.md`) e arquivar o duplicado com redirecionamento/nota.
2. Introduzir tabela de traçabilidade (Roadmap ↔ Épicos ↔ Histórias ↔ Requisitos) em `130-plano-epicos-e-historias-tricket.md` com referência por ID (RF/RNF).
3. Automatizar geração do `120_dicionario_de_dados.md` (script que lê `pg_catalog`, RLS, índices, comentários e origem das migrations) e carimbo "gerado em <data>".
4. Padronizar front-matter de metadados para todos os arquivos de `docs/`.
5. Integrar SEO/URLs com rotas: adicionar referências bilaterais entre `Estrutura de URLs e SEO.md` e `estrutura-de-paginas-e-links.md`.
6. Expandir `rpc-functions-standard.md` com checklist de PR e exemplos de testes (RBAC/RLS, `search_path`, `SECURITY DEFINER`, formatos de retorno JSONB).
7. Criar `docs/README.md` como índice, convenções e governança de atualização de documentos.

## Próximos passos
- Plano criado em `tricket-vault/plans/2025-08-18-0000-analise-documentacao-tricket.md` com ações detalhadas, riscos e critérios de aceite.
- Abrir branch específica para executar as mudanças propostas e seguir a governança do repositório.
