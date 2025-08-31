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