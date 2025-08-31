
-- ====================================================================
-- SEÇÃO 1: CONTAS CAPPTA
-- ====================================================================

-- Tabela de Contas Cappta
CREATE TABLE public.cappta_accounts (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.iam_profiles(id) ON DELETE CASCADE,
    cappta_account_id TEXT UNIQUE NOT NULL,
    account_status TEXT DEFAULT 'PENDING', -- PENDING, ACTIVE, SUSPENDED, CANCELLED
    account_type TEXT, -- MERCHANT, RESELLER
    merchant_id TEXT,
    terminal_id TEXT,
    api_key TEXT, -- Criptografado
    secret_key TEXT, -- Criptografado
    webhook_url TEXT,
    webhook_secret TEXT,
    onboarding_status TEXT DEFAULT 'PENDING',
    onboarding_data JSONB, -- Dados do processo de onboarding
    verification_documents JSONB, -- Documentos de verificação
    account_settings JSONB, -- Configurações da conta
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.cappta_accounts IS 'Contas de integração com Cappta.';
COMMENT ON COLUMN public.cappta_accounts.profile_id IS 'FK para iam_profiles.id - proprietário da conta.';
COMMENT ON COLUMN public.cappta_accounts.cappta_account_id IS 'ID único da conta na Cappta.';
COMMENT ON COLUMN public.cappta_accounts.account_status IS 'Status da conta: PENDING, ACTIVE, SUSPENDED, CANCELLED.';
COMMENT ON COLUMN public.cappta_accounts.merchant_id IS 'ID do merchant na Cappta.';
COMMENT ON COLUMN public.cappta_accounts.terminal_id IS 'ID do terminal na Cappta.';
COMMENT ON COLUMN public.cappta_accounts.onboarding_data IS 'Dados do processo de onboarding em JSON.';

-- Tabela de Transações Cappta
CREATE TABLE public.cappta_transactions (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    cappta_account_id UUID NOT NULL REFERENCES public.cappta_accounts(id) ON DELETE CASCADE,
    marketplace_payment_id UUID,
    cappta_transaction_id TEXT UNIQUE NOT NULL,
    transaction_type TEXT NOT NULL, -- PAYMENT, REFUND, CHARGEBACK
    transaction_status TEXT DEFAULT 'PENDING', -- PENDING, APPROVED, DECLINED, CANCELLED
    amount_cents INTEGER NOT NULL,
    currency_code TEXT DEFAULT 'BRL',
    payment_method TEXT, -- CREDIT_CARD, DEBIT_CARD, PIX
    card_brand TEXT, -- VISA, MASTERCARD, etc.
    card_last_digits TEXT,
    authorization_code TEXT,
    nsu TEXT, -- Número Sequencial Único
    tid TEXT, -- Transaction ID
    installments INTEGER DEFAULT 1,
    merchant_fee_cents INTEGER, -- Taxa do merchant
    gateway_fee_cents INTEGER, -- Taxa do gateway
    net_amount_cents INTEGER, -- Valor líquido
    settlement_date DATE, -- Data de liquidação
    transaction_data JSONB, -- Dados completos da transação
    cappta_response JSONB, -- Resposta completa da Cappta
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.cappta_transactions IS 'Transações processadas pela Cappta.';
COMMENT ON COLUMN public.cappta_transactions.cappta_account_id IS 'FK para cappta_accounts.id.';
COMMENT ON COLUMN public.cappta_transactions.marketplace_payment_id IS 'FK para marketplace_payments.id - pagamento relacionado.';
COMMENT ON COLUMN public.cappta_transactions.cappta_transaction_id IS 'ID único da transação na Cappta.';
COMMENT ON COLUMN public.cappta_transactions.merchant_fee_cents IS 'Taxa cobrada do merchant em centavos.';
COMMENT ON COLUMN public.cappta_transactions.net_amount_cents IS 'Valor líquido após taxas em centavos.';

-- Tabela de Webhooks Cappta
CREATE TABLE public.cappta_webhooks (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    cappta_account_id UUID REFERENCES public.cappta_accounts(id) ON DELETE SET NULL,
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
COMMENT ON TABLE public.cappta_webhooks IS 'Webhooks recebidos da Cappta.';
COMMENT ON COLUMN public.cappta_webhooks.webhook_event IS 'Tipo do evento do webhook.';
COMMENT ON COLUMN public.cappta_webhooks.webhook_data IS 'Dados do webhook em JSON.';
COMMENT ON COLUMN public.cappta_webhooks.processed IS 'Indica se o webhook foi processado.';
COMMENT ON COLUMN public.cappta_webhooks.signature_valid IS 'Indica se a assinatura do webhook é válida.';
COMMENT ON COLUMN public.cappta_webhooks.raw_payload IS 'Payload bruto recebido do webhook.';

-- Índices para performance
CREATE INDEX idx_cappta_accounts_profile_id ON public.cappta_accounts(profile_id);
CREATE INDEX idx_cappta_accounts_cappta_account_id ON public.cappta_accounts(cappta_account_id);
CREATE INDEX idx_cappta_accounts_account_status ON public.cappta_accounts(account_status);
CREATE INDEX idx_cappta_accounts_merchant_id ON public.cappta_accounts(merchant_id);

CREATE INDEX idx_cappta_transactions_cappta_account_id ON public.cappta_transactions(cappta_account_id);
CREATE INDEX idx_cappta_transactions_marketplace_payment_id ON public.cappta_transactions(marketplace_payment_id);
CREATE INDEX idx_cappta_transactions_cappta_transaction_id ON public.cappta_transactions(cappta_transaction_id);
CREATE INDEX idx_cappta_transactions_transaction_status ON public.cappta_transactions(transaction_status);
CREATE INDEX idx_cappta_transactions_created_at ON public.cappta_transactions(created_at);
CREATE INDEX idx_cappta_transactions_settlement_date ON public.cappta_transactions(settlement_date);

CREATE INDEX idx_cappta_webhooks_cappta_account_id ON public.cappta_webhooks(cappta_account_id);
CREATE INDEX idx_cappta_webhooks_webhook_event ON public.cappta_webhooks(webhook_event);
CREATE INDEX idx_cappta_webhooks_processed ON public.cappta_webhooks(processed);
CREATE INDEX idx_cappta_webhooks_created_at ON public.cappta_webhooks(created_at);

-- =====================================================================
-- SEÇÃO 2: TABELAS DE LOOKUP CAPPTA
-- =====================================================================

-- Tabela de Respostas da API Cappta (para análise e debug)
CREATE TABLE public.cappta_api_responses (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    cappta_account_id UUID REFERENCES public.cappta_accounts(id) ON DELETE SET NULL,
    endpoint TEXT NOT NULL,
    http_method TEXT NOT NULL,
    request_data JSONB,
    response_status INTEGER,
    response_data JSONB,
    response_time_ms INTEGER,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.cappta_api_responses IS 'Log de respostas da API Cappta para análise e debug.';
COMMENT ON COLUMN public.cappta_api_responses.endpoint IS 'Endpoint da API chamado.';
COMMENT ON COLUMN public.cappta_api_responses.http_method IS 'Método HTTP usado: GET, POST, PUT, DELETE.';
COMMENT ON COLUMN public.cappta_api_responses.request_data IS 'Dados enviados na requisição.';
COMMENT ON COLUMN public.cappta_api_responses.response_status IS 'Status HTTP da resposta.';
COMMENT ON COLUMN public.cappta_api_responses.response_data IS 'Dados retornados pela API.';
COMMENT ON COLUMN public.cappta_api_responses.response_time_ms IS 'Tempo de resposta em milissegundos.';

-- Índices para performance
CREATE INDEX idx_cappta_api_responses_cappta_account_id ON public.cappta_api_responses(cappta_account_id);
CREATE INDEX idx_cappta_api_responses_endpoint ON public.cappta_api_responses(endpoint);
CREATE INDEX idx_cappta_api_responses_response_status ON public.cappta_api_responses(response_status);
CREATE INDEX idx_cappta_api_responses_created_at ON public.cappta_api_responses(created_at);

-- =====================================================================
-- SEÇÃO 3: TRIGGERS PARA UPDATED_AT
-- =====================================================================

-- Triggers para atualizar updated_at automaticamente
CREATE TRIGGER on_cappta_accounts_update
BEFORE UPDATE ON public.cappta_accounts
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_cappta_transactions_update
BEFORE UPDATE ON public.cappta_transactions
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_cappta_webhooks_update
BEFORE UPDATE ON public.cappta_webhooks
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

