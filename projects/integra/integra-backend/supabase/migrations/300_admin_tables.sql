-- ===========================================================================
-- ARQUITETURA DE DADOS FINAL SUPABASE - PROJETO INTEGRA
-- Parte 11: Módulo de Administração e BI (Admin)
-- ===========================================================================

-- ==============================================
-- CRIAÇÃO DE TIPOS ENUM DO MÓDULO ADMIN
-- ==============================================

-- Tipos de indicadores
CREATE TYPE indicator_type_enum AS ENUM (
  'financial',     -- Financeiro
  'operational',   -- Operacional
  'performance',   -- Desempenho
  'efficiency',    -- Eficiência
  'satisfaction',  -- Satisfação
  'compliance'     -- Conformidade
);

-- Períodos de indicadores
CREATE TYPE indicator_period_enum AS ENUM (
  'daily',         -- Diário
  'weekly',        -- Semanal
  'monthly',       -- Mensal
  'quarterly',     -- Trimestral
  'yearly',        -- Anual
  'custom'         -- Personalizado
);

-- Tipos de alertas
CREATE TYPE alert_type_enum AS ENUM (
  'info',          -- Informação
  'warning',       -- Aviso
  'critical',      -- Crítico
  'success',       -- Sucesso
  'error'          -- Erro
);

-- ==============================================
-- TABELAS DO MÓDULO DE ADMINISTRAÇÃO E BI
-- ==============================================

