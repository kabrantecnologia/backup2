-- Migration: Sistema de Rastreamento de Erros de Produtos
-- Data: 2025-08-17
-- Descrição: Implementa tabela para registrar erros de produtos e funções para inativar/reativar produtos

-- =====================================================
-- 1. TABELA DE ERROS DE PRODUTOS
-- =====================================================

CREATE TABLE public.marketplace_product_errors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES marketplace_products(id) ON DELETE CASCADE,
    error_type TEXT NOT NULL,
    error_description TEXT,
    error_details JSONB,
    reported_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reported_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    resolved_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Comentários da tabela
COMMENT ON TABLE public.marketplace_product_errors IS 'Registro de erros encontrados em produtos do marketplace';
COMMENT ON COLUMN public.marketplace_product_errors.id IS 'Identificador único do erro';
COMMENT ON COLUMN public.marketplace_product_errors.product_id IS 'ID do produto com erro';
COMMENT ON COLUMN public.marketplace_product_errors.error_type IS 'Tipo do erro: BROKEN_IMAGE, INVALID_DATA, API_ERROR, PROCESSING_ERROR, OTHER';
COMMENT ON COLUMN public.marketplace_product_errors.error_description IS 'Descrição legível do erro';
COMMENT ON COLUMN public.marketplace_product_errors.error_details IS 'Detalhes técnicos do erro em formato JSON';
COMMENT ON COLUMN public.marketplace_product_errors.reported_by_user_id IS 'Usuário que reportou o erro';
COMMENT ON COLUMN public.marketplace_product_errors.reported_at IS 'Data e hora do reporte';
COMMENT ON COLUMN public.marketplace_product_errors.status IS 'Status do erro: ACTIVE, RESOLVED, IGNORED';
COMMENT ON COLUMN public.marketplace_product_errors.resolved_by_user_id IS 'Usuário que resolveu o erro';
COMMENT ON COLUMN public.marketplace_product_errors.resolved_at IS 'Data e hora da resolução';
COMMENT ON COLUMN public.marketplace_product_errors.resolution_notes IS 'Notas sobre a resolução do erro';

-- =====================================================
-- 2. CONSTRAINTS E VALIDAÇÕES
-- =====================================================

-- Constraint para tipos de erro válidos
ALTER TABLE public.marketplace_product_errors 
ADD CONSTRAINT chk_error_type 
CHECK (error_type IN ('BROKEN_IMAGE', 'INVALID_DATA', 'API_ERROR', 'PROCESSING_ERROR', 'OTHER'));

-- Constraint para status válidos
ALTER TABLE public.marketplace_product_errors 
ADD CONSTRAINT chk_error_status 
CHECK (status IN ('ACTIVE', 'RESOLVED', 'IGNORED'));

-- Constraint para garantir que erros resolvidos tenham data de resolução
ALTER TABLE public.marketplace_product_errors 
ADD CONSTRAINT chk_resolved_data_consistency 
CHECK (
    (status = 'RESOLVED' AND resolved_at IS NOT NULL) OR 
    (status != 'RESOLVED' AND resolved_at IS NULL)
);

-- =====================================================
-- 3. ÍNDICES PARA PERFORMANCE
-- =====================================================

CREATE INDEX idx_marketplace_product_errors_product_id ON public.marketplace_product_errors(product_id);
CREATE INDEX idx_marketplace_product_errors_error_type ON public.marketplace_product_errors(error_type);
CREATE INDEX idx_marketplace_product_errors_status ON public.marketplace_product_errors(status);
CREATE INDEX idx_marketplace_product_errors_reported_at ON public.marketplace_product_errors(reported_at);
CREATE INDEX idx_marketplace_product_errors_reported_by ON public.marketplace_product_errors(reported_by_user_id);

-- =====================================================
-- 4. FUNÇÃO RPC PARA INATIVAR PRODUTO COM ERRO
-- =====================================================

CREATE OR REPLACE FUNCTION public.inactivate_product_with_error(
    p_product_id UUID,
    p_error_type TEXT,
    p_error_description TEXT DEFAULT NULL,
    p_error_details JSONB DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_product_record marketplace_products%ROWTYPE;
    v_error_record marketplace_product_errors%ROWTYPE;
    v_result JSON;
BEGIN
    -- Verificar se o produto existe
    SELECT * INTO v_product_record 
    FROM marketplace_products 
    WHERE id = p_product_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Product not found',
            'product_id', p_product_id
        );
    END IF;
    
    -- Verificar se o tipo de erro é válido
    IF p_error_type NOT IN ('BROKEN_IMAGE', 'INVALID_DATA', 'API_ERROR', 'PROCESSING_ERROR', 'OTHER') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid error type',
            'valid_types', ARRAY['BROKEN_IMAGE', 'INVALID_DATA', 'API_ERROR', 'PROCESSING_ERROR', 'OTHER']
        );
    END IF;
    
    -- Registrar o erro
    INSERT INTO marketplace_product_errors (
        product_id,
        error_type,
        error_description,
        error_details,
        reported_by_user_id
    ) VALUES (
        p_product_id,
        p_error_type,
        p_error_description,
        p_error_details,
        auth.uid()
    ) RETURNING * INTO v_error_record;
    
    -- Inativar o produto
    UPDATE marketplace_products 
    SET 
        status = 'INACTIVE',
        updated_at = now()
    WHERE id = p_product_id;
    
    -- Retornar resultado
    SELECT json_build_object(
        'success', true,
        'message', 'Product inactivated successfully',
        'product_id', p_product_id,
        'error_id', v_error_record.id,
        'previous_status', v_product_record.status,
        'new_status', 'INACTIVE',
        'error_type', p_error_type,
        'reported_at', v_error_record.reported_at
    ) INTO v_result;
    
    RETURN v_result;
