

-- ============================================
-- MIGRAÇÃO: Asaas Master Webhook Integration
-- Descrição: Tabelas para processar webhooks da conta master Asaas
-- Autor: João Henrique Andrade - Tricket
-- ============================================

-- Tabela: master_webhook_events
-- Armazena todos os eventos recebidos da conta master Asaas
CREATE TABLE IF NOT EXISTS public.master_webhook_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB NOT NULL,
    source VARCHAR(50) DEFAULT 'asaas_master',
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMPTZ,
    processing_error TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_master_webhook_events_event_type ON public.master_webhook_events(event_type);
CREATE INDEX IF NOT EXISTS idx_master_webhook_events_processed ON public.master_webhook_events(processed);
CREATE INDEX IF NOT EXISTS idx_master_webhook_events_created_at ON public.master_webhook_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_master_webhook_events_source ON public.master_webhook_events(source);

-- Tabela: master_financial_transactions
-- Registra transações financeiras da conta master
CREATE TABLE IF NOT EXISTS public.master_financial_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_id VARCHAR(100) UNIQUE,
    event_id UUID REFERENCES public.master_webhook_events(id),
    value DECIMAL(15,2) NOT NULL,
    net_value DECIMAL(15,2),
    transfer_fee DECIMAL(15,2) DEFAULT 0,
    status VARCHAR(50),
    transfer_type VARCHAR(50),
    scheduled_date DATE,
    effective_date DATE,
    transaction_receipt_url TEXT,
    bank_account JSONB,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para transações financeiras
CREATE INDEX IF NOT EXISTS idx_master_financial_transactions_transfer_id ON public.master_financial_transactions(transfer_id);
CREATE INDEX IF NOT EXISTS idx_master_financial_transactions_status ON public.master_financial_transactions(status);
CREATE INDEX IF NOT EXISTS idx_master_financial_transactions_created_at ON public.master_financial_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_master_financial_transactions_effective_date ON public.master_financial_transactions(effective_date);

-- Tabela: asaas_accounts (extensão)
-- Adicionar campos necessários para integração com conta master
ALTER TABLE public.asaas_accounts 
ADD COLUMN IF NOT EXISTS master_account_id VARCHAR(100),
ADD COLUMN IF NOT EXISTS last_balance_update TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS subscription_id VARCHAR(100),
ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(50),
ADD COLUMN IF NOT EXISTS subscription_cycle VARCHAR(50),
ADD COLUMN IF NOT EXISTS subscription_value DECIMAL(15,2),
ADD COLUMN IF NOT EXISTS balance DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS pending_balance DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_received DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_transferred DECIMAL(15,2) DEFAULT 0;

-- Índices para asaas_accounts
CREATE INDEX IF NOT EXISTS idx_asaas_accounts_master_account_id ON public.asaas_accounts(master_account_id);
CREATE INDEX IF NOT EXISTS idx_asaas_accounts_subscription_id ON public.asaas_accounts(subscription_id);
CREATE INDEX IF NOT EXISTS idx_asaas_accounts_balance ON public.asaas_accounts(balance);
CREATE INDEX IF NOT EXISTS idx_asaas_accounts_last_balance_update ON public.asaas_accounts(last_balance_update);

-- Tabela: subscription_propagation_log
-- Log de propagação de assinaturas para subcontas
CREATE TABLE IF NOT EXISTS public.subscription_propagation_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id VARCHAR(100) NOT NULL,
    customer_id VARCHAR(100) NOT NULL,
    affected_accounts UUID[],
    propagation_status VARCHAR(50) DEFAULT 'PENDING',
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para log de propagação
CREATE INDEX IF NOT EXISTS idx_subscription_propagation_subscription_id ON public.subscription_propagation_log(subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscription_propagation_customer_id ON public.subscription_propagation_log(customer_id);
CREATE INDEX IF NOT EXISTS idx_subscription_propagation_status ON public.subscription_propagation_log(propagation_status);
CREATE INDEX IF NOT EXISTS idx_subscription_propagation_created_at ON public.subscription_propagation_log(created_at DESC);

-- Função: Atualizar timestamp automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualização automática de updated_at
CREATE TRIGGER update_master_webhook_events_updated_at
    BEFORE UPDATE ON public.master_webhook_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_master_financial_transactions_updated_at
    BEFORE UPDATE ON public.master_financial_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscription_propagation_log_updated_at
    BEFORE UPDATE ON public.subscription_propagation_log
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- View: v_master_webhook_summary
-- Visão resumida dos eventos master
CREATE OR REPLACE VIEW public.v_master_webhook_summary AS
SELECT 
    event_type,
    COUNT(*) as total_events,
    COUNT(CASE WHEN processed = true THEN 1 END) as processed_events,
    COUNT(CASE WHEN processed = false THEN 1 END) as pending_events,
    COUNT(CASE WHEN processing_error IS NOT NULL THEN 1 END) as error_events,
    MIN(created_at) as first_event_at,
    MAX(created_at) as last_event_at
FROM public.master_webhook_events
GROUP BY event_type
ORDER BY total_events DESC;


-- Comentários para documentação
COMMENT ON TABLE public.master_webhook_events IS 'Registra todos os eventos de webhook recebidos da conta master Asaas';
COMMENT ON TABLE public.master_financial_transactions IS 'Registra transações financeiras da conta master Asaas';
COMMENT ON TABLE public.subscription_propagation_log IS 'Log de propagação de assinaturas para subcontas';

COMMENT ON COLUMN public.master_webhook_events.event_type IS 'Tipo do evento recebido (ex: PAYMENT_RECEIVED, TRANSFER_COMPLETED)';
COMMENT ON COLUMN public.master_webhook_events.event_data IS 'Dados completos do evento em formato JSON';
COMMENT ON COLUMN public.master_webhook_events.processed IS 'Indica se o evento já foi processado';