-- Tabela de Indicadores de Desempenho (KPIs)
CREATE TABLE public.admin_indicators (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  indicator_type indicator_type_enum NOT NULL,
  module TEXT NOT NULL, -- Módulo relacionado (finance, crm, hr, etc.)
  calculation_query TEXT, -- Query SQL para cálculo do indicador
  target_value DECIMAL(15,2), -- Valor alvo/meta
  min_acceptable DECIMAL(15,2), -- Valor mínimo aceitável
  max_acceptable DECIMAL(15,2), -- Valor máximo aceitável
  unit TEXT, -- Unidade de medida (%, R$, unidades, etc.)
  period indicator_period_enum DEFAULT 'monthly',
  responsible_id UUID REFERENCES public.core_users(id) ON DELETE SET NULL, 
  notes TEXT,                                                         
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,     
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_admin_indicators_indicator_type ON public.admin_indicators(indicator_type);
CREATE INDEX idx_admin_indicators_module ON public.admin_indicators(module);
CREATE INDEX idx_admin_indicators_period ON public.admin_indicators(period);
CREATE INDEX idx_admin_indicators_responsible_id ON public.admin_indicators(responsible_id);

-- Trigger para updated_at
CREATE TRIGGER on_admin_indicators_update
BEFORE UPDATE ON public.admin_indicators
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Valores de Indicadores (histórico de medições)
CREATE TABLE public.admin_indicator_values (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  indicator_id UUID NOT NULL REFERENCES public.admin_indicators(id) ON DELETE CASCADE,
  value DECIMAL(15,2) NOT NULL,
  reference_date DATE NOT NULL,
  period_start DATE, -- Início do período de medição
  period_end DATE, -- Fim do período de medição
  status TEXT, -- Status baseado na meta (acima, abaixo, dentro do esperado)
  notes TEXT,
  calculated_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,                  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_admin_indicator_values_indicator_id ON public.admin_indicator_values(indicator_id);
CREATE INDEX idx_admin_indicator_values_reference_date ON public.admin_indicator_values(reference_date);
CREATE INDEX idx_admin_indicator_values_status ON public.admin_indicator_values(status);

-- Tabela de Painéis (Dashboards)
CREATE TABLE public.admin_dashboards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  layout JSONB, -- Layout do dashboard (em formato JSON)
  is_public BOOLEAN DEFAULT false,
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_admin_dashboards_created_by ON public.admin_dashboards(created_by);
CREATE INDEX idx_admin_dashboards_is_public ON public.admin_dashboards(is_public);

-- Trigger para updated_at
CREATE TRIGGER on_admin_dashboards_update
BEFORE UPDATE ON public.admin_dashboards
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Widgets (componentes de visualização para dashboards)
CREATE TABLE public.admin_widgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  dashboard_id UUID NOT NULL REFERENCES public.admin_dashboards(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  widget_type TEXT NOT NULL, -- Tipo de widget (gráfico, tabela, cartão, etc.)
  config JSONB, -- Configuração do widget (em formato JSON)
  data_source TEXT, -- Fonte dos dados (query, api, etc.)
  refresh_interval INTEGER, -- Intervalo de atualização em minutos
  position JSONB, -- Posição no dashboard (em formato JSON)
  size JSONB, -- Tamanho do widget (em formato JSON)
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_admin_widgets_dashboard_id ON public.admin_widgets(dashboard_id);
CREATE INDEX idx_admin_widgets_widget_type ON public.admin_widgets(widget_type);

-- Trigger para updated_at
CREATE TRIGGER on_admin_widgets_update
BEFORE UPDATE ON public.admin_widgets
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Relatórios
CREATE TABLE public.admin_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  report_type TEXT NOT NULL, -- Tipo de relatório
  query TEXT, -- Query SQL para gerar o relatório
  parameters JSONB, -- Parâmetros do relatório (em formato JSON)
  template TEXT, -- Template/Layout do relatório
  schedule TEXT, -- Programação para geração automática (cron format)
  recipients JSONB, -- Lista de destinatários para envio automático
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_admin_reports_report_type ON public.admin_reports(report_type);
CREATE INDEX idx_admin_reports_created_by ON public.admin_reports(created_by);

-- Trigger para updated_at
CREATE TRIGGER on_admin_reports_update
BEFORE UPDATE ON public.admin_reports
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Relatórios Gerados (histórico)
CREATE TABLE public.admin_report_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  report_id UUID NOT NULL REFERENCES public.admin_reports(id) ON DELETE CASCADE,
  generated_date TIMESTAMPTZ DEFAULT now(),
  parameters_used JSONB, -- Parâmetros utilizados na geração
  file_url TEXT, -- URL para o arquivo do relatório
  generated_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  sent_to JSONB, -- Lista de destinatários para quem foi enviado
  sent_date TIMESTAMPTZ,
  notes TEXT,
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_admin_report_history_report_id ON public.admin_report_history(report_id);
CREATE INDEX idx_admin_report_history_generated_date ON public.admin_report_history(generated_date);
CREATE INDEX idx_admin_report_history_generated_by ON public.admin_report_history(generated_by);

-- Tabela de Alertas do Sistema
CREATE TABLE public.admin_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  alert_type alert_type_enum NOT NULL DEFAULT 'info',
  module TEXT, -- Módulo relacionado (finance, crm, hr, etc.)
  reference_id UUID, -- ID de referência (se relacionado a algum registro específico)
  reference_table TEXT, -- Tabela de referência
  start_date TIMESTAMPTZ DEFAULT now(),
  end_date TIMESTAMPTZ,
  is_read BOOLEAN DEFAULT false,
  read_date TIMESTAMPTZ,
  read_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  assigned_to UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  resolution TEXT,
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_admin_alerts_alert_type ON public.admin_alerts(alert_type);
CREATE INDEX idx_admin_alerts_module ON public.admin_alerts(module);
CREATE INDEX idx_admin_alerts_reference_id ON public.admin_alerts(reference_id);
CREATE INDEX idx_admin_alerts_is_read ON public.admin_alerts(is_read);
CREATE INDEX idx_admin_alerts_assigned_to ON public.admin_alerts(assigned_to);
CREATE INDEX idx_admin_alerts_created_by ON public.admin_alerts(created_by);
CREATE INDEX idx_admin_alerts_start_date ON public.admin_alerts(start_date);

-- Trigger para updated_at
CREATE TRIGGER on_admin_alerts_update
BEFORE UPDATE ON public.admin_alerts
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Configurações do Sistema
CREATE TABLE public.admin_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  module TEXT NOT NULL, -- Módulo relacionado (finance, crm, hr, etc.)
  setting_key TEXT NOT NULL,
  setting_value TEXT,
  data_type TEXT, -- Tipo de dado (string, number, boolean, json, etc.)
  description TEXT,
  is_public BOOLEAN DEFAULT false,
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active',
  UNIQUE(module, setting_key)
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_admin_settings_module ON public.admin_settings(module);
CREATE INDEX idx_admin_settings_setting_key ON public.admin_settings(setting_key);
CREATE INDEX idx_admin_settings_is_public ON public.admin_settings(is_public);

-- Trigger para updated_at
CREATE TRIGGER on_admin_settings_update
BEFORE UPDATE ON public.admin_settings
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Logs de Auditoria
CREATE TABLE public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  action TEXT NOT NULL, -- Ação realizada (insert, update, delete, login, etc.)
  table_name TEXT, -- Nome da tabela afetada
  record_id UUID, -- ID do registro afetado
  old_values JSONB, -- Valores antigos (antes da alteração)
  new_values JSONB, -- Novos valores (após a alteração)
  ip_address TEXT, -- Endereço IP do usuário
  user_agent TEXT, -- User Agent do navegador
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_admin_audit_logs_user_id ON public.admin_audit_logs(user_id);
CREATE INDEX idx_admin_audit_logs_action ON public.admin_audit_logs(action);
CREATE INDEX idx_admin_audit_logs_table_name ON public.admin_audit_logs(table_name);
CREATE INDEX idx_admin_audit_logs_record_id ON public.admin_audit_logs(record_id);
CREATE INDEX idx_admin_audit_logs_created_at ON public.admin_audit_logs(created_at);

