-- ===========================================================================
-- ARQUITETURA DE DADOS FINAL SUPABASE - PROJETO INTEGRA
-- Parte 4: Módulo de Logística (Logistics)
-- ===========================================================================

-- ==============================================
-- CRIAÇÃO DE TIPOS ENUM DO MÓDULO DE LOGÍSTICA
-- ==============================================

-- Status de veículos
CREATE TYPE vehicle_status_enum AS ENUM (
  'available',    -- Disponível
  'maintenance',  -- Em manutenção
  'in_use',       -- Em uso
  'inactive'      -- Inativo
);

-- Tipos de veículos
CREATE TYPE vehicle_type_enum AS ENUM (
  'car',          -- Carro
  'van',          -- Van
  'truck',        -- Caminhão
  'motorcycle',   -- Moto
  'other'         -- Outro
);

-- Status de viagens/rotas
CREATE TYPE route_status_enum AS ENUM (
  'planned',      -- Planejada
  'in_progress',  -- Em andamento
  'completed',    -- Concluída
  'cancelled'     -- Cancelada
);

-- Tipos de manutenção
CREATE TYPE maintenance_type_enum AS ENUM (
  'preventive',   -- Preventiva
  'corrective',   -- Corretiva
  'emergency'     -- Emergencial
);

-- ==============================================
-- TABELAS DO MÓDULO DE LOGÍSTICA
-- ==============================================

-- Tabela de Veículos
CREATE TABLE public.logistics_vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plate TEXT NOT NULL UNIQUE,
  model TEXT NOT NULL,
  brand TEXT NOT NULL,
  year INTEGER,
  capacity TEXT,
  color TEXT,
  document TEXT, -- RENAVAM, documentação, etc.
  purchase_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status vehicle_status_enum DEFAULT 'available',
  type vehicle_type_enum NOT NULL
);

-- Índices para busca por status e tipo
CREATE INDEX idx_logistics_vehicles_status ON public.logistics_vehicles(status);
CREATE INDEX idx_logistics_vehicles_type ON public.logistics_vehicles(type);

-- Trigger para updated_at
CREATE TRIGGER on_logistics_vehicles_update
BEFORE UPDATE ON public.logistics_vehicles
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Motoristas
CREATE TABLE public.logistics_drivers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE CASCADE,
  license_number TEXT NOT NULL,
  license_type TEXT NOT NULL,
  license_expiration DATE NOT NULL,
  start_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índice para busca por pessoa
CREATE INDEX idx_logistics_drivers_person_id ON public.logistics_drivers(person_id);

-- Trigger para updated_at
CREATE TRIGGER on_logistics_drivers_update
BEFORE UPDATE ON public.logistics_drivers
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Rotas/Itinerários
CREATE TABLE public.logistics_routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  start_point TEXT,
  end_point TEXT,
  estimated_distance DECIMAL(10,2),
  estimated_time INTEGER, -- Em minutos
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Trigger para updated_at
CREATE TRIGGER on_logistics_routes_update
BEFORE UPDATE ON public.logistics_routes
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Paradas da Rota
CREATE TABLE public.logistics_route_stops (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID NOT NULL REFERENCES public.logistics_routes(id) ON DELETE CASCADE,
  sequence_number INTEGER NOT NULL,
  address_id UUID REFERENCES public.core_addresses(id) ON DELETE SET NULL,
  address_description TEXT,
  estimated_time INTEGER, -- Em minutos
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_logistics_route_stops_route_id ON public.logistics_route_stops(route_id);
CREATE INDEX idx_logistics_route_stops_address_id ON public.logistics_route_stops(address_id);

-- Trigger para updated_at
CREATE TRIGGER on_logistics_route_stops_update
BEFORE UPDATE ON public.logistics_route_stops
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Viagens (instâncias de uso de veículo em uma rota)
CREATE TABLE public.logistics_trips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.logistics_vehicles(id) ON DELETE RESTRICT,
  driver_id UUID NOT NULL REFERENCES public.logistics_drivers(id) ON DELETE RESTRICT,
  route_id UUID REFERENCES public.logistics_routes(id) ON DELETE SET NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  start_odometer INTEGER,
  end_odometer INTEGER,
  fuel_consumption DECIMAL(10,2),
  notes TEXT,
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status route_status_enum DEFAULT 'planned'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_logistics_trips_vehicle_id ON public.logistics_trips(vehicle_id);
CREATE INDEX idx_logistics_trips_driver_id ON public.logistics_trips(driver_id);
CREATE INDEX idx_logistics_trips_route_id ON public.logistics_trips(route_id);
CREATE INDEX idx_logistics_trips_start_date ON public.logistics_trips(start_date);
CREATE INDEX idx_logistics_trips_status ON public.logistics_trips(status);

-- Trigger para updated_at
CREATE TRIGGER on_logistics_trips_update
BEFORE UPDATE ON public.logistics_trips
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Adicionando a referência à tabela de coletas de doação (foreign key pendente)
ALTER TABLE public.donation_collections
ADD CONSTRAINT fk_donation_collections_vehicle 
FOREIGN KEY (vehicle_id) REFERENCES public.logistics_vehicles(id) ON DELETE SET NULL;

-- Tabela de Manutenções de Veículos
CREATE TABLE public.logistics_vehicle_maintenance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.logistics_vehicles(id) ON DELETE CASCADE,
  maintenance_date TIMESTAMPTZ NOT NULL,
  odometer INTEGER,
  description TEXT NOT NULL,
  cost DECIMAL(15,2),
  provider TEXT, -- Oficina/prestador do serviço
  next_maintenance_date TIMESTAMPTZ,
  next_maintenance_odometer INTEGER,
  notes TEXT,
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  type maintenance_type_enum NOT NULL,
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_logistics_vehicle_maintenance_vehicle_id ON public.logistics_vehicle_maintenance(vehicle_id);
CREATE INDEX idx_logistics_vehicle_maintenance_date ON public.logistics_vehicle_maintenance(maintenance_date);
CREATE INDEX idx_logistics_vehicle_maintenance_next_date ON public.logistics_vehicle_maintenance(next_maintenance_date);
CREATE INDEX idx_logistics_vehicle_maintenance_type ON public.logistics_vehicle_maintenance(type);

-- Trigger para updated_at
CREATE TRIGGER on_logistics_vehicle_maintenance_update
BEFORE UPDATE ON public.logistics_vehicle_maintenance
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Abastecimentos
CREATE TABLE public.logistics_fuel_supply (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.logistics_vehicles(id) ON DELETE CASCADE,
  supply_date TIMESTAMPTZ NOT NULL,
  odometer INTEGER NOT NULL,
  fuel_type TEXT NOT NULL,
  quantity DECIMAL(10,2) NOT NULL, -- em litros
  price_per_unit DECIMAL(10,2),
  total_cost DECIMAL(15,2),
  gas_station TEXT,
  driver_id UUID REFERENCES public.logistics_drivers(id) ON DELETE SET NULL,
  notes TEXT,
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_logistics_fuel_supply_vehicle_id ON public.logistics_fuel_supply(vehicle_id);
CREATE INDEX idx_logistics_fuel_supply_driver_id ON public.logistics_fuel_supply(driver_id);
CREATE INDEX idx_logistics_fuel_supply_date ON public.logistics_fuel_supply(supply_date);

-- Trigger para updated_at
CREATE TRIGGER on_logistics_fuel_supply_update
BEFORE UPDATE ON public.logistics_fuel_supply
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

