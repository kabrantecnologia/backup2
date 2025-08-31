-- ===========================================================================
-- ARQUITETURA DE DADOS FINAL SUPABASE - PROJETO INTEGRA
-- Parte 1: Core/Entidades Principais
-- ===========================================================================

-- -----------------------------------------------------
-- Implementação das recomendações do relatório:
-- 1. Cláusulas ON DELETE para integridade referencial
-- 2. Tipos ENUM para otimização
-- 3. Índices para performance
-- 4. Sistema RBAC refinado
-- -----------------------------------------------------


-- ==============================================
-- CRIAÇÃO DE TIPOS ENUM
-- ==============================================

-- Status padrão para entidades
CREATE TYPE status_enum AS ENUM (
  'active',       -- Ativo
  'inactive',     -- Inativo
  'pending',      -- Pendente
  'archived',     -- Arquivado
  'deleted'       -- Excluído
);

-- Tipos de pessoa
CREATE TYPE person_type_enum AS ENUM (
  'individual',    -- Pessoa física
  'organization'   -- Pessoa jurídica
);

-- Gêneros
CREATE TYPE gender_enum AS ENUM (
  'male',          -- Masculino
  'female',        -- Feminino
  'other',         -- Outro
  'not_specified'  -- Não especificado
);

-- Tipos de contato
CREATE TYPE contact_type_enum AS ENUM (
  'phone',         -- Telefone fixo
  'mobile',        -- Celular
  'email',         -- E-mail
  'whatsapp',      -- WhatsApp
  'other'          -- Outro
);

-- Níveis de acesso
CREATE TYPE access_level_enum AS ENUM (
  'admin',         -- Administrador
  'manager',       -- Gestor
  'operator',      -- Operador
  'basic',         -- Básico
  'guest'          -- Visitante
);

-- ==============================================
-- TABELAS PRINCIPAIS (CORE)
-- ==============================================

-- Tabela de Pessoas (físicas e jurídicas)
CREATE TABLE public.core_people (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  type person_type_enum NOT NULL DEFAULT 'individual',
  document TEXT UNIQUE,
  birth_date DATE,
  gender gender_enum DEFAULT 'not_specified',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active',
  department_id UUID, -- FK adicionada após criação da tabela departments
  CONSTRAINT check_document_format CHECK (
    (type = 'individual' AND length(regexp_replace(document, '[^0-9]', '', 'g')) = 11) OR
    (type = 'organization' AND length(regexp_replace(document, '[^0-9]', '', 'g')) = 14) OR
    document IS NULL
  )
);

-- Trigger para updated_at
CREATE TRIGGER on_core_people_update
BEFORE UPDATE ON public.core_people
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Endereços
CREATE TABLE public.core_addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID REFERENCES public.core_people(id) ON DELETE CASCADE,
  street TEXT NOT NULL,
  number TEXT,
  complement TEXT,
  district TEXT,
  city TEXT,
  state TEXT,
  zipcode TEXT,
  type TEXT,
  reference_point TEXT,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índice para melhorar a performance em consultas de endereços por pessoa
CREATE INDEX idx_core_addresses_person_id ON public.core_addresses(person_id);

-- Trigger para updated_at
CREATE TRIGGER on_core_addresses_update
BEFORE UPDATE ON public.core_addresses
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Contatos
CREATE TABLE public.core_contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID REFERENCES public.core_people(id) ON DELETE CASCADE,
  type contact_type_enum NOT NULL,
  value TEXT NOT NULL,
  is_primary BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índice para melhorar a performance em consultas de contatos por pessoa
CREATE INDEX idx_core_contacts_person_id ON public.core_contacts(person_id);

-- Trigger para updated_at
CREATE TRIGGER on_core_contacts_update
BEFORE UPDATE ON public.core_contacts
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Departamentos
CREATE TABLE public.core_departments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  code TEXT UNIQUE,
  manager_id UUID REFERENCES public.core_people(id) ON DELETE SET NULL,
  cost_center TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índice para busca de departamento por gestor
