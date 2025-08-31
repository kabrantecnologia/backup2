-- ===========================================================================
-- ARQUITETURA DE DADOS FINAL SUPABASE - PROJETO INTEGRA
-- Parte 5: Módulo de CRM (Customer Relationship Management)
-- ===========================================================================

-- ==============================================
-- CRIAÇÃO DE TIPOS ENUM DO MÓDULO DE CRM
-- ==============================================

-- Status de interação/contato
CREATE TYPE interaction_status_enum AS ENUM (
  'pending',      -- Pendente
  'completed',    -- Concluído
  'failed',       -- Falhou
  'scheduled',    -- Agendado
  'cancelled'     -- Cancelado
);

-- Tipos de interação/contato
CREATE TYPE interaction_type_enum AS ENUM (
  'phone',        -- Telefone
  'email',        -- Email
  'visit',        -- Visita
  'whatsapp',     -- WhatsApp
  'sms',          -- SMS
  'social_media', -- Redes sociais
  'event',        -- Evento
  'other'         -- Outro
);

-- Status de oportunidade
CREATE TYPE opportunity_status_enum AS ENUM (
  'new',          -- Nova
  'in_progress',  -- Em andamento
  'won',          -- Ganha
  'lost',         -- Perdida
  'delayed'       -- Adiada
);

-- ==============================================
-- TABELAS DO MÓDULO DE CRM
-- ==============================================

-- Tabela de Segmentação (Grupos de pessoas para campanhas/ações específicas)
CREATE TABLE public.crm_segments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  criteria TEXT, -- Critérios de segmentação
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Trigger para updated_at
CREATE TRIGGER on_crm_segments_update
BEFORE UPDATE ON public.crm_segments
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de relacionamento Segmento-Pessoas
CREATE TABLE public.crm_segment_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  segment_id UUID NOT NULL REFERENCES public.crm_segments(id) ON DELETE CASCADE,
  person_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE CASCADE,
  added_at TIMESTAMPTZ DEFAULT now(),
  added_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  notes TEXT,
  UNIQUE(segment_id, person_id) -- Cada pessoa só pode estar uma vez em cada segmento
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_crm_segment_members_segment_id ON public.crm_segment_members(segment_id);
CREATE INDEX idx_crm_segment_members_person_id ON public.crm_segment_members(person_id);

-- Tabela de Campanhas de CRM
CREATE TABLE public.crm_campaigns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  segment_id UUID REFERENCES public.crm_segments(id) ON DELETE SET NULL,
  goal TEXT,
  budget DECIMAL(15,2),
  responsible_id UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_crm_campaigns_segment_id ON public.crm_campaigns(segment_id);
CREATE INDEX idx_crm_campaigns_responsible_id ON public.crm_campaigns(responsible_id);
CREATE INDEX idx_crm_campaigns_date_range ON public.crm_campaigns(start_date, end_date);

-- Trigger para updated_at
CREATE TRIGGER on_crm_campaigns_update
BEFORE UPDATE ON public.crm_campaigns
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Interações/Contatos com Pessoas
CREATE TABLE public.crm_interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE CASCADE,
  campaign_id UUID REFERENCES public.crm_campaigns(id) ON DELETE SET NULL,
  type interaction_type_enum NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  duration INTEGER, -- Em minutos
  subject TEXT,
  description TEXT,
  next_action TEXT,
  next_action_date TIMESTAMPTZ,
  user_id UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status interaction_status_enum DEFAULT 'pending'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_crm_interactions_person_id ON public.crm_interactions(person_id);
CREATE INDEX idx_crm_interactions_campaign_id ON public.crm_interactions(campaign_id);
CREATE INDEX idx_crm_interactions_user_id ON public.crm_interactions(user_id);
CREATE INDEX idx_crm_interactions_date ON public.crm_interactions(date);
CREATE INDEX idx_crm_interactions_next_action_date ON public.crm_interactions(next_action_date);
CREATE INDEX idx_crm_interactions_status ON public.crm_interactions(status);

