-- =================================================================
-- 1050_seed_cappta.sql
-- Objetivo: Contas Cappta e transações simuladas.
-- =================================================================

-- Contas Cappta
INSERT INTO public.cappta_accounts (
    id, profile_id, cappta_account_id, account_status, account_type, merchant_id, terminal_id,
    api_key, secret_key, webhook_url, webhook_secret, onboarding_status
) VALUES
    ('4b000000-0000-0000-0000-00000000010f','20000000-0000-0000-0000-0000000000c1','acc_alfa_cappta','ACTIVE','MERCHANT','mrc_alfa','term_alfa','sk_cappta_alfa','sec_cappta_alfa','https://webhooks.tricket.dev/cappta/alfa','whcappta_alfa','APPROVED'),
    ('4b000000-0000-0000-0000-000000000110','20000000-0000-0000-0000-0000000000c2','acc_beta_cappta','ACTIVE','MERCHANT','mrc_beta','term_beta','sk_cappta_beta','sec_cappta_beta','https://webhooks.tricket.dev/cappta/beta','whcappta_beta','APPROVED')
ON CONFLICT (id) DO NOTHING;

-- Transações
INSERT INTO public.cappta_transactions (
    id, cappta_account_id, cappta_transaction_id, transaction_type, transaction_status,
    amount_cents, currency_code, payment_method, card_brand, card_last_digits,
    authorization_code, nsu, tid, installments, merchant_fee_cents, gateway_fee_cents,
    net_amount_cents, settlement_date
) VALUES
    ('4c000000-0000-0000-0000-000000000111','4b000000-0000-0000-0000-00000000010f','trx_alfa_001','PAYMENT','APPROVED', 599,'BRL','CREDIT_CARD','VISA','1234','A1B2C3','000123','TID123',1, 30, 10, 559, now()::date),
    ('4c000000-0000-0000-0000-000000000112','4b000000-0000-0000-0000-000000000110','trx_beta_001','PAYMENT','APPROVED', 579,'BRL','DEBIT_CARD','MASTERCARD','9876','D4E5F6','000456','TID456',1, 25, 8, 546, now()::date)
ON CONFLICT (id) DO NOTHING;

-- Webhook simulado
INSERT INTO public.cappta_webhooks (id, cappta_account_id, webhook_event, webhook_data, processed, signature_valid)
VALUES ('4d000000-0000-0000-0000-000000000113','4b000000-0000-0000-0000-00000000010f','TRANSACTION_APPROVED','{"transactionId":"trx_alfa_001"}'::jsonb,false,true)
ON CONFLICT (id) DO NOTHING;
