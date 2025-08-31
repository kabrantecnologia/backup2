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

/**********************************************************************************************************************
*   SEÇÃO 3: FUNÇÕES DE CONSULTA DE CONFIGURAÇÕES
*   Descrição: Funções para buscar configurações da aplicação de forma otimizada e segura.
**********************************************************************************************************************/

-- Função: get_app_settings
-- Retorna todas as configurações da aplicação, agregadas em um único objeto JSON.
CREATE OR REPLACE FUNCTION public.get_app_settings()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    settings_json JSONB;
BEGIN
    -- Constrói um objeto JSON onde cada chave da tabela vira uma chave do objeto.
    SELECT jsonb_object_agg(key, value) INTO settings_json
    FROM public.ui_app_settings;
    
    -- Retorna o objeto JSON ou um objeto vazio se a tabela não tiver registros.
    RETURN COALESCE(settings_json, '{}'::jsonb);
END;
$$;
COMMENT ON FUNCTION public.get_app_settings() IS 'Retorna todas as configurações da tabela ui_app_settings como um único objeto JSONB (chave-valor).';

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