-- Trigger para updated_at
CREATE TRIGGER on_crm_interactions_update
BEFORE UPDATE ON public.crm_interactions
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Oportunidades (potenciais doações, parcerias, etc.)
CREATE TABLE public.crm_opportunities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE CASCADE,
  campaign_id UUID REFERENCES public.crm_campaigns(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  expected_amount DECIMAL(15,2),
  expected_date TIMESTAMPTZ,
  probability INTEGER CHECK (probability BETWEEN 0 AND 100), -- Probabilidade de sucesso (%)
  assigned_to UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status opportunity_status_enum DEFAULT 'new'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_crm_opportunities_person_id ON public.crm_opportunities(person_id);
CREATE INDEX idx_crm_opportunities_campaign_id ON public.crm_opportunities(campaign_id);
CREATE INDEX idx_crm_opportunities_assigned_to ON public.crm_opportunities(assigned_to);
CREATE INDEX idx_crm_opportunities_expected_date ON public.crm_opportunities(expected_date);
CREATE INDEX idx_crm_opportunities_status ON public.crm_opportunities(status);

-- Trigger para updated_at
CREATE TRIGGER on_crm_opportunities_update
BEFORE UPDATE ON public.crm_opportunities
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Eventos (Eventos para engajamento)
CREATE TABLE public.crm_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  location TEXT,
  capacity INTEGER,
  organizer_id UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  campaign_id UUID REFERENCES public.crm_campaigns(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_crm_events_organizer_id ON public.crm_events(organizer_id);
CREATE INDEX idx_crm_events_campaign_id ON public.crm_events(campaign_id);
CREATE INDEX idx_crm_events_date_range ON public.crm_events(start_date, end_date);

-- Trigger para updated_at
CREATE TRIGGER on_crm_events_update
BEFORE UPDATE ON public.crm_events
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Participantes de Eventos
CREATE TABLE public.crm_event_attendees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES public.crm_events(id) ON DELETE CASCADE,
  person_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE CASCADE,
  registered_at TIMESTAMPTZ DEFAULT now(),
  attended BOOLEAN DEFAULT false,
  feedback TEXT,
  notes TEXT,
  UNIQUE(event_id, person_id) -- Cada pessoa só pode ser registrada uma vez por evento
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_crm_event_attendees_event_id ON public.crm_event_attendees(event_id);
CREATE INDEX idx_crm_event_attendees_person_id ON public.crm_event_attendees(person_id);
CREATE INDEX idx_crm_event_attendees_attended ON public.crm_event_attendees(attended);

-- Tabela de Lembretes/Tarefas
CREATE TABLE public.crm_reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMPTZ NOT NULL,
  person_id UUID REFERENCES public.core_people(id) ON DELETE CASCADE,
  assigned_to UUID NOT NULL REFERENCES public.core_users(id) ON DELETE CASCADE,
  completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  priority INTEGER DEFAULT 3, -- 1=Alta, 2=Média, 3=Baixa
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_crm_reminders_person_id ON public.crm_reminders(person_id);
CREATE INDEX idx_crm_reminders_assigned_to ON public.crm_reminders(assigned_to);
CREATE INDEX idx_crm_reminders_due_date ON public.crm_reminders(due_date);
CREATE INDEX idx_crm_reminders_completed ON public.crm_reminders(completed);
CREATE INDEX idx_crm_reminders_priority ON public.crm_reminders(priority);

-- Trigger para updated_at
CREATE TRIGGER on_crm_reminders_update
BEFORE UPDATE ON public.crm_reminders
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Notas sobre pessoas
CREATE TABLE public.crm_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE CASCADE,
  title TEXT,
  content TEXT NOT NULL,
  created_by UUID NOT NULL REFERENCES public.core_users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_crm_notes_person_id ON public.crm_notes(person_id);
CREATE INDEX idx_crm_notes_created_by ON public.crm_notes(created_by);

-- Trigger para updated_at
CREATE TRIGGER on_crm_notes_update
BEFORE UPDATE ON public.crm_notes
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

