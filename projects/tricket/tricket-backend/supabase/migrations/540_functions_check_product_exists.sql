-- Função: get_product_by_gtin
-- Descrição: Busca um produto na tabela marketplace_products através do código GTIN
-- Parâmetros:
--   - p_gtin (TEXT): Código GTIN do produto (ex: '07894900086003')
-- Retorno: JSONB com dados do produto (id, nome, gtin, imagem) ou NULL se não encontrado
-- Uso: SELECT get_product_by_gtin('07894900086003');

CREATE OR REPLACE FUNCTION public.get_product_by_gtin(p_gtin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_product_data JSONB := NULL;
BEGIN
    -- Validação de entrada
    IF p_gtin IS NULL OR LENGTH(TRIM(p_gtin)) = 0 THEN
        RETURN NULL;
    END IF;

    -- Remove espaços em branco e normaliza o GTIN
    p_gtin := TRIM(p_gtin);

    -- Busca o produto e sua primeira imagem (baseado na view_products_with_image)
    SELECT jsonb_build_object(
        'id', p.id,
        'nome', p.name,
        'gtin', p.gtin,
        'imagem', pi.image_url
    ) INTO v_product_data
    FROM public.marketplace_products p
    LEFT JOIN public.marketplace_brands b ON p.brand_id = b.id
    LEFT JOIN LATERAL (
        SELECT image_url 
        FROM public.marketplace_product_images 
        WHERE product_id = p.id 
        ORDER BY sort_order ASC 
        LIMIT 1
    ) pi ON true
    WHERE p.gtin = p_gtin 
    AND p.status = 'ACTIVE';

    RETURN v_product_data;

EXCEPTION
    WHEN OTHERS THEN
        -- Em caso de erro, retorna NULL
        RETURN NULL;
END;
$$;

-- Comentários da função
COMMENT ON FUNCTION public.get_product_by_gtin(TEXT) IS 'Busca um produto ativo na tabela marketplace_products através do código GTIN, retornando seus dados básicos.';

-- Concede permissões para usuários autenticados
GRANT EXECUTE ON FUNCTION public.get_product_by_gtin(TEXT) TO authenticated;

-- =====================================================================================================================
-- TESTES DA FUNÇÃO
-- =====================================================================================================================

-- Exemplos de uso:
-- SELECT get_product_by_gtin('07894900086003'); 
-- Retorna: {"id": "uuid", "nome": "Nome do Produto", "gtin": "07894900086003", "imagem": "url_da_imagem"}
-- ou NULL se não encontrado

-- SELECT get_product_by_gtin(''); -- Retorna NULL (GTIN vazio)
-- SELECT get_product_by_gtin(NULL); -- Retorna NULL (GTIN nulo)

-- Para verificar apenas se existe (compatibilidade com versão anterior):
-- SELECT get_product_by_gtin('07894900086003') IS NOT NULL AS exists;

-- Para extrair campos específicos:
-- SELECT 
--     get_product_by_gtin('07894900086003')->>'id' AS product_id,
--     get_product_by_gtin('07894900086003')->>'nome' AS product_name,
--     get_product_by_gtin('07894900086003')->>'imagem' AS product_image;
