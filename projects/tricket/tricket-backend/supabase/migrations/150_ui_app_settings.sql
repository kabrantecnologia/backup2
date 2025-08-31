-- supabase/seed.sql
-- Descrição: Popula o banco de dados com dados iniciais para a UI do projeto Tricket.

-- =====================================================================
-- SEÇÃO 1: DADOS INICIAIS (ROLES E CONFIGURAÇÕES)
-- =====================================================================

-- Roles Padrão
INSERT INTO public.rbac_roles (name, description, level) VALUES
('ADMIN', 'Administrador do sistema Tricket com acesso total.', 100),
('SUPPORT', 'Membro da equipe de suporte Tricket.', 80)
ON CONFLICT (name) DO NOTHING;

-- Configurações da Aplicação
INSERT INTO public.ui_app_settings (key, value, description) VALUES
('MAINTENANCE_MODE', 'false', 'Controla se a aplicação está em modo de manutenção.'),
('ALLOW_REGISTRATION', 'true', 'Controla se novos usuários podem se registrar.'),
('APP_NAME', 'Tricket', 'Plataforma de marketplace B2B com múltiplos perfis.'),
('DEVELOPER_NAME', 'Kabran Tecnologia', 'Nome da empresa ou desenvolvedor responsável pelo sistema.'),
('BUCKET_URL', 'https://api-dev2-tricket.kabran.com.br/storage/v1/object/public', 'URL do bucket de armazenamento público.'),
('EDGE_FUNCTIONS_URL', 'https://api-dev2-tricket.kabran.com.br/functions/v1/', 'URL das funções edge do sistema.'),
('APP_IMAGES', 'https://api-dev2-tricket.kabran.com.br/storage/v1/object/public/app-images/', 'URL das imagens do sistema.')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- =====================================================================
-- DADOS INICIAIS (CORES DA MARCA TRICKET)
-- =====================================================================

