-- ===========================================================================
-- ARQUITETURA DE DADOS FINAL SUPABASE - PROJETO INTEGRA
-- Parte 3: Módulo de Doações (Donation)
-- ===========================================================================

-- ==============================================
-- CRIAÇÃO DE TIPOS ENUM DO MÓDULO DE DOAÇÕES
-- ==============================================

-- Status da doação
CREATE TYPE donation_status_enum AS ENUM (
  'pending',      -- Pendente
  'confirmed',    -- Confirmada
  'cancelled',    -- Cancelada
  'collected',    -- Coletada
  'delivered'     -- Entregue
);

-- Tipo de doação
CREATE TYPE donation_type_enum AS ENUM (
  'money',        -- Dinheiro
  'goods',        -- Bens/Produtos
  'food',         -- Alimentos
  'clothing',     -- Roupas
  'service',      -- Serviço
  'other'         -- Outro
);

-- Meio de captação
CREATE TYPE donation_source_enum AS ENUM (
  'telemarketing',    -- Telemarketing
  'website',          -- Website
  'app',              -- Aplicativo
  'event',            -- Evento
  'direct_contact',   -- Contato direto
  'social_media',     -- Redes sociais
  'partner',          -- Parceiro
  'other'             -- Outro
);

-- ==============================================
-- TABELAS DO MÓDULO DE DOAÇÕES
-- ==============================================

-- Tabela de Campanhas
CREATE TABLE public.donation_campaigns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  start_date DATE,
  end_date DATE,
  goal DECIMAL(15,2),
  target_items TEXT,
  responsible_id UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índice para busca por responsável
CREATE INDEX idx_donation_campaigns_responsible_id ON public.donation_campaigns(responsible_id);
-- Índice para busca por período
CREATE INDEX idx_donation_campaigns_dates ON public.donation_campaigns(start_date, end_date);

-- Trigger para updated_at
CREATE TRIGGER on_donation_campaigns_update
BEFORE UPDATE ON public.donation_campaigns
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Categorias de Itens
CREATE TABLE public.donation_item_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES public.donation_item_categories(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índice para busca por hierarquia
CREATE INDEX idx_donation_item_categories_parent_id ON public.donation_item_categories(parent_id);

-- Trigger para updated_at
CREATE TRIGGER on_donation_item_categories_update
BEFORE UPDATE ON public.donation_item_categories
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Itens (Catálogo de itens para doação)
CREATE TABLE public.donation_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  category_id UUID REFERENCES public.donation_item_categories(id) ON DELETE SET NULL,
  unit TEXT, -- unidade de medida (kg, unidade, etc.)
  price DECIMAL(15,2), -- valor estimado
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índice para busca por categoria
CREATE INDEX idx_donation_items_category_id ON public.donation_items(category_id);

-- Trigger para updated_at
CREATE TRIGGER on_donation_items_update
BEFORE UPDATE ON public.donation_items
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Doações
CREATE TABLE public.donations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  donor_id UUID REFERENCES public.core_people(id) ON DELETE SET NULL,
  campaign_id UUID REFERENCES public.donation_campaigns(id) ON DELETE SET NULL,
  type donation_type_enum NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  total_amount DECIMAL(15,2),
  payment_method payment_method_enum,
  receipt_number TEXT,
  source donation_source_enum,
  notes TEXT,
  operator_id UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status donation_status_enum DEFAULT 'pending'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_donations_donor_id ON public.donations(donor_id);
CREATE INDEX idx_donations_campaign_id ON public.donations(campaign_id);
CREATE INDEX idx_donations_date ON public.donations(date);
CREATE INDEX idx_donations_operator_id ON public.donations(operator_id);
CREATE INDEX idx_donations_status ON public.donations(status);
CREATE INDEX idx_donations_type ON public.donations(type);

-- Trigger para updated_at
CREATE TRIGGER on_donations_update
BEFORE UPDATE ON public.donations
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Itens Doados (detalhes dos itens em cada doação)
CREATE TABLE public.donation_items_donated (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  donation_id UUID NOT NULL REFERENCES public.donations(id) ON DELETE CASCADE,
  item_id UUID REFERENCES public.donation_items(id) ON DELETE SET NULL,
  quantity DECIMAL(15,2) NOT NULL,
  unit_value DECIMAL(15,2),
  total_value DECIMAL(15,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_donation_items_donated_donation_id ON public.donation_items_donated(donation_id);
CREATE INDEX idx_donation_items_donated_item_id ON public.donation_items_donated(item_id);

-- Trigger para updated_at
CREATE TRIGGER on_donation_items_donated_update
BEFORE UPDATE ON public.donation_items_donated
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Doações Recorrentes
CREATE TABLE public.donation_recurring_donations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  donor_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE CASCADE,
  amount DECIMAL(15,2) NOT NULL,
  frequency TEXT NOT NULL CHECK (frequency IN ('monthly', 'bimonthly', 'quarterly', 'semiannually', 'annually')),
  payment_method payment_method_enum,
  start_date DATE NOT NULL,
  end_date DATE,
  last_donation_date TIMESTAMPTZ,
  next_donation_date TIMESTAMPTZ,
  campaign_id UUID REFERENCES public.donation_campaigns(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_donation_recurring_donations_donor_id ON public.donation_recurring_donations(donor_id);
CREATE INDEX idx_donation_recurring_donations_campaign_id ON public.donation_recurring_donations(campaign_id);
CREATE INDEX idx_donation_recurring_donations_next_donation_date ON public.donation_recurring_donations(next_donation_date);

-- Trigger para updated_at
CREATE TRIGGER on_donation_recurring_donations_update
BEFORE UPDATE ON public.donation_recurring_donations
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Coletas (para coleta física de doações)
CREATE TABLE public.donation_collections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  donation_id UUID NOT NULL REFERENCES public.donations(id) ON DELETE CASCADE,
  scheduled_date TIMESTAMPTZ NOT NULL,
  collection_date TIMESTAMPTZ,
  address_id UUID REFERENCES public.core_addresses(id) ON DELETE SET NULL,
  driver_id UUID REFERENCES public.core_people(id) ON DELETE SET NULL,
  vehicle_id UUID, -- Referência a ser adicionada depois da criação da tabela logistics_vehicles
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'pending'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_donation_collections_donation_id ON public.donation_collections(donation_id);
CREATE INDEX idx_donation_collections_address_id ON public.donation_collections(address_id);
CREATE INDEX idx_donation_collections_driver_id ON public.donation_collections(driver_id);
CREATE INDEX idx_donation_collections_scheduled_date ON public.donation_collections(scheduled_date);

-- Trigger para updated_at
CREATE TRIGGER on_donation_collections_update
BEFORE UPDATE ON public.donation_collections
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

