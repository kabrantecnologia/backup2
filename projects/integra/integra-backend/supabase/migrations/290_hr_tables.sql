-- ===========================================================================
-- CORREÇÃO PARA MÓDULO DE RECURSOS HUMANOS (HR)
-- ===========================================================================

-- Esta migração corrige o erro de referência às tabelas que não existiam
-- Deve ser executada antes da criação das tabelas hr_employees e hr_selection_process

-- ==============================================
-- CRIAÇÃO DE TIPOS ENUM DO MÓDULO HR NECESSÁRIOS
-- ==============================================

-- Tipos de contrato (se ainda não existir)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'contract_type_enum') THEN
        CREATE TYPE contract_type_enum AS ENUM (
          'clt',           -- CLT
          'pj',            -- Pessoa Jurídica
          'trainee',       -- Estagiário
          'temporary',     -- Temporário
          'volunteer'      -- Voluntário
        );
    END IF;
END$$;

-- Status de candidato (se ainda não existir)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'candidate_status_enum') THEN
        CREATE TYPE candidate_status_enum AS ENUM (
          'applied',       -- Candidatou-se
          'screening',     -- Em triagem
          'interview',     -- Em entrevista
          'testing',       -- Em teste
          'offered',       -- Oferta realizada
          'hired',         -- Contratado
          'rejected',      -- Rejeitado
          'withdrawn'      -- Desistiu
        );
    END IF;
END$$;

-- Status de treinamento
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'training_status_enum') THEN
        CREATE TYPE training_status_enum AS ENUM (
          'planned',       -- Planejado
          'in_progress',   -- Em andamento
          'completed',     -- Concluído
          'cancelled'      -- Cancelado
        );
    END IF;
END$$;

-- ==============================================
-- TABELA DE CARGOS (POSITIONS)
-- ==============================================

-- Tabela de Cargos (necessária antes de hr_employees)
CREATE TABLE public.hr_positions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  code TEXT UNIQUE,
  department_id UUID REFERENCES public.core_departments(id) ON DELETE SET NULL,
  description TEXT,
  requirements TEXT,
  salary_range_min DECIMAL(15,2),
  salary_range_max DECIMAL(15,2),
  is_management BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_positions_department_id ON public.hr_positions(department_id);
CREATE INDEX idx_positions_title ON public.hr_positions(title);

-- Trigger para updated_at
CREATE TRIGGER on_positions_update
BEFORE UPDATE ON public.hr_positions
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- ==============================================
-- TABELA DE LOCALIDADES (LOCATIONS)
-- ==============================================

-- Tabela de Localidades (necessária antes de hr_employees)
CREATE TABLE public.hr_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  address_id UUID REFERENCES public.core_addresses(id) ON DELETE SET NULL,
  description TEXT,
  capacity INTEGER,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_locations_name ON public.hr_locations(name);
CREATE INDEX idx_locations_address_id ON public.hr_locations(address_id);

-- Trigger para updated_at
CREATE TRIGGER on_locations_update
BEFORE UPDATE ON public.hr_locations
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();


-- ==============================================
-- TABELA DE FUNCIONÁRIOS (HR_EMPLOYEES)
-- ==============================================