INSERT INTO public.ui_app_collors (name, light_theme_hex, dark_theme_hex, category, description)
VALUES
    -- ===================================
    -- 1. CORES DA MARCA (BRAND)
    -- ===================================
    ('brand-primary', '#022b33', '#022b33', 'brand', 'Cor principal da marca, usada em elementos de destaque e CTAs'),
    ('brand-secondary', '#4BC033', '#4BC033', 'brand', 'Cor secundária da marca, usada em textos e fundos'),
    ('brand-accent', '#f8e400', '#f8e400', 'brand', 'Cor de destaque (amarelo), usada para alertas e pontos de atenção'),

    -- ===================================
    -- 2. FUNDOS (BACKGROUNDS)
    -- ===================================
    ('background-primary', '#FFFFFF', '#18181B', 'background', 'Fundo principal da aplicação (área de conteúdo)'),
    ('background-secondary', '#F1F5F9', '#27272A', 'background', 'Fundo para áreas secundárias e seções destacadas'),
    ('background-sidebar-primary', '#022b33', '#18181B', 'background', 'Fundo da barra de navegação principal (sidebar)'),
    ('background-sidebar-secondary', '#FFFFFF', '#27272A', 'background', 'Fundo de uma possível barra de navegação secundária'),
    ('background-active', '#E2E8F0', '#3F3F46', 'background', 'Cor de fundo para itens de menu e elementos ativos'),
    ('background-overlay', 'rgba(2, 43, 51, 0.5)', 'rgba(0, 0, 0, 0.7)', 'background', 'Cor de fundo para modais e sobreposições'),

    -- ===================================
    -- 3. TEXTOS
    -- ===================================
    ('text-primary', '#022b33', '#F4F4F5', 'text', 'Cor de texto principal, para títulos e parágrafos'),
    ('text-secondary', '#3A5C64', '#A1A1AA', 'text', 'Cor de texto secundária, para subtítulos e descrições'),
    ('text-tertiary', '#627F87', '#71717A', 'text', 'Cor de texto terciária, para informações de menor destaque (placeholders, etc)'),
    ('text-inactive', '#627F87', '#71717A', 'text', 'Cor de texto para elementos inativos ou desabilitados'),
    ('text-on-brand', '#FFFFFF', '#FFFFFF', 'text', 'Cor de texto para ser usada sobre fundos com a cor `brand-primary`'),
    ('text-link', '#4bc033', '#23838a', 'text', 'Cor para links de texto'),
    ('text-fixed', '#FFFFFF', '#FFFFFF', 'text', 'Cor para textos fixos que não mudam com o tema (ex: texto em botões primários)'),

    -- ===================================
    -- 4. BORDAS E DIVISORES
    -- ===================================
    ('border-primary', '#E2E8F0', '#3F3F46', 'border', 'Cor principal para bordas de componentes como cards e inputs'),
    ('border-divider', '#F1F5F9', '#27272A', 'border', 'Cor para linhas divisórias sutis'),
    ('border-focus', '#4bc033', '#23838a', 'border', 'Cor da borda para elementos em foco (inputs, botões)'),

    -- ===================================
    -- 5. COMPONENTES
    -- ===================================
    ('component-card', '#FFFFFF', '#27272A', 'component', 'Cor de fundo para cards'),
    ('component-input', '#FFFFFF', '#27272A', 'component', 'Cor de fundo para campos de entrada'),
    ('component-input-inactive', '#F1F5F9', '#18181B', 'component', 'Cor de fundo para campos de entrada inativos'),
    ('component-element-selected', 'rgba(75, 192, 51, 0.1)', 'rgba(35, 131, 138, 0.15)', 'component', 'Cor de fundo para linhas de tabela ou itens de lista selecionados'),

    -- ===================================
    -- 6. BOTÕES
    -- ===================================
    -- Botão Primário
    ('button-primary-background', '#022b33', '#4BC033', 'button', 'Fundo de botões primários'),
    ('button-primary-hover', '#42a82c', '#42a82c', 'button', 'Fundo de botões primários em estado hover'),
    ('button-primary-text', '#FFFFFF', '#FFFFFF', 'button', 'Texto de botões primários'),
    -- Botão Secundário
    ('button-secondary-background', '#E2E8F0', '#E2E8F0', 'button', 'Fundo de botões secundários'),
    ('button-secondary-hover', '#CBD5E1', '#CBD5E1', 'button', 'Fundo de botões secundários em estado hover'),
    ('button-secondary-text', '#022b33', '#022b33', 'button', 'Texto de botões secundários'),
    -- Botão Inativo
    ('button-inactive-background', '#F1F5F9', '#27272A', 'button', 'Fundo para botões inativos'),
    ('button-inactive-text', '#627F87', '#71717A', 'button', 'Texto para botões inativos'),

    -- ===================================
    -- 7. CORES SEMÂNTICAS (ESTADOS)
    -- ===================================
    -- Sucesso (Usa o verde da marca)
    ('state-success-text', '#166534', '#4ADE80', 'state', 'Cor de texto para mensagens de sucesso'),
    ('state-success-background', 'rgba(34, 197, 94, 0.1)', 'rgba(74, 222, 128, 0.15)', 'state', 'Fundo para alertas de sucesso'),
    ('state-success-border', 'rgba(34, 197, 94, 0.2)', 'rgba(74, 222, 128, 0.3)', 'state', 'Borda para alertas de sucesso'),
    -- Alerta (Usa o amarelo da marca)
    ('state-warning-text', '#B45309', '#f8e400', 'state', 'Cor de texto para mensagens de alerta'),
    ('state-warning-background', 'rgba(248, 228, 0, 0.1)', 'rgba(248, 228, 0, 0.15)', 'state', 'Fundo para alertas de aviso'),
    ('state-warning-border', 'rgba(248, 228, 0, 0.2)', 'rgba(248, 228, 0, 0.3)', 'state', 'Borda para alertas de aviso'),
    -- Erro (Error/Danger)
    ('state-error-text', '#DC2626', '#F87171', 'state', 'Cor de texto para mensagens de erro'),
    ('state-error-background', 'rgba(220, 38, 38, 0.1)', 'rgba(248, 113, 113, 0.15)', 'state', 'Fundo para alertas de erro'),
    ('state-error-border', 'rgba(220, 38, 38, 0.2)', 'rgba(248, 113, 113, 0.3)', 'state', 'Borda para alertas de erro'),
    -- Informação (Info)
    ('state-info-text', '#2563EB', '#60A5FA', 'state', 'Cor de texto para mensagens informativas'),
    ('state-info-background', 'rgba(37, 99, 235, 0.1)', 'rgba(96, 165, 250, 0.15)', 'state', 'Fundo para alertas informativos'),
    ('state-info-border', 'rgba(37, 99, 235, 0.2)', 'rgba(96, 165, 250, 0.3)', 'state', 'Borda para alertas informativos');

