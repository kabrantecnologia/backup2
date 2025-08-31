-- =====================================================================
-- MIGRATION: 581 - RPC Functions para Operações Cappta
-- Data: 2025-08-19
-- Descrição: Implementa funções RPC para integração completa com Cappta
-- =====================================================================

-- =====================================================================
-- SEÇÃO 1: RPC PARA REGISTRO DE MERCHANT
-- =====================================================================

CREATE OR REPLACE FUNCTION public.cappta_register_merchant(
    p_profile_id UUID,
    p_merchant_data JSONB
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_account_id UUID;
    v_profile_record RECORD;
    v_existing_account RECORD;
BEGIN
    -- Validar se profile existe e é do tipo PJ
    SELECT * INTO v_profile_record 
    FROM public.iam_profiles 
    WHERE id = p_profile_id AND profile_type = 'PJ' AND status = 'ACTIVE';
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'PROFILE_NOT_FOUND',
            'message', 'Profile não encontrado ou não é do tipo PJ ativo'
        );
    END IF;

    -- Verificar se já existe conta Cappta para este profile
    SELECT * INTO v_existing_account 
    FROM public.cappta_accounts 
    WHERE profile_id = p_profile_id;
    
    IF FOUND THEN
        -- Atualizar dados existentes
        UPDATE public.cappta_accounts 
        SET 
            onboarding_data = p_merchant_data,
            updated_at = now()
        WHERE profile_id = p_profile_id
        RETURNING id INTO v_account_id;
        
        v_result := jsonb_build_object(
            'success', true,
            'action', 'updated',
            'account_id', v_account_id,
            'profile_id', p_profile_id,
            'merchant_data', p_merchant_data
        );
    ELSE
        -- Criar nova conta Cappta
        INSERT INTO public.cappta_accounts (
            profile_id,
            cappta_account_id,
            account_status,
            account_type,
            onboarding_status,
            onboarding_data
        ) VALUES (
            p_profile_id,
            'pending_' || p_profile_id::text, -- Temporário até resposta da API
            'PENDING',
            'MERCHANT',
            'PENDING',
            p_merchant_data
        ) RETURNING id INTO v_account_id;
        
        v_result := jsonb_build_object(
            'success', true,
            'action', 'created',
            'account_id', v_account_id,
            'profile_id', p_profile_id,
            'merchant_data', p_merchant_data
        );
    END IF;

    -- Log da operação
    INSERT INTO public.cappta_api_responses (
        cappta_account_id,
        endpoint,
        http_method,
        request_data,
        response_status,
        response_data
    ) VALUES (
        v_account_id,
        '/merchants',
        'POST',
        p_merchant_data,
        200,
        v_result
    );

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'DATABASE_ERROR',
            'message', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.cappta_register_merchant IS 'Registra ou atualiza merchant na integração Cappta';

-- =====================================================================
-- SEÇÃO 2: RPC PARA ATUALIZAR CONTA COM RESPOSTA DA API CAPPTA
-- =====================================================================

CREATE OR REPLACE FUNCTION public.cappta_update_merchant_response(
    p_profile_id UUID,
    p_cappta_merchant_id TEXT,
    p_api_response JSONB
) RETURNS JSONB AS $$
DECLARE
    v_account_id UUID;
    v_result JSONB;
BEGIN
    -- Atualizar conta com dados da resposta da Cappta
    UPDATE public.cappta_accounts 
    SET 
        cappta_account_id = p_cappta_merchant_id,
        merchant_id = p_cappta_merchant_id,
        account_status = CASE 
            WHEN (p_api_response->>'status')::text = 'active' THEN 'ACTIVE'
            ELSE 'PENDING'
        END,
        onboarding_status = 'COMPLETED',
        account_settings = p_api_response,
        updated_at = now()
    WHERE profile_id = p_profile_id
    RETURNING id INTO v_account_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'ACCOUNT_NOT_FOUND',
            'message', 'Conta Cappta não encontrada para este profile'
        );
    END IF;

    v_result := jsonb_build_object(
        'success', true,
        'account_id', v_account_id,
        'cappta_merchant_id', p_cappta_merchant_id,
        'status', 'updated'
    );

    -- Log da atualização
    INSERT INTO public.cappta_api_responses (
        cappta_account_id,
        endpoint,
        http_method,
        request_data,
        response_status,
        response_data
    ) VALUES (
        v_account_id,
        '/merchants/update',
        'PUT',
        jsonb_build_object('cappta_merchant_id', p_cappta_merchant_id),
        200,
        p_api_response
    );

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'DATABASE_ERROR',
            'message', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.cappta_update_merchant_response IS 'Atualiza conta Cappta com resposta da API';

-- =====================================================================
-- SEÇÃO 3: RPC PARA PROCESSAR WEBHOOK DE TRANSAÇÃO
-- =====================================================================

CREATE OR REPLACE FUNCTION public.cappta_process_transaction_webhook(
    p_webhook_data JSONB
) RETURNS JSONB AS $$
DECLARE
    v_transaction_id UUID;
    v_merchant_account UUID;
    v_cappta_transaction_id TEXT;
    v_merchant_id TEXT;
    v_result JSONB;
    v_existing_transaction RECORD;
