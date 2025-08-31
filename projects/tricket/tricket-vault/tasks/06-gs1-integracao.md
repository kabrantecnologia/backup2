# Tarefa 06 — Integração GS1 (Enriquecimento por GTIN)

- Branch sugerida: `feat/06-gs1-integracao`
- Objetivo: Consultar Verified by GS1, armazenar bruto em `gs1_api_responses`, enriquecer `marketplace_products` e sugerir categoria via mapeamento GPC.

## Checklist
- [ ] Criar branch a partir de `dev`.
- [ ] Tabelas: `gs1_api_responses`, `marketplace_gpc_to_tricket_category_mapping` (status e índices).
- [ ] Funções/RPCs: `get_product_by_gtin(p_gtin text)` (ou wrapper) para consulta e enriquecimento; upload de imagens (armazenar url/metadata).
- [ ] Fluxo: se `gtin` existir → retorna; se não → consulta GS1 → upsert produto/brand → retorna.
- [ ] Admin aprova nova brand (`marketplace_brands.status`).
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
- Pré-preenchimento por GTIN nos testes e mapeamento GPC→categoria sugerida funcional.

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 6)
- `docs/Análise de Compatibilidade GS1 Brasil.md`
- `docs/110-supabase_arquitetura.md`
- `docs/rpc-functions-standard.md`
