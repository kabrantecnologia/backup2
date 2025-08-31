-- =====================================================================
-- DADOS INICIAIS (CONFIGURAÇÕES)
-- =====================================================================

-- Configurações da Aplicação para o Projeto Integra
INSERT INTO public.ui_app_settings (key, value, description) VALUES
('MAINTENANCE_MODE', 'false', 'Controla se a aplicação está em modo de manutenção.'),
('ALLOW_REGISTRATION', 'true', 'Controla se novos usuários podem se registrar.'),
('APP_NAME', 'Projeto Integra', 'Sistema de Gestão Integrada para o NACJ.'),
('DEVELOPER_NAME', 'Kabran Tecnologia', 'Nome da empresa ou desenvolvedor responsável pelo sistema.'),
('BUCKET_URL', 'https://api-dev-integra.kabran.com.br/storage/v1/object/public', 'URL do bucket de armazenamento público.'),
('EDGE_FUNCTIONS_URL', 'https://api-dev-integra.kabran.com.br/functions/v1/', 'URL das funções edge do sistema.'),
('APP_IMAGES', 'https://api-dev-integra.kabran.com.br/storage/v1/object/public/app-images/', 'URL das imagens do sistema.')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- =====================================================================
-- DADOS INICIAIS (ROLES)
-- =====================================================================

-- Roles Padrão
INSERT INTO public.rbac_roles (name, description, level) VALUES
('ADMIN', 'Administrador do sistema com acesso total.', 100),
('SUPPORT', 'Membro da equipe de suporte.', 80)
ON CONFLICT (name) DO NOTHING;

-- =====================================================================
-- DADOS INICIAIS (CORES)
-- =====================================================================

