-- -----------------------------------------
-- Tabelas de Lookup Cappta
-- -----------------------------------------

-- 7.13 MCCs Cappta (`cappta_mcc_options`)
CREATE TABLE public.cappta_mcc_options (
    id INTEGER PRIMARY KEY, -- ID fornecido pela API Cappta
    description TEXT NOT NULL UNIQUE, -- Descrição do MCC
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.cappta_mcc_options IS 'Tabela de lookup para os Códigos de Categoria de Comerciante (MCC) utilizados pela Cappta.';
COMMENT ON COLUMN public.cappta_mcc_options.id IS 'ID fornecido pela API Cappta, ex: 1, 742, 763.';
COMMENT ON COLUMN public.cappta_mcc_options.description IS 'Descrição do MCC, ex: "Padrão Gerente", "Veterinarios", "Cooperativas".';

-- 7.11 Naturezas Jurídicas Cappta (`cappta_legal_nature_options`)
CREATE TABLE public.cappta_legal_nature_options (
    id INTEGER PRIMARY KEY, -- ID fornecido pela API Cappta
    description TEXT NOT NULL UNIQUE, -- Descrição da natureza jurídica
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.cappta_legal_nature_options IS 'Tabela de lookup para as naturezas jurídicas utilizadas pela Cappta.';
COMMENT ON COLUMN public.cappta_legal_nature_options.id IS 'ID fornecido pela API Cappta, ex: 1, 2, 3, 4.';
COMMENT ON COLUMN public.cappta_legal_nature_options.description IS 'Descrição da natureza jurídica, ex: "EI", "EIRELI", "Societies", "Coperatives".';

-- 7.12 Status Cappta (`cappta_status_options`)
CREATE TABLE public.cappta_status_options (
    id INTEGER PRIMARY KEY, -- ID fornecido pela API Cappta/JSON
    description TEXT NOT NULL, -- Descrição do status
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.cappta_status_options IS 'Tabela de lookup para os diversos status utilizados pela Cappta (derivado do credenciamento_options.json).';
COMMENT ON COLUMN public.cappta_status_options.id IS 'ID fornecido, ex: 1, 2, 5, 99.';
COMMENT ON COLUMN public.cappta_status_options.description IS 'Descrição do status, ex: "Enabled", "Processing", "Error".';

-- 7.10 Tipos de Conta Cappta (`cappta_account_type_options`)
CREATE TABLE public.cappta_account_type_options (
    id INTEGER PRIMARY KEY, -- ID fornecido pela API Cappta/JSON
    description TEXT NOT NULL UNIQUE, -- Descrição/código do tipo de conta do JSON (ex: "CC", "PP")
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.cappta_account_type_options IS 'Tabela de lookup para os tipos de conta bancária utilizados pela Cappta (derivado do credenciamento_options.json).';
COMMENT ON COLUMN public.cappta_account_type_options.id IS 'ID fornecido, ex: 1, 2, 3.';
COMMENT ON COLUMN public.cappta_account_type_options.description IS 'Descrição/código do tipo de conta, ex: "CC", "PP", "PG".';

-- 7.5 Tipos de Plano Cappta (`cappta_plan_types`)
CREATE TABLE public.cappta_plan_types (
    id INTEGER PRIMARY KEY, -- ID do tipo de plano na Cappta
    description TEXT NOT NULL UNIQUE, -- Nome do tipo de plano
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.cappta_plan_types IS 'Tabela de lookup para os tipos de plano da Cappta (Partner, Reseller, Merchant).';
COMMENT ON COLUMN public.cappta_plan_types.id IS 'ID do tipo de plano na Cappta, ex: 2, 3, 4.';
COMMENT ON COLUMN public.cappta_plan_types.description IS 'Nome do tipo de plano, ex: "Partner", "Reseller", "Merchant".';

-- 7.6 Tipos de Produto Cappta (`cappta_product_types`)
CREATE TABLE public.cappta_product_types (
    id INTEGER PRIMARY KEY, -- ID do tipo de produto na Cappta
    description TEXT NOT NULL UNIQUE, -- Nome do tipo de produto
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.cappta_product_types IS 'Tabela de lookup para os tipos de produto da Cappta (POS, Online).';
COMMENT ON COLUMN public.cappta_product_types.id IS 'ID do tipo de produto na Cappta, ex: 1 para POS, 2 para Online.';
COMMENT ON COLUMN public.cappta_product_types.description IS 'Nome do tipo de produto, ex: "POS", "Online".';

-- 7.7 Esquemas de Pagamento Cappta (`cappta_payment_schemes`)
CREATE TABLE public.cappta_payment_schemes (
    id INTEGER PRIMARY KEY, -- ID do esquema na Cappta
    scheme_code TEXT, -- Código do esquema, ex: "PIX", "VCD"
    type TEXT NOT NULL, -- Modalidade: 'debit', 'credit', 'voucher'
    description TEXT NOT NULL UNIQUE, -- Descrição do esquema
    brand TEXT, -- Bandeira, ex: "Visa", "Mastercard"
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.cappta_payment_schemes IS 'Tabela de lookup para os esquemas de pagamento (bandeiras e modalidades) suportados pela Cappta.';
COMMENT ON COLUMN public.cappta_payment_schemes.id IS 'ID do esquema na Cappta, ex: 1, 2, 3...';
COMMENT ON COLUMN public.cappta_payment_schemes.scheme_code IS 'Código do esquema, ex: "PIX", "VCD", "MCC".';
COMMENT ON COLUMN public.cappta_payment_schemes.type IS 'Modalidade: ''debit'', ''credit'', ''voucher''.';
COMMENT ON COLUMN public.cappta_payment_schemes.description IS 'Descrição do esquema, ex: "Pix", "Visa Cartão de Débito", "Mastercard Cartão de Crédito".';
COMMENT ON COLUMN public.cappta_payment_schemes.brand IS 'Bandeira, ex: "Visa", "Mastercard", "Elo", "Pix".';

-- 7.3 Modelos de Dispositivos POS Cappta (`cappta_pos_device_models`)
CREATE TABLE public.cappta_pos_device_models (
    id INTEGER PRIMARY KEY, -- ID do modelo na Cappta
    name TEXT NOT NULL UNIQUE, -- Nome do modelo
    manufacturer TEXT, -- Fabricante
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.cappta_pos_device_models IS 'Tabela de lookup para os modelos de dispositivos POS homologados pela Cappta.';
COMMENT ON COLUMN public.cappta_pos_device_models.id IS 'ID do modelo na Cappta, ex: 1, 2, 3...';
COMMENT ON COLUMN public.cappta_pos_device_models.name IS 'Nome do modelo, ex: "VERIFONE - Vx685", "PAX - S920".';
COMMENT ON COLUMN public.cappta_pos_device_models.manufacturer IS 'Opcional, inferido do nome, ex: "VERIFONE", "PAX".';

-- ----------------------------------------
-- Tabelas Principais da Integração Cappta
-- ----------------------------------------

-- 7.8 Planos Cappta (`cappta_plans`)
CREATE TABLE public.cappta_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cappta_plan_id_external TEXT NOT NULL UNIQUE, -- ID do plano na API da Cappta
    name TEXT NOT NULL, -- Nome do plano
    cappta_base_plan_id_external TEXT, -- ID do plano base na Cappta, se derivado
    plan_type_id INTEGER NOT NULL REFERENCES public.cappta_plan_types(id), -- ex: 4 para "Merchant"
    product_type_id INTEGER NOT NULL REFERENCES public.cappta_product_types(id), -- ex: 1 para "POS"
    default_settlement_days INTEGER, -- Prazo de liquidação padrão em dias
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (name)
);
COMMENT ON TABLE public.cappta_plans IS 'Armazena os planos de pagamento configurados na Cappta, associados a um revendedor específico.';
COMMENT ON COLUMN public.cappta_plans.cappta_plan_id_external IS 'ID do plano na API da Cappta.';
COMMENT ON COLUMN public.cappta_plans.name IS 'Nome do plano, ex: "Plano Padrão Comerciantes Tricket".';
COMMENT ON COLUMN public.cappta_plans.cappta_base_plan_id_external IS 'Opcional, ID do plano base na Cappta, se este for derivado.';
COMMENT ON COLUMN public.cappta_plans.plan_type_id IS 'FK para cappta_plan_types.id - ex: 4 para "Merchant".';
COMMENT ON COLUMN public.cappta_plans.product_type_id IS 'FK para cappta_product_types.id - ex: 1 para "POS".';
COMMENT ON COLUMN public.cappta_plans.default_settlement_days IS 'Prazo de liquidação padrão em dias, D+X.';

-- 7.9 Configurações de Esquema do Plano Cappta (`cappta_plan_scheme_configs`)
CREATE TABLE public.cappta_plan_scheme_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cappta_plan_id UUID NOT NULL REFERENCES public.cappta_plans(id) ON DELETE CASCADE,
    cappta_payment_scheme_id INTEGER NOT NULL REFERENCES public.cappta_payment_schemes(id),
    merchant_fee_percentage NUMERIC(5,2) NOT NULL, -- Taxa percentual para o comerciante
    merchant_fixed_fee NUMERIC(10,2) DEFAULT 0.00, -- Taxa fixa para o comerciante
    settlement_days_override INTEGER, -- Prazo de liquidação específico para o esquema
    number_of_installments INTEGER DEFAULT 1, -- 1 para à vista, 2 para 2x, etc.
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (cappta_plan_id, cappta_payment_scheme_id, number_of_installments)
);
COMMENT ON TABLE public.cappta_plan_scheme_configs IS 'Tabela de ligação que detalha as taxas e condições para cada esquema de pagamento dentro de um plano Cappta específico.';
COMMENT ON COLUMN public.cappta_plan_scheme_configs.merchant_fee_percentage IS 'Taxa percentual para o comerciante neste esquema, ex: 1.99 para 1.99%.';
COMMENT ON COLUMN public.cappta_plan_scheme_configs.merchant_fixed_fee IS 'Taxa fixa para o comerciante neste esquema, opcional.';
COMMENT ON COLUMN public.cappta_plan_scheme_configs.settlement_days_override IS 'Opcional, se este esquema tiver um prazo de liquidação diferente do padrão do plano.';
COMMENT ON COLUMN public.cappta_plan_scheme_configs.number_of_installments IS 'Para crédito parcelado, 1 para à vista, 2 para 2x, etc. Default 1 para à vista.';

-- 7.2 Onboarding de Comerciantes Cappta (`cappta_merchant_onboardings`)
CREATE TABLE public.cappta_merchant_onboardings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID interno Tricket
    merchant_profile_id UUID NOT NULL REFERENCES public.iam_profiles(id),
    merchant_asaas_bank_account_id UUID NOT NULL, -- Conta Asaas do comerciante. FK to public.bank_accounts(id) to be added in 09_conta_bancaria_taxas.sql
    cappta_plan_id_assigned_external TEXT NOT NULL, -- ID externo do plano Cappta atribuído
    request_payload_cappta JSONB, -- Payload enviado para Cappta
    response_payload_cappta JSONB, -- Resposta da Cappta
    cappta_onboarding_status_id INTEGER NOT NULL,
    cappta_onboarding_status_scope TEXT NOT NULL DEFAULT 'MERCHANT_ACCREDITATION' CHECK (cappta_onboarding_status_scope = 'MERCHANT_ACCREDITATION'),
    cappta_onboarding_status_description TEXT, -- Descrição do status da Cappta
    tpv_expected_cents INTEGER, -- Volume total de processamento esperado
    cappta_merchant_external_id TEXT, -- ID do comerciante na Cappta
    last_attempt_at TIMESTAMPTZ,
    onboarding_completed_at TIMESTAMPTZ,
    error_details_cappta TEXT, -- Detalhes de erro
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    FOREIGN KEY (cappta_onboarding_status_id) REFERENCES public.cappta_status_options(id),
    UNIQUE (merchant_profile_id, cappta_plan_id_assigned_external)
);
COMMENT ON TABLE public.cappta_merchant_onboardings IS 'Gerencia o processo de cadastro (onboarding) de comerciantes na plataforma Cappta.';
COMMENT ON COLUMN public.cappta_merchant_onboardings.id IS 'ID interno da Tricket para este processo de onboarding.';
COMMENT ON COLUMN public.cappta_merchant_onboardings.merchant_profile_id IS 'FK para profiles.id - o comerciante sendo cadastrado.';
COMMENT ON COLUMN public.cappta_merchant_onboardings.merchant_asaas_bank_account_id IS 'FK para bank_accounts.id - a conta Asaas do comerciante que será usada na Cappta. Constraint a ser adicionada em 09_conta_bancaria_taxas.sql';
COMMENT ON COLUMN public.cappta_merchant_onboardings.cappta_plan_id_assigned_external IS 'ID externo do plano Cappta atribuído ao comerciante (refere-se a cappta_plans.cappta_plan_id_external).';
COMMENT ON COLUMN public.cappta_merchant_onboardings.request_payload_cappta IS 'Payload JSON completo enviado para a API de onboarding da Cappta.';
COMMENT ON COLUMN public.cappta_merchant_onboardings.response_payload_cappta IS 'Payload JSON completo da resposta da API de onboarding da Cappta.';
COMMENT ON COLUMN public.cappta_merchant_onboardings.cappta_onboarding_status_id IS 'ID do status do onboarding do comerciante na Cappta.';
COMMENT ON COLUMN public.cappta_merchant_onboardings.cappta_onboarding_status_scope IS 'Scope do status do onboarding, fixo em ''MERCHANT_ACCREDITATION''.';
COMMENT ON COLUMN public.cappta_merchant_onboardings.cappta_onboarding_status_description IS 'Descrição do status retornada pela Cappta, ex: "Processing", "Enabled".';
COMMENT ON COLUMN public.cappta_merchant_onboardings.tpv_expected_cents IS 'Volume total de processamento esperado em centavos, informado no cadastro.';
COMMENT ON COLUMN public.cappta_merchant_onboardings.cappta_merchant_external_id IS 'Opcional, se a Cappta retornar algum ID específico para o comerciante após o onboarding bem-sucedido.';
COMMENT ON COLUMN public.cappta_merchant_onboardings.last_attempt_at IS 'Timestamp da última tentativa de envio da requisição de onboarding.';
COMMENT ON COLUMN public.cappta_merchant_onboardings.onboarding_completed_at IS 'Opcional, timestamp de quando o onboarding foi concluído com sucesso.';
COMMENT ON COLUMN public.cappta_merchant_onboardings.error_details_cappta IS 'Opcional, para armazenar mensagens de erro ou detalhes se o onboarding falhar.';

-- 7.4 Dispositivos POS Cappta (`cappta_pos_devices`)
CREATE TABLE public.cappta_pos_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cappta_pos_id_external TEXT, -- ID do POS na Cappta
    merchant_profile_id UUID NOT NULL REFERENCES public.iam_profiles(id),
    model_id INTEGER NOT NULL REFERENCES public.cappta_pos_device_models(id),
    serial_key TEXT NOT NULL UNIQUE, -- Número de série da maquininha
    status_cappta_id INTEGER NOT NULL,
    status_cappta_scope TEXT NOT NULL DEFAULT 'POS_DEVICE' CHECK (status_cappta_scope = 'POS_DEVICE'),
    status_description_cappta TEXT, -- Descrição do status na Cappta
    activation_date TIMESTAMPTZ,
    last_activity_date TIMESTAMPTZ,
    notes TEXT, -- Observações internas
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    FOREIGN KEY (status_cappta_id) REFERENCES public.cappta_status_options(id)
);
COMMENT ON TABLE public.cappta_pos_devices IS 'Armazena informações sobre cada dispositivo POS (maquininha) vinculado a um comerciante.';
COMMENT ON COLUMN public.cappta_pos_devices.cappta_pos_id_external IS 'ID do POS retornado pela API da Cappta, pode ser o serial_key ou um ID específico, opcional.';
COMMENT ON COLUMN public.cappta_pos_devices.merchant_profile_id IS 'FK para profiles.id. Lógica de aplicação deve garantir que profile_type = ''ORGANIZATION'' e atua como Comerciante.';
COMMENT ON COLUMN public.cappta_pos_devices.model_id IS 'FK para cappta_pos_device_models.id - o modelo da maquininha.';
COMMENT ON COLUMN public.cappta_pos_devices.serial_key IS 'Número de série da maquininha.';
COMMENT ON COLUMN public.cappta_pos_devices.status_cappta_id IS 'ID do status do dispositivo POS na Cappta.';
COMMENT ON COLUMN public.cappta_pos_devices.status_cappta_scope IS 'Scope do status do dispositivo POS, fixo em ''POS_DEVICE''.';
COMMENT ON COLUMN public.cappta_pos_devices.status_description_cappta IS 'Descrição do status na Cappta, ex: "Enabled", "Inactive" - pode ser obtida via join ou armazenada para referência.';




-- Script de inserção para Cappta Lookups --

INSERT INTO public.cappta_account_type_options (id, description) VALUES (1, 'CC') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_account_type_options (id, description) VALUES (2, 'PP') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_account_type_options (id, description) VALUES (3, 'PG') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_legal_nature_options (id, description) VALUES (1, 'EI') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_legal_nature_options (id, description) VALUES (2, 'EIRELI') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_legal_nature_options (id, description) VALUES (3, 'Societies') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_legal_nature_options (id, description) VALUES (4, 'Cooperatives') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_status_options (id, description) VALUES (1, 'Enabled') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.cappta_status_options (id, description) VALUES (2, 'Processing') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.cappta_status_options (id, description) VALUES (3, 'InvalidBank') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.cappta_status_options (id, description) VALUES (4, 'Disabled') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.cappta_status_options (id, description) VALUES (5, 'AnalyzingRisk') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.cappta_status_options (id, description) VALUES (99, 'Error') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (1, 'Padrão Gerente/Marketplace') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (742, 'Veterinarios') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (763, 'Cooperativas Agrícolas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (780, 'Paisagismo e Jardinagem') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (1520, 'Empreiteiros (Residencial e Comercial)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (1711, 'Encanadores ou Servicos de Aquecimento e Ar Condicionado') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (1731, 'Eletricistas e Servicos Eletricos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (1740, 'Pedreiros e Servicos de instalacao de Pedras, Ladrilhos, Tijolos, Forros e Isolamento') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (1750, 'Marceneiros e Carpintaria') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (1761, 'Colocacao de Telhas, Beirais e Trabalhos de Folha Metal') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (1771, 'Concretagem e Pavimentacao') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (1799, 'Demais Servicos de Reforma e Construcao Nao- Classificados') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (2741, 'Impressoes e Encadernacoes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (2791, 'Tipografia') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (2842, 'Atacadistas e Distribuidores de Produtos Quimicos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (3248, 'TAM Airlines') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4111, 'Transporte de Passageiros em Trem, Metro e Balsas (urbano)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4112, 'Ferroviaria') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4119, 'Servicos de Ambulancia') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4121, 'Taxi e Limusine') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4131, 'Transporte de Passageiros em onibus') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4214, 'Transporte de Carga Rodoviario e Armazenamento') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4215, 'Courier') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4225, 'Armazenamento de Mercadorias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4411, 'Cruzeiros Maritimos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4457, 'Aluguel de Barco') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4468, 'Marinas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4511, 'Outras Cias Aereas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4582, 'Turismo') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4722, 'Agencias de Viagem / Operadoras de Turismo') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4723, 'Agencia de Viagem') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4784, 'Pedagios (Rodovias e Pontes)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4789, 'Transporte Turistico (bondinhos, cavalos, carruagens, bicicletas)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4812, 'Telefones e Telecomunicacoes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4814, 'Servicos de Telecomunicacoes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4816, 'Provedores de internet') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4821, 'Telegrafia') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4899, 'TV a Cabo e outros tipos de TV paga') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (4900, 'Servicos de agua, Luz, Gas, Tratamento de Lixo e Outros') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5013, 'Atacadistas Acessorios de Veiculos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5021, 'Atacadistas e Distribuidores de Mobilia de Escritorio e Comercial') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5039, 'Atacadistas e Distribuidores de Materiais de Construcao') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5044, 'Atacadistas e Distribuidores de Equipamentos de Escritorio, Fotocopiadoras e de Fotografia') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5045, 'Atacadistas e Distribuidores de Computadores, Equipamentos Perifericos e Softwares') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5046, 'Atacadistas e Distribuidores de Maquinas e Equipamentos para Estabelecimentos Comerciais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5047, 'Atacadistas e Distribuidores de Equipamentos Hospitalares, Medico e Oftalmico') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5051, 'Atacadistas Metalicos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5065, 'Atacadistas e Distribuidores de Partes Eletricas e Eletronicas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5072, 'Atacadistas e Distribuidores de Ferragens e Ferramentas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5074, 'Atacadistas e Distribuidores de Aquecimentos e Encanamentos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5085, 'Atacadistas e Distribuidores de Suprimentos Industriais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5094, 'Atacadistas e Distribuidores de Joias, Relogios e Pedras Preciosas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5099, 'Atacadistas Mercadorias Duraveis') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5111, 'Atacadistas Papelaria') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5122, 'Atacadistas e Distribuidores para Drogarias e Farmacias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5131, 'Atacadistas e Distribuidores de Tecidos e Produtos de Armarinho') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5137, 'Atacadistas e Distribuidores de Roupas (Uniformes Comerciais, Escolares e Esportivos)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5139, 'Atacadistas e Distribuidores de Calcados ') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5169, 'Atacadistas e Distribuidores de Produtos Quimicos e Semelhantes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5172, 'Atacadistas e Distribuidores de Petroleo e Derivados') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5192, 'Atacadistas e Distribuidores de Livros, Periodicos e Jornais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5193, 'Atacadistas e Distribuidores de Flores, Plantas e Sementes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5198, 'Atacadistas e Distribuidores de Tintas e Vernizes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5199, 'Atacadistas Nao Duraveis') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5200, 'Home Center') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5211, 'Lojas de Materiais de Construcao') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5231, 'Vidros, Tintas e Coberturas de Parede') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5251, 'Ferragens e Ferramentas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5261, 'Suprimentos para Jardins e Gramado') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5300, 'Atacadistas e Distribuidores de Alimentos e Provisoes para Casa') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5309, 'DutyFree') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5311, 'Lojas de Departamento') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5331, 'Lojas de Variedades ') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5399, 'Artigos para a Casa') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5411, 'Supermercados e Mercearias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5422, 'Acougues, Peixaria, Avicolas e Frigorificos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5441, 'Docerias e Confeitarias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5451, 'Laticinios') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5462, 'Padarias / Lojas de Biscoitos / bomboniere') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5499, 'Comida Especializada') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5511, 'Venda de Carros e Caminhoes (novos e usados)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5521, 'Venda de Carros Usados') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5532, 'Lojas de Pneus') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5533, 'Pecas e Acessorios Automotivos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5541, 'Postos de Combustivel') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5542, 'Postos de Gasolina') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5551, 'Venda de Barcos Motorizados') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5561, 'Roupas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5571, 'Venda de Motocicletas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5599, 'Venda de Veiculos Recreativos e Maquinarios') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5611, 'Roupas Masculinas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5621, 'Roupas Femininas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5631, 'Acessorios Femininos e lingeries') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5641, 'Roupa Infantil') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5651, 'Vestuario') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5655, 'Roupas, Sapatos e Acessorios (Equestre, Motocross e Uso de Motocicleta)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5661, 'Calcados') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5691, 'Roupas Masculinas e Femininas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5697, 'Costureiras e Alfaiates') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5698, 'Salão Cabeleleiro') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5699, 'Roupas Especiais e Acessorios') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5712, 'Moveis, Mobilias e Decoracoes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5713, 'Revestimentos e Pisos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5714, 'Cortinas e Artigos de Tapecaria') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5718, 'Lareiras') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5719, 'Cama, Mesa e Banho e Outras Utilidades Domesticas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5722, 'Eletro-domesticos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5732, 'Eletronicos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5733, 'Instrumentos Musicais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5734, 'Software de Computador') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5735, 'CDs e DVDs') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5811, 'Buffets / Festas a Domicilio / Aluguel de artigos para Festas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5812, 'Restaurantes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5813, 'Bares e Casas Noturnas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5814, 'Lanchonetes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5912, 'Drogarias e Farmacias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5921, 'Bebidas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5931, 'Artigos de Segunda Mao / Brechos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5932, 'Antiguidades - venda') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5933, 'Alimentos Naturais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5935, 'Desmanche de Automoveis') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5940, 'Bicicletas ') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5941, 'Artigos Esportivos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5942, 'Livrarias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5943, 'Papelarias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5944, 'Joalherias, Relojoarias e Pratarias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5945, 'Brinquedos e Jogos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5946, 'Cameras Fotograficas e Acessorios') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5947, 'Presentes, Cartoes e Lembrancas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5948, 'Bolsas, malas e acessorios de couro') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5949, 'Armarinhos e Tecido') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5950, 'Loja de Cristal') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5960, 'Marketing de Seguro') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5962, 'Taxi e Limusine') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5964, 'Cosmeticos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5965, 'Marketing Direto') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5966, 'Telemarketing') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5967, 'Mensagens Via Telefone, Televisao ou Internet') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5968, 'Salao de Beleza') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5969, 'Marketing ') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5970, 'Arte') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5971, 'Galerias de Arte') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5976, 'Materiais Ortopedicos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5977, 'Cosmeticos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5983, 'Oleo de Combustivel, Madeira e Carvao') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5992, 'Floricultura') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5993, 'Tabacaria') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5994, 'Banca de Jornais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5995, 'Pet Shop') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5996, 'Piscinas e Banheiras') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (5999, 'Lojas Especializadas e Não Listadas Anteriormente') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (6010, 'Finanças') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (6012, 'Bancos Instituicoes Financeiras') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (6051, 'Casas de Cambio') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (6211, 'Corretor de Seguros') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (6300, 'Seguros em Geral') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (6513, 'Imobiliarias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (6533, 'Financas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7011, 'Hoteis / Resorts / Pousadas / Moteis') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7032, 'Camping') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7033, 'Camping e Estacionamento de Trailers') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7210, 'Lavanderias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7211, 'Lavanderia Auto-Servico ') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7216, 'SERVIcOS DE LAVAGEM A SECO') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7217, 'Limpeza de Tapete') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7221, 'Estudios Fotograficos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7230, 'Salao de Beleza') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7251, 'Sapataria ') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7261, 'Funerarias / Crematorios') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7273, 'Acompanhantes e Agencias de Casamento') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7276, 'Cartorios') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7277, 'Terapia') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7278, 'Supermercados e Mercearias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7296, 'Aluguel de Roupas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7297, 'Casas de Massagem') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7298, 'Clinicas de Estetica Facial / Corporal ') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7299, 'Outros Serviços Pessoais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7311, 'Servicos de Publicidade (Anuncios e propaganda)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7321, 'Consultoria Empresarial') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7333, 'Graficas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7338, 'Copias / Fotocopias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7342, 'Dedetizacao e Desinfeccao') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7349, 'Servicos de Manutencao e Limpeza de Edificios') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7361, 'Agencias de Emprego') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7372, 'Servicos de Programacao de Computadores e Processamento de Dados') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7379, 'Consertos de Computadores') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7392, 'Consultoria Empresarial') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7393, 'Servicos de Seguranca') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7394, 'Aluguel de Equipamento e Mobilia de Escritorios ') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7395, 'Laboratorios Fotograficos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7399, 'Gerenciamento de Escritorios') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7512, 'Locadoras de Veiculos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7513, 'Aluguel de Caminhoes / Peruas / Vans') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7523, 'Estacionamento') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7531, 'Funilaria e Pintura Automotiva') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7534, 'Borracharia') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7535, 'Funilaria e Pintura Automotiva') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7538, 'Oficinas Automotivas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7542, 'Lava Rapido') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7549, 'Guincho') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7622, 'Consertos de Radios, TVs e Aparelho de Som') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7623, 'Consertos de Ar-condicionado e Refrigeracao') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7629, 'Consertos de Eletrodomesticos Pequenos e Maquinas Comerciais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7631, 'Conserto de Relogios e Joias') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7641, 'Reparo e Restauracao de Moveis') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7692, 'Serralheiros e Soldadores') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7699, 'Lojas de Consertos Gerais e Serviços Relacionados') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7829, 'Producao de Video') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7832, 'Cinemas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7841, 'Locadoras de Filmes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7911, 'Danca (Estudios, Escolas e Saloes)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7922, 'Teatro / Shows / Concertos / Grupos de Danca / Grupos Carnavalescos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7929, 'Bandas, Orquestras e Artistas Diversos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7932, 'Casas de Bilhar') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7933, 'Boliche') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7941, 'Campos e Quadras de Esporte') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7991, 'Museus / Jardins Botânicos / Exposicoes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7994, 'Lojas de Diversao / Video Game / Lan House / Ciber Cafe') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7995, 'Apostas, Casas Lotericas, Bingos ') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7996, 'Parques Tematicos e de Diversoes, Circos e Atividades Exotericas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7997, 'Academias / Clubes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7998, 'Aquarios') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (7999, 'Recreacao e Entretenimento') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8011, 'Medicos (Clinicas e Consultorios)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8021, 'Dentistas e Ortodontistas (Clinicas e Consultorios)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8031, 'Ortopedistas (Clinicas e Consultorios)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8041, 'Quiropraxia e Fisioterapia') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8042, 'Oftalmologistas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8043, 'Óticas e Produtos Óticos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8049, 'Servico Medico') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8050, 'Casas de Repouso, Clinicas de Recuperacao e Servicos de Enfermagem') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8062, 'Hospitais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8071, 'Laboratorios Medicos e Odontologicos') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8099, 'Servico Especializado de Saude') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8111, 'Advogados') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8211, 'Escolas de Ensino fundamental e Medio') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8220, 'Ensino Superior ') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8241, 'Consultoria de Informática') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8244, 'Treinamentos de Escritorio') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8249, 'Escolas Profissionalizantes') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8299, 'Extra-curriculares e Auto-Escola') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8351, 'Creches, Bercarios e Pre-Escola') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8398, 'Organizacoes de Servicos Beneficientes e Sociais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8641, 'Associacoes Civicas e Sociais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8651, 'Organizacao Politica') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8661, 'Organizacoes Religiosas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8675, 'Associacao Automobilistica') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8699, 'Organizacoes Sindicais, Associacoes Culturais e e outras associacoes nao classificadas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8734, 'Certificacao e Inspecao') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8911, 'Arquitetura / Engenharia') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8931, 'Servicos de Auditoria e Contabilidade') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (8999, 'Outros Serviços Profissionais de Especializados') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9311, 'Pagamento de Taxas') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9399, 'Servicos Governamentais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9402, 'Correios') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9403, 'Pagamento de Títulos e Finanças') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9404, 'Transporte Ferroviário de Carga') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9405, 'Instituição Financeira - Caixa Eletrônico') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9406, 'Loterias Governamentais') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9408, '') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9409, 'ALUGUEL DE CAMINHÕES (TRUCK/UTILITY TRAILER RENTALS)') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9410, '') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9411, '') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9412, '') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9413, '') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9414, '') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9415, '') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9416, '') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9417, '') ON CONFLICT (description) DO NOTHING;
INSERT INTO public.cappta_mcc_options (id, description) VALUES (9418, '') ON CONFLICT (description) DO NOTHING;