END;
$$;

-- Comentário da função
COMMENT ON FUNCTION public.inactivate_product_with_error IS 'Inativa um produto e registra o erro que causou a inativação';

-- =====================================================
-- 5. FUNÇÃO RPC PARA REATIVAR PRODUTO E RESOLVER ERRO
-- =====================================================

CREATE OR REPLACE FUNCTION public.reactivate_product_resolve_error(
    p_product_id UUID,
    p_error_id UUID,
    p_resolution_notes TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_error_record marketplace_product_errors%ROWTYPE;
    v_result JSON;
BEGIN
    -- Verificar se o erro existe e pertence ao produto
    SELECT * INTO v_error_record 
    FROM marketplace_product_errors 
    WHERE id = p_error_id AND product_id = p_product_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Error record not found or does not belong to the specified product',
            'product_id', p_product_id,
            'error_id', p_error_id
        );
    END IF;
    
    -- Verificar se o erro já foi resolvido
    IF v_error_record.status = 'RESOLVED' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Error already resolved',
            'resolved_at', v_error_record.resolved_at,
            'resolved_by', v_error_record.resolved_by_user_id
        );
    END IF;
    
    -- Resolver o erro
    UPDATE marketplace_product_errors 
    SET 
        status = 'RESOLVED',
        resolved_by_user_id = auth.uid(),
        resolved_at = now(),
        resolution_notes = p_resolution_notes,
        updated_at = now()
    WHERE id = p_error_id;
    
    -- Reativar o produto
    UPDATE marketplace_products 
    SET 
        status = 'ACTIVE',
        updated_at = now()
    WHERE id = p_product_id;
    
    SELECT json_build_object(
        'success', true,
        'message', 'Product reactivated and error resolved successfully',
        'product_id', p_product_id,
        'error_id', p_error_id,
        'resolved_at', now(),
        'resolved_by', auth.uid(),
        'resolution_notes', p_resolution_notes
    ) INTO v_result;
    
    RETURN v_result;
END;
$$;

-- Comentário da função
COMMENT ON FUNCTION public.reactivate_product_resolve_error IS 'Reativa um produto e marca o erro como resolvido';

-- =====================================================
-- 6. FUNÇÃO RPC PARA LISTAR PRODUTOS COM ERROS
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_products_with_errors(
    p_error_status TEXT DEFAULT 'ACTIVE',
    p_error_type TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    error_id UUID,
    product_id UUID,
    product_name TEXT,
    product_gtin TEXT,
    product_status TEXT,
    error_type TEXT,
    error_description TEXT,
    error_status TEXT,
    reported_at TIMESTAMPTZ,
    reported_by_email TEXT,
    resolved_at TIMESTAMPTZ,
    resolved_by_email TEXT,
    resolution_notes TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pe.id as error_id,
        pe.product_id,
        p.name as product_name,
        p.gtin as product_gtin,
        p.status as product_status,
        pe.error_type,
        pe.error_description,
        pe.status as error_status,
        pe.reported_at,
        reporter.email as reported_by_email,
        pe.resolved_at,
        resolver.email as resolved_by_email,
        pe.resolution_notes
    FROM marketplace_product_errors pe
    JOIN marketplace_products p ON pe.product_id = p.id
    LEFT JOIN auth.users reporter ON pe.reported_by_user_id = reporter.id
    LEFT JOIN auth.users resolver ON pe.resolved_by_user_id = resolver.id
    WHERE 
        (p_error_status IS NULL OR pe.status = p_error_status) AND
        (p_error_type IS NULL OR pe.error_type = p_error_type)
    ORDER BY pe.reported_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- Comentário da função
COMMENT ON FUNCTION public.get_products_with_errors IS 'Lista produtos com erros baseado em filtros de status e tipo';

-- =====================================================
-- 7. VIEW PARA RELATÓRIOS DE ERROS
-- =====================================================

CREATE VIEW public.v_product_errors_summary AS
SELECT 
    pe.id as error_id,
    pe.product_id,
    p.name as product_name,
    p.gtin,
    p.status as product_status,
    pe.error_type,
    pe.error_description,
    pe.status as error_status,
    pe.reported_at,
    pe.resolved_at,
    reporter.email as reported_by_email,
    resolver.email as resolved_by_email,
    pe.resolution_notes,
    CASE 
        WHEN pe.status = 'RESOLVED' THEN pe.resolved_at - pe.reported_at
        ELSE now() - pe.reported_at
    END as resolution_time
FROM marketplace_product_errors pe
JOIN marketplace_products p ON pe.product_id = p.id
LEFT JOIN auth.users reporter ON pe.reported_by_user_id = reporter.id
LEFT JOIN auth.users resolver ON pe.resolved_by_user_id = resolver.id
ORDER BY pe.reported_at DESC;

-- Comentário da view
COMMENT ON VIEW public.v_product_errors_summary IS 'View consolidada com informações de erros de produtos e tempo de resolução';

-- =====================================================
-- 8. TRIGGER PARA ATUALIZAR updated_at
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_marketplace_product_errors_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_marketplace_product_errors_updated_at
    BEFORE UPDATE ON public.marketplace_product_errors
    FOR EACH ROW
    EXECUTE FUNCTION public.update_marketplace_product_errors_updated_at();

-- =====================================================
-- 9. GRANTS E PERMISSÕES
-- =====================================================

-- Permitir que usuários autenticados executem as funções
GRANT EXECUTE ON FUNCTION public.inactivate_product_with_error TO authenticated;
GRANT EXECUTE ON FUNCTION public.reactivate_product_resolve_error TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_products_with_errors TO authenticated;

-- Permitir acesso à view para usuários autenticados
GRANT SELECT ON public.v_product_errors_summary TO authenticated;