INSERT INTO public.ui_app_collors (name, light_theme_hex, dark_theme_hex, category, description)
VALUES
    -- ===================================
    -- 1. CORES DA MARCA (BRAND)
    -- ===================================
    ('brand-primary', '#C93602', '#C93602', 'brand', 'Cor principal da marca (laranja), usada em elementos de destaque e CTAs'),
    ('brand-secondary', '#013D25', '#EBF2EF', 'brand', 'Cor secundária da marca (verde escuro), usada em textos e fundos'),

    -- ===================================
    -- 2. FUNDOS (BACKGROUNDS)
    -- ===================================
    ('background-primary', '#FFFFFF', '#18181B', 'background', 'Fundo principal da aplicação (área de conteúdo)'),
    ('background-secondary', '#F5F8F7', '#27272A', 'background', 'Fundo para áreas secundárias e seções destacadas'),
    ('background-sidebar-primary', '#013D25', '#18181B', 'background', 'Fundo da barra de navegação principal (sidebar)'),
    ('background-sidebar-secondary', '#FFFFFF', '#27272A', 'background', 'Fundo de uma possível barra de navegação secundária'),
    ('background-active', '#EBF2EF', '#3F3F46', 'background', 'Cor de fundo para itens de menu e elementos ativos'),
    ('background-overlay', 'rgba(1, 61, 37, 0.5)', 'rgba(0, 0, 0, 0.7)', 'background', 'Cor de fundo para modais e sobreposições'),

    -- ===================================
    -- 3. TEXTOS
    -- ===================================
    ('text-primary', '#013D25', '#F4F4F5', 'text', 'Cor de texto principal, para títulos e parágrafos'),
    ('text-secondary', '#03544B', '#A1A1AA', 'text', 'Cor de texto secundária, para subtítulos e descrições'),
    ('text-tertiary', '#5B7A71', '#71717A', 'text', 'Cor de texto terciária, para informações de menor destaque (placeholders, etc)'),
    ('text-inactive', '#5B7A71', '#71717A', 'text', 'Cor de texto para elementos inativos ou desabilitados'),
    ('text-on-brand', '#FFFFFF', '#FFFFFF', 'text', 'Cor de texto para ser usada sobre fundos com a cor `brand-primary`'),
    ('text-link', '#C93602', '#60A5FA', 'text', 'Cor para links de texto'),
    ('text-fixed', '#FFFFFF', '#FFFFFF', 'text', 'Cor para links de texto fixos'),

    -- ===================================
    -- 4. BORDAS E DIVISORES
    -- ===================================
    ('border-primary', '#EBF2EF', '#3F3F46', 'border', 'Cor principal para bordas de componentes como cards e inputs'),
    ('border-divider', '#F5F8F7', '#27272A', 'border', 'Cor para linhas divisórias sutis'),
    ('border-focus', '#C93602', '#60A5FA', 'border', 'Cor da borda para elementos em foco (inputs, botões)'),

    -- ===================================
    -- 5. COMPONENTES
    -- ===================================
    ('component-card', '#FFFFFF', '#27272A', 'component', 'Cor de fundo para cards'),
    ('component-input', '#FFFFFF', '#27272A', 'component', 'Cor de fundo para campos de entrada'),
    ('component-input-inactive', '#F5F8F7', '#18181B', 'component', 'Cor de fundo para campos de entrada inativos'),
    ('component-element-selected', 'rgba(201, 54, 2, 0.1)', 'rgba(96, 165, 250, 0.12)', 'component', 'Cor de fundo para linhas de tabela ou itens de lista selecionados'),

    -- ===================================
    -- 6. BOTÕES
    -- ===================================
    -- Botão Primário
    ('button-primary-background', '#03544B', '#03544B', 'button', 'Fundo de botões primários'),
    ('button-primary-hover', '#013D25', '#013D25', 'button', 'Fundo de botões primários em estado hover'),
    ('button-primary-text', '#FFFFFF', '#FFFFFF', 'button', 'Texto de botões primários'),
    -- Botão Secundário
    ('button-secondary-background', '#EBF2EF', '#3F3F46', 'button', 'Fundo de botões secundários'),
    ('button-secondary-hover', '#D8E5E1', '#52525B', 'button', 'Fundo de botões secundários em estado hover'),
    ('button-secondary-text', '#013D25', '#F4F4F5', 'button', 'Texto de botões secundários'),
    -- Botão Inativo
    ('button-inactive-background', '#F5F8F7', '#27272A', 'button', 'Fundo para botões inativos'),
    ('button-inactive-text', '#5B7A71', '#71717A', 'button', 'Texto para botões inativos'),

    -- ===================================
    -- 7. CORES SEMÂNTICAS (ESTADOS)
    -- ===================================
    -- Sucesso
    ('state-success-text', '#166534', '#4ADE80', 'state', 'Cor de texto para mensagens de sucesso'),
    ('state-success-background', 'rgba(34, 197, 94, 0.1)', 'rgba(74, 222, 128, 0.15)', 'state', 'Fundo para alertas de sucesso'),
    ('state-success-border', 'rgba(34, 197, 94, 0.2)', 'rgba(74, 222, 128, 0.3)', 'state', 'Borda para alertas de sucesso'),
    -- Alerta (Warning)
    ('state-warning-text', '#B45309', '#FBBF24', 'state', 'Cor de texto para mensagens de alerta'),
    ('state-warning-background', 'rgba(251, 191, 36, 0.1)', 'rgba(251, 191, 36, 0.15)', 'state', 'Fundo para alertas de aviso'),
    ('state-warning-border', 'rgba(251, 191, 36, 0.2)', 'rgba(251, 191, 36, 0.3)', 'state', 'Borda para alertas de aviso'),
    -- Erro (Error/Danger)
    ('state-error-text', '#DC2626', '#F87171', 'state', 'Cor de texto para mensagens de erro'),
    ('state-error-background', 'rgba(220, 38, 38, 0.1)', 'rgba(248, 113, 113, 0.15)', 'state', 'Fundo para alertas de erro'),
    ('state-error-border', 'rgba(220, 38, 38, 0.2)', 'rgba(248, 113, 113, 0.3)', 'state', 'Borda para alertas de erro'),
    -- Informação (Info)
    ('state-info-text', '#2563EB', '#60A5FA', 'state', 'Cor de texto para mensagens informativas'),
    ('state-info-background', 'rgba(37, 99, 235, 0.1)', 'rgba(96, 165, 250, 0.15)', 'state', 'Fundo para alertas informativos'),
    ('state-info-border', 'rgba(37, 99, 235, 0.2)', 'rgba(96, 165, 250, 0.3)', 'state', 'Borda para alertas informativos');


