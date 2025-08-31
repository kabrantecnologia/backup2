-- supabase/seed.sql
-- Descrição: Popula o banco de dados com dados iniciais essenciais para o ambiente de desenvolvimento.

-- Roles Padrão Sugeridos (Inserir após a criação da tabela, se necessário via script de seed)
INSERT INTO public.rbac_roles (name, description, level) VALUES ('ADMIN', 'Administrador do sistema Tricket com acesso total.', 100);
INSERT INTO public.rbac_roles (name, description, level) VALUES ('SUPPORT', 'Membro da equipe de suporte Tricket.', 80);

-- =====================================================================
-- SEÇÃO: DADOS INICIAIS (UI STRUCTURE - PROJETO INTEGRA)
-- Descrição: Popula as tabelas de controle da interface com as
--            páginas e menus principais para o sistema Integra.
-- =====================================================================
-- =====================================================================
-- SEÇÃO 1: DADOS INICIAIS (ROLES E CONFIGURAÇÕES)
-- =====================================================================

-- NOTA: Roles são inseridas nas migrações específicas
-- Esta seção foi removida para evitar duplicação

INSERT INTO public.ui_app_settings (key, value, description) VALUES
('MAINTENANCE_MODE', 'false', 'Controla se a aplicação está em modo de manutenção.'),
('ALLOW_REGISTRATION', 'true', 'Controla se novos usuários podem se registrar.'),
('APP_NAME', 'Tricket', 'Plataforma de marketplace B2B com múltiplos perfis.'),
('DEVELOPER_NAME', 'Kabran Tecnologia', 'Nome da empresa ou desenvolvedor responsável pelo sistema.'),
('BUCKET_URL', 'https://api.staging.tricket.com.br/storage/v1/object/public', 'URL do bucket de armazenamento público.'),
('EDGE_FUNCTIONS_URL', 'https://api.staging.tricket.com.br/functions/v1/', 'URL das funções edge do sistema.'),
('APP_IMAGES', 'https://api.staging.tricket.com.br/storage/v1/object/public/app-images/', 'URL das imagens do sistema.')
ON CONFLICT (key) DO NOTHING;

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

    -- Menus de Administrador (ADM)
    INSERT INTO public.ui_app_elements (id, element_type, parent_id, page_id, label, icon, path, position) VALUES
    ('admin_visao_geral', 'SIDEBAR_MENU', NULL, NULL, 'Visão Geral', 'lucide/layout-dashboard', '/admin/visao-geral', 0),
    ('admin_minha_conta', 'SIDEBAR_MENU', NULL, NULL, 'Minha Conta', 'phosphor-bold/user-bold', '/admin/minha-conta', 10),
    ('admin_notificacoes', 'SIDEBAR_MENU', NULL, NULL, 'Notificações', 'phosphor-bold/bell-ringing-bold', '/admin/notificacoes', 20),
    ('admin_cadastros', 'SIDEBAR_MENU', NULL, NULL, 'Cadastros', 'phosphor-bold/database-bold', NULL, 30),
    ('admin_financeiro', 'SIDEBAR_MENU', NULL, NULL, 'Financeiro', 'phosphor-bold/currency-circle-dollar-bold', NULL, 40),
    ('admin_suporte', 'SIDEBAR_MENU', NULL, NULL, 'Suporte', 'phosphor-bold/wechat-logo-bold', NULL, 50),
    ('admin_relatorios', 'SIDEBAR_MENU', NULL, NULL, 'Relatórios', 'phosphor-bold/chart-line-up-bold', NULL, 60),
    ('admin_configuracoes', 'SIDEBAR_MENU', NULL, NULL, 'Configurações', 'phosphor-bold/gear-bold', '/admin/configuracoes', 90)
    ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, parent_id = EXCLUDED.parent_id, page_id = EXCLUDED.page_id, label = EXCLUDED.label, icon = EXCLUDED.icon, path = EXCLUDED.path, position = EXCLUDED.position, updated_at = now();

    -- Sub-menus de Cadastros do Administrador
    INSERT INTO public.ui_app_elements (id, element_type, parent_id, page_id, label, icon, path, position) VALUES
    ('admin_cadastros_usuarios', 'SIDEBAR_MENU', 'admin_cadastros', NULL, 'Usuários', 'phosphor-bold/users-bold', '/admin/cadastros/usuarios', 0),
    ('admin_cadastros_planos', 'SIDEBAR_MENU', 'admin_cadastros', NULL, 'Planos', 'phosphor-bold/tag-chevron-bold', '/admin/cadastros/planos', 10),
    ('admin_cadastros_terminais', 'SIDEBAR_MENU', 'admin_cadastros', NULL, 'Terminais', 'phosphor-bold/device-mobile-bold', '/admin/cadastros/terminais', 20),
    ('admin_cadastros_equipamentos', 'SIDEBAR_MENU', 'admin_cadastros', NULL, 'Equipamentos', 'phosphor-bold/desktop-tower-bold', '/admin/cadastros/equipamentos', 30),
    ('admin_cadastros_produtos', 'SIDEBAR_MENU', 'admin_cadastros', NULL, 'Produtos', 'phosphor-bold/package-bold', '/admin/cadastros/produtos', 40),
    ('admin_cadastros_categorias', 'SIDEBAR_MENU', 'admin_cadastros', NULL, 'Categorias', 'phosphor-bold/folders-bold', '/admin/cadastros/categorias', 50)
    ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, parent_id = EXCLUDED.parent_id, page_id = EXCLUDED.page_id, label = EXCLUDED.label, icon = EXCLUDED.icon, path = EXCLUDED.path, position = EXCLUDED.position, updated_at = now();

    -- Sub-menus de Financeiro do Administrador
    INSERT INTO public.ui_app_elements (id, element_type, parent_id, page_id, label, icon, path, position) VALUES
    ('admin_financeiro_transacoes', 'SIDEBAR_MENU', 'admin_financeiro', NULL, 'Transações', 'phosphor-bold/arrows-left-right-bold', '/admin/financeiro/transacoes', 0),
    ('admin_financeiro_extrato', 'SIDEBAR_MENU', 'admin_financeiro', NULL, 'Extrato', 'phosphor-bold/list-dashes-bold', '/admin/financeiro/extrato', 10)
    ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, parent_id = EXCLUDED.parent_id, page_id = EXCLUDED.page_id, label = EXCLUDED.label, icon = EXCLUDED.icon, path = EXCLUDED.path, position = EXCLUDED.position, updated_at = now();

    -- Sub-menus de Suporte do Administrador
    INSERT INTO public.ui_app_elements (id, element_type, parent_id, page_id, label, icon, path, position) VALUES
    ('admin_suporte_tickets', 'SIDEBAR_MENU', 'admin_suporte', NULL, 'Tickets', 'phosphor-bold/wechat-logo-bold', '/admin/suporte/tickets', 0)
    ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, parent_id = EXCLUDED.parent_id, page_id = EXCLUDED.page_id, label = EXCLUDED.label, icon = EXCLUDED.icon, path = EXCLUDED.path, position = EXCLUDED.position, updated_at = now();

    -- Sub-menus de Relatórios do Administrador
    INSERT INTO public.ui_app_elements (id, element_type, parent_id, page_id, label, icon, path, position) VALUES
    ('admin_relatorios_vendas', 'SIDEBAR_MENU', 'admin_relatorios', NULL, 'Vendas', 'phosphor-bold/chart-line-up-bold', '/admin/relatorios/vendas', 0),
    ('admin_relatorios_produtos', 'SIDEBAR_MENU', 'admin_relatorios', NULL, 'Produtos', 'phosphor-bold/chart-scatter-bold', '/admin/relatorios/produtos', 10),
    ('admin_relatorios_usuarios', 'SIDEBAR_MENU', 'admin_relatorios', NULL, 'Usuários', 'phosphor-bold/chart-pie-bold', '/admin/relatorios/usuarios', 20)
    ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, parent_id = EXCLUDED.parent_id, page_id = EXCLUDED.page_id, label = EXCLUDED.label, icon = EXCLUDED.icon, path = EXCLUDED.path, position = EXCLUDED.position, updated_at = now();

    -- Menus de Fornecedor
    INSERT INTO public.ui_app_elements (id, element_type, parent_id, page_id, label, icon, path, position) VALUES
    ('fornecedor_visao_geral', 'SIDEBAR_MENU', NULL, NULL, 'Visão Geral', 'lucide/layout-dashboard', '/fornecedor/visao-geral', 0),
    ('fornecedor_minha_conta', 'SIDEBAR_MENU', NULL, NULL, 'Minha Conta', 'phosphor-bold/user-bold', '/fornecedor/minha-conta', 10),
    ('fornecedor_ofertas', 'SIDEBAR_MENU', NULL, NULL, 'Ofertas', 'phosphor-bold/tag-bold', '/fornecedor/ofertas', 20),
    ('fornecedor_pedidos', 'SIDEBAR_MENU', NULL, NULL, 'Pedidos', 'phosphor-bold/shopping-cart-bold', '/fornecedor/pedidos', 30),
    ('fornecedor_financeiro', 'SIDEBAR_MENU', NULL, NULL, 'Financeiro', 'phosphor-bold/currency-circle-dollar-bold', '/fornecedor/financeiro', 40),
    ('fornecedor_notificacoes', 'SIDEBAR_MENU', NULL, NULL, 'Notificações', 'phosphor-bold/bell-ringing-bold', '/fornecedor/notificacoes', 50),
    ('fornecedor_configuracoes', 'SIDEBAR_MENU', NULL, NULL, 'Configurações', 'phosphor-bold/gear-bold', '/fornecedor/configuracoes', 90)
    ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, parent_id = EXCLUDED.parent_id, page_id = EXCLUDED.page_id, label = EXCLUDED.label, icon = EXCLUDED.icon, path = EXCLUDED.path, position = EXCLUDED.position, updated_at = now();

    -- Menus de Comerciante
    INSERT INTO public.ui_app_elements (id, element_type, parent_id, page_id, label, icon, path, position) VALUES
    ('comerciante_visao_geral', 'SIDEBAR_MENU', NULL, NULL, 'Visão Geral', 'lucide/layout-dashboard', '/comerciante/visao-geral', 0),
    ('comerciante_minha_conta', 'SIDEBAR_MENU', NULL, NULL, 'Minha Conta', 'phosphor-bold/user-bold', '/comerciante/minha-conta', 10),
    ('comerciante_minha_pos', 'SIDEBAR_MENU', NULL, NULL, 'Minha POS', 'phosphor-bold/contactless-payment-bold', '/comerciante/minha-pos', 20),
    ('comerciante_pedidos', 'SIDEBAR_MENU', NULL, NULL, 'Pedidos', 'phosphor-bold/shopping-cart-bold', '/comerciante/pedidos', 30),
    ('comerciante_financeiro', 'SIDEBAR_MENU', NULL, NULL, 'Financeiro', 'phosphor-bold/currency-circle-dollar-bold', '/comerciante/financeiro', 40),
    ('comerciante_notificacoes', 'SIDEBAR_MENU', NULL, NULL, 'Notificações', 'phosphor-bold/bell-ringing-bold', '/comerciante/notificacoes', 50),
    ('comerciante_configuracoes', 'SIDEBAR_MENU', NULL, NULL, 'Configurações', 'phosphor-bold/gear-bold', '/comerciante/configuracoes', 90)
    ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, parent_id = EXCLUDED.parent_id, page_id = EXCLUDED.page_id, label = EXCLUDED.label, icon = EXCLUDED.icon, path = EXCLUDED.path, position = EXCLUDED.position, updated_at = now();

    -- 4. Conceder permissões específicas por contexto/role
    -- ADMIN só tem acesso aos menus administrativos (admin_*)
    IF admin_role_id IS NOT NULL THEN
        INSERT INTO public.ui_role_element_permissions (role_id, element_id)
        SELECT admin_role_id, id FROM public.ui_app_elements WHERE id LIKE 'admin_%'
        ON CONFLICT (role_id, element_id) DO NOTHING;
    END IF;

    -- Nota: Menus de fornecedor e comerciante são controlados por platform_role
    -- através da lógica de contexto de perfil, não por role global
END;
$$;