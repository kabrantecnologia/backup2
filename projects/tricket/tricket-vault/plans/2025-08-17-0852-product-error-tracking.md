# Plano de Execução: Sistema de Rastreamento de Erros de Produtos

**Data**: 2025-08-17 08:52  
**Tarefa**: Implementar sistema para registrar erros de imagens danificadas e inativar produtos automaticamente  
**Branch**: `feat/product-error-tracking`

## Contexto

A integração com a API GS1 Brasil está funcionando, mas alguns produtos aparecem no front-end com imagens danificadas. É necessário criar um sistema para:

1. Registrar estes erros de forma estruturada
2. Inativar automaticamente produtos com problemas
3. Manter histórico dos motivos de inativação

## Implementações Planejadas

### 1. Tabela de Registro de Erros (`marketplace_product_errors`)

```sql
CREATE TABLE public.marketplace_product_errors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES marketplace_products(id) ON DELETE CASCADE,
    error_type TEXT NOT NULL, -- 'BROKEN_IMAGE', 'INVALID_DATA', etc.
    error_description TEXT,
    error_details JSONB, -- dados técnicos do erro
    reported_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reported_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status TEXT NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE', 'RESOLVED', 'IGNORED'
    resolved_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 2. Função RPC para Inativar Produto

```sql
CREATE OR REPLACE FUNCTION public.inactivate_product_with_error(
    p_product_id UUID,
    p_error_type TEXT,
    p_error_description TEXT DEFAULT NULL,
    p_error_details JSONB DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
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
        'new_status', 'INACTIVE'
    ) INTO v_result;
    
    RETURN v_result;
END;
$$;
```

### 3. Função RPC para Reativar Produto

```sql
CREATE OR REPLACE FUNCTION public.reactivate_product_resolve_error(
    p_product_id UUID,
    p_error_id UUID,
    p_resolution_notes TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Resolver o erro
    UPDATE marketplace_product_errors 
    SET 
        status = 'RESOLVED',
        resolved_by_user_id = auth.uid(),
        resolved_at = now(),
        resolution_notes = p_resolution_notes,
        updated_at = now()
    WHERE id = p_error_id AND product_id = p_product_id;
    
    -- Reativar o produto
    UPDATE marketplace_products 
    SET 
        status = 'ACTIVE',
        updated_at = now()
    WHERE id = p_product_id;
    
    SELECT json_build_object(
        'success', true,
        'message', 'Product reactivated and error resolved',
        'product_id', p_product_id,
        'error_id', p_error_id
    ) INTO v_result;
    
    RETURN v_result;
END;
$$;
```

### 4. Índices e Constraints

```sql
-- Índices para performance
CREATE INDEX idx_marketplace_product_errors_product_id ON marketplace_product_errors(product_id);
CREATE INDEX idx_marketplace_product_errors_error_type ON marketplace_product_errors(error_type);
CREATE INDEX idx_marketplace_product_errors_status ON marketplace_product_errors(status);
CREATE INDEX idx_marketplace_product_errors_reported_at ON marketplace_product_errors(reported_at);

-- Constraint para tipos de erro válidos
ALTER TABLE marketplace_product_errors 
ADD CONSTRAINT chk_error_type 
CHECK (error_type IN ('BROKEN_IMAGE', 'INVALID_DATA', 'API_ERROR', 'PROCESSING_ERROR', 'OTHER'));

-- Constraint para status válidos
ALTER TABLE marketplace_product_errors 
ADD CONSTRAINT chk_error_status 
CHECK (status IN ('ACTIVE', 'RESOLVED', 'IGNORED'));
```

### 5. View para Relatórios

```sql
CREATE VIEW public.v_product_errors_summary AS
SELECT 
    pe.id as error_id,
    pe.product_id,
    p.name as product_name,
    p.gtin,
    pe.error_type,
    pe.error_description,
    pe.status as error_status,
    p.status as product_status,
    pe.reported_at,
    pe.resolved_at,
    reporter.email as reported_by_email,
    resolver.email as resolved_by_email,
    pe.resolution_notes
FROM marketplace_product_errors pe
JOIN marketplace_products p ON pe.product_id = p.id
LEFT JOIN auth.users reporter ON pe.reported_by_user_id = reporter.id
LEFT JOIN auth.users resolver ON pe.resolved_by_user_id = resolver.id
ORDER BY pe.reported_at DESC;
```

## Testes Planejados

1. Teste de criação de erro e inativação de produto
2. Teste de resolução de erro e reativação de produto  
3. Teste de consulta de relatórios
4. Teste de constraints e validações

## Arquivos que serão criados/modificados

- `supabase/migrations/26_marketplace_product_errors.sql` - Nova migration
- Testes de integração correspondentes