-- =====================================================================
-- ESTRUTURA DA UI (PÁGINAS E MENUS)
-- =====================================================================

DO $$
DECLARE
    admin_role_id UUID;
BEGIN
    -- 1. Obter o ID do role 'ADMIN'
    SELECT id INTO admin_role_id FROM public.rbac_roles WHERE name = 'ADMIN' LIMIT 1;

    -- 2. Inserir as páginas principais do Integra
    INSERT INTO public.ui_app_pages (id, path, name) VALUES
    ('page-integra-dashboard', 'integra/admin/dashboard', 'Dashboard Principal'),
    ('page-integra-usuarios', 'integra/admin/cadastros/usuarios', 'Cadastro de Usuários'),
    ('page-integra-crm-contatos', 'integra/admin/crm/contatos', 'Gestão de Contatos (CRM)'),
    ('page-integra-dp-folha', 'integra/admin/dp/folha', 'Auxiliar de Folha de Pagamento'),
    ('page-integra-financeiro-remessas', 'integra/admin/financeiro/remessas', 'Gestão de Remessas'),
    ('page-integra-logistica-coletas', 'integra/admin/logistica/coletas', 'Gestão de Coletas'),
    ('page-integra-bazar-pdv', 'integra/admin/bazar/pdv', 'Ponto de Venda do Bazar'),
    ('page-integra-departamentos', 'integra/admin/cadastros/departamentos', 'Departamentos'),
    ('page-integra-funcionarios', 'integra/admin/cadastros/funcionarios', 'Funcionários'),
    ('page-integra-pessoas', 'integra/admin/cadastros/pessoas', 'Cadastro de Pessoas'),
    -- Páginas do CRM
    ('page-crm-dashboard', 'integra/crm/dashboard', 'Dashboard CRM'),
    ('page-crm-campaigns', 'integra/crm/campaigns', 'Campanhas'),
    ('page-crm-segments', 'integra/crm/segments', 'Segmentos'),
    ('page-crm-interactions', 'integra/crm/interactions', 'Interações'),
    ('page-crm-reminders', 'integra/crm/reminders', 'Lembretes')
    ON CONFLICT (id) DO NOTHING;

    -- 3. Inserir os elementos de menu do Integra
    -- Menus Principais
    INSERT INTO public.ui_app_elements (id, element_type, parent_id, page_id, label, icon, path, position) VALUES
    ('integra_dashboard', 'SIDEBAR_MENU', NULL, 'page-integra-dashboard', 'Dashboard', 'lucide/layout-dashboard', 'integra/admin/dashboard', 0),
    ('integra_cadastros', 'SIDEBAR_MENU', NULL, NULL, 'Cadastros', 'phosphor-bold/database-bold', NULL, 10),
    ('integra_crm', 'SIDEBAR_MENU', NULL, NULL, 'CRM', 'phosphor-bold/users-three-bold', NULL, 20),
    ('integra_dp', 'SIDEBAR_MENU', NULL, NULL, 'Depto. Pessoal', 'phosphor-bold/briefcase-bold', NULL, 30),
    ('integra_financeiro', 'SIDEBAR_MENU', NULL, NULL, 'Financeiro', 'phosphor-bold/currency-circle-dollar-bold', NULL, 40),
    ('integra_logistica', 'SIDEBAR_MENU', NULL, NULL, 'Logística', 'phosphor-bold/truck-bold', NULL, 50),
    ('integra_bazar', 'SIDEBAR_MENU', NULL, NULL, 'Bazar', 'phosphor-bold/storefront-bold', NULL, 60),
    ('integra_configuracoes', 'SIDEBAR_MENU', NULL, NULL, 'Configurações', 'phosphor-bold/gear-bold', 'integra/admin/configuracoes', 90)
    ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, parent_id = EXCLUDED.parent_id, page_id = EXCLUDED.page_id, label = EXCLUDED.label, icon = EXCLUDED.icon, path = EXCLUDED.path, position = EXCLUDED.position;

    -- Sub-menus de Cadastros
    INSERT INTO public.ui_app_elements (id, element_type, parent_id, page_id, label, icon, path, position) VALUES
    ('integra_cadastros_usuarios', 'SIDEBAR_MENU', 'integra_cadastros', 'page-integra-usuarios', 'Usuários', 'phosphor-bold/users-bold', 'integra/admin/cadastros/usuarios', 0),
    ('integra_cadastros_departamentos', 'SIDEBAR_MENU', 'integra_cadastros', 'page-integra-departamentos', 'Departamentos', 'phosphor-bold/buildings-bold', 'integra/admin/cadastros/departamentos', 10),
    ('integra_cadastros_funcionarios', 'SIDEBAR_MENU', 'integra_cadastros', 'page-integra-funcionarios', 'Funcionários', 'phosphor-bold/buildings-bold', 'integra/admin/cadastros/funcionarios', 20),
    ('integra_cadastros_pessoas', 'SIDEBAR_MENU', 'integra_cadastros', 'page-integra-pessoas', 'Pessoas', 'phosphor-bold/user-bold', 'integra/admin/cadastros/pessoas', 30)
    ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, parent_id = EXCLUDED.parent_id, page_id = EXCLUDED.page_id, label = EXCLUDED.label, icon = EXCLUDED.icon, path = EXCLUDED.path, position = EXCLUDED.position;

    -- Sub-menus de CRM
    INSERT INTO public.ui_app_elements (id, element_type, parent_id, page_id, label, icon, path, position) VALUES
    ('integra_crm_dashboard', 'SIDEBAR_MENU', 'integra_crm', 'page-crm-dashboard', 'Dashboard', 'phosphor-bold/chart-pie-slice-bold', 'integra/crm/dashboard', 0),
    ('integra_crm_contatos', 'SIDEBAR_MENU', 'integra_crm', 'page-integra-crm-contatos', 'Contatos', 'phosphor-bold/address-book-bold', 'integra/admin/crm/contatos', 10),
    ('integra_crm_campaigns', 'SIDEBAR_MENU', 'integra_crm', 'page-crm-campaigns', 'Campanhas', 'phosphor-bold/megaphone-bold', 'integra/crm/campaigns', 20),
    ('integra_crm_segments', 'SIDEBAR_MENU', 'integra_crm', 'page-crm-segments', 'Segmentos', 'phosphor-bold/users-four-bold', 'integra/crm/segments', 30),
    ('integra_crm_interactions', 'SIDEBAR_MENU', 'integra_crm', 'page-crm-interactions', 'Interações', 'phosphor-bold/chats-teardrop-bold', 'integra/crm/interactions', 40),
    ('integra_crm_reminders', 'SIDEBAR_MENU', 'integra_crm', 'page-crm-reminders', 'Lembretes', 'phosphor-bold/notification-bold', 'integra/crm/reminders', 50)
    ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, parent_id = EXCLUDED.parent_id, page_id = EXCLUDED.page_id, label = EXCLUDED.label, icon = EXCLUDED.icon, path = EXCLUDED.path, position = EXCLUDED.position;

    -- 4. Conceder permissões de menu para o ADMIN do Integra
    IF admin_role_id IS NOT NULL THEN
        INSERT INTO public.ui_role_element_permissions (role_id, element_id)
        SELECT admin_role_id, id FROM public.ui_app_elements WHERE id LIKE 'integra_%'
        ON CONFLICT (role_id, element_id) DO NOTHING;
    END IF;

