-- ===========================================================================
-- ARQUITETURA DE DADOS FINAL SUPABASE - PROJETO INTEGRA
-- Parte 9: Módulo de Refeitório/Cafeteria (Cafeteria)
-- ===========================================================================

-- ==============================================
-- CRIAÇÃO DE TIPOS ENUM DO MÓDULO DE REFEITÓRIO
-- ==============================================

-- Tipos de refeição
CREATE TYPE meal_type_enum AS ENUM (
  'breakfast',    -- Café da manhã
  'lunch',        -- Almoço
  'dinner',       -- Jantar
  'snack',        -- Lanche
  'special'       -- Especial
);

-- Status de cardápio
CREATE TYPE menu_status_enum AS ENUM (
  'draft',        -- Rascunho
  'approved',     -- Aprovado
  'active',       -- Ativo/Em uso
  'completed',    -- Concluído
  'cancelled'     -- Cancelado
);

-- ==============================================
-- TABELAS DO MÓDULO DE REFEITÓRIO
-- ==============================================

-- Tabela de Categorias de Alimentos
CREATE TABLE public.cafeteria_food_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Trigger para updated_at
CREATE TRIGGER on_cafeteria_food_categories_update
BEFORE UPDATE ON public.cafeteria_food_categories
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Ingredientes
CREATE TABLE public.cafeteria_ingredients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  unit TEXT NOT NULL, -- Unidade de medida (kg, g, l, ml, etc)
  category_id UUID REFERENCES public.cafeteria_food_categories(id) ON DELETE SET NULL,
  nutrition_info TEXT, -- Informações nutricionais
  allergens TEXT, -- Alergênicos
  stock_quantity DECIMAL(10,3) DEFAULT 0,
  min_stock_level DECIMAL(10,3) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_cafeteria_ingredients_category_id ON public.cafeteria_ingredients(category_id);

-- Trigger para updated_at
CREATE TRIGGER on_cafeteria_ingredients_update
BEFORE UPDATE ON public.cafeteria_ingredients
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Fornecedores de Ingredientes
CREATE TABLE public.cafeteria_suppliers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE CASCADE, -- Referência ao fornecedor
  contact_person TEXT,
  delivery_days TEXT, -- Ex: "1,3,5" para segunda, quarta e sexta
  minimum_order_value DECIMAL(15,2),
  delivery_time INTEGER, -- Tempo de entrega em dias
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_cafeteria_suppliers_person_id ON public.cafeteria_suppliers(person_id);

-- Trigger para updated_at
CREATE TRIGGER on_cafeteria_suppliers_update
BEFORE UPDATE ON public.cafeteria_suppliers
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de relação entre Ingredientes e Fornecedores
CREATE TABLE public.cafeteria_supplier_ingredients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  supplier_id UUID NOT NULL REFERENCES public.cafeteria_suppliers(id) ON DELETE CASCADE,
  ingredient_id UUID NOT NULL REFERENCES public.cafeteria_ingredients(id) ON DELETE CASCADE,
  unit_price DECIMAL(15,2),
  last_purchase_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(supplier_id, ingredient_id) -- Um ingrediente só pode ser associado uma vez a cada fornecedor
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_cafeteria_supplier_ingredients_supplier_id ON public.cafeteria_supplier_ingredients(supplier_id);
CREATE INDEX idx_cafeteria_supplier_ingredients_ingredient_id ON public.cafeteria_supplier_ingredients(ingredient_id);

-- Trigger para updated_at
CREATE TRIGGER on_cafeteria_supplier_ingredients_update
BEFORE UPDATE ON public.cafeteria_supplier_ingredients
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Pedidos de Compra
CREATE TABLE public.cafeteria_purchase_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  supplier_id UUID NOT NULL REFERENCES public.cafeteria_suppliers(id) ON DELETE CASCADE,
  order_date DATE NOT NULL,
  delivery_date DATE,
  total_amount DECIMAL(15,2),
  payment_terms TEXT,
  notes TEXT,
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_cafeteria_purchase_orders_supplier_id ON public.cafeteria_purchase_orders(supplier_id);
CREATE INDEX idx_cafeteria_purchase_orders_order_date ON public.cafeteria_purchase_orders(order_date);
CREATE INDEX idx_cafeteria_purchase_orders_delivery_date ON public.cafeteria_purchase_orders(delivery_date);

-- Trigger para updated_at
CREATE TRIGGER on_cafeteria_purchase_orders_update
BEFORE UPDATE ON public.cafeteria_purchase_orders
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Itens do Pedido de Compra
CREATE TABLE public.cafeteria_purchase_order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  purchase_order_id UUID NOT NULL REFERENCES public.cafeteria_purchase_orders(id) ON DELETE CASCADE,
  ingredient_id UUID NOT NULL REFERENCES public.cafeteria_ingredients(id) ON DELETE CASCADE,
  quantity DECIMAL(10,3) NOT NULL,
  unit_price DECIMAL(15,2) NOT NULL,
  total_price DECIMAL(15,2) NOT NULL,
  received_quantity DECIMAL(10,3) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_cafeteria_purchase_order_items_purchase_order_id ON public.cafeteria_purchase_order_items(purchase_order_id);
CREATE INDEX idx_cafeteria_purchase_order_items_ingredient_id ON public.cafeteria_purchase_order_items(ingredient_id);

