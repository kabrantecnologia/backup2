/**********************************************************************************************************************
*   -- INFORMAÇÕES DO SCRIPT --
*   NOME DO ARQUIVO: 13_views.sql
*   VERSÃO: 1.0
*   CRIADO POR: Gemini
*   DATA DE CRIAÇÃO: 2025-07-25
*
*   -- SUMÁRIO --
*   Este script cria e gerencia as VISUALIZAÇÕES (VIEWS) do banco de dados. As views são usadas para simplificar
*   consultas complexas, encapsular a lógica de junção de tabelas e fornecer uma camada de abstração segura
*   para o acesso aos dados. As views aqui definidas atendem a necessidades específicas da aplicação, como
*   exibir dados consolidados para administradores e apresentar informações de produtos de forma otimizada.
*
**********************************************************************************************************************/

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

-- View: view_admin_profile_approval
-- Consolida dados de perfis individuais e de organização para o painel de aprovação de administradores.
CREATE OR REPLACE VIEW public.view_admin_profile_approval AS
-- Perfis Individuais (PF)
SELECT
    p.id AS profile_id, p.profile_type, p.onboarding_status, id.profile_role::text AS profile_role,
    id.full_name AS name, id.contact_email AS email, id.cpf AS cpf_cnpj, id.birth_date,
    NULL AS company_type, id.contact_phone AS mobile_phone, id.income_value_cents,
    a.street AS address, a.number AS address_number, a.complement, a.state_id AS province, a.zip_code AS postal_code
FROM public.iam_profiles p
JOIN public.iam_individual_details id ON p.id = id.profile_id
LEFT JOIN public.iam_addresses a ON p.id = a.profile_id AND a.is_default = true
WHERE p.profile_type = 'INDIVIDUAL' AND p.onboarding_status <> 'LIMITED_ACCESS_COLLABORATOR_ONLY'
UNION ALL
-- Perfis de Organização (PJ)
SELECT
    p.id AS profile_id, p.profile_type, p.onboarding_status, od.platform_role::text AS profile_role,
    od.company_name AS name, od.contact_email AS email, od.cnpj AS cpf_cnpj, NULL AS birth_date,
    od.company_type, od.contact_phone AS mobile_phone, od.income_value_cents,
    a.street AS address, a.number AS address_number, a.complement, a.state_id AS province, a.zip_code AS postal_code
FROM public.iam_profiles p
JOIN public.iam_organization_details od ON p.id = od.profile_id
LEFT JOIN public.iam_addresses a ON p.id = a.profile_id AND a.is_default = true
WHERE p.profile_type = 'ORGANIZATION' AND p.onboarding_status <> 'LIMITED_ACCESS_COLLABORATOR_ONLY';
COMMENT ON VIEW public.view_admin_profile_approval IS 'View otimizada para administradores aprovarem perfis, consolidando dados de PF e PJ e excluindo colaboradores de acesso limitado.';

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