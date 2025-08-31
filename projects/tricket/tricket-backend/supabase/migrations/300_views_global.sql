/**********************************************************************************************************************
*   SEÇÃO 1: VIEWS GEOGRÁFICAS E DE ADMINISTRAÇÃO
*   Descrição: Views para facilitar a consulta de dados geográficos e para painéis administrativos.
**********************************************************************************************************************/

-- View: view_cities_with_states
-- Fornece uma lista de cidades com os nomes dos seus respectivos estados, simplificando consultas de endereço.
CREATE OR REPLACE VIEW public.view_cities_with_states AS
SELECT
    c.id AS city_id,
    c.name AS city_name,
    c.state_id,
    s.name AS state_name,
    s.country_code,
    c.created_at,
    c.updated_at
FROM public.generic_cities c
JOIN public.generic_states s ON c.state_id = s.id;
COMMENT ON VIEW public.view_cities_with_states IS 'Visualização que combina cidades com seus respectivos estados para facilitar consultas.';


/**********************************************************************************************************************
*   SEÇÃO 2: VIEWS DO MARKETPLACE
*   Descrição: Views para otimizar a exibição de produtos e ofertas no marketplace.
**********************************************************************************************************************/

-- View: view_products_with_image
-- Fornece uma visão consolidada dos produtos do catálogo com o nome da marca e a imagem principal.
CREATE OR REPLACE VIEW public.view_products_with_image AS
SELECT
    p.id, p.name, p.description, p.gtin, p.brand_id, b.name AS brand_name,
    pi.image_url, p.sub_category_id, sc.name AS sub_category_name, p.status
FROM public.marketplace_products p
JOIN public.marketplace_brands b ON p.brand_id = b.id
LEFT JOIN public.marketplace_sub_categories sc ON p.sub_category_id = sc.id
LEFT JOIN LATERAL (
    SELECT image_url FROM public.marketplace_product_images
    WHERE product_id = p.id ORDER BY sort_order LIMIT 1
) pi ON true;
COMMENT ON VIEW public.view_products_with_image IS 'Visão consolidada de produtos com nome da marca e imagem principal para listagens rápidas.';

-- View: view_supplier_products
-- Fornece uma visão detalhada das ofertas dos fornecedores, incluindo dados do produto, marca e imagem.
CREATE OR REPLACE VIEW public.view_supplier_products AS
SELECT
    sp.id, sp.product_id, p.name AS product_name, p.description AS product_description,
    p.gtin AS product_gtin, p.brand_id, b.name AS brand_name, pi.image_url,
    sp.supplier_profile_id, sp.supplier_sku, sp.price_cents
FROM public.marketplace_supplier_products sp
JOIN public.marketplace_products p ON sp.product_id = p.id
JOIN public.marketplace_brands b ON p.brand_id = b.id
LEFT JOIN LATERAL (
    SELECT image_url FROM public.marketplace_product_images
    WHERE product_id = p.id ORDER BY sort_order LIMIT 1
) pi ON true;
COMMENT ON VIEW public.view_supplier_products IS 'Visão detalhada das ofertas dos fornecedores, enriquecida com dados do produto, marca e imagem principal.';