-- Tabela de Funcionários (necessária antes de hr_selection_process)
CREATE TABLE public.hr_employees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE CASCADE,
  employee_code TEXT UNIQUE,
  admission_date DATE,
  termination_date DATE,
  department_id UUID REFERENCES public.core_departments(id) ON DELETE SET NULL,
  position_id UUID REFERENCES public.hr_positions(id) ON DELETE SET NULL,
  manager_id UUID REFERENCES public.hr_employees(id) ON DELETE SET NULL,
  contract_type TEXT,
  salary DECIMAL(15,2),
  work_hours INTEGER, -- Horas semanais
  location_id UUID REFERENCES public.hr_locations(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_employees_person_id ON public.hr_employees(person_id);
CREATE INDEX idx_hr_employees_department_id ON public.hr_employees(department_id);
CREATE INDEX idx_hr_employees_position_id ON public.hr_employees(position_id);
CREATE INDEX idx_hr_employees_manager_id ON public.hr_employees(manager_id);
CREATE INDEX idx_hr_employees_contract_type ON public.hr_employees(contract_type);
CREATE INDEX idx_hr_employees_admission_date ON public.hr_employees(admission_date);

-- Trigger para updated_at
CREATE TRIGGER on_hr_employees_update
BEFORE UPDATE ON public.hr_employees
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- ==============================================
-- TABELA DE CANDIDATOS (HR_CANDIDATES)
-- ==============================================

-- Tabela de Candidatos (necessária antes de hr_selection_process)
CREATE TABLE public.hr_candidates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE CASCADE,
  position_id UUID REFERENCES public.hr_positions(id) ON DELETE SET NULL,
  resume_url TEXT,
  source TEXT, -- Como o candidato chegou (site, indicação, etc.)
  referred_by UUID REFERENCES public.core_people(id) ON DELETE SET NULL,
  expected_salary DECIMAL(15,2),
  availability_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status candidate_status_enum DEFAULT 'applied'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_candidates_person_id ON public.hr_candidates(person_id);
CREATE INDEX idx_hr_candidates_position_id ON public.hr_candidates(position_id);
CREATE INDEX idx_hr_candidates_status ON public.hr_candidates(status);

-- Trigger para updated_at
CREATE TRIGGER on_hr_candidates_update
BEFORE UPDATE ON public.hr_candidates
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- ==============================================
-- TABELA DE DOCUMENTOS DE FUNCIONÁRIOS
-- ==============================================

-- Tabela de Documentos de Funcionários
CREATE TABLE public.hr_employee_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES public.hr_employees(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL,
  document_number TEXT,
  issue_date DATE,
  expiration_date DATE,
  document_url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_employee_documents_employee_id ON public.hr_employee_documents(employee_id);
CREATE INDEX idx_hr_employee_documents_document_type ON public.hr_employee_documents(document_type);
CREATE INDEX idx_hr_employee_documents_expiration_date ON public.hr_employee_documents(expiration_date);

-- Trigger para updated_at
CREATE TRIGGER on_hr_employee_documents_update
BEFORE UPDATE ON public.hr_employee_documents
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- ==============================================
-- TABELA DE BENEFÍCIOS DE FUNCIONÁRIOS
-- ==============================================

-- Tabela de Benefícios
CREATE TABLE public.hr_benefits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  provider TEXT,
  cost DECIMAL(15,2),
  frequency TEXT, -- Mensal, Anual, etc.
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_benefits_name ON public.hr_benefits(name);
CREATE INDEX idx_hr_benefits_status ON public.hr_benefits(status);

-- Trigger para updated_at
CREATE TRIGGER on_hr_benefits_update
BEFORE UPDATE ON public.hr_benefits
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- ==============================================
-- TABELA DE RELACIONAMENTO FUNCIONÁRIOS-BENEFÍCIOS
-- ==============================================

-- Tabela de Benefícios dos Funcionários
CREATE TABLE public.hr_employee_benefits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES public.hr_employees(id) ON DELETE CASCADE,
  benefit_id UUID NOT NULL REFERENCES public.hr_benefits(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  end_date DATE,
  value DECIMAL(15,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_employee_benefits_employee_id ON public.hr_employee_benefits(employee_id);
CREATE INDEX idx_hr_employee_benefits_benefit_id ON public.hr_employee_benefits(benefit_id);
CREATE INDEX idx_hr_employee_benefits_start_date ON public.hr_employee_benefits(start_date);
CREATE INDEX idx_hr_employee_benefits_end_date ON public.hr_employee_benefits(end_date);
CREATE INDEX idx_hr_employee_benefits_status ON public.hr_employee_benefits(status);

-- Trigger para updated_at
CREATE TRIGGER on_hr_employee_benefits_update
BEFORE UPDATE ON public.hr_employee_benefits
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- ==============================================
-- TABELA DE VAGAS DE EMPREGO
-- ==============================================

-- Tabela de Vagas de Emprego
CREATE TABLE public.hr_job_openings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  position_id UUID REFERENCES public.hr_positions(id) ON DELETE SET NULL,
  department_id UUID REFERENCES public.core_departments(id) ON DELETE SET NULL,
  location_id UUID REFERENCES public.hr_locations(id) ON DELETE SET NULL,
  vacancy_count INTEGER DEFAULT 1,
  description TEXT,
  requirements TEXT,
  responsibilities TEXT,
  salary_range TEXT,
  post_date DATE DEFAULT CURRENT_DATE,
  closing_date DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_job_openings_title ON public.hr_job_openings(title);
CREATE INDEX idx_hr_job_openings_position_id ON public.hr_job_openings(position_id);
CREATE INDEX idx_hr_job_openings_department_id ON public.hr_job_openings(department_id);
CREATE INDEX idx_hr_job_openings_location_id ON public.hr_job_openings(location_id);
CREATE INDEX idx_hr_job_openings_post_date ON public.hr_job_openings(post_date);
CREATE INDEX idx_hr_job_openings_closing_date ON public.hr_job_openings(closing_date);
CREATE INDEX idx_hr_job_openings_status ON public.hr_job_openings(status);

-- Trigger para updated_at
CREATE TRIGGER on_hr_job_openings_update
BEFORE UPDATE ON public.hr_job_openings
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();


-- ==============================================
-- TABELA DE PROCESSO SELETIVO
-- ==============================================

-- Tabela de Processo Seletivo (etapas do candidato)
CREATE TABLE public.hr_selection_process (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  candidate_id UUID NOT NULL REFERENCES public.hr_candidates(id) ON DELETE CASCADE,
  stage_name TEXT NOT NULL, -- Nome da etapa (Entrevista, Teste, Dinâmica, etc.)
  stage_date TIMESTAMPTZ,
  evaluator_id UUID REFERENCES public.hr_employees(id) ON DELETE SET NULL,
  score INTEGER, -- Pontuação (1-100)
  feedback TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_selection_process_candidate_id ON public.hr_selection_process(candidate_id);
CREATE INDEX idx_hr_selection_process_evaluator_id ON public.hr_selection_process(evaluator_id);
CREATE INDEX idx_hr_selection_process_stage_date ON public.hr_selection_process(stage_date);

-- Trigger para updated_at
CREATE TRIGGER on_hr_selection_process_update
BEFORE UPDATE ON public.hr_selection_process
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Habilidades/Competências
CREATE TABLE public.hr_skills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT, -- Categoria (Técnica, Comportamental, etc.)
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_skills_category ON public.hr_skills(category);

-- Trigger para updated_at
CREATE TRIGGER on_hr_skills_update
BEFORE UPDATE ON public.hr_skills
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de relação entre Funcionários e Habilidades
CREATE TABLE public.hr_employee_skills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES public.hr_employees(id) ON DELETE CASCADE,
  skill_id UUID NOT NULL REFERENCES public.hr_skills(id) ON DELETE CASCADE,
  proficiency INTEGER, -- Nível de proficiência (1-5)
  certification_name TEXT,
  certification_date DATE,
  certification_expiry_date DATE,
  certification_url TEXT, -- URL para o certificado digitalizado
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(employee_id, skill_id)
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_employee_skills_employee_id ON public.hr_employee_skills(employee_id);
CREATE INDEX idx_hr_employee_skills_skill_id ON public.hr_employee_skills(skill_id);

-- Trigger para updated_at
CREATE TRIGGER on_hr_employee_skills_update
BEFORE UPDATE ON public.hr_employee_skills
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Treinamentos
CREATE TABLE public.hr_trainings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  instructor TEXT,
  start_date DATE,
  end_date DATE,
  location TEXT,
  max_participants INTEGER,
  cost DECIMAL(15,2),
  prerequisites TEXT,
  notes TEXT,
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status training_status_enum DEFAULT 'planned'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_trainings_start_date ON public.hr_trainings(start_date);
CREATE INDEX idx_hr_trainings_end_date ON public.hr_trainings(end_date);
CREATE INDEX idx_hr_trainings_created_by ON public.hr_trainings(created_by);
CREATE INDEX idx_hr_trainings_status ON public.hr_trainings(status);

-- Trigger para updated_at
CREATE TRIGGER on_hr_trainings_update
BEFORE UPDATE ON public.hr_trainings
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de relação entre Funcionários e Treinamentos
CREATE TABLE public.hr_employee_trainings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES public.hr_employees(id) ON DELETE CASCADE,
  training_id UUID NOT NULL REFERENCES public.hr_trainings(id) ON DELETE CASCADE,
  registration_date DATE DEFAULT CURRENT_DATE,
  attendance BOOLEAN,
  completion_date DATE,
  score INTEGER, -- Pontuação (1-100)
  certificate_url TEXT, -- URL para o certificado digitalizado
  feedback TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_employee_trainings_employee_id ON public.hr_employee_trainings(employee_id);
CREATE INDEX idx_hr_employee_trainings_training_id ON public.hr_employee_trainings(training_id);
CREATE INDEX idx_hr_employee_trainings_registration_date ON public.hr_employee_trainings(registration_date);
CREATE INDEX idx_hr_employee_trainings_completion_date ON public.hr_employee_trainings(completion_date);

-- Trigger para updated_at
CREATE TRIGGER on_hr_employee_trainings_update
BEFORE UPDATE ON public.hr_employee_trainings
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Avaliações de Desempenho
CREATE TABLE public.hr_performance_evaluations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES public.hr_employees(id) ON DELETE CASCADE,
  evaluator_id UUID REFERENCES public.hr_employees(id) ON DELETE SET NULL,
  evaluation_date DATE NOT NULL,
  period_start DATE,
  period_end DATE,
  overall_rating INTEGER, -- Avaliação geral (1-5)
  strengths TEXT,
  areas_for_improvement TEXT,
  goals_achieved TEXT,
  goals_for_next_period TEXT,
  employee_comments TEXT,
  evaluator_comments TEXT,
  acknowledged_by_employee BOOLEAN DEFAULT false,
  acknowledged_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_performance_evaluations_employee_id ON public.hr_performance_evaluations(employee_id);
CREATE INDEX idx_hr_performance_evaluations_evaluator_id ON public.hr_performance_evaluations(evaluator_id);
CREATE INDEX idx_hr_performance_evaluations_evaluation_date ON public.hr_performance_evaluations(evaluation_date);

-- Trigger para updated_at
CREATE TRIGGER on_hr_performance_evaluations_update
BEFORE UPDATE ON public.hr_performance_evaluations
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Critérios de Avaliação
CREATE TABLE public.hr_evaluation_criteria (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT, -- Categoria (Produtividade, Comportamento, etc.)
  weight INTEGER DEFAULT 1, -- Peso do critério
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_evaluation_criteria_category ON public.hr_evaluation_criteria(category);

-- Trigger para updated_at
CREATE TRIGGER on_hr_evaluation_criteria_update
BEFORE UPDATE ON public.hr_evaluation_criteria
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de relação entre Avaliações de Desempenho e Critérios
CREATE TABLE public.hr_evaluation_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  evaluation_id UUID NOT NULL REFERENCES public.hr_performance_evaluations(id) ON DELETE CASCADE,
  criteria_id UUID NOT NULL REFERENCES public.hr_evaluation_criteria(id) ON DELETE CASCADE,
  score INTEGER NOT NULL, -- Pontuação (1-5)
  comments TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(evaluation_id, criteria_id)
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_hr_evaluation_scores_evaluation_id ON public.hr_evaluation_scores(evaluation_id);
CREATE INDEX idx_hr_evaluation_scores_criteria_id ON public.hr_evaluation_scores(criteria_id);

-- Trigger para updated_at
CREATE TRIGGER on_hr_evaluation_scores_update
BEFORE UPDATE ON public.hr_evaluation_scores
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();