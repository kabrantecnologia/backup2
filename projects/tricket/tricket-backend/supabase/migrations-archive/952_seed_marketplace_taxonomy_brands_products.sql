
-- Upserts com CTEs para garantir IDs quando já existem registros por nome/slug
WITH dept AS (
  INSERT INTO public.marketplace_departments (id, name, slug, description, sort_order)
  VALUES ('40000000-0000-0000-0000-0000000000f1','Mercearia','mercearia','Itens de mercearia',1)
  ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
  RETURNING id
), cat AS (
  INSERT INTO public.marketplace_categories (id, department_id, name, slug, description, sort_order)
  SELECT '41000000-0000-0000-0000-000000000101', d.id, 'Mercearia Doce','mercearia-doce','Doces e confeitaria',1
  FROM dept d
  ON CONFLICT (department_id, name) DO UPDATE SET name = EXCLUDED.name
  RETURNING id
), sub AS (
  INSERT INTO public.marketplace_sub_categories (id, category_id, name, slug, description, sort_order)
  SELECT '42000000-0000-0000-0000-000000000102', c.id, 'Chocolates','chocolates','Chocolates em geral',1
  FROM cat c
  ON CONFLICT (category_id, name) DO UPDATE SET name = EXCLUDED.name
  RETURNING id
), brand AS (
  INSERT INTO public.marketplace_brands (id, name, slug, description, status)
  VALUES ('43000000-0000-0000-0000-000000000103','DoceBom','docebom','Marca de chocolates', 'ACTIVE')
  ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
  RETURNING id
)
INSERT INTO public.marketplace_products (
    id, sub_category_id, brand_id, name, description, sku_base, attributes, status, gtin,
    gpc_category_code, ncm_code, net_content, net_content_unit, gross_weight, net_weight, weight_unit,
    height, width, depth, dimension_unit, country_of_origin_code, gs1_company_name, gs1_company_gln
)
SELECT
    '44000000-0000-0000-0000-000000000104', s.id, b.id,
    'Chocolate ao Leite 90g', 'Barra de chocolate ao leite 90g', 'CHOC-90', '{"sabor":"ao leite","classificacao":"barra"}'::jsonb, 'ACTIVE',
    '7891000312217', '10000000', '1806.32.10', 90, 'g', 0.10, 0.09, 'kg', 0.8, 6.0, 15.0, 'cm', 'BR', 'DoceBom S.A.', '79012345000199'
FROM sub s, brand b
ON CONFLICT (gtin) DO NOTHING;

-- Imagem do produto
INSERT INTO public.marketplace_product_images (id, product_id, image_url, alt_text, sort_order)
VALUES ('45000000-0000-0000-0000-000000000105','44000000-0000-0000-0000-000000000104','https://picsum.photos/seed/choc90/600/400','Chocolate 90g',0)
ON CONFLICT DO NOTHING;
