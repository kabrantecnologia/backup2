-- =================================================================
-- 1040_seed_asaas.sql
-- Objetivo: Contas Asaas para fornecedores e alguns clientes/pagamentos de exemplo.
-- =================================================================

-- Contas Asaas (uma por fornecedor)
INSERT INTO public.asaas_accounts (
    id, profile_id, asaas_account_id, api_key, account_status, account_type, wallet_id,
    webhook_url, webhook_token, onboarding_status, verification_status
) VALUES
    ('47000000-0000-0000-0000-000000000108','20000000-0000-0000-0000-0000000000c1','acc_alfa_asaas','sk_test_alfa','ACTIVE','MERCHANT','wallet_alfa','https://webhooks.tricket.dev/asaas/alfa','whsec_alfa','APPROVED','APPROVED'),
    ('47000000-0000-0000-0000-000000000109','20000000-0000-0000-0000-0000000000c2','acc_beta_asaas','sk_test_beta','ACTIVE','MERCHANT','wallet_beta','https://webhooks.tricket.dev/asaas/beta','whsec_beta','APPROVED','APPROVED')
ON CONFLICT (id) DO NOTHING;

-- Clientes Asaas (ligados genericamente a PFs)
INSERT INTO public.asaas_customers (
    id, asaas_account_id, profile_id, asaas_customer_id, customer_name, customer_email,
    customer_phone, customer_cpf_cnpj, customer_type, address
) VALUES
    ('48000000-0000-0000-0000-00000000010a','47000000-0000-0000-0000-000000000108','10000000-0000-0000-0000-0000000000b1','cust_pf1','Fulano de Tal','pf1@tricket.dev','+55 11 99999-0001','11122233344','INDIVIDUAL','{"city":"São Paulo","zip":"01001-000"}'::jsonb),
    ('48000000-0000-0000-0000-00000000010b','47000000-0000-0000-0000-000000000109','10000000-0000-0000-0000-0000000000b2','cust_pf2','Ciclana de Tal','pf2@tricket.dev','+55 11 99999-0002','55566677788','INDIVIDUAL','{"city":"Rio de Janeiro","zip":"20040-010"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- Pagamentos Asaas
INSERT INTO public.asaas_payments (
    id, asaas_account_id, asaas_customer_id, asaas_payment_id, billing_type, payment_status,
    value_cents, description, due_date, installment_count, installment_number
) VALUES
    ('49000000-0000-0000-0000-00000000010c','47000000-0000-0000-0000-000000000108','48000000-0000-0000-0000-00000000010a','pay_alfa_001','PIX','CONFIRMED', 1599,'Pedido #ALFA-0001', now()::date, 1, 1),
    ('49000000-0000-0000-0000-00000000010d','47000000-0000-0000-0000-000000000109','48000000-0000-0000-0000-00000000010b','pay_beta_001','CREDIT_CARD','RECEIVED', 579,'Pedido #BETA-0001', now()::date, 1, 1)
ON CONFLICT (id) DO NOTHING;

-- Webhook simulado
INSERT INTO public.asaas_webhooks (id, asaas_account_id, webhook_event, webhook_data, processed, signature_valid)
VALUES ('4a000000-0000-0000-0000-00000000010e','47000000-0000-0000-0000-000000000108','PAYMENT_CONFIRMED','{"paymentId":"pay_alfa_001"}'::jsonb,false,true)
ON CONFLICT (id) DO NOTHING;