CREATE INDEX idx_core_departments_manager_id ON public.core_departments(manager_id);

-- Trigger para updated_at
CREATE TRIGGER on_core_departments_update
BEFORE UPDATE ON public.core_departments
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Adicionando constraint que faltava na tabela people
ALTER TABLE public.core_people 
ADD CONSTRAINT fk_core_people_department 
FOREIGN KEY (department_id) REFERENCES public.core_departments(id) ON DELETE SET NULL;

-- Índice para busca de pessoas por departamento
CREATE INDEX idx_core_people_department_id ON public.core_people(department_id);

-- Tabela de Grupos (para categorização)
CREATE TABLE public.core_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL,
  module TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Trigger para updated_at
CREATE TRIGGER on_core_groups_update
BEFORE UPDATE ON public.core_groups
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();


-- Tabela de Usuários do sistema
CREATE TABLE public.core_users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  person_id UUID REFERENCES public.core_people(id) ON DELETE CASCADE,
  login TEXT UNIQUE,
  email TEXT UNIQUE,
  access_level access_level_enum DEFAULT 'basic',
  last_access TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
  -- Removido o campo "modules TEXT[]" substituído pelo sistema RBAC
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_core_users_person_id ON public.core_users(person_id);
CREATE INDEX idx_core_users_login ON public.core_users(login);
CREATE INDEX idx_core_users_email ON public.core_users(email);

-- Trigger para updated_at
CREATE TRIGGER on_core_users_update
BEFORE UPDATE ON public.core_users
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Permissões por Módulo
CREATE TABLE public.core_module_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_id UUID NOT NULL REFERENCES public.rbac_roles(id) ON DELETE CASCADE,
  module_name TEXT NOT NULL, -- Nome do módulo (finance, logistics, etc.)
  can_view BOOLEAN DEFAULT false,
  can_create BOOLEAN DEFAULT false,
  can_edit BOOLEAN DEFAULT false,
  can_delete BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(role_id, module_name) -- Cada papel só tem uma configuração por módulo
);

-- Índice para consultas de permissão por papel
CREATE INDEX idx_core_module_permissions_role_id ON public.core_module_permissions(role_id);

-- Trigger para updated_at
CREATE TRIGGER on_core_module_permissions_update
BEFORE UPDATE ON public.core_module_permissions
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Histórico
CREATE TABLE public.core_history_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID REFERENCES public.core_people(id) ON DELETE SET NULL,
  date TIMESTAMPTZ DEFAULT now(),
  type TEXT NOT NULL,
  description TEXT,
  user_id UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'recorded'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_core_history_logs_person_id ON public.core_history_logs(person_id);
CREATE INDEX idx_core_history_logs_user_id ON public.core_history_logs(user_id);
CREATE INDEX idx_core_history_logs_date ON public.core_history_logs(date);

-- Tabela de Auditoria
CREATE TABLE public.core_audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date TIMESTAMPTZ DEFAULT now(),
  type TEXT NOT NULL,
  description TEXT,
  user_id UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  person_id UUID REFERENCES public.core_people(id) ON DELETE SET NULL,
  module TEXT,
  table_name TEXT,
  record_id UUID
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_core_audit_logs_date ON public.core_audit_logs(date);
CREATE INDEX idx_core_audit_logs_user_id ON public.core_audit_logs(user_id);
CREATE INDEX idx_core_audit_logs_person_id ON public.core_audit_logs(person_id);
CREATE INDEX idx_core_audit_logs_module ON public.core_audit_logs(module);

-- Tabela de Arquivos
CREATE TABLE public.core_files (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  storage_path TEXT NOT NULL,
  type TEXT NOT NULL,
  entity_type TEXT NOT NULL, -- Tipo da entidade relacionada (person, donation, etc.)
  entity_id UUID NOT NULL,   -- ID da entidade relacionada
  description TEXT,
  user_id UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  upload_date TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_core_files_entity ON public.core_files(entity_type, entity_id);
CREATE INDEX idx_core_files_user_id ON public.core_files(user_id);
