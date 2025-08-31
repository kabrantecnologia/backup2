-- =================================================================
-- 1010_seed_iam_addresses_contacts.sql
-- Objetivo: Endereços e contatos básicos para perfis PF e PJ criados em 1000.
-- =================================================================

-- Endereços para PFs
INSERT INTO public.iam_addresses (
    id, profile_id, address_type, is_default, street, number, complement,
    neighborhood, city_id, state_id, zip_code, country, notes, latitude, longitude
) VALUES
    ('30000000-0000-0000-0000-0000000000d1','10000000-0000-0000-0000-0000000000b1','MAIN', true,'Rua Alfa','100','Ap 11','Centro',3828,26,'01001-000','Brasil','Endereço PF1',-23.55052,-46.63331),
    ('30000000-0000-0000-0000-0000000000d2','10000000-0000-0000-0000-0000000000b2','MAIN', true,'Rua Beta','200',NULL,'Bairro B',3241,19,'20040-010','Brasil','Endereço PF2',-22.90685,-43.17290),
    ('30000000-0000-0000-0000-0000000000d3','20000000-0000-0000-0000-0000000000c1','MAIN', true,'Av. Fornecedor','1000','Sala 101','Distrito Ind.',3828,26,'04538-132','Brasil','Endereço PJ1',-23.59531,-46.68525),
    ('30000000-0000-0000-0000-0000000000d4','20000000-0000-0000-0000-0000000000c2','MAIN', true,'Alameda Beta','500',NULL,'Parque Tec',3241,19,'22250-040','Brasil','Endereço PJ2',-22.96424,-43.19028)
ON CONFLICT (id) DO NOTHING;

-- Contatos (usar iam_contacts se existir)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema='public' AND table_name='iam_contacts'
    ) THEN
        INSERT INTO public.iam_contacts (id, profile_id, name, label, email, phone, is_default)
        VALUES
            ('31000000-0000-0000-0000-0000000000e1','10000000-0000-0000-0000-0000000000b1','Fulano de Tal','PERSONAL','pf1@tricket.dev','+55 11 99999-0001', true),
            ('31000000-0000-0000-0000-0000000000e2','10000000-0000-0000-0000-0000000000b2','Ciclana de Tal','PERSONAL','pf2@tricket.dev','+55 11 99999-0002', true),
            ('31000000-0000-0000-0000-0000000000e3','20000000-0000-0000-0000-0000000000c1','Contato Alfa','BUSINESS','contato@fornecedor-alfa.dev','+55 11 4000-1001', true),
            ('31000000-0000-0000-0000-0000000000e4','20000000-0000-0000-0000-0000000000c2','Contato Beta','BUSINESS','contato@fornecedor-beta.dev','+55 11 4000-1002', true)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END$$;
