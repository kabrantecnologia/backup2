/**********************************************************************************************************************
*   -- INFORMAÇÕES DO SCRIPT --
*   NOME DO ARQUIVO: 04_ui_structure.sql
*   VERSÃO: 1.0
*   CRIADO POR: Gemini
*   DATA DE CRIAÇÃO: 2025-07-25
*
*   -- SUMÁRIO --
*   Este script define a estrutura do banco de dados para gerenciar a Interface do Usuário (UI) de forma dinâmica.
*   Ele cria tabelas para armazenar configurações globais da aplicação, registrar as páginas e seus elementos
*   (como menus e abas), e controlar as permissões de acesso a esses elementos com base nos papéis (roles) dos
*   usuários. O objetivo é permitir que a navegação e a visibilidade dos componentes da UI sejam configuráveis
*   pelo backend.
*
**********************************************************************************************************************/

/**********************************************************************************************************************
*   SEÇÃO 1: CONFIGURAÇÕES E ESTRUTURA DA UI
*   Descrição: Tabelas para armazenar configurações globais, páginas da aplicação e os elementos de UI que as compõem.
**********************************************************************************************************************/

-- Tabela: ui_app_settings
-- Armazena configurações globais do sistema de forma chave-valor (ex: modo de manutenção, chaves de API).
CREATE TABLE public.ui_app_settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    description TEXT
);
COMMENT ON TABLE public.ui_app_settings IS 'Guarda configurações globais do sistema de forma organizada, como chaves de API, modo de manutenção, etc.';
COMMENT ON COLUMN public.ui_app_settings.key IS 'Chave única para a configuração (ex: "MAINTENANCE_MODE").';
COMMENT ON COLUMN public.ui_app_settings.value IS 'Valor da configuração (ex: "true", "api_key_xyz").';
COMMENT ON COLUMN public.ui_app_settings.description IS 'Descrição clara da finalidade da configuração.';