END;
$$;

-- =====================================================================
-- SEÇÃO 3: ESTRUTURA DE GRIDS DINÂMICOS
-- =====================================================================

DO $$
BEGIN
    -- 1. Inserir a definição dos grids para o Integra
    INSERT INTO public.ui_grids (id, page_id, description, collection_id) VALUES
    ('grid-integra-pessoas', 'page-integra-pessoas', 'Grid de pessoas do sistema Integra.', NULL),
    ('grid-integra-usuarios', 'page-integra-usuarios', 'Grid de usuários do sistema Integra.', 'a1b2c3d4-e5f6-a7b8-c9d0-e1f2a3b4c5d6'),
    ('grid-integra-crm-contatos', 'page-integra-crm-contatos', 'Grid de contatos do CRM.', 'b2c3d4e5-f6a7-b8c9-d0e1-f2a3b4c5d6e7'),
    ('grid-integra-departamentos', 'page-integra-departamentos', 'Grid de departamentos do sistema Integra.', NULL),
    ('grid-integra-funcionarios', 'page-integra-funcionarios', 'Grid de funcionários do sistema Integra.', NULL),
    -- Grids do CRM
    ('grid-crm-campaigns', 'page-crm-campaigns', 'Grid de Campanhas do CRM', NULL),
    ('grid-crm-segments', 'page-crm-segments', 'Grid de Segmentos do CRM', NULL),
    ('grid-crm-interactions', 'page-crm-interactions', 'Grid de Interações do CRM', NULL),
    ('grid-crm-reminders', 'page-crm-reminders', 'Grid de Lembretes do CRM', NULL)
    ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description, collection_id = EXCLUDED.collection_id;

    -- 2. Inserir as colunas para os grids do Integra
    INSERT INTO public.ui_grid_columns (grid_id, data_key, label, size, position) VALUES
    ('grid-integra-pessoas', 'actions', 'Ações', '5%', 0),
    ('grid-integra-pessoas', 'person_name', 'Nome', '30%', 10),
    ('grid-integra-pessoas', 'person_type', 'Tipo', '35%', 20),
    ('grid-integra-pessoas', 'person_status', 'Status', '25%', 40)
    ON CONFLICT (grid_id, data_key) DO UPDATE
    SET label = EXCLUDED.label, size = EXCLUDED.size, position = EXCLUDED.position;
    INSERT INTO public.ui_grid_columns (grid_id, data_key, label, size, position) VALUES
    ('grid-integra-usuarios', 'actions', 'Ações', '5%', 0),
    ('grid-integra-usuarios', 'full_name', 'Nome', '40%', 10),
    ('grid-integra-usuarios', 'email', 'E-mail', '40%', 20),
    ('grid-integra-usuarios', 'status', 'Status', '15%', 30)
    ON CONFLICT (grid_id, data_key) DO UPDATE
    SET label = EXCLUDED.label, size = EXCLUDED.size, position = EXCLUDED.position;

    INSERT INTO public.ui_grid_columns (grid_id, data_key, label, size, position) VALUES
    ('grid-integra-crm-contatos', 'actions', 'Ações', '5%', 0),
    ('grid-integra-crm-contatos', 'contact_name', 'Nome do Contato', '30%', 10),
    ('grid-integra-crm-contatos', 'type', 'Tipo', '15%', 20),
    ('grid-integra-crm-contatos', 'last_interaction', 'Última Interação', '25%', 30),
    ('grid-integra-crm-contatos', 'status', 'Status', '25%', 40)
    ON CONFLICT (grid_id, data_key) DO UPDATE
    SET label = EXCLUDED.label, size = EXCLUDED.size, position = EXCLUDED.position;

    -- 3. Inserir as colunas para os grids do Integra
    INSERT INTO public.ui_grid_columns (grid_id, data_key, label, size, position) VALUES
    ('grid-integra-departamentos', 'actions', 'Ações', '5%', 0),
    ('grid-integra-departamentos', 'name', 'Nome do Departamento', '35%', 10),
    ('grid-integra-departamentos', 'code', 'Código', '20%', 20),
    ('grid-integra-departamentos', 'manager_name', 'Gestor', '25%', 30),
    ('grid-integra-departamentos', 'status', 'Status', '15%', 40)
    ON CONFLICT (grid_id, data_key) DO UPDATE
    SET label = EXCLUDED.label, size = EXCLUDED.size, position = EXCLUDED.position;

    -- 4. Inserir as colunas para os grids do Integra
    INSERT INTO public.ui_grid_columns (grid_id, data_key, label, size, position) VALUES
    ('grid-integra-funcionarios', 'actions', 'Ações', '5%', 0),
    ('grid-integra-funcionarios', 'name', 'Nome do Funcionário', '35%', 10),
    ('grid-integra-funcionarios', 'code', 'Código', '10%', 20),
    ('grid-integra-funcionarios', 'department_name', 'Departamento', '35%', 30),
    ('grid-integra-funcionarios', 'status', 'Status', '15%', 40)
    ON CONFLICT (grid_id, data_key) DO UPDATE
    SET label = EXCLUDED.label, size = EXCLUDED.size, position = EXCLUDED.position;

    -- Colunas para o grid de Campanhas do CRM
    INSERT INTO public.ui_grid_columns (grid_id, data_key, label, size, position) VALUES
    ('grid-crm-campaigns', 'actions', 'Ações', '5%', 0),
    ('grid-crm-campaigns', 'name', 'Nome', '30%', 10),
    ('grid-crm-campaigns', 'start_date', 'Data Início', '20%', 20),
    ('grid-crm-campaigns', 'end_date', 'Data Fim', '20%', 30),
    ('grid-crm-campaigns', 'status', 'Status', '25%', 40)
    ON CONFLICT (grid_id, data_key) DO UPDATE SET label = EXCLUDED.label, size = EXCLUDED.size, position = EXCLUDED.position;

    -- Colunas para o grid de Segmentos do CRM
    INSERT INTO public.ui_grid_columns (grid_id, data_key, label, size, position) VALUES
    ('grid-crm-segments', 'actions', 'Ações', '5%', 0),
    ('grid-crm-segments', 'name', 'Nome', '45%', 10),
    ('grid-crm-segments', 'description', 'Descrição', '50%', 20)
    ON CONFLICT (grid_id, data_key) DO UPDATE SET label = EXCLUDED.label, size = EXCLUDED.size, position = EXCLUDED.position;

    -- Colunas para o grid de Interações do CRM
    INSERT INTO public.ui_grid_columns (grid_id, data_key, label, size, position) VALUES
    ('grid-crm-interactions', 'actions', 'Ações', '5%', 0),
    ('grid-crm-interactions', 'contact_name', 'Contato', '30%', 10),
    ('grid-crm-interactions', 'interaction_date', 'Data', '25%', 20),
    ('grid-crm-interactions', 'type', 'Tipo', '20%', 30),
    ('grid-crm-interactions', 'notes', 'Notas', '20%', 40)
    ON CONFLICT (grid_id, data_key) DO UPDATE SET label = EXCLUDED.label, size = EXCLUDED.size, position = EXCLUDED.position;

    -- Colunas para o grid de Lembretes do CRM
    INSERT INTO public.ui_grid_columns (grid_id, data_key, label, size, position) VALUES
    ('grid-crm-reminders', 'actions', 'Ações', '5%', 0),
    ('grid-crm-reminders', 'contact_name', 'Contato', '30%', 10),
    ('grid-crm-reminders', 'reminder_date', 'Data Lembrete', '25%', 20),
    ('grid-crm-reminders', 'notes', 'Notas', '20%', 30),
    ('grid-crm-reminders', 'status', 'Status', '20%', 40)
    ON CONFLICT (grid_id, data_key) DO UPDATE SET label = EXCLUDED.label, size = EXCLUDED.size, position = EXCLUDED.position;

END;
$$;