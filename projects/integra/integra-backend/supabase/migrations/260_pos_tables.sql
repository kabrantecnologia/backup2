-- ===========================================================================
-- ARQUITETURA DE DADOS FINAL SUPABASE - PROJETO INTEGRA
-- Parte 7: Módulo de PDV (Ponto de Venda/Point of Sale)
-- ===========================================================================

-- ==============================================
-- CRIAÇÃO DE TIPOS ENUM DO MÓDULO DE PDV
-- ==============================================

-- Status de venda
CREATE TYPE sale_status_enum AS ENUM (
  'pending',      -- Pendente
  'completed',    -- Concluída
  'cancelled',    -- Cancelada
  'refunded',     -- Reembolsada
  'partial'       -- Parcialmente paga
);

-- Tipos de desconto
CREATE TYPE discount_type_enum AS ENUM (
  'percentage',   -- Percentual
  'fixed'         -- Valor fixo
);

-- Status de item de estoque
CREATE TYPE inventory_item_status_enum AS ENUM (
  'available',    -- Disponível
  'low_stock',    -- Baixo estoque
  'out_of_stock', -- Sem estoque
  'discontinued', -- Descontinuado
  'reserved'      -- Reservado
);

-- ==============================================
-- TABELAS DO MÓDULO DE PDV
-- ==============================================

