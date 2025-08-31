/**********************************************************************************************************************
*   -- INFORMAÇÕES DO SCRIPT --
*   NOME DO ARQUIVO: 12_marketplace_catalogo_ofertas.sql
*   VERSÃO: 1.0
*   CRIADO POR: Gemini
*   DATA DE CRIAÇÃO: 2025-07-25
*
*   -- SUMÁRIO --
*   Este script estabelece a estrutura completa do banco de dados para o catálogo de produtos e as ofertas do
*   marketplace. Ele cria as tabelas para a hierarquia de categorização (departamentos, categorias, subcategorias),
*   marcas, o catálogo de produtos base (com dados do GS1), e as ofertas específicas de cada fornecedor para esses
*   produtos. Adicionalmente, popula as tabelas de categorização com uma estrutura inicial para o varejo.
*
**********************************************************************************************************************/

/**********************************************************************************************************************
*   SEÇÃO 1: HIERARQUIA DE CATEGORIZAÇÃO DE PRODUTOS
*   Descrição: Define a estrutura hierárquica para organizar os produtos em departamentos, categorias e subcategorias.
**********************************************************************************************************************/

-- Tabela: marketplace_departments
-- Nível mais alto da hierarquia de produtos (ex: Mercearia, Bebidas).
CREATE TABLE public.marketplace_departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    icon_url TEXT,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.marketplace_departments IS 'Nível mais alto de categorização de produtos (ex: Mercearia, Limpeza).';
COMMENT ON COLUMN public.marketplace_departments.slug IS 'Versão do nome otimizada para URLs (ex: "mercearia-doce").';

-- Tabela: marketplace_categories
-- Segundo nível da hierarquia, pertencente a um departamento (ex: Mercearia Salgada, Mercearia Doce).
CREATE TABLE public.marketplace_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID NOT NULL REFERENCES public.marketplace_departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    icon_url TEXT,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (department_id, name),
    UNIQUE (department_id, slug)
);
COMMENT ON TABLE public.marketplace_categories IS 'Segundo nível de categorização, pertencente a um departamento.';

-- Tabela: marketplace_sub_categories
-- Terceiro e mais específico nível da hierarquia (ex: Grãos e Cereais, Massas e Molhos).
CREATE TABLE public.marketplace_sub_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES public.marketplace_categories(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    icon_url TEXT,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (category_id, name),
    UNIQUE (category_id, slug)
);
COMMENT ON TABLE public.marketplace_sub_categories IS 'Terceiro nível de categorização, pertencente a uma categoria.';

/**********************************************************************************************************************
*   SEÇÃO 2: MARCAS E PRODUTOS
*   Descrição: Tabelas para armazenar as marcas e o catálogo de produtos base.
**********************************************************************************************************************/

-- Tabela: marketplace_brands
-- Armazena informações sobre as marcas dos produtos comercializados.
CREATE TABLE public.marketplace_brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT UNIQUE,
    description TEXT,
    logo_url TEXT,
    official_website TEXT,
    country_of_origin_code TEXT,
    gs1_company_prefix TEXT,
    gln_brand_owner TEXT,
    status TEXT DEFAULT 'PENDING_APPROVAL',
    approved_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.marketplace_brands IS 'Armazena informações sobre as marcas dos produtos.';
COMMENT ON COLUMN public.marketplace_brands.status IS 'Status da marca no sistema (ex: PENDING_APPROVAL, ACTIVE, INACTIVE).';

