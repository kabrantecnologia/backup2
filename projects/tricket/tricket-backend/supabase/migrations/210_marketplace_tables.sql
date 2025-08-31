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

