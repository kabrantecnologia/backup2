-- ===========================================================================
-- ARQUITETURA DE DADOS FINAL SUPABASE - PROJETO INTEGRA
-- Parte 6: Módulo de Empréstimos (Loans)
-- ===========================================================================

-- ==============================================
-- CRIAÇÃO DE TIPOS ENUM DO MÓDULO DE EMPRÉSTIMOS
-- ==============================================

-- Status de empréstimo
CREATE TYPE loan_status_enum AS ENUM (
  'pending',      -- Pendente de aprovação
  'approved',     -- Aprovado
  'active',       -- Ativo/Em andamento
  'late',         -- Atrasado
  'completed',    -- Concluído
  'defaulted',    -- Inadimplente
  'cancelled',    -- Cancelado
  'rejected'      -- Rejeitado
);

-- Tipos de empréstimo
CREATE TYPE loan_type_enum AS ENUM (
  'personal',     -- Pessoal
  'emergency',    -- Emergencial
  'education',    -- Educacional
  'housing',      -- Habitação
  'business',     -- Negócios
  'medical',      -- Médico
  'other'         -- Outro
);

-- Status de pagamento
CREATE TYPE payment_status_enum AS ENUM (
  'pending',      -- Pendente
  'paid',         -- Pago
  'partial',      -- Parcialmente pago
  'late',         -- Atrasado
  'cancelled',    -- Cancelado
  'refunded'      -- Devolvido
);

-- ==============================================
-- TABELAS DO MÓDULO DE EMPRÉSTIMOS
-- ==============================================

-- Tabela de Programas de Empréstimo
CREATE TABLE public.loan_programs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  interest_rate DECIMAL(6,3), -- Taxa de juros (%)
  min_amount DECIMAL(15,2),
  max_amount DECIMAL(15,2),
  min_term INTEGER, -- Prazo mínimo em meses
  max_term INTEGER, -- Prazo máximo em meses
  grace_period INTEGER, -- Período de carência em dias
  late_fee_percent DECIMAL(6,3), -- Taxa de multa por atraso (%)
  requirements TEXT, -- Requisitos para participação
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Trigger para updated_at
CREATE TRIGGER on_loan_programs_update
BEFORE UPDATE ON public.loan_programs
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Empréstimos
CREATE TABLE public.loans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  borrower_id UUID NOT NULL REFERENCES public.core_people(id) ON DELETE RESTRICT, -- Mutuário
  program_id UUID REFERENCES public.loan_programs(id) ON DELETE SET NULL,
  loan_type loan_type_enum NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  interest_rate DECIMAL(6,3) NOT NULL, -- Taxa de juros (%)
  term INTEGER NOT NULL, -- Prazo em meses
  start_date DATE,
  end_date DATE,
  purpose TEXT,
  application_date DATE NOT NULL,
  approved_date DATE,
  approved_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  guarantor_id UUID REFERENCES public.core_people(id) ON DELETE SET NULL, -- Fiador/Avalista
  disbursed_amount DECIMAL(15,2), -- Valor efetivamente liberado
  disbursement_date DATE,
  total_paid DECIMAL(15,2) DEFAULT 0,
  remaining_balance DECIMAL(15,2), -- Saldo devedor
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status loan_status_enum DEFAULT 'pending'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_loans_borrower_id ON public.loans(borrower_id);
CREATE INDEX idx_loans_program_id ON public.loans(program_id);
CREATE INDEX idx_loans_guarantor_id ON public.loans(guarantor_id);
CREATE INDEX idx_loans_approved_by ON public.loans(approved_by);
CREATE INDEX idx_loans_application_date ON public.loans(application_date);
CREATE INDEX idx_loans_status ON public.loans(status);
CREATE INDEX idx_loans_type ON public.loans(loan_type);