-- Trigger para updated_at
CREATE TRIGGER on_cafeteria_purchase_order_items_update
BEFORE UPDATE ON public.cafeteria_purchase_order_items
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Receitas
CREATE TABLE public.cafeteria_recipes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  preparation TEXT,
  serving_size INTEGER, -- Número de porções
  preparation_time INTEGER, -- Em minutos
  category_id UUID REFERENCES public.cafeteria_food_categories(id) ON DELETE SET NULL,
  nutrition_info TEXT, -- Informações nutricionais
  cost_per_serving DECIMAL(15,2),
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_cafeteria_recipes_category_id ON public.cafeteria_recipes(category_id);
CREATE INDEX idx_cafeteria_recipes_created_by ON public.cafeteria_recipes(created_by);

-- Trigger para updated_at
CREATE TRIGGER on_cafeteria_recipes_update
BEFORE UPDATE ON public.cafeteria_recipes
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Ingredientes da Receita
CREATE TABLE public.cafeteria_recipe_ingredients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipe_id UUID NOT NULL REFERENCES public.cafeteria_recipes(id) ON DELETE CASCADE,
  ingredient_id UUID NOT NULL REFERENCES public.cafeteria_ingredients(id) ON DELETE CASCADE,
  quantity DECIMAL(10,3) NOT NULL,
  optional BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_cafeteria_recipe_ingredients_recipe_id ON public.cafeteria_recipe_ingredients(recipe_id);
CREATE INDEX idx_cafeteria_recipe_ingredients_ingredient_id ON public.cafeteria_recipe_ingredients(ingredient_id);

-- Trigger para updated_at
CREATE TRIGGER on_cafeteria_recipe_ingredients_update
BEFORE UPDATE ON public.cafeteria_recipe_ingredients
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Cardápios
CREATE TABLE public.cafeteria_menus (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  date DATE NOT NULL,
  meal_type meal_type_enum NOT NULL,
  description TEXT,
  notes TEXT,
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  approved_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status menu_status_enum DEFAULT 'draft'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_cafeteria_menus_date ON public.cafeteria_menus(date);
CREATE INDEX idx_cafeteria_menus_meal_type ON public.cafeteria_menus(meal_type);
CREATE INDEX idx_cafeteria_menus_created_by ON public.cafeteria_menus(created_by);
CREATE INDEX idx_cafeteria_menus_approved_by ON public.cafeteria_menus(approved_by);
CREATE INDEX idx_cafeteria_menus_status ON public.cafeteria_menus(status);

-- Trigger para updated_at
CREATE TRIGGER on_cafeteria_menus_update
BEFORE UPDATE ON public.cafeteria_menus
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Itens do Cardápio
CREATE TABLE public.cafeteria_menu_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  menu_id UUID NOT NULL REFERENCES public.cafeteria_menus(id) ON DELETE CASCADE,
  recipe_id UUID NOT NULL REFERENCES public.cafeteria_recipes(id) ON DELETE CASCADE,
  servings INTEGER NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_cafeteria_menu_items_menu_id ON public.cafeteria_menu_items(menu_id);
CREATE INDEX idx_cafeteria_menu_items_recipe_id ON public.cafeteria_menu_items(recipe_id);

-- Trigger para updated_at
CREATE TRIGGER on_cafeteria_menu_items_update
BEFORE UPDATE ON public.cafeteria_menu_items
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Controle de Refeições (registros de refeições servidas)
CREATE TABLE public.cafeteria_meal_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  menu_id UUID REFERENCES public.cafeteria_menus(id) ON DELETE SET NULL,
  meal_type meal_type_enum NOT NULL,
  date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  total_servings INTEGER DEFAULT 0, -- Total de refeições servidas
  employees_served INTEGER DEFAULT 0, -- Funcionários atendidos
  beneficiaries_served INTEGER DEFAULT 0, -- Beneficiários atendidos
  visitors_served INTEGER DEFAULT 0, -- Visitantes atendidos
  notes TEXT,
  recorded_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_cafeteria_meal_records_menu_id ON public.cafeteria_meal_records(menu_id);
CREATE INDEX idx_cafeteria_meal_records_date ON public.cafeteria_meal_records(date);
CREATE INDEX idx_cafeteria_meal_records_meal_type ON public.cafeteria_meal_records(meal_type);
CREATE INDEX idx_cafeteria_meal_records_recorded_by ON public.cafeteria_meal_records(recorded_by);

-- Trigger para updated_at
CREATE TRIGGER on_cafeteria_meal_records_update
BEFORE UPDATE ON public.cafeteria_meal_records
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Movimentação de Estoque de Ingredientes
CREATE TABLE public.cafeteria_ingredient_movements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ingredient_id UUID NOT NULL REFERENCES public.cafeteria_ingredients(id) ON DELETE CASCADE,
  quantity DECIMAL(10,3) NOT NULL, -- Positivo para entrada, negativo para saída
  reference_type TEXT, -- Tipo de referência (compra, receita, ajuste, etc.)
  reference_id UUID, -- ID da entidade referenciada (pedido, receita, etc.)
  reason TEXT,
  unit_cost DECIMAL(15,2),
  total_cost DECIMAL(15,2),
  performed_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  performed_at TIMESTAMPTZ DEFAULT now(),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_cafeteria_ingredient_movements_ingredient_id ON public.cafeteria_ingredient_movements(ingredient_id);
CREATE INDEX idx_cafeteria_ingredient_movements_reference_id ON public.cafeteria_ingredient_movements(reference_id);
CREATE INDEX idx_cafeteria_ingredient_movements_performed_by ON public.cafeteria_ingredient_movements(performed_by);
CREATE INDEX idx_cafeteria_ingredient_movements_performed_at ON public.cafeteria_ingredient_movements(performed_at);

