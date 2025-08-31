-- =====================================================================
-- SEÇÃO 4: FUNÇÕES AUXILIARES
-- =====================================================================

-- Função para calcular valor líquido da transação Cappta
CREATE OR REPLACE FUNCTION public.calculate_cappta_net_amount()
RETURNS TRIGGER AS $$
BEGIN
    -- Calcular valor líquido: valor total - taxa merchant - taxa gateway
    NEW.net_amount_cents := NEW.amount_cents - 
                           COALESCE(NEW.merchant_fee_cents, 0) - 
                           COALESCE(NEW.gateway_fee_cents, 0);
    
    -- Garantir que o valor líquido não seja negativo
    IF NEW.net_amount_cents < 0 THEN
        NEW.net_amount_cents := 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- Trigger para calcular valor líquido automaticamente
CREATE TRIGGER calculate_cappta_net_amount_trigger
BEFORE INSERT OR UPDATE ON public.cappta_transactions
FOR EACH ROW
EXECUTE PROCEDURE public.calculate_cappta_net_amount();

-- Função para processar webhook Cappta
CREATE OR REPLACE FUNCTION public.process_cappta_webhook(webhook_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    webhook_record RECORD;
    transaction_id TEXT;
    account_id UUID;
BEGIN
    -- Buscar o webhook
    SELECT * INTO webhook_record FROM public.cappta_webhooks WHERE id = webhook_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Extrair dados do webhook
    transaction_id := webhook_record.webhook_data->>'transaction_id';
    
    -- Buscar a conta Cappta relacionada
    SELECT id INTO account_id 
    FROM public.cappta_accounts 
    WHERE cappta_account_id = webhook_record.webhook_data->>'account_id';
    
    -- Processar baseado no tipo de evento
    CASE webhook_record.webhook_event
        WHEN 'transaction.approved' THEN
            -- Atualizar status da transação para aprovada
            UPDATE public.cappta_transactions 
            SET transaction_status = 'APPROVED',
                cappta_response = webhook_record.webhook_data
            WHERE cappta_transaction_id = transaction_id;
            
        WHEN 'transaction.declined' THEN
            -- Atualizar status da transação para recusada
            UPDATE public.cappta_transactions 
            SET transaction_status = 'DECLINED',
                cappta_response = webhook_record.webhook_data
            WHERE cappta_transaction_id = transaction_id;
            
        WHEN 'transaction.settled' THEN
            -- Atualizar data de liquidação
            UPDATE public.cappta_transactions 
            SET settlement_date = (webhook_record.webhook_data->>'settlement_date')::DATE,
                cappta_response = webhook_record.webhook_data
            WHERE cappta_transaction_id = transaction_id;
            
        ELSE
            -- Evento não reconhecido, apenas logar
            NULL;
    END CASE;
    
    -- Marcar webhook como processado
    UPDATE public.cappta_webhooks 
    SET processed = TRUE, 
        processed_at = now() 
    WHERE id = webhook_id;
    
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Em caso de erro, atualizar o webhook com o erro
        UPDATE public.cappta_webhooks 
        SET processing_error = SQLERRM,
            retry_count = retry_count + 1
        WHERE id = webhook_id;
        
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';