-- Tabela: ui_app_pages
-- Registra as páginas da aplicação, que funcionam como contêineres para outros elementos de UI, como abas.
CREATE TABLE public.ui_app_pages (
    id TEXT PRIMARY KEY,
    path TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.ui_app_pages IS 'Registra as páginas da aplicação, que servem como contêineres para elementos de UI como abas.';
COMMENT ON COLUMN public.ui_app_pages.id IS 'Identificador único e estável da página (ex: "page-cadastros-usuarios").';
COMMENT ON COLUMN public.ui_app_pages.path IS 'O caminho da URL da página, usado para roteamento (ex: "/cadastros/usuarios").';
COMMENT ON COLUMN public.ui_app_pages.name IS 'Nome amigável da página (ex: "Usuários").';

-- Tabela: ui_app_elements
-- Tabela unificada para todos os elementos de navegação da UI, como itens de menu e abas de página.
CREATE TABLE public.ui_app_elements (
    id TEXT PRIMARY KEY,
    element_type public.element_type_enum NOT NULL,
    parent_id TEXT REFERENCES public.ui_app_elements(id) ON DELETE CASCADE,
    page_id TEXT REFERENCES public.ui_app_pages(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    icon TEXT,
    path TEXT,
    position SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.ui_app_elements IS 'Tabela unificada para todos os elementos de navegação da UI (menus, abas, etc).';
COMMENT ON COLUMN public.ui_app_elements.element_type IS 'O tipo do elemento (SIDEBAR_MENU ou PAGE_TAB).';
COMMENT ON COLUMN public.ui_app_elements.parent_id IS 'Referência ao elemento pai, usado para criar sub-menus.';
COMMENT ON COLUMN public.ui_app_elements.page_id IS 'Se o elemento for uma aba (PAGE_TAB), indica a qual página ele pertence.';
COMMENT ON COLUMN public.ui_app_elements.label IS 'O texto que será exibido para o usuário (ex: "Meus Pedidos").';
COMMENT ON COLUMN public.ui_app_elements.icon IS 'Nome ou classe do ícone a ser exibido ao lado do label.';
COMMENT ON COLUMN public.ui_app_elements.path IS 'O caminho da URL para navegação quando o elemento é clicado.';
COMMENT ON COLUMN public.ui_app_elements.position IS 'Define a ordem de exibição do elemento em relação aos seus irmãos.';

/**********************************************************************************************************************
*   SEÇÃO 2: PERMISSÕES DE ACESSO À UI
*   Descrição: Tabela que conecta os papéis do sistema (rbac_roles) aos elementos da UI, controlando a visibilidade.
**********************************************************************************************************************/

-- Tabela: ui_role_element_permissions
-- Concede permissão para um papel (role) visualizar um elemento de UI específico.
CREATE TABLE public.ui_role_element_permissions (
    role_id UUID NOT NULL REFERENCES public.rbac_roles(id) ON DELETE CASCADE,
    element_id TEXT NOT NULL REFERENCES public.ui_app_elements(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, element_id)
);
COMMENT ON TABLE public.ui_role_element_permissions IS 'Concede permissão de um role para um elemento de UI específico, controlando sua visibilidade.';
COMMENT ON COLUMN public.ui_role_element_permissions.role_id IS 'FK para a tabela de papéis (rbac_roles).';
COMMENT ON COLUMN public.ui_role_element_permissions.element_id IS 'FK para a tabela de elementos de UI (ui_app_elements).';


-- =====================================================================
-- SEÇÃO 3: ESTRUTURA DE GRIDS DINÂMICOS
-- Descrição: Popula as tabelas que controlam a exibição de grids/tabelas no front-end.
-- =====================================================================

-- Criação das tabelas de grid (se não existirem)
-- NOTA: O ideal é que estas tabelas sejam criadas em um arquivo de migração.
CREATE TABLE IF NOT EXISTS public.ui_grids (
    id TEXT PRIMARY KEY,
    page_id TEXT REFERENCES public.ui_app_pages(id),
    collection_id UUID, -- ID da coleção de dados no WeWeb
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ui_grid_columns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grid_id TEXT NOT NULL REFERENCES public.ui_grids(id) ON DELETE CASCADE,
    data_key TEXT NOT NULL,
    label TEXT NOT NULL,
    size TEXT DEFAULT '1fr',
    position INT DEFAULT 0,
    is_visible BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(grid_id, data_key)
);

-- Tabela: ui_app_collors
-- Armazena configurações de cores da interface para personalização visual da aplicação.
CREATE TABLE public.ui_app_collors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    light_theme_hex TEXT NOT NULL,
    dark_theme_hex TEXT NOT NULL,
    category TEXT NOT NULL, -- 'primary', 'secondary', 'accent', 'background', etc.
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.ui_app_collors IS 'Armazena cores personalizáveis para uso em toda a interface da aplicação, com suporte a temas claro e escuro.';
COMMENT ON COLUMN public.ui_app_collors.name IS 'Nome identificador da cor (ex: "primary-blue", "success").';
COMMENT ON COLUMN public.ui_app_collors.light_theme_hex IS 'Código hexadecimal da cor para o tema claro (ex: "#1E88E5").';
COMMENT ON COLUMN public.ui_app_collors.dark_theme_hex IS 'Código hexadecimal da cor para o tema escuro (ex: "#0D47A1").';
COMMENT ON COLUMN public.ui_app_collors.category IS 'Categoria da cor (ex: "primary", "secondary", "accent", "background").';
COMMENT ON COLUMN public.ui_app_collors.description IS 'Descrição sobre onde e como esta cor é utilizada.';

/**********************************************************************************************************************
*   SEÇÃO 3: FUNÇÕES DE CONSULTA DE CONFIGURAÇÕES
*   Descrição: Funções para buscar configurações da aplicação de forma otimizada e segura.
**********************************************************************************************************************/

-- Função: get_app_settings
-- Retorna todas as configurações da aplicação e cores em um único objeto JSON.
CREATE OR REPLACE FUNCTION public.get_app_settings()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    settings_json JSONB;
    colors_json JSONB;
    result_json JSONB;
    color_categories_json JSONB;
    category_rec RECORD;
    category_colors JSONB;
BEGIN
    -- Constrói um objeto JSON com as configurações
    SELECT jsonb_object_agg(key, value) INTO settings_json
    FROM public.ui_app_settings;
    
    -- Inicializa o objeto JSON para as cores
    colors_json := '{}'::jsonb;
    
    -- Itera sobre cada categoria de cor separadamente
    FOR category_rec IN SELECT DISTINCT category FROM public.ui_app_collors LOOP
        -- Para cada categoria, obtem as cores como um array JSON
        SELECT jsonb_agg(
            jsonb_build_object(
                'name', name,
                'light', light_theme_hex,
                'dark', dark_theme_hex,
                'description', description
            )
        ) INTO category_colors
        FROM public.ui_app_collors
        WHERE category = category_rec.category;
        
        -- Adiciona a categoria ao objeto JSON principal
        colors_json := colors_json || jsonb_build_object(category_rec.category, category_colors);
    END LOOP;
    
    -- Combina configurações e cores em um objeto JSON final
    SELECT jsonb_build_object(
        'settings', COALESCE(settings_json, '{}'::jsonb),
        'colors', COALESCE(colors_json, '{}'::jsonb)
    ) INTO result_json;
    
    -- Retorna o objeto JSON combinado
    RETURN result_json;
END;
$$;
COMMENT ON FUNCTION public.get_app_settings() IS 'Retorna todas as configurações e cores da aplicação como um objeto JSONB estruturado com "settings" e "colors".';

-- Função: get_app_setting
-- Retorna o valor de uma única configuração da aplicação, especificada por sua chave.
CREATE OR REPLACE FUNCTION public.get_app_setting(p_key TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    setting_value TEXT;
BEGIN
    -- Busca o valor de uma configuração específica a partir da chave fornecida.
    SELECT value INTO setting_value
    FROM public.ui_app_settings
    WHERE key = p_key;
    
    RETURN setting_value;
END;
$$;
COMMENT ON FUNCTION public.get_app_setting(TEXT) IS 'Retorna o valor de uma configuração específica da aplicação com base na chave (key) fornecida.';

-- =================================================================
-- VIEW PARA EXIBIR CORES AGRUPADAS POR CATEGORIA (FORMATO ARRAY)
-- =================================================================
-- Esta view transforma os dados da tabela 'ui_app_collors' em um
-- único array JSON. Cada elemento do array é um objeto que
-- representa uma categoria e contém uma lista de suas cores.
-- Este formato é ideal para repetição dinâmica no front-end.

CREATE OR REPLACE VIEW public.view_ui_colors_by_category AS
SELECT
    -- jsonb_agg cria o array JSON final.
    jsonb_agg(
        -- jsonb_build_object cria um objeto para cada categoria.
        jsonb_build_object(
            'category', category,
            'colors', colors
        )
        ORDER BY category -- Ordena as categorias alfabeticamente.
    ) AS colors_json
FROM (
    -- Subconsulta para agrupar as cores por categoria.
    SELECT
        category,
        -- jsonb_agg agrupa todos os objetos de cor de uma mesma categoria em um único array JSON.
        jsonb_agg(
            -- jsonb_build_object cria um objeto JSON para cada linha (cada cor).
            jsonb_build_object(
                'name', name,
                'light_theme_hex', light_theme_hex,
                'dark_theme_hex', dark_theme_hex,
                'description', description
            )
            ORDER BY name -- Ordena os tokens alfabeticamente dentro de cada categoria.
        ) AS colors
    FROM
        public.ui_app_collors
    GROUP BY
        category
) AS grouped_colors;

-- Exemplo de como consultar a view:
-- SELECT * FROM public.view_ui_colors_by_category;