BEGIN
    -- Extrair dados do webhook
    v_cappta_transaction_id := p_webhook_data->>'transaction_id';
    v_merchant_id := p_webhook_data->>'merchant_id';
    
    IF v_cappta_transaction_id IS NULL OR v_merchant_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'INVALID_WEBHOOK_DATA',
            'message', 'transaction_id ou merchant_id ausente no webhook'
        );
    END IF;

    -- Buscar conta Cappta do merchant
    SELECT id INTO v_merchant_account 
    FROM public.cappta_accounts 
    WHERE merchant_id = v_merchant_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'MERCHANT_NOT_FOUND',
            'message', 'Merchant não encontrado: ' || v_merchant_id
        );
    END IF;

    -- Verificar se transação já existe (idempotência)
    SELECT * INTO v_existing_transaction 
    FROM public.cappta_transactions 
    WHERE cappta_transaction_id = v_cappta_transaction_id;
    
    IF FOUND THEN
        -- Atualizar transação existente
        UPDATE public.cappta_transactions 
        SET 
            transaction_status = COALESCE(p_webhook_data->>'status', transaction_status),
            transaction_data = p_webhook_data,
            cappta_response = p_webhook_data,
            updated_at = now()
        WHERE cappta_transaction_id = v_cappta_transaction_id
        RETURNING id INTO v_transaction_id;
        
        v_result := jsonb_build_object(
            'success', true,
            'action', 'updated',
            'transaction_id', v_transaction_id
        );
    ELSE
        -- Criar nova transação
        INSERT INTO public.cappta_transactions (
            cappta_account_id,
            cappta_transaction_id,
            transaction_type,
            transaction_status,
            amount_cents,
            currency_code,
            payment_method,
            card_brand,
            authorization_code,
            nsu,
            installments,
            merchant_fee_cents,
            net_amount_cents,
            settlement_date,
            transaction_data,
            cappta_response
        ) VALUES (
            v_merchant_account,
            v_cappta_transaction_id,
            COALESCE(p_webhook_data->>'transaction_type', 'PAYMENT'),
            COALESCE(p_webhook_data->>'status', 'PENDING'),
            (p_webhook_data->>'amount_cents')::integer,
            COALESCE(p_webhook_data->>'currency', 'BRL'),
            p_webhook_data->>'payment_method',
            p_webhook_data->>'card_brand',
            p_webhook_data->>'authorization_code',
            p_webhook_data->>'nsu',
            COALESCE((p_webhook_data->>'installments')::integer, 1),
            (p_webhook_data->>'merchant_fee_cents')::integer,
            (p_webhook_data->>'net_amount_cents')::integer,
            CASE 
                WHEN p_webhook_data->>'settlement_date' IS NOT NULL 
                THEN (p_webhook_data->>'settlement_date')::date
                ELSE NULL
            END,
            p_webhook_data,
            p_webhook_data
        ) RETURNING id INTO v_transaction_id;
        
        v_result := jsonb_build_object(
            'success', true,
            'action', 'created',
            'transaction_id', v_transaction_id
        );
    END IF;

    -- Registrar webhook recebido
    INSERT INTO public.cappta_webhooks (
        cappta_account_id,
        webhook_event,
        webhook_data,
        processed,
        processed_at,
        signature_valid,
        raw_payload
    ) VALUES (
        v_merchant_account,
        'transaction.' || COALESCE(p_webhook_data->>'status', 'unknown'),
        p_webhook_data,
        true,
        now(),
        true, -- TODO: Implementar validação de assinatura
        p_webhook_data::text
    );

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        -- Registrar webhook com erro
        INSERT INTO public.cappta_webhooks (
            cappta_account_id,
            webhook_event,
            webhook_data,
            processed,
            processing_error,
            signature_valid,
            raw_payload
        ) VALUES (
            v_merchant_account,
            'transaction.error',
            p_webhook_data,
            false,
            SQLERRM,
            true,
            p_webhook_data::text
        );
        
        RETURN jsonb_build_object(
            'success', false,
            'error', 'PROCESSING_ERROR',
            'message', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.cappta_process_transaction_webhook IS 'Processa webhook de transação da Cappta';

-- =====================================================================
-- SEÇÃO 4: RPC PARA PROCESSAR LIQUIDAÇÃO
-- =====================================================================

CREATE OR REPLACE FUNCTION public.cappta_process_settlement(
    p_merchant_id TEXT,
    p_settlement_data JSONB
) RETURNS JSONB AS $$
DECLARE
    v_merchant_account UUID;
    v_settlement_id TEXT;
    v_total_amount_cents INTEGER := 0;
    v_total_fee_cents INTEGER := 0;
    v_net_amount_cents INTEGER := 0;
    v_transaction_count INTEGER := 0;
    v_result JSONB;
    v_transaction_refs TEXT[];
    v_ref TEXT;
BEGIN
    -- Buscar conta do merchant
    SELECT id INTO v_merchant_account 
    FROM public.cappta_accounts 
    WHERE merchant_id = p_merchant_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'MERCHANT_NOT_FOUND',
            'message', 'Merchant não encontrado: ' || p_merchant_id
        );
    END IF;

    -- Extrair dados da liquidação
    v_settlement_id := p_settlement_data->>'settlement_id';
    v_transaction_refs := ARRAY(SELECT jsonb_array_elements_text(p_settlement_data->'transaction_refs'));
    
    -- Calcular totais das transações incluídas
    SELECT 
        COALESCE(SUM(amount_cents), 0),
        COALESCE(SUM(merchant_fee_cents), 0),
        COALESCE(SUM(net_amount_cents), 0),
        COUNT(*)
    INTO v_total_amount_cents, v_total_fee_cents, v_net_amount_cents, v_transaction_count
    FROM public.cappta_transactions 
    WHERE cappta_account_id = v_merchant_account 
    AND cappta_transaction_id = ANY(v_transaction_refs)
    AND transaction_status = 'approved';

    -- Atualizar status das transações para 'settled'
    UPDATE public.cappta_transactions 
    SET 
        transaction_status = 'settled',
        settlement_date = COALESCE(
            (p_settlement_data->>'settlement_date')::date, 
            CURRENT_DATE
        ),
        updated_at = now()
    WHERE cappta_account_id = v_merchant_account 
    AND cappta_transaction_id = ANY(v_transaction_refs)
    AND transaction_status = 'approved';

    -- Registrar webhook de liquidação
    INSERT INTO public.cappta_webhooks (
        cappta_account_id,
        webhook_event,
        webhook_data,
        processed,
        processed_at,
        signature_valid,
        raw_payload
    ) VALUES (
        v_merchant_account,
        'settlement.completed',
        p_settlement_data,
        true,
        now(),
        true,
        p_settlement_data::text
    );

    v_result := jsonb_build_object(
        'success', true,
        'settlement_id', v_settlement_id,
        'merchant_id', p_merchant_id,
        'transaction_count', v_transaction_count,
        'total_amount_cents', v_total_amount_cents,
        'total_fee_cents', v_total_fee_cents,
        'net_amount_cents', v_net_amount_cents,
        'settlement_date', COALESCE(
            (p_settlement_data->>'settlement_date')::date, 
            CURRENT_DATE
        )
    );

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'SETTLEMENT_ERROR',
            'message', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.cappta_process_settlement IS 'Processa liquidação de transações Cappta';

