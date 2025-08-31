-- =====================================================================
-- SEÇÃO 1: CONTAS ASAAS
-- =====================================================================

-- Tabela de Contas Asaas
CREATE TABLE public.asaas_accounts (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.iam_profiles(id) ON DELETE CASCADE,
    asaas_account_id TEXT UNIQUE NOT NULL,
    api_key TEXT NOT NULL, -- Criptografado
    account_status TEXT DEFAULT 'PENDING', -- PENDING, ACTIVE, SUSPENDED, CANCELLED
    account_type TEXT DEFAULT 'MERCHANT', -- MERCHANT, MARKETPLACE
    wallet_id TEXT,
    webhook_url TEXT,
    webhook_token TEXT,
    onboarding_status TEXT DEFAULT 'PENDING',
    onboarding_data JSONB, -- Dados do processo de onboarding
    verification_status TEXT, -- AWAITING_DOCUMENTATION, UNDER_ANALYSIS, APPROVED, REJECTED
    account_settings JSONB, -- Configurações da conta
    fees_configuration JSONB, -- Configuração de taxas
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.asaas_accounts IS 'Contas de integração com Asaas.';
COMMENT ON COLUMN public.asaas_accounts.profile_id IS 'FK para iam_profiles.id - proprietário da conta.';
COMMENT ON COLUMN public.asaas_accounts.asaas_account_id IS 'ID único da conta no Asaas.';
COMMENT ON COLUMN public.asaas_accounts.api_key IS 'Chave da API do Asaas (criptografada).';
COMMENT ON COLUMN public.asaas_accounts.wallet_id IS 'ID da carteira no Asaas.';
COMMENT ON COLUMN public.asaas_accounts.verification_status IS 'Status de verificação da conta.';

-- Tabela de Clientes Asaas
CREATE TABLE public.asaas_customers (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    asaas_account_id UUID NOT NULL REFERENCES public.asaas_accounts(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES public.iam_profiles(id) ON DELETE SET NULL,
    asaas_customer_id TEXT UNIQUE NOT NULL,
    customer_name TEXT NOT NULL,
    customer_email TEXT,
    customer_phone TEXT,
    customer_cpf_cnpj TEXT,
    customer_type TEXT, -- INDIVIDUAL, ORGANIZATION
    address JSONB, -- Endereço do cliente
    customer_data JSONB, -- Dados completos do cliente
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.asaas_customers IS 'Clientes cadastrados no Asaas.';
COMMENT ON COLUMN public.asaas_customers.asaas_account_id IS 'FK para asaas_accounts.id.';
COMMENT ON COLUMN public.asaas_customers.profile_id IS 'FK para iam_profiles.id - perfil relacionado (opcional).';
COMMENT ON COLUMN public.asaas_customers.asaas_customer_id IS 'ID único do cliente no Asaas.';
COMMENT ON COLUMN public.asaas_customers.customer_cpf_cnpj IS 'CPF ou CNPJ do cliente.';

-- Tabela de Pagamentos Asaas
CREATE TABLE public.asaas_payments (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    asaas_account_id UUID NOT NULL REFERENCES public.asaas_accounts(id) ON DELETE CASCADE,
    asaas_customer_id UUID NOT NULL REFERENCES public.asaas_customers(id) ON DELETE RESTRICT,
    marketplace_payment_id UUID,
    asaas_payment_id TEXT UNIQUE NOT NULL,
    billing_type TEXT NOT NULL, -- BOLETO, CREDIT_CARD, PIX, UNDEFINED
    payment_status TEXT DEFAULT 'PENDING', -- PENDING, RECEIVED, CONFIRMED, OVERDUE, REFUNDED, etc.
    value_cents INTEGER NOT NULL,
    net_value_cents INTEGER, -- Valor líquido após taxas
    original_value_cents INTEGER, -- Valor original antes de descontos
    interest_value_cents INTEGER, -- Valor de juros
    description TEXT,
    external_reference TEXT, -- Referência externa
    due_date DATE NOT NULL,
    payment_date DATE,
    credit_date DATE, -- Data de crédito
    estimated_credit_date DATE,
    installment_count INTEGER DEFAULT 1,
    installment_number INTEGER DEFAULT 1,
    installment_value_cents INTEGER,
    discount JSONB, -- Configuração de desconto
    fine JSONB, -- Configuração de multa
    interest JSONB, -- Configuração de juros
    payment_link TEXT, -- Link para pagamento
    bank_slip_url TEXT, -- URL do boleto
    invoice_url TEXT, -- URL da fatura
    pix_transaction JSONB, -- Dados da transação PIX
    credit_card JSONB, -- Dados do cartão de crédito
    asaas_response JSONB, -- Resposta completa do Asaas
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.asaas_payments IS 'Pagamentos processados pelo Asaas.';
COMMENT ON COLUMN public.asaas_payments.asaas_account_id IS 'FK para asaas_accounts.id.';
COMMENT ON COLUMN public.asaas_payments.asaas_customer_id IS 'FK para asaas_customers.id.';
COMMENT ON COLUMN public.asaas_payments.asaas_payment_id IS 'ID único do pagamento no Asaas.';
COMMENT ON COLUMN public.asaas_payments.billing_type IS 'Tipo de cobrança: BOLETO, CREDIT_CARD, PIX, UNDEFINED.';
COMMENT ON COLUMN public.asaas_payments.value_cents IS 'Valor do pagamento em centavos.';
COMMENT ON COLUMN public.asaas_payments.net_value_cents IS 'Valor líquido após taxas em centavos.';

-- Tabela de Webhooks Asaas
CREATE TABLE public.asaas_webhooks (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    asaas_account_id UUID REFERENCES public.asaas_accounts(id) ON DELETE SET NULL,
    webhook_event TEXT NOT NULL,
    webhook_data JSONB NOT NULL,
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMPTZ,
    processing_error TEXT,
    retry_count INTEGER DEFAULT 0,
    signature_valid BOOLEAN,
    raw_payload TEXT, -- Payload bruto recebido
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.asaas_webhooks IS 'Webhooks recebidos do Asaas.';
COMMENT ON COLUMN public.asaas_webhooks.webhook_event IS 'Tipo do evento do webhook.';
COMMENT ON COLUMN public.asaas_webhooks.webhook_data IS 'Dados do webhook em JSON.';
COMMENT ON COLUMN public.asaas_webhooks.processed IS 'Indica se o webhook foi processado.';
COMMENT ON COLUMN public.asaas_webhooks.signature_valid IS 'Indica se a assinatura do webhook é válida.';

-- Índices para performance
CREATE INDEX idx_asaas_accounts_profile_id ON public.asaas_accounts(profile_id);
CREATE INDEX idx_asaas_accounts_asaas_account_id ON public.asaas_accounts(asaas_account_id);
CREATE INDEX idx_asaas_accounts_account_status ON public.asaas_accounts(account_status);
CREATE INDEX idx_asaas_accounts_verification_status ON public.asaas_accounts(verification_status);

CREATE INDEX idx_asaas_customers_asaas_account_id ON public.asaas_customers(asaas_account_id);
CREATE INDEX idx_asaas_customers_profile_id ON public.asaas_customers(profile_id);
CREATE INDEX idx_asaas_customers_asaas_customer_id ON public.asaas_customers(asaas_customer_id);
CREATE INDEX idx_asaas_customers_customer_cpf_cnpj ON public.asaas_customers(customer_cpf_cnpj);

CREATE INDEX idx_asaas_payments_asaas_account_id ON public.asaas_payments(asaas_account_id);
CREATE INDEX idx_asaas_payments_asaas_customer_id ON public.asaas_payments(asaas_customer_id);
CREATE INDEX idx_asaas_payments_marketplace_payment_id ON public.asaas_payments(marketplace_payment_id);
CREATE INDEX idx_asaas_payments_asaas_payment_id ON public.asaas_payments(asaas_payment_id);
CREATE INDEX idx_asaas_payments_payment_status ON public.asaas_payments(payment_status);
CREATE INDEX idx_asaas_payments_billing_type ON public.asaas_payments(billing_type);
CREATE INDEX idx_asaas_payments_due_date ON public.asaas_payments(due_date);
CREATE INDEX idx_asaas_payments_payment_date ON public.asaas_payments(payment_date);

CREATE INDEX idx_asaas_webhooks_asaas_account_id ON public.asaas_webhooks(asaas_account_id);
CREATE INDEX idx_asaas_webhooks_webhook_event ON public.asaas_webhooks(webhook_event);
CREATE INDEX idx_asaas_webhooks_processed ON public.asaas_webhooks(processed);
CREATE INDEX idx_asaas_webhooks_created_at ON public.asaas_webhooks(created_at);

-- =====================================================================
-- SEÇÃO 2: TRIGGERS PARA UPDATED_AT
-- =====================================================================

-- Triggers para atualizar updated_at automaticamente
CREATE TRIGGER on_asaas_accounts_update
BEFORE UPDATE ON public.asaas_accounts
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_asaas_customers_update
BEFORE UPDATE ON public.asaas_customers
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_asaas_payments_update
BEFORE UPDATE ON public.asaas_payments
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_asaas_webhooks_update
BEFORE UPDATE ON public.asaas_webhooks
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- =====================================================================
-- ARQUITETURA FINANCEIRA DA PLATAFORMA E SUB-CONTAS
-- Descrição: Cria as tabelas para controle financeiro da plataforma
-- e para o histórico de saldo das sub-contas.
-- =====================================================================

-- =====================================================================
-- SEÇÃO 1: TABELAS DA CONTA MASTER (PLATAFORMA TRICKET)
-- =====================================================================

-- Tabela: asaas_platform_financial_transactions
-- Registra todas as movimentações financeiras da conta principal da Tricket.
CREATE TABLE public.asaas_platform_financial_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asaas_transaction_id TEXT NOT NULL UNIQUE,
    transaction_type TEXT NOT NULL, -- Ex: 'FEE_MERCHANT', 'PLATFORM_PAYOUT'
    description TEXT,
    value_cents BIGINT NOT NULL,
    related_payment_id UUID REFERENCES public.asaas_payments(id) ON DELETE SET NULL,
    related_profile_id UUID REFERENCES public.iam_profiles(id) ON DELETE SET NULL,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT now(),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.asaas_platform_financial_transactions IS 'Registra todas as transações da conta master da Tricket (taxas, pagamentos, etc.).';
COMMENT ON COLUMN public.asaas_platform_financial_transactions.asaas_transaction_id IS 'ID da transferência ou lançamento correspondente na API do Asaas.';
COMMENT ON COLUMN public.asaas_platform_financial_transactions.transaction_type IS 'Categoriza a transação (ex: FEE_MERCHANT, PLATFORM_PAYOUT). Idealmente, seria um ENUM.';
COMMENT ON COLUMN public.asaas_platform_financial_transactions.value_cents IS 'Valor da transação em centavos. Pode ser positivo (crédito) ou negativo (débito).';
COMMENT ON COLUMN public.asaas_platform_financial_transactions.related_payment_id IS 'FK para a transação do cliente que originou esta movimentação (se aplicável).';
COMMENT ON COLUMN public.asaas_platform_financial_transactions.related_profile_id IS 'FK para o perfil do cliente relacionado a esta movimentação (se aplicável).';


-- Tabela: asaas_platform_balance_history
-- Armazena o histórico de saldo da conta principal da Tricket.
CREATE TABLE public.asaas_platform_balance_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    snapshot_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    balance_cents BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.asaas_platform_balance_history IS 'Armazena snapshots periódicos do saldo da conta master da Tricket para performance e análise.';
COMMENT ON COLUMN public.asaas_platform_balance_history.snapshot_at IS 'Data e hora em que o saldo foi registrado.';
COMMENT ON COLUMN public.asaas_platform_balance_history.balance_cents IS 'Saldo total da conta em centavos no momento do snapshot.';


-- =====================================================================
-- SEÇÃO 2: TABELA DAS SUB-CONTAS (CLIENTES)
-- =====================================================================

-- Tabela: subaccount_balance_history
-- Armazena o histórico de saldo para cada sub-conta de cliente.
CREATE TABLE public.subaccount_balance_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asaas_account_id UUID NOT NULL REFERENCES public.asaas_accounts(id) ON DELETE CASCADE,
    snapshot_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    balance_cents BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (asaas_account_id, snapshot_at)
);

COMMENT ON TABLE public.subaccount_balance_history IS 'Armazena snapshots periódicos do saldo de cada sub-conta de cliente.';
COMMENT ON COLUMN public.subaccount_balance_history.asaas_account_id IS 'FK que identifica a qual sub-conta este registro de saldo pertence.';
COMMENT ON COLUMN public.subaccount_balance_history.snapshot_at IS 'Data e hora em que o saldo foi registrado.';
COMMENT ON COLUMN public.subaccount_balance_history.balance_cents IS 'Saldo total da sub-conta em centavos no momento do snapshot.';
COMMENT ON CONSTRAINT subaccount_balance_history_asaas_account_id_snapshot_at_key ON public.subaccount_balance_history IS 'Garante que não haja mais de um registro de saldo para a mesma conta no mesmo instante.';


-- =====================================================================
-- SEÇÃO 3: ÍNDICES E TRIGGERS
-- =====================================================================

-- Índices para performance de consulta
CREATE INDEX idx_platform_transactions_related_payment_id ON public.asaas_platform_financial_transactions(related_payment_id);
CREATE INDEX idx_platform_transactions_transaction_date ON public.asaas_platform_financial_transactions(transaction_date);
CREATE INDEX idx_platform_balance_snapshot_at ON public.asaas_platform_balance_history(snapshot_at);
CREATE INDEX idx_subaccount_balance_asaas_account_id ON public.subaccount_balance_history(asaas_account_id);
CREATE INDEX idx_subaccount_balance_snapshot_at ON public.subaccount_balance_history(snapshot_at);

-- Trigger para atualizar o campo `updated_at` (assumindo que a função public.handle_updated_at já existe)
CREATE TRIGGER on_platform_transactions_update
BEFORE UPDATE ON public.asaas_platform_financial_transactions
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();