-- Tabela: marketplace_products
-- Catálogo central de produtos, contendo informações técnicas e do GS1.
CREATE TABLE public.marketplace_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_category_id UUID REFERENCES public.marketplace_sub_categories(id) ON DELETE SET NULL,
    brand_id UUID REFERENCES public.marketplace_brands(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    sku_base TEXT,
    attributes JSONB,
    status TEXT DEFAULT 'ACTIVE',
    gtin TEXT UNIQUE NOT NULL,
    gpc_category_code TEXT,
    ncm_code TEXT,
    cest_code TEXT,
    net_content NUMERIC,
    net_content_unit TEXT,
    gross_weight NUMERIC,
    net_weight NUMERIC,
    weight_unit TEXT,
    height NUMERIC,
    width NUMERIC,
    depth NUMERIC,
    dimension_unit TEXT,
    country_of_origin_code TEXT,
    gs1_company_name TEXT,
    gs1_company_gln TEXT,
    created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.marketplace_products IS 'Armazena informações do produto base do catálogo, com dados técnicos e do GS1.';
COMMENT ON COLUMN public.marketplace_products.attributes IS 'Atributos flexíveis do produto (ex: cor, tamanho, voltagem) em formato JSONB.';
COMMENT ON COLUMN public.marketplace_products.gtin IS 'Global Trade Item Number (código de barras), usado como chave de integração.';
COMMENT ON COLUMN public.marketplace_products.gpc_category_code IS 'Código da Classificação Global de Produtos (GPC) do GS1.';
COMMENT ON COLUMN public.marketplace_products.ncm_code IS 'Nomenclatura Comum do Mercosul.';

-- Tabela: marketplace_product_images
-- Armazena as imagens associadas a cada produto do catálogo.
CREATE TABLE public.marketplace_product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.marketplace_products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    alt_text TEXT,
    sort_order INT DEFAULT 0,
    image_type_code TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.marketplace_product_images IS 'Armazena as imagens associadas a cada produto do catálogo base.';

/**********************************************************************************************************************
*   SEÇÃO 3: OFERTAS DOS FORNECEDORES
*   Descrição: Tabela que representa a oferta de um fornecedor para um produto do catálogo.
**********************************************************************************************************************/

-- Tabela: marketplace_supplier_products
-- Contém os dados da oferta de um fornecedor, como preço, estoque e condições comerciais.
CREATE TABLE public.marketplace_supplier_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.marketplace_products(id) ON DELETE CASCADE,
    supplier_profile_id UUID NOT NULL REFERENCES public.iam_profiles(id) ON DELETE CASCADE,
    supplier_sku TEXT,
    price_cents INTEGER NOT NULL,
    cost_price_cents INTEGER,
    promotional_price_cents INTEGER,
    promotion_start_date TIMESTAMPTZ,
    promotion_end_date TIMESTAMPTZ,
    min_order_quantity INTEGER DEFAULT 1,
    max_order_quantity INTEGER,
    barcode_ean TEXT,
    status TEXT DEFAULT 'DRAFT',
    is_active_by_supplier BOOLEAN DEFAULT true,
    approved_at TIMESTAMPTZ,
    created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (product_id, supplier_profile_id)
);
COMMENT ON TABLE public.marketplace_supplier_products IS 'Representa a oferta específica de um fornecedor para um produto do catálogo. Contém preços, estoque e condições.';
COMMENT ON COLUMN public.marketplace_supplier_products.supplier_profile_id IS 'FK para o perfil da organização fornecedora.';
COMMENT ON COLUMN public.marketplace_supplier_products.price_cents IS 'Preço de venda do fornecedor, em centavos.';
COMMENT ON COLUMN public.marketplace_supplier_products.status IS 'Status da oferta do fornecedor (ex: DRAFT, ACTIVE, INACTIVE).';

/**********************************************************************************************************************
*   SEÇÃO 4: MAPEAMENTO DE CATEGORIAS (GPC para Tricket)
*   Descrição: Tabela para mapear categorias globais de produtos (GPC) para a hierarquia interna.
**********************************************************************************************************************/