-- =====================================================================
-- SEÇÃO 2: DADOS INICIAIS (UI STRUCTURE)
-- =====================================================================

DO $$
DECLARE
    admin_role_id UUID;
BEGIN
    -- 1. Obter o ID do role 'ADMIN'
    SELECT id INTO admin_role_id FROM public.rbac_roles WHERE name = 'ADMIN' LIMIT 1;

    -- 2. Inserir as páginas principais do Tricket
    INSERT INTO public.ui_app_pages (id, path, name) VALUES
    ('page-admin-dashboard', '/admin/visao-geral', 'Dashboard Administrativo'),
    ('page-fornecedor-dashboard', '/fornecedor/visao-geral', 'Dashboard Fornecedor'),
    ('page-comerciante-dashboard', '/comerciante/visao-geral', 'Dashboard Comerciante')
    ON CONFLICT (id) DO NOTHING;

    -- 3. Inserir os elementos de menu do Tricket
    -- (O restante do script de menus e permissões permanece o mesmo)
    -- ...

END;
$$;


-- =====================================================================
-- SEÇÃO 2: ESTRUTURA DA UI (PÁGINAS E MENUS)
-- =====================================================================

DO $$
DECLARE
    admin_role_id UUID;
BEGIN
    -- 1. Obter o ID do role 'ADMIN'
    SELECT id INTO admin_role_id FROM public.rbac_roles WHERE name = 'ADMIN' LIMIT 1;

    -- 2. Inserir as páginas principais do Tricket
    INSERT INTO public.ui_app_pages (id, path, name) VALUES
    ('page-admin-dashboard', 'tricket/admin/visao-geral', 'Dashboard Administrativo'),
    ('page-admin-usuarios', 'tricket/admin/cadastros/usuarios', 'Cadastro de Usuários'),
    ('page-admin-produtos', 'tricket/admin/cadastros/produtos', 'Cadastro de Produtos'),
    ('page-admin-categorias', 'tricket/admin/cadastros/categorias', 'Cadastro de Categorias'),
    ('page-admin-terminais', 'tricket/admin/cadastros/terminais', 'Cadastro de Terminais'),
    ('page-admin-equipamentos', 'tricket/admin/cadastros/equipamentos', 'Cadastro de Equipamentos'),
    ('page-admin-planos', 'tricket/admin/cadastros/planos', 'Cadastro de Planos'),
    ('page-fornecedor-dashboard', 'tricket/fornecedor/visao-geral', 'Dashboard Fornecedor'),
    ('page-comerciante-dashboard', 'tricket/comerciante/visao-geral', 'Dashboard Comerciante')
    ON CONFLICT (id) DO NOTHING;

    -- 3. Inserir os elementos de menu do Tricket
    -- Menus de Administrador (ADM)
    INSERT INTO public.ui_app_elements (id, element_type, parent_id, page_id, label, icon, path, position) VALUES
    ('admin_visao_geral', 'SIDEBAR_MENU', NULL, 'page-admin-dashboard', 'Visão Geral', 'lucide/layout-dashboard', 'tricket/admin/visao-geral', 0),
    ('admin_minha_conta', 'SIDEBAR_MENU', NULL, NULL, 'Minha Conta', 'phosphor-bold/user-bold', 'tricket/admin/minha-conta', 10),
    ('admin_notificacoes', 'SIDEBAR_MENU', NULL, NULL, 'Notificações', 'phosphor-bold/bell-ringing-bold', 'tricket/admin/notificacoes', 20),
    ('admin_cadastros', 'SIDEBAR_MENU', NULL, NULL, 'Cadastros', 'phosphor-bold/database-bold', NULL, 30),
    ('admin_financeiro', 'SIDEBAR_MENU', NULL, NULL, 'Financeiro', 'phosphor-bold/currency-circle-dollar-bold', NULL, 40),
    ('admin_suporte', 'SIDEBAR_MENU', NULL, NULL, 'Suporte', 'phosphor-bold/wechat-logo-bold', NULL, 50),
    ('admin_relatorios', 'SIDEBAR_MENU', NULL, NULL, 'Relatórios', 'phosphor-bold/chart-line-up-bold', NULL, 60),
    ('admin_configuracoes', 'SIDEBAR_MENU', NULL, NULL, 'Configurações', 'phosphor-bold/gear-bold', 'tricket/admin/configuracoes', 90)
    ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, parent_id = EXCLUDED.parent_id, page_id = EXCLUDED.page_id, label = EXCLUDED.label, icon = EXCLUDED.icon, path = EXCLUDED.path, position = EXCLUDED.position, updated_at = now();

    -- Sub-menus de Cadastros do Administrador
    INSERT INTO public.ui_app_elements (id, element_type, parent_id, page_id, label, icon, path, position) VALUES
    ('admin_cadastros_usuarios', 'SIDEBAR_MENU', 'admin_cadastros', 'page-admin-usuarios', 'Usuários', 'phosphor-bold/users-bold', 'tricket/admin/cadastros/usuarios', 0),
    ('admin_cadastros_planos', 'SIDEBAR_MENU', 'admin_cadastros', 'page-admin-planos', 'Planos', 'phosphor-bold/tag-chevron-bold', 'tricket/admin/cadastros/planos', 10),
    ('admin_cadastros_terminais', 'SIDEBAR_MENU', 'admin_cadastros', 'page-admin-terminais', 'Terminais', 'phosphor-bold/device-mobile-bold', 'tricket/admin/cadastros/terminais', 20),
    ('admin_cadastros_equipamentos', 'SIDEBAR_MENU', 'admin_cadastros', 'page-admin-equipamentos', 'Equipamentos', 'phosphor-bold/desktop-tower-bold', 'tricket/admin/cadastros/equipamentos', 30),
    ('admin_cadastros_produtos', 'SIDEBAR_MENU', 'admin_cadastros', 'page-admin-produtos', 'Produtos', 'phosphor-bold/package-bold', 'tricket/admin/cadastros/produtos', 40),
    ('admin_cadastros_categorias', 'SIDEBAR_MENU', 'admin_cadastros', 'page-admin-categorias', 'Categorias', 'phosphor-bold/folders-bold', 'tricket/admin/cadastros/categorias', 50)
    ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, parent_id = EXCLUDED.parent_id, page_id = EXCLUDED.page_id, label = EXCLUDED.label, icon = EXCLUDED.icon, path = EXCLUDED.path, position = EXCLUDED.position, updated_at = now();

    -- ... (Restante da inserção dos menus de admin, fornecedor e comerciante) ...

    -- 4. Conceder permissões de menu para o ADMIN
    IF admin_role_id IS NOT NULL THEN
        INSERT INTO public.ui_role_element_permissions (role_id, element_id)
        SELECT admin_role_id, id FROM public.ui_app_elements WHERE id LIKE 'admin_%'
        ON CONFLICT (role_id, element_id) DO NOTHING;
    END IF;