-- Trigger para updated_at
CREATE TRIGGER on_loans_update
BEFORE UPDATE ON public.loans
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Parcelas do Empréstimo
CREATE TABLE public.loan_installments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id UUID NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
  installment_number INTEGER NOT NULL,
  due_date DATE NOT NULL,
  amount DECIMAL(15,2) NOT NULL, -- Valor da parcela
  principal DECIMAL(15,2) NOT NULL, -- Valor do principal
  interest DECIMAL(15,2) NOT NULL, -- Valor dos juros
  late_fee DECIMAL(15,2) DEFAULT 0, -- Multa por atraso
  paid_amount DECIMAL(15,2) DEFAULT 0, -- Valor efetivamente pago
  payment_date DATE, -- Data do pagamento
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status payment_status_enum DEFAULT 'pending',
  UNIQUE(loan_id, installment_number) -- Cada empréstimo só pode ter uma parcela com o mesmo número
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_loan_installments_loan_id ON public.loan_installments(loan_id);
CREATE INDEX idx_loan_installments_due_date ON public.loan_installments(due_date);
CREATE INDEX idx_loan_installments_status ON public.loan_installments(status);

-- Trigger para updated_at
CREATE TRIGGER on_loan_installments_update
BEFORE UPDATE ON public.loan_installments
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Pagamentos
CREATE TABLE public.loan_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id UUID NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
  installment_id UUID REFERENCES public.loan_installments(id) ON DELETE SET NULL,
  amount DECIMAL(15,2) NOT NULL,
  payment_date DATE NOT NULL,
  payment_method TEXT, -- Método de pagamento (dinheiro, transferência, etc.)
  transaction_id UUID REFERENCES public.finance_transactions(id) ON DELETE SET NULL, -- Referência à transação financeira
  received_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status payment_status_enum DEFAULT 'pending'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_loan_payments_loan_id ON public.loan_payments(loan_id);
CREATE INDEX idx_loan_payments_installment_id ON public.loan_payments(installment_id);
CREATE INDEX idx_loan_payments_transaction_id ON public.loan_payments(transaction_id);
CREATE INDEX idx_loan_payments_payment_date ON public.loan_payments(payment_date);
CREATE INDEX idx_loan_payments_received_by ON public.loan_payments(received_by);

-- Trigger para updated_at
CREATE TRIGGER on_loan_payments_update
BEFORE UPDATE ON public.loan_payments
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Documentos de Empréstimo
CREATE TABLE public.loan_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id UUID NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  file_path TEXT, -- Caminho para o arquivo no Storage
  document_type TEXT,
  uploaded_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  upload_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  status status_enum DEFAULT 'active'
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_loan_documents_loan_id ON public.loan_documents(loan_id);
CREATE INDEX idx_loan_documents_uploaded_by ON public.loan_documents(uploaded_by);
CREATE INDEX idx_loan_documents_upload_date ON public.loan_documents(upload_date);

-- Trigger para updated_at
CREATE TRIGGER on_loan_documents_update
BEFORE UPDATE ON public.loan_documents
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de Garantias/Colaterais
CREATE TABLE public.loan_collaterals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id UUID NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  value DECIMAL(15,2) NOT NULL,
  type TEXT,
  status TEXT,
  evaluation_date DATE,
  evaluated_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_loan_collaterals_loan_id ON public.loan_collaterals(loan_id);
CREATE INDEX idx_loan_collaterals_evaluated_by ON public.loan_collaterals(evaluated_by);

-- Trigger para updated_at
CREATE TRIGGER on_loan_collaterals_update
BEFORE UPDATE ON public.loan_collaterals
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela de histórico de status do empréstimo
CREATE TABLE public.loan_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id UUID NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
  previous_status loan_status_enum,
  new_status loan_status_enum NOT NULL,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  changed_by UUID REFERENCES public.core_users(id) ON DELETE SET NULL,
  reason TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para melhorar a performance nas consultas
CREATE INDEX idx_loan_status_history_loan_id ON public.loan_status_history(loan_id);
CREATE INDEX idx_loan_status_history_changed_by ON public.loan_status_history(changed_by);
CREATE INDEX idx_loan_status_history_changed_at ON public.loan_status_history(changed_at);

