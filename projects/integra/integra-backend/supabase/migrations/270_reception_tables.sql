-- ===========================================================================
-- ARQUITETURA DE DADOS FINAL SUPABASE - PROJETO INTEGRA
-- Parte 8: Módulo de Recepção (Reception)
-- ===========================================================================

-- ==============================================
-- CRIAÇÃO DE TIPOS ENUM DO MÓDULO DE RECEPÇÃO
-- ==============================================

-- Status de visita
CREATE TYPE visit_status_enum AS ENUM (
  'scheduled',    -- Agendada
  'check_in',     -- Entrada
  'in_progress',  -- Em andamento
  'check_out',    -- Saída
  'completed',    -- Concluída
  'no_show',      -- Não compareceu
  'cancelled'     -- Cancelada
);

-- Tipos de visitantes
CREATE TYPE visitor_type_enum AS ENUM (
  'beneficiary',  -- Beneficiário
  'donor',        -- Doador
  'employee',     -- Funcionário
  'volunteer',    -- Voluntário
  'supplier',     -- Fornecedor
  'partner',      -- Parceiro
  'guest',        -- Convidado
  'other'         -- Outro
);

-- Tipos de agendamento
CREATE TYPE appointment_type_enum AS ENUM (
  'service',      -- Atendimento
  'donation',     -- Doação
  'meeting',      -- Reunião
  'event',        -- Evento
  'visit',        -- Visita
  'other'         -- Outro
);

-- ==============================================
-- TABELAS DO MÓDULO DE RECEPÇÃO
-- ==============================================

-- Tabela de Visitantes
CREATE TABLE public.reception_visitors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE CASCADE,
  visitor_type visitor_type_enum NOT NULL,
  badge_number TEXT,
  notes TEXT,
  photo_url TEXT,
  id_document_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_reception_visitors_person_id ON public.reception_visitors(person_id);
CREATE INDEX idx_reception_visitors_type ON public.reception_visitors(visitor_type);

-- Trigger para updated_at
CREATE TRIGGER on_reception_visitors_update
BEFORE UPDATE ON public.reception_visitors
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Agendamentos
CREATE TABLE public.reception_appointments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  visitor_id UUID NOT NULL REFERENCES public.reception_visitors(id) ON DELETE CASCADE,
  appointment_type appointment_type_enum NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  duration INTEGER, -- Em minutos
  department_id UUID REFERENCES public.core_departments(id) ON DELETE SET NULL,
  employee_id UUID REFERENCES public.core_people(id) ON DELETE SET NULL, -- Funcionário que atenderá
  reason TEXT,
  notes TEXT,
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status visit_status_enum DEFAULT 'scheduled'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_reception_appointments_visitor_id ON public.reception_appointments(visitor_id);
CREATE INDEX idx_reception_appointments_department_id ON public.reception_appointments(department_id);
CREATE INDEX idx_reception_appointments_employee_id ON public.reception_appointments(employee_id);
CREATE INDEX idx_reception_appointments_date ON public.reception_appointments(date);
CREATE INDEX idx_reception_appointments_status ON public.reception_appointments(status);

-- Trigger para updated_at
CREATE TRIGGER on_reception_appointments_update
BEFORE UPDATE ON public.reception_appointments
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Visitas (registro de entrada e saída)
CREATE TABLE public.reception_visits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  visitor_id UUID NOT NULL REFERENCES public.reception_visitors(id) ON DELETE CASCADE,
  appointment_id UUID REFERENCES public.reception_appointments(id) ON DELETE SET NULL,
  check_in TIMESTAMPTZ NOT NULL DEFAULT now(),
  check_out TIMESTAMPTZ,
  department_id UUID REFERENCES public.core_departments(id) ON DELETE SET NULL,
  employee_id UUID REFERENCES public.core_people(id) ON DELETE SET NULL, -- Funcionário visitado
  reason TEXT,
  badge_number TEXT,
  vehicle_plate TEXT,
  notes TEXT,
  check_in_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL, -- Quem registrou a entrada
  check_out_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL, -- Quem registrou a saída
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status visit_status_enum DEFAULT 'check_in'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_reception_visits_visitor_id ON public.reception_visits(visitor_id);
CREATE INDEX idx_reception_visits_appointment_id ON public.reception_visits(appointment_id);
CREATE INDEX idx_reception_visits_department_id ON public.reception_visits(department_id);
CREATE INDEX idx_reception_visits_employee_id ON public.reception_visits(employee_id);
CREATE INDEX idx_reception_visits_check_in ON public.reception_visits(check_in);
CREATE INDEX idx_reception_visits_check_out ON public.reception_visits(check_out);
CREATE INDEX idx_reception_visits_status ON public.reception_visits(status);

-- Trigger para updated_at
CREATE TRIGGER on_reception_visits_update
BEFORE UPDATE ON public.reception_visits
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Itens Pessoais/Pertences
CREATE TABLE public.reception_belongings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  visit_id UUID NOT NULL REFERENCES public.reception_visits(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity INTEGER DEFAULT 1,
  stored_location TEXT,
  returned BOOLEAN DEFAULT false,
  returned_at TIMESTAMPTZ,
  returned_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_reception_belongings_visit_id ON public.reception_belongings(visit_id);
CREATE INDEX idx_reception_belongings_returned ON public.reception_belongings(returned);

-- Trigger para updated_at
CREATE TRIGGER on_reception_belongings_update
BEFORE UPDATE ON public.reception_belongings
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Serviços de Recepção
CREATE TABLE public.reception_services (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  department_id UUID REFERENCES public.core_departments(id) ON DELETE SET NULL,
  duration INTEGER, -- Em minutos
  max_daily_appointments INTEGER,
  start_time TIME,
  end_time TIME,
  days_available TEXT, -- Ex: "1,2,3,4,5" para dias da semana
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_reception_services_department_id ON public.reception_services(department_id);

-- Trigger para updated_at
CREATE TRIGGER on_reception_services_update
BEFORE UPDATE ON public.reception_services
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Mensagens/Recados
CREATE TABLE public.reception_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipient_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE CASCADE, -- Destinatário
  sender_id UUID REFERENCES public.core_people(id) ON DELETE SET NULL, -- Remetente
  visitor_id UUID REFERENCES public.reception_visitors(id) ON DELETE SET NULL, -- Visitante relacionado
  message TEXT NOT NULL,
  delivered BOOLEAN DEFAULT false,
  delivered_at TIMESTAMPTZ,
  delivered_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  priority INTEGER DEFAULT 3, -- 1=Alta, 2=Média, 3=Baixa
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_reception_messages_recipient_id ON public.reception_messages(recipient_id);
CREATE INDEX idx_reception_messages_sender_id ON public.reception_messages(sender_id);
CREATE INDEX idx_reception_messages_visitor_id ON public.reception_messages(visitor_id);
CREATE INDEX idx_reception_messages_delivered ON public.reception_messages(delivered);
CREATE INDEX idx_reception_messages_priority ON public.reception_messages(priority);

-- Trigger para updated_at
CREATE TRIGGER on_reception_messages_update
BEFORE UPDATE ON public.reception_messages
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

