# Tarefa 05 — Catálogo do Marketplace (Produtos Base)

- Branch sugerida: `feat/05-marketplace-catalogo-base`
- Objetivo: Consolidar departamentos/categorias/subcategorias, marcas e produtos base com imagens.

## Checklist
- [ ] Criar branch a partir de `dev`.
- [ ] Tabelas: `marketplace_departments`, `marketplace_categories`, `marketplace_sub_categories`, `marketplace_brands`, `marketplace_products`, `marketplace_product_images`.
- [ ] Constraints de unicidade por nível e `gtin` único.
- [ ] Views auxiliares: `view_products_with_image`.
- [ ] RPCs de consulta/curadoria (admin) e leitura pública autenticada.
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
- CRUD admin funcional e leitura pelo marketplace (backend) consistente.

## Referências
- `docs/130-plano-epicos-e-historias-tricket.md` (Épico 5)
- `docs/110-supabase_arquitetura.md`
- `docs/Análise de Compatibilidade GS1 Brasil.md`