END;
$$;


-- Populando os dados do grid de usuários
DO $$
BEGIN
    -- 1. Inserir a definição dos grids
    INSERT INTO public.ui_grids (id, page_id, description, collection_id) VALUES
    ('grid-usuarios-admin', 'page-admin-usuarios', 'Grid que exibe a lista de usuários na página de administração.', '0d9f87db-7d2c-4d06-9233-c819a509fe8a'),
    ('grid-produtos-admin', 'page-admin-produtos', 'Grid que exibe a lista de produtos na página de administração.', '0d9f87db-7d2c-4d06-9233-c819a509fe8a'),
    ('grid-categorias-admin', 'page-admin-categorias', 'Grid que exibe a lista de categorias na página de administração.', '0d9f87db-7d2c-4d06-9233-c819a509fe8a'),
    ('grid-terminais-admin', 'page-admin-terminais', 'Grid que exibe a lista de terminais na página de administração.', '0d9f87db-7d2c-4d06-9233-c819a509fe8a'),
    ('grid-equipamentos-admin', 'page-admin-equipamentos', 'Grid que exibe a lista de equipamentos na página de administração.', '0d9f87db-7d2c-4d06-9233-c819a509fe8a'),
    ('grid-planos-admin', 'page-admin-planos', 'Grid que exibe a lista de planos na página de administração.', '0d9f87db-7d2c-4d06-9233-c819a509fe8a')
    ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description, collection_id = EXCLUDED.collection_id;

    -- 2. Inserir as colunas para os grids
    INSERT INTO public.ui_grid_columns (grid_id, data_key, label, size, position) VALUES
    ('grid-usuarios-admin', 'actions', 'Ações', '5%', 0),
    ('grid-usuarios-admin', 'full_name', 'Nome', '20%', 1),
    ('grid-usuarios-admin', 'email', 'E-mail', '20%', 10),
    ('grid-usuarios-admin', 'phone', 'Telefone', '15%', 20),
    ('grid-usuarios-admin', 'entity_type', 'PF/PJ', '10%', 30),
    ('grid-usuarios-admin', 'profile_type', 'Tipo', '15%', 40),
    ('grid-usuarios-admin', 'status', 'Status', '15%', 50),
    
    ('grid-produtos-admin', 'actions', 'Ações', '5%', 0),
    ('grid-produtos-admin', 'image_url', 'Imagem', '5%', 1),
    ('grid-produtos-admin', 'name', 'Nome', '30%', 10),
    ('grid-produtos-admin', 'gtin', 'GTIN', '15%', 20),
    ('grid-produtos-admin', 'brand_name', 'Marca', '15%', 30),
    ('grid-produtos-admin', 'category_name', 'Categoria', '15%', 40),
    ('grid-produtos-admin', 'status', 'Status', '15%', 50),

    ('grid-categorias-admin', 'actions', 'Ações', '5%', 0),
    ('grid-categorias-admin', 'name', 'Nome', '45%', 10),
    ('grid-categorias-admin', 'description', 'Descrição', '35%', 20),
    ('grid-categorias-admin', 'status', 'Status', '15%', 30),

    ('grid-terminais-admin', 'actions', 'Ações', '5%', 0),
    ('grid-terminais-admin', 'name', 'Nome', '45%', 10),
    ('grid-terminais-admin', 'description', 'Descrição', '35%', 20),
    ('grid-terminais-admin', 'status', 'Status', '15%', 30),

    ('grid-equipamentos-admin', 'actions', 'Ações', '5%', 0),
    ('grid-equipamentos-admin', 'name', 'Nome', '45%', 10),
    ('grid-equipamentos-admin', 'description', 'Descrição', '35%', 20),
    ('grid-equipamentos-admin', 'status', 'Status', '15%', 30),

    ('grid-planos-admin', 'actions', 'Ações', '5%', 0),
    ('grid-planos-admin', 'name', 'Nome', '45%', 10),
    ('grid-planos-admin', 'description', 'Descrição', '35%', 20),
    ('grid-planos-admin', 'status', 'Status', '15%', 30)
    ON CONFLICT (grid_id, data_key) DO UPDATE
    SET label = EXCLUDED.label, size = EXCLUDED.size, position = EXCLUDED.position;

END;
$$;