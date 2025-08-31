-- ===========================================================================
-- ARQUITETURA DE DADOS FINAL SUPABASE - PROJETO INTEGRA
-- Parte 2: Módulo Financeiro (Finance)
-- ===========================================================================

-- ==============================================
-- CRIAÇÃO DE TIPOS ENUM DO MÓDULO FINANCEIRO
-- ==============================================

-- Tipo de transação financeira
CREATE TYPE finance_transaction_type_enum AS ENUM (
  'income',       -- Receita
  'expense',      -- Despesa
  'transfer'      -- Transferência
);

-- Status de transação financeira
CREATE TYPE finance_transaction_status_enum AS ENUM (
  'pending',      -- Pendente
  'paid',         -- Pago
  'cancelled',    -- Cancelado
  'refunded',     -- Estornado
  'overdue'       -- Atrasado
);

-- Formas de pagamento
CREATE TYPE payment_method_enum AS ENUM (
  'cash',         -- Dinheiro
  'credit_card',  -- Cartão de crédito
  'debit_card',   -- Cartão de débito
  'bank_transfer',-- Transferência bancária
  'pix',          -- PIX
  'check',        -- Cheque
  'billet',       -- Boleto
  'other'         -- Outro
);

-- ==============================================
-- TABELAS DO MÓDULO FINANCEIRO
-- ==============================================

-- Tabela de Centros de Custo
CREATE TABLE public.finance_cost_centers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT UNIQUE,
  parent_id UUID REFERENCES public.finance_cost_centers(id) ON DELETE SET NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índice para busca por hierarquia
CREATE INDEX idx_cost_centers_parent_id ON public.finance_cost_centers(parent_id);

-- Trigger para updated_at
CREATE TRIGGER on_finance_cost_centers_update
BEFORE UPDATE ON public.finance_cost_centers
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Plano de Contas
CREATE TABLE public.finance_account_plan (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT UNIQUE,
  type TEXT NOT NULL CHECK (type IN ('revenue', 'expense', 'asset', 'liability')),
  parent_id UUID REFERENCES public.finance_account_plan(id) ON DELETE SET NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índice para busca por hierarquia
CREATE INDEX idx_account_plan_parent_id ON public.finance_account_plan(parent_id);

-- Trigger para updated_at
CREATE TRIGGER on_finance_account_plan_update
BEFORE UPDATE ON public.finance_account_plan
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Contas Financeiras (Bancos, Caixa, etc)
CREATE TABLE public.finance_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  bank_code TEXT,
  account_number TEXT,
  branch TEXT,
  owner_name TEXT,
  document TEXT,
  opening_balance DECIMAL(15,2) DEFAULT 0,
  current_balance DECIMAL(15,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Trigger para updated_at
CREATE TRIGGER on_finance_accounts_update
BEFORE UPDATE ON public.finance_accounts
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Transações Financeiras
CREATE TABLE public.finance_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type finance_transaction_type_enum NOT NULL,
  description TEXT NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  due_date TIMESTAMPTZ,
  payment_date TIMESTAMPTZ,
  person_id UUID REFERENCES public.core_people(id) ON DELETE SET NULL,
  account_id UUID NOT NULL REFERENCES public.finance_accounts(id) ON DELETE CASCADE,
  destination_account_id UUID REFERENCES public.finance_accounts(id) ON DELETE SET NULL,
  cost_center_id UUID REFERENCES public.finance_cost_centers(id) ON DELETE SET NULL,
  account_plan_id UUID REFERENCES public.finance_account_plan(id) ON DELETE SET NULL,
  payment_method payment_method_enum,
  document_number TEXT,
  notes TEXT,
  attachment_id UUID REFERENCES public.core_files(id) ON DELETE SET NULL,
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status finance_transaction_status_enum DEFAULT 'pending'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_finance_transactions_person_id ON public.finance_transactions(person_id);
CREATE INDEX idx_finance_transactions_account_id ON public.finance_transactions(account_id);
CREATE INDEX idx_finance_transactions_cost_center_id ON public.finance_transactions(cost_center_id);
CREATE INDEX idx_finance_transactions_account_plan_id ON public.finance_transactions(account_plan_id);
CREATE INDEX idx_finance_transactions_date ON public.finance_transactions(date);
CREATE INDEX idx_finance_transactions_due_date ON public.finance_transactions(due_date);
CREATE INDEX idx_finance_transactions_payment_date ON public.finance_transactions(payment_date);
CREATE INDEX idx_finance_transactions_status ON public.finance_transactions(status);
CREATE INDEX idx_finance_transactions_type ON public.finance_transactions(type);

-- Trigger para updated_at
CREATE TRIGGER on_finance_transactions_update
BEFORE UPDATE ON public.finance_transactions
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Parcelas (para pagamentos parcelados)
CREATE TABLE public.finance_installments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID NOT NULL REFERENCES public.finance_transactions(id) ON DELETE CASCADE,
  installment_number INTEGER NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  due_date TIMESTAMPTZ NOT NULL,
  payment_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status finance_transaction_status_enum DEFAULT 'pending'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_finance_installments_transaction_id ON public.finance_installments(transaction_id);
CREATE INDEX idx_finance_installments_due_date ON public.finance_installments(due_date);
CREATE INDEX idx_finance_installments_status ON public.finance_installments(status);

-- Trigger para updated_at
CREATE TRIGGER on_finance_installments_update
BEFORE UPDATE ON public.finance_installments
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela para conciliação bancária
CREATE TABLE public.finance_bank_reconciliation (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id UUID NOT NULL REFERENCES public.finance_accounts(id) ON DELETE CASCADE,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  initial_balance DECIMAL(15,2) NOT NULL,
  final_balance DECIMAL(15,2) NOT NULL,
  statement_balance DECIMAL(15,2) NOT NULL,
  difference DECIMAL(15,2) DEFAULT 0,
  notes TEXT,
  created_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_finance_bank_reconciliation_account_id ON public.finance_bank_reconciliation(account_id);
CREATE INDEX idx_finance_bank_reconciliation_date_range ON public.finance_bank_reconciliation(start_date, end_date);

-- Trigger para updated_at
CREATE TRIGGER on_finance_bank_reconciliation_update
BEFORE UPDATE ON public.finance_bank_reconciliation
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

