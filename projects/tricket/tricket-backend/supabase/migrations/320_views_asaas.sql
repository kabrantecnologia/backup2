
-- View para contas Asaas com informações dos perfis
CREATE OR REPLACE VIEW public.view_asaas_accounts_with_profiles AS
SELECT 
    -- Informações da conta Asaas
    aa.id as account_id,
    aa.asaas_account_id,
    aa.account_status,
    aa.account_type,
    aa.wallet_id,
    aa.onboarding_status as asaas_onboarding_status,
    aa.verification_status,
    aa.webhook_url,
    aa.webhook_token,
    aa.created_at as account_created_at,
    aa.updated_at as account_updated_at,
    
    -- Informações básicas do perfil
    p.id as profile_id,
    p.profile_type,
    p.avatar_url,
    p.onboarding_status as profile_onboarding_status,
    p.time_zone,
    p.active as profile_active,
    p.created_at as profile_created_at,
    p.updated_at as profile_updated_at,
    
    -- Informações específicas para pessoa física
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.full_name
        ELSE NULL
    END as individual_name,
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.cpf
        ELSE NULL
    END as individual_cpf,
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.birth_date
        ELSE NULL
    END as individual_birth_date,
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.contact_email
        ELSE NULL
    END as individual_email,
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.contact_phone
        ELSE NULL
    END as individual_phone,
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.profile_role::text
        ELSE NULL
    END as individual_role,
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.income_value_cents
        ELSE NULL
    END as individual_income_cents,
    
    -- Informações específicas para pessoa jurídica
    CASE 
        WHEN p.profile_type = 'ORGANIZATION' THEN org.company_name
        ELSE NULL
    END as organization_company_name,
    CASE 
        WHEN p.profile_type = 'ORGANIZATION' THEN org.trade_name
        ELSE NULL
    END as organization_trade_name,
    CASE 
        WHEN p.profile_type = 'ORGANIZATION' THEN org.cnpj
        ELSE NULL
    END as organization_cnpj,
    CASE 
        WHEN p.profile_type = 'ORGANIZATION' THEN org.company_type::text
        ELSE NULL
    END as organization_company_type,
    CASE 
        WHEN p.profile_type = 'ORGANIZATION' THEN org.contact_email
        ELSE NULL
    END as organization_email,
    CASE 
        WHEN p.profile_type = 'ORGANIZATION' THEN org.contact_phone
        ELSE NULL
    END as organization_phone,
    CASE 
        WHEN p.profile_type = 'ORGANIZATION' THEN org.platform_role::text
        ELSE NULL
    END as organization_platform_role,
    CASE 
        WHEN p.profile_type = 'ORGANIZATION' THEN org.income_value_cents
        ELSE NULL
    END as organization_income_cents,
    
    -- Campos unificados para facilitar consultas
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.full_name
        WHEN p.profile_type = 'ORGANIZATION' THEN COALESCE(org.trade_name, org.company_name)
        ELSE 'Nome não disponível'
    END as display_name,
    
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.cpf
        WHEN p.profile_type = 'ORGANIZATION' THEN org.cnpj
        ELSE NULL
    END as document_number,
    
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.contact_email
        WHEN p.profile_type = 'ORGANIZATION' THEN org.contact_email
        ELSE NULL
    END as contact_email,
    
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.contact_phone
        WHEN p.profile_type = 'ORGANIZATION' THEN org.contact_phone
        ELSE NULL
    END as contact_phone,
    
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.income_value_cents
        WHEN p.profile_type = 'ORGANIZATION' THEN org.income_value_cents
        ELSE NULL
    END as income_value_cents,
    
    -- Dados JSONB da conta Asaas
    aa.onboarding_data,
    aa.account_settings,
    aa.fees_configuration

FROM public.asaas_accounts aa
INNER JOIN public.iam_profiles p ON aa.profile_id = p.id
LEFT JOIN public.iam_individual_details ind ON p.id = ind.profile_id AND p.profile_type = 'INDIVIDUAL'
LEFT JOIN public.iam_organization_details org ON p.id = org.profile_id AND p.profile_type = 'ORGANIZATION'
ORDER BY aa.created_at DESC;

-- Comentários da view
COMMENT ON VIEW public.view_asaas_accounts_with_profiles IS 'View que combina informações das contas Asaas com dados dos perfis (pessoa física e jurídica)';

-- Índices para otimizar consultas na view (aplicados nas tabelas base)
CREATE INDEX IF NOT EXISTS idx_asaas_accounts_status ON public.asaas_accounts(account_status);
CREATE INDEX IF NOT EXISTS idx_asaas_accounts_created_at ON public.asaas_accounts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_iam_profiles_type ON public.iam_profiles(profile_type);
CREATE INDEX IF NOT EXISTS idx_iam_profiles_active ON public.iam_profiles(active);