-- =====================================================================
-- SEÇÃO 5: RPC PARA CONSULTAR STATUS DE MERCHANT
-- =====================================================================

CREATE OR REPLACE FUNCTION public.cappta_get_merchant_status(
    p_profile_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_account_record RECORD;
    v_transaction_stats RECORD;
    v_result JSONB;
BEGIN
    -- Buscar dados da conta
    SELECT * INTO v_account_record 
    FROM public.cappta_accounts 
    WHERE profile_id = p_profile_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'ACCOUNT_NOT_FOUND',
            'message', 'Conta Cappta não encontrada para este profile'
        );
    END IF;

    -- Buscar estatísticas de transações
    SELECT 
        COUNT(*) as total_transactions,
        COALESCE(SUM(CASE WHEN transaction_status = 'approved' THEN amount_cents ELSE 0 END), 0) as total_approved_cents,
        COALESCE(SUM(CASE WHEN transaction_status = 'settled' THEN amount_cents ELSE 0 END), 0) as total_settled_cents,
        COALESCE(SUM(CASE WHEN transaction_status = 'approved' THEN net_amount_cents ELSE 0 END), 0) as total_net_cents
    INTO v_transaction_stats
    FROM public.cappta_transactions 
    WHERE cappta_account_id = v_account_record.id;

    v_result := jsonb_build_object(
        'success', true,
        'account', jsonb_build_object(
            'id', v_account_record.id,
            'cappta_account_id', v_account_record.cappta_account_id,
            'merchant_id', v_account_record.merchant_id,
            'account_status', v_account_record.account_status,
            'onboarding_status', v_account_record.onboarding_status,
            'created_at', v_account_record.created_at,
            'updated_at', v_account_record.updated_at
        ),
        'statistics', jsonb_build_object(
            'total_transactions', v_transaction_stats.total_transactions,
            'total_approved_cents', v_transaction_stats.total_approved_cents,
            'total_settled_cents', v_transaction_stats.total_settled_cents,
            'total_net_cents', v_transaction_stats.total_net_cents
        )
    );

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'QUERY_ERROR',
            'message', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.cappta_get_merchant_status IS 'Consulta status e estatísticas de merchant Cappta';

-- =====================================================================
-- SEÇÃO 6: GRANTS E PERMISSÕES
-- =====================================================================

-- Conceder permissões para as funções
GRANT EXECUTE ON FUNCTION public.cappta_register_merchant TO authenticated;
GRANT EXECUTE ON FUNCTION public.cappta_update_merchant_response TO authenticated;
GRANT EXECUTE ON FUNCTION public.cappta_process_transaction_webhook TO authenticated;
GRANT EXECUTE ON FUNCTION public.cappta_process_settlement TO authenticated;
GRANT EXECUTE ON FUNCTION public.cappta_get_merchant_status TO authenticated;
