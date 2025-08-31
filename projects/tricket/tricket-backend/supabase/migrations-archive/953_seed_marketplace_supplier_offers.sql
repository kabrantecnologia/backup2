-- =================================================================
-- 1030_seed_marketplace_supplier_offers.sql
-- Objetivo: Ofertas dos fornecedores criados em 1000 para o produto de 1020.
-- =================================================================

INSERT INTO public.marketplace_supplier_products (
    id, product_id, supplier_profile_id, supplier_sku, price_cents, cost_price_cents,
    promotional_price_cents, promotion_start_date, promotion_end_date, min_order_quantity,
    status, is_active_by_supplier
) VALUES
    ('46000000-0000-0000-0000-000000000106','44000000-0000-0000-0000-000000000104','20000000-0000-0000-0000-0000000000c1','ALFA-CHOC-90', 599, 400, 499, now(), now() + interval '15 days', 1, 'ACTIVE', true),
    ('46000000-0000-0000-0000-000000000107','44000000-0000-0000-0000-000000000104','20000000-0000-0000-0000-0000000000c2','BETA-CHOC-90', 579, 420, NULL, NULL, NULL, 1, 'ACTIVE', true)
ON CONFLICT (id) DO NOTHING;