-- View simplificada para consultas básicas
CREATE OR REPLACE VIEW public.view_asaas_accounts_summary AS
SELECT 
    aa.id as account_id,
    aa.asaas_account_id,
    aa.account_status,
    aa.account_type,
    aa.wallet_id,
    aa.onboarding_status,
    aa.verification_status,
    p.profile_type,
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.full_name
        WHEN p.profile_type = 'ORGANIZATION' THEN COALESCE(org.trade_name, org.company_name)
        ELSE 'Nome não disponível'
    END as display_name,
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.cpf
        WHEN p.profile_type = 'ORGANIZATION' THEN org.cnpj
        ELSE NULL
    END as document_number,
    CASE 
        WHEN p.profile_type = 'INDIVIDUAL' THEN ind.contact_email
        WHEN p.profile_type = 'ORGANIZATION' THEN org.contact_email
        ELSE NULL
    END as contact_email,
    aa.created_at,
    aa.updated_at
FROM public.asaas_accounts aa
INNER JOIN public.iam_profiles p ON aa.profile_id = p.id
LEFT JOIN public.iam_individual_details ind ON p.id = ind.profile_id AND p.profile_type = 'INDIVIDUAL'
LEFT JOIN public.iam_organization_details org ON p.id = org.profile_id AND p.profile_type = 'ORGANIZATION'
ORDER BY aa.created_at DESC;

COMMENT ON VIEW public.view_asaas_accounts_summary IS 'View simplificada com informações essenciais das contas Asaas e perfis';

-- View para logs de webhook do Asaas (formato para frontend)
CREATE OR REPLACE VIEW public.view_asaas_webhook_logs AS
SELECT 
    -- Campos principais solicitados
    aa.profile_id,
    aa.asaas_account_id,
    aw.webhook_event as asaas_webhook_event,
    
    -- Status do webhook formatado para frontend
    CASE 
        WHEN aw.processed = true THEN 'PROCESSED'
        WHEN aw.processing_error IS NOT NULL THEN 'ERROR'
        WHEN aw.retry_count >= 3 THEN 'FAILED'
        ELSE 'PENDING'
    END as asaas_webhook_status,
    
    aw.created_at as asaas_webhook_created_at,
    
    -- Campos adicionais para log detalhado
    aw.id as webhook_id,
    aw.processed_at,
    aw.processing_error,
    aw.retry_count,
    aw.signature_valid,
    
    -- Informações contextuais da conta
    aa.account_status,
    aa.verification_status,
    aa.account_type,
    
    -- Dados do webhook para detalhamento
    aw.webhook_data,
    aw.raw_payload,
    
    -- Campos calculados para melhor UX no frontend
    CASE 
        WHEN aw.processed = true THEN 'success'
        WHEN aw.processing_error IS NOT NULL THEN 'error'
        WHEN aw.retry_count >= 3 THEN 'failed'
        ELSE 'warning'
    END as log_level,
    
    -- Mensagem amigável para o log
    CASE 
        WHEN aw.processed = true THEN 'Webhook processado com sucesso'
        WHEN aw.processing_error IS NOT NULL THEN CONCAT('Erro: ', aw.processing_error)
        WHEN aw.retry_count >= 3 THEN 'Webhook falhou após múltiplas tentativas'
        ELSE 'Webhook aguardando processamento'
    END as log_message,
    
    -- Tempo desde a criação (para ordenação e filtros)
    EXTRACT(EPOCH FROM (NOW() - aw.created_at)) as seconds_since_created,
    
    -- Formatação de data amigável
    TO_CHAR(aw.created_at, 'DD/MM/YYYY HH24:MI:SS') as formatted_date,
    
    -- Indicador de urgência baseado no tempo e status
    CASE 
        WHEN aw.processed = true THEN 'low'
        WHEN aw.retry_count >= 2 AND aw.processed = false THEN 'high'
        WHEN EXTRACT(EPOCH FROM (NOW() - aw.created_at)) > 3600 AND aw.processed = false THEN 'medium'
        ELSE 'low'
    END as urgency_level

FROM public.asaas_webhooks aw
INNER JOIN public.asaas_accounts aa ON aw.asaas_account_id = aa.id
ORDER BY aw.created_at DESC;

-- Comentário da view
COMMENT ON VIEW public.view_asaas_webhook_logs IS 'View otimizada para exibir eventos de webhook do Asaas em formato de log para o frontend';

-- Índices para otimizar consultas de log (aplicados nas tabelas base)
CREATE INDEX IF NOT EXISTS idx_asaas_webhooks_log_status ON public.asaas_webhooks(processed, retry_count);
CREATE INDEX IF NOT EXISTS idx_asaas_webhooks_log_date ON public.asaas_webhooks(created_at DESC, processed);
CREATE INDEX IF NOT EXISTS idx_asaas_accounts_webhook_logs ON public.asaas_accounts(profile_id, account_status);