-- Tabela de Categorias de Produtos
CREATE TABLE public.pos_product_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES public.pos_product_categories(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índice para busca por categorias pai
CREATE INDEX idx_pos_product_categories_parent_id ON public.pos_product_categories(parent_id);

-- Trigger para updated_at
CREATE TRIGGER on_pos_product_categories_update
BEFORE UPDATE ON public.pos_product_categories
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Produtos
CREATE TABLE public.pos_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  category_id UUID REFERENCES public.pos_product_categories(id) ON DELETE SET NULL,
  barcode TEXT,
  sku TEXT UNIQUE,
  cost_price DECIMAL(15,2),
  sale_price DECIMAL(15,2) NOT NULL,
  donation_id UUID REFERENCES public.donation_items(id) ON DELETE SET NULL, -- Para itens doados que serão vendidos
  min_stock_level INTEGER DEFAULT 0,
  max_stock_level INTEGER,
  tax_rate DECIMAL(5,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_pos_products_category_id ON public.pos_products(category_id);
CREATE INDEX idx_pos_products_donation_id ON public.pos_products(donation_id);
CREATE INDEX idx_pos_products_barcode ON public.pos_products(barcode);

-- Trigger para updated_at
CREATE TRIGGER on_pos_products_update
BEFORE UPDATE ON public.pos_products
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Estoque
CREATE TABLE public.pos_inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES public.pos_products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 0,
  location TEXT, -- Localização física do item (prateleira, seção, etc.)
  batch_number TEXT,
  expiration_date DATE,
  last_count_date TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status inventory_item_status_enum DEFAULT 'available'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_pos_inventory_product_id ON public.pos_inventory(product_id);
CREATE INDEX idx_pos_inventory_status ON public.pos_inventory(status);
CREATE INDEX idx_pos_inventory_expiration_date ON public.pos_inventory(expiration_date);

-- Trigger para updated_at
CREATE TRIGGER on_pos_inventory_update
BEFORE UPDATE ON public.pos_inventory
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Movimentações de Estoque
CREATE TABLE public.pos_inventory_movements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES public.pos_products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL, -- Positivo para entrada, negativo para saída
  reference_type TEXT, -- Tipo de referência (venda, ajuste, doação, etc.)
  reference_id UUID, -- ID da entidade referenciada (venda, doação, etc.)
  reason TEXT,
  performed_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  performed_at TIMESTAMPTZ DEFAULT now(),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_pos_inventory_movements_product_id ON public.pos_inventory_movements(product_id);
CREATE INDEX idx_pos_inventory_movements_performed_by ON public.pos_inventory_movements(performed_by);
CREATE INDEX idx_pos_inventory_movements_performed_at ON public.pos_inventory_movements(performed_at);

-- Tabela de Caixas (Terminais de PDV)
CREATE TABLE public.pos_registers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  location TEXT,
  terminal_id TEXT,
  current_balance DECIMAL(15,2) DEFAULT 0,
  last_closing_date TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Trigger para updated_at
CREATE TRIGGER on_pos_registers_update
BEFORE UPDATE ON public.pos_registers
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Aberturas e Fechamentos de Caixa
CREATE TABLE public.pos_register_operations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  register_id UUID NOT NULL REFERENCES public.pos_registers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.core_users(id) ON DELETE CASCADE,
  operation_type TEXT NOT NULL, -- 'open' ou 'close'
  opening_amount DECIMAL(15,2),
  expected_amount DECIMAL(15,2),
  actual_amount DECIMAL(15,2),
  difference DECIMAL(15,2),
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_pos_register_operations_register_id ON public.pos_register_operations(register_id);
CREATE INDEX idx_pos_register_operations_user_id ON public.pos_register_operations(user_id);
CREATE INDEX idx_pos_register_operations_time ON public.pos_register_operations(start_time, end_time);

-- Trigger para updated_at
CREATE TRIGGER on_pos_register_operations_update
BEFORE UPDATE ON public.pos_register_operations
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Vendas
CREATE TABLE public.pos_sales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  register_id UUID REFERENCES public.pos_registers(id) ON DELETE SET NULL,
  customer_id UUID REFERENCES public.core_people(id) ON DELETE SET NULL, -- Cliente (opcional)
  user_id UUID NOT NULL REFERENCES public.core_users(id) ON DELETE CASCADE, -- Atendente
  sale_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  subtotal DECIMAL(15,2) NOT NULL,
  discount_amount DECIMAL(15,2) DEFAULT 0,
  discount_type discount_type_enum,
  discount_reason TEXT,
  tax_amount DECIMAL(15,2) DEFAULT 0,
  total DECIMAL(15,2) NOT NULL,
  payment_method TEXT,
  transaction_id UUID REFERENCES public.finance_transactions(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status sale_status_enum DEFAULT 'pending'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_pos_sales_register_id ON public.pos_sales(register_id);
CREATE INDEX idx_pos_sales_customer_id ON public.pos_sales(customer_id);
CREATE INDEX idx_pos_sales_user_id ON public.pos_sales(user_id);
CREATE INDEX idx_pos_sales_sale_date ON public.pos_sales(sale_date);
CREATE INDEX idx_pos_sales_transaction_id ON public.pos_sales(transaction_id);
CREATE INDEX idx_pos_sales_status ON public.pos_sales(status);

-- Trigger para updated_at
CREATE TRIGGER on_pos_sales_update
BEFORE UPDATE ON public.pos_sales
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Itens da Venda
CREATE TABLE public.pos_sale_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_id UUID NOT NULL REFERENCES public.pos_sales(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.pos_products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(15,2) NOT NULL,
  discount_amount DECIMAL(15,2) DEFAULT 0,
  discount_type discount_type_enum,
  tax_amount DECIMAL(15,2) DEFAULT 0,
  subtotal DECIMAL(15,2) NOT NULL, -- quantidade * preço unitário
  total DECIMAL(15,2) NOT NULL, -- subtotal - desconto + imposto
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_pos_sale_items_sale_id ON public.pos_sale_items(sale_id);
CREATE INDEX idx_pos_sale_items_product_id ON public.pos_sale_items(product_id);

-- Tabela de Pagamentos da Venda
CREATE TABLE public.pos_sale_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_id UUID NOT NULL REFERENCES public.pos_sales(id) ON DELETE CASCADE,
  amount DECIMAL(15,2) NOT NULL,
  payment_method TEXT NOT NULL, -- Dinheiro, cartão, PIX, etc.
  payment_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  reference TEXT, -- Número de referência (NSU, autorização, etc.)
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status payment_status_enum DEFAULT 'pending'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_pos_sale_payments_sale_id ON public.pos_sale_payments(sale_id);
CREATE INDEX idx_pos_sale_payments_payment_date ON public.pos_sale_payments(payment_date);
CREATE INDEX idx_pos_sale_payments_status ON public.pos_sale_payments(status);

-- Trigger para updated_at
CREATE TRIGGER on_pos_sale_payments_update
BEFORE UPDATE ON public.pos_sale_payments
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