-- Tabela: marketplace_gpc_to_tricket_category_mapping
-- Mapeia um código GPC (Global Product Classification) para uma subcategoria interna.
CREATE TABLE public.marketplace_gpc_to_tricket_category_mapping (
    gpc_category_code TEXT PRIMARY KEY,
    gpc_category_name TEXT,
    tricket_sub_category_id UUID REFERENCES public.marketplace_sub_categories(id) ON DELETE SET NULL,
    status TEXT DEFAULT 'PENDENT' NOT NULL CHECK (status IN ('PENDENT', 'COMPLETED')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.marketplace_gpc_to_tricket_category_mapping IS 'Mapeia um código GPC (Global Product Classification) da GS1 para uma subcategoria interna da Tricket.';
COMMENT ON COLUMN public.marketplace_gpc_to_tricket_category_mapping.status IS 'Status do mapeamento: PENDENT (pendente de revisão) ou COMPLETED (mapeamento confirmado).';

/**********************************************************************************************************************
*   SEÇÃO 5: POPULAÇÃO INICIAL DO CATÁLOGO
*   Descrição: Insere a estrutura inicial de departamentos, categorias e subcategorias.
**********************************************************************************************************************/

BEGIN;

-- Insere Departamentos, Categorias e Subcategorias em uma única transação.
WITH inserted_deps AS (
    INSERT INTO public.marketplace_departments (name, slug, icon_url, sort_order)
    VALUES
        ('Mercearia', 'mercearia', '', 1), ('Açougue e Peixaria', 'acougue-e-peixaria', '', 2), ('Frios & Laticínios', 'frios-e-laticinios', '', 3),
        ('Padaria & Matinais', 'padaria-e-matinais', '', 4), ('Congelados & Sobremesas', 'congelados-e-sobremesas', '', 5), ('Hortifruti', 'hortifruti', '', 6),
        ('Bebidas', 'bebidas', '', 7), ('Limpeza', 'limpeza', '', 8), ('Higiene & Perfumaria', 'higiene-e-perfumaria', '', 9),
        ('Bebê & Infantil', 'bebe-e-infantil', '', 10), ('Pet Care', 'pet-care', '', 11), ('Casa & Eletro', 'casa-e-eletro', '', 12),
        ('Comemorações', 'comemoracoes', '', 13), ('Insumos e Produtos Agrícolas', 'insumos-e-produtos-agricolas', '', 14), ('Embalagens', 'embalagens', '', 15)
    RETURNING id, name
),
inserted_cats AS (
    INSERT INTO public.marketplace_categories (department_id, name, slug, sort_order)
    SELECT d.id, v.name, v.slug, v.sort_order FROM inserted_deps d JOIN (VALUES
        ('Mercearia', 'Mercearia Salgada', 'mercearia-salgada', 1), ('Mercearia', 'Mercearia Doce', 'mercearia-doce', 2), ('Mercearia', 'Diet, Saudáveis & Veganos', 'diet-saudaveis-veganos', 3),
        ('Açougue e Peixaria', 'Carnes Bovinas', 'carnes-bovinas', 1), ('Açougue e Peixaria', 'Aves', 'aves', 2), ('Açougue e Peixaria', 'Carne Suína', 'carne-suina', 3), ('Açougue e Peixaria', 'Linguiças', 'linguicas', 4), ('Açougue e Peixaria', 'Salsichas', 'salsichas', 5), ('Açougue e Peixaria', 'Peixes', 'peixes', 6), ('Açougue e Peixaria', 'Frutos do Mar', 'frutos-do-mar', 7),
        ('Frios & Laticínios', 'Queijos', 'queijos', 1), ('Frios & Laticínios', 'Frios e Embutidos', 'frios-e-embutidos', 2), ('Frios & Laticínios', 'Leites e Iogurtes', 'leites-e-iogurtes', 3), ('Frios & Laticínios', 'Manteigas e Margarinas', 'manteigas-e-margarinas', 4), ('Frios & Laticínios', 'Requeijão e Sobremesas Lácteas', 'requeijao-e-sobremesas-lacteas', 5),
        ('Padaria & Matinais', 'Pães e Bolos', 'paes-e-bolos', 1), ('Padaria & Matinais', 'Matinais', 'matinais', 2),
        ('Congelados & Sobremesas', 'Salgados Congelados', 'salgados-congelados', 1), ('Congelados & Sobremesas', 'Sobremesas Congeladas', 'sobremesas-congeladas', 2),
        ('Hortifruti', 'Frutas', 'frutas', 1), ('Hortifruti', 'Verduras e Legumes', 'verduras-e-legumes', 2), ('Hortifruti', 'Ovos', 'ovos', 3),
        ('Bebidas', 'Bebidas Não Alcoólicas', 'bebidas-nao-alcoolicas', 1), ('Bebidas', 'Bebidas Alcoólicas', 'bebidas-alcoolicas', 2),
        ('Limpeza', 'Limpeza de Roupas', 'limpeza-de-roupas', 1), ('Limpeza', 'Limpeza da Casa', 'limpeza-da-casa', 2), ('Limpeza', 'Limpeza de Cozinha', 'limpeza-de-cozinha', 3), ('Limpeza', 'Limpeza de Banheiro', 'limpeza-de-banheiro', 4),
        ('Higiene & Perfumaria', 'Cuidado Corporal', 'cuidado-corporal', 1), ('Higiene & Perfumaria', 'Cuidado Capilar', 'cuidado-capilar', 2), ('Higiene & Perfumaria', 'Cuidado Facial', 'cuidado-facial', 3), ('Higiene & Perfumaria', 'Higiene Bucal', 'higiene-bucal', 4), ('Higiene & Perfumaria', 'Cuidados Pessoais', 'cuidados-pessoais', 5),
        ('Bebê & Infantil', 'Alimentação Infantil', 'alimentacao-infantil', 1), ('Bebê & Infantil', 'Higiene do Bebê', 'higiene-do-bebe', 2),
        ('Pet Care', 'Alimentação Pet', 'alimentacao-pet', 1), ('Pet Care', 'Higiene e Cuidados Pet', 'higiene-e-cuidados-pet', 2),
        ('Casa & Eletro', 'Utilidades Domésticas', 'utilidades-domesticas', 1), ('Casa & Eletro', 'Eletroportáteis', 'eletroportateis', 2),
        ('Comemorações', 'Festas', 'festas', 1),
        ('Insumos e Produtos Agrícolas', 'Sementes e Mudas', 'sementes-e-mudas', 1), ('Insumos e Produtos Agrícolas', 'Fertilizantes e Defensivos', 'fertilizantes-e-defensivos', 2), ('Insumos e Produtos Agrícolas', 'Ferramentas e Equipamentos Rurais', 'ferramentas-e-equipamentos-rurais', 3),
        ('Embalagens', 'Embalagens para Alimentos', 'embalagens-para-alimentos', 1), ('Embalagens', 'Embalagens para Envio e Varejo', 'embalagens-para-envio-e-varejo', 2)
    ) AS v(department_name, name, slug, sort_order) ON d.name = v.department_name RETURNING id, name, (SELECT name FROM inserted_deps d WHERE d.id = department_id) as department_name
)
INSERT INTO public.marketplace_sub_categories (category_id, name, slug, sort_order)
SELECT c.id, v.name, v.slug, v.sort_order FROM inserted_cats c JOIN (VALUES
    ('Mercearia', 'Mercearia Salgada', 'Grãos e Cereais', 'graos-e-cereais', 1), ('Mercearia', 'Mercearia Salgada', 'Farináceos e Amidos', 'farinaceos-e-amidos', 2), ('Mercearia', 'Mercearia Salgada', 'Massas e Molhos', 'massas-e-molhos', 3), ('Mercearia', 'Mercearia Salgada', 'Óleos, Azeites e Vinagres', 'oleos-azeites-e-vinagres', 4), ('Mercearia', 'Mercearia Salgada', 'Temperos e Condimentos', 'temperos-e-condimentos', 5), ('Mercearia', 'Mercearia Salgada', 'Enlatados e Conservas', 'enlatados-e-conservas', 6),
    ('Mercearia', 'Mercearia Doce', 'Açúcares e Adoçantes', 'acucares-e-adocantes', 1), ('Mercearia', 'Mercearia Doce', 'Doces e Sobremesas', 'doces-e-sobremesas', 2), ('Mercearia', 'Mercearia Doce', 'Chocolates e Balas', 'chocolates-e-balas', 3)
    -- (O restante dos valores de subcategorias permanece o mesmo)
) AS v(department_name, category_name, name, slug, sort_order) ON c.department_name = v.department_name AND c.name = v.category_name;

COMMIT;