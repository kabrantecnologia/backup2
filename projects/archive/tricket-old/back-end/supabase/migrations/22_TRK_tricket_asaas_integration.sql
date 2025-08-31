-- Arquivo: 17_tricket_asaas_integration.sql
-- Descrição: Integração com Asaas - contas, clientes, pagamentos e webhooks
-- Versão: 1.0
-- Autor: Cascade

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
-- SEÇÃO 3: FUNÇÕES AUXILIARES
-- =====================================================================

-- Função para processar webhook Asaas
CREATE OR REPLACE FUNCTION public.process_asaas_webhook(webhook_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    webhook_record RECORD;
    payment_id TEXT;
    customer_id TEXT;
    account_id UUID;
BEGIN
    -- Buscar o webhook
    SELECT * INTO webhook_record FROM public.asaas_webhooks WHERE id = webhook_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Extrair dados do webhook
    payment_id := webhook_record.webhook_data->>'payment';
    customer_id := webhook_record.webhook_data->>'customer';
    
    -- Buscar a conta Asaas relacionada
    SELECT id INTO account_id 
    FROM public.asaas_accounts 
    WHERE asaas_account_id = webhook_record.webhook_data->>'account';
    
    -- Processar baseado no tipo de evento
    CASE webhook_record.webhook_event
        WHEN 'PAYMENT_CREATED' THEN
            -- Criar ou atualizar pagamento
            INSERT INTO public.asaas_payments (
                asaas_account_id, 
                asaas_customer_id,
                asaas_payment_id,
                billing_type,
                payment_status,
                value_cents,
                due_date,
                asaas_response
            ) VALUES (
                account_id,
                (SELECT id FROM public.asaas_customers WHERE asaas_customer_id = customer_id),
                payment_id,
                webhook_record.webhook_data->>'billingType',
                webhook_record.webhook_data->>'status',
                ((webhook_record.webhook_data->>'value')::DECIMAL * 100)::INTEGER,
                (webhook_record.webhook_data->>'dueDate')::DATE,
                webhook_record.webhook_data
            ) ON CONFLICT (asaas_payment_id) DO UPDATE SET
                payment_status = EXCLUDED.payment_status,
                asaas_response = EXCLUDED.asaas_response;
                
        WHEN 'PAYMENT_RECEIVED' THEN
            -- Atualizar status do pagamento para recebido
            UPDATE public.asaas_payments 
            SET payment_status = 'RECEIVED',
                payment_date = (webhook_record.webhook_data->>'paymentDate')::DATE,
                net_value_cents = ((webhook_record.webhook_data->>'netValue')::DECIMAL * 100)::INTEGER,
                asaas_response = webhook_record.webhook_data
            WHERE asaas_payment_id = payment_id;
            
        WHEN 'PAYMENT_CONFIRMED' THEN
            -- Atualizar status do pagamento para confirmado
            UPDATE public.asaas_payments 
            SET payment_status = 'CONFIRMED',
                credit_date = (webhook_record.webhook_data->>'creditDate')::DATE,
                asaas_response = webhook_record.webhook_data
            WHERE asaas_payment_id = payment_id;
            
        WHEN 'PAYMENT_OVERDUE' THEN
            -- Atualizar status do pagamento para vencido
            UPDATE public.asaas_payments 
            SET payment_status = 'OVERDUE',
                asaas_response = webhook_record.webhook_data
            WHERE asaas_payment_id = payment_id;
            
        ELSE
            -- Evento não reconhecido, apenas logar
            NULL;
    END CASE;
    
    -- Marcar webhook como processado
    UPDATE public.asaas_webhooks 
    SET processed = TRUE, 
        processed_at = now() 
    WHERE id = webhook_id;
    
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Em caso de erro, atualizar o webhook com o erro
        UPDATE public.asaas_webhooks 
        SET processing_error = SQLERRM,
            retry_count = retry_count + 1
        WHERE id = webhook_id;
        
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- Função para sincronizar cliente Asaas com perfil
CREATE OR REPLACE FUNCTION public.sync_asaas_customer_with_profile(
    p_asaas_customer_id UUID,
    p_profile_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    customer_record RECORD;
    profile_record RECORD;
BEGIN
    -- Buscar o cliente Asaas
    SELECT * INTO customer_record FROM public.asaas_customers WHERE id = p_asaas_customer_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Buscar o perfil
    SELECT * INTO profile_record FROM public.profile_users WHERE id = p_profile_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Atualizar a associação
    UPDATE public.asaas_customers 
    SET profile_id = p_profile_id,
        updated_at = now()
    WHERE id = p_asaas_customer_id;
    
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';
