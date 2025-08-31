-- Migration: Melhorias no Sistema de Carrinho
-- Data: 2025-08-17
-- Descrição: Adiciona nome do fornecedor, imagem do produto e validação de fornecedor único

/**********************************************************************************************************************
*   SEÇÃO 1: ATUALIZAR SNAPSHOT DO CARRINHO COM DADOS COMPLETOS
**********************************************************************************************************************/

-- Função melhorada para snapshot do carrinho com dados completos
CREATE OR REPLACE FUNCTION public._cart_snapshot(p_cart_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_header JSONB;
  v_items JSONB;
  v_total_qty INT;
  v_total_cents BIGINT;
  v_supplier_info JSONB;
BEGIN
  -- Cabeçalho do carrinho
  SELECT to_jsonb(c) INTO v_header FROM public.marketplace_carts c WHERE c.id = p_cart_id;

  -- Itens do carrinho com dados completos
  SELECT COALESCE(jsonb_agg(
           jsonb_build_object(
             'id', i.id,
             'offer_id', i.offer_id,
             'product_id', i.product_id,
             'supplier_profile_id', i.supplier_profile_id,
             'quantity', i.quantity,
             'unit_price_cents', i.unit_price_cents,
             'note', i.note,
             'created_at', i.created_at,
             'updated_at', i.updated_at,
             -- Dados do produto
             'product_name', p.name,
             'product_gtin', p.gtin,
             'product_description', p.description,
             -- Imagem principal do produto
             'product_image_url', (
               SELECT pi.image_url 
               FROM public.marketplace_product_images pi 
               WHERE pi.product_id = p.id 
               ORDER BY pi.sort_order ASC, pi.created_at ASC 
               LIMIT 1
             ),
             -- Dados do fornecedor
             'supplier_name', COALESCE(
               org.company_name,
               org.trade_name,
               ind.full_name,
               'Fornecedor não identificado'
             ),
             'supplier_type', prof.profile_type,
             -- Dados da oferta
             'supplier_sku', sp.supplier_sku,
             'min_order_quantity', sp.min_order_quantity,
             'max_order_quantity', sp.max_order_quantity
           )
         ), '[]'::jsonb)
  INTO v_items
  FROM public.marketplace_cart_items i
  JOIN public.marketplace_products p ON p.id = i.product_id
  JOIN public.marketplace_supplier_products sp ON sp.id = i.offer_id
  JOIN public.iam_profiles prof ON prof.id = i.supplier_profile_id
  LEFT JOIN public.iam_organization_details org ON org.profile_id = prof.id
  LEFT JOIN public.iam_individual_details ind ON ind.profile_id = prof.id
  WHERE i.cart_id = p_cart_id;

  -- Totais
  SELECT COALESCE(SUM(i.quantity),0), COALESCE(SUM(i.quantity * i.unit_price_cents),0)
  INTO v_total_qty, v_total_cents
  FROM public.marketplace_cart_items i
  WHERE i.cart_id = p_cart_id;

  -- Informações do fornecedor (se houver itens)
  SELECT jsonb_build_object(
    'supplier_profile_id', i.supplier_profile_id,
    'supplier_name', COALESCE(
      org.company_name,
      org.trade_name,
      ind.full_name,
      'Fornecedor não identificado'
    ),
    'supplier_type', prof.profile_type,
    'supplier_contact_email', COALESCE(org.contact_email, ind.contact_email),
    'supplier_contact_phone', COALESCE(org.contact_phone, ind.contact_phone)
  )
  INTO v_supplier_info
  FROM public.marketplace_cart_items i
  JOIN public.iam_profiles prof ON prof.id = i.supplier_profile_id
  LEFT JOIN public.iam_organization_details org ON org.profile_id = prof.id
  LEFT JOIN public.iam_individual_details ind ON ind.profile_id = prof.id
  WHERE i.cart_id = p_cart_id
  LIMIT 1;

  RETURN jsonb_build_object(
    'cart', v_header,
    'items', v_items,
    'supplier', COALESCE(v_supplier_info, '{}'::jsonb),
    'summary', jsonb_build_object(
      'total_quantity', v_total_qty, 
      'total_cents', v_total_cents,
      'items_count', jsonb_array_length(COALESCE(v_items, '[]'::jsonb))
    )
  );
END;$$;

COMMENT ON FUNCTION public._cart_snapshot(UUID) IS 'Retorna snapshot completo do carrinho com dados de produto, fornecedor e imagens.';

/**********************************************************************************************************************
*   SEÇÃO 2: FUNÇÃO PARA VERIFICAR FORNECEDOR ÚNICO
**********************************************************************************************************************/

-- Função para verificar se carrinho tem fornecedor único
CREATE OR REPLACE FUNCTION public._cart_has_single_supplier(p_cart_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_suppliers UUID[];
  v_current_supplier UUID;
  v_supplier_name TEXT;
BEGIN
  -- Buscar todos os fornecedores no carrinho
  SELECT ARRAY_AGG(DISTINCT supplier_profile_id)
  INTO v_suppliers
  FROM public.marketplace_cart_items
  WHERE cart_id = p_cart_id;

  -- Se não há itens, retorna sucesso
  IF v_suppliers IS NULL OR array_length(v_suppliers, 1) = 0 THEN
    RETURN jsonb_build_object(
      'is_single_supplier', true,
      'current_supplier_id', null,
      'current_supplier_name', null
    );
  END IF;

  -- Se há apenas um fornecedor, retorna sucesso
  IF array_length(v_suppliers, 1) = 1 THEN
    v_current_supplier := v_suppliers[1];
    
    -- Buscar nome do fornecedor
    SELECT COALESCE(
      org.company_name,
      org.trade_name,
      ind.full_name,
      'Fornecedor não identificado'
    )
    INTO v_supplier_name
    FROM public.iam_profiles prof
    LEFT JOIN public.iam_organization_details org ON org.profile_id = prof.id
    LEFT JOIN public.iam_individual_details ind ON ind.profile_id = prof.id
    WHERE prof.id = v_current_supplier;

    RETURN jsonb_build_object(
      'is_single_supplier', true,
      'current_supplier_id', v_current_supplier,
      'current_supplier_name', v_supplier_name
    );
  END IF;

  -- Se há múltiplos fornecedores, retorna erro
  RETURN jsonb_build_object(
    'is_single_supplier', false,
    'current_supplier_id', null,
    'current_supplier_name', null,
    'error', 'Cart has multiple suppliers'
  );
END;$$;

COMMENT ON FUNCTION public._cart_has_single_supplier(UUID) IS 'Verifica se o carrinho tem apenas um fornecedor.';

/**********************************************************************************************************************
*   SEÇÃO 3: FUNÇÃO PARA LIMPAR CARRINHO E TROCAR FORNECEDOR
**********************************************************************************************************************/

-- Função para limpar carrinho atual e adicionar item de novo fornecedor
CREATE OR REPLACE FUNCTION public.rpc_cart_clear_and_add_item(p_data JSONB)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_buyer_profile_id UUID := public._get_active_buyer_profile_for_user();
  v_offer_id UUID := (p_data->>'offer_id')::uuid;
  v_qty INT := COALESCE(NULLIF(p_data->>'quantity','')::int, 1);
  v_note TEXT := NULLIF(p_data->>'note','');
  v_cart_id UUID;
  v_product_id UUID;
  v_supplier_profile_id UUID;
  v_unit_price_cents INT;
  v_items_removed INT;
BEGIN
  IF v_offer_id IS NULL THEN RAISE EXCEPTION 'Field "offer_id" is required'; END IF;
  IF v_qty IS NULL OR v_qty <= 0 THEN RAISE EXCEPTION 'quantity must be > 0'; END IF;

  -- Validar oferta
  SELECT t.product_id, t.supplier_profile_id, t.price_cents
  INTO v_product_id, v_supplier_profile_id, v_unit_price_cents
  FROM public.marketplace_supplier_products t
  WHERE t.id = v_offer_id
    AND COALESCE(t.is_active_by_supplier, true) = true
    AND t.status <> 'INACTIVE'
  LIMIT 1;
  
  IF v_product_id IS NULL THEN
    RAISE EXCEPTION 'Invalid or inactive offer_id=%', v_offer_id;
  END IF;

  -- Obter carrinho ativo
  v_cart_id := public._get_or_create_active_cart(v_buyer_profile_id);

  -- Contar itens que serão removidos
  SELECT COUNT(*) INTO v_items_removed
  FROM public.marketplace_cart_items
  WHERE cart_id = v_cart_id;

  -- Limpar todos os itens do carrinho atual
  DELETE FROM public.marketplace_cart_items WHERE cart_id = v_cart_id;

  -- Adicionar o novo item
  INSERT INTO public.marketplace_cart_items (
    cart_id, offer_id, product_id, supplier_profile_id, quantity, unit_price_cents, note
  ) VALUES (
    v_cart_id, v_offer_id, v_product_id, v_supplier_profile_id, v_qty, v_unit_price_cents, v_note
  );

  -- Retornar snapshot com informações da operação
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Cart cleared and new item added',
    'items_removed', v_items_removed,
    'cart_data', public._cart_snapshot(v_cart_id)
  );
END;$$;

COMMENT ON FUNCTION public.rpc_cart_clear_and_add_item(JSONB) IS 'Limpa o carrinho atual e adiciona item de novo fornecedor.';
GRANT EXECUTE ON FUNCTION public.rpc_cart_clear_and_add_item(JSONB) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 4: FUNÇÃO MELHORADA PARA ADICIONAR ITEM COM VALIDAÇÃO DE FORNECEDOR
**********************************************************************************************************************/

-- Função melhorada para adicionar item com validação de fornecedor único
CREATE OR REPLACE FUNCTION public.rpc_cart_add_item(p_data JSONB)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_buyer_profile_id UUID := public._get_active_buyer_profile_for_user();
  v_offer_id UUID := (p_data->>'offer_id')::uuid;
  v_qty INT := COALESCE(NULLIF(p_data->>'quantity','')::int, 1);
  v_note TEXT := NULLIF(p_data->>'note','');
  v_force_clear BOOLEAN := COALESCE((p_data->>'force_clear')::boolean, false);
  v_cart_id UUID;
  v_product_id UUID;
  v_supplier_profile_id UUID;
  v_unit_price_cents INT;
  v_supplier_check JSONB;
  v_current_supplier_name TEXT;
  v_new_supplier_name TEXT;
BEGIN
  IF v_offer_id IS NULL THEN RAISE EXCEPTION 'Field "offer_id" is required'; END IF;
  IF v_qty IS NULL OR v_qty <= 0 THEN RAISE EXCEPTION 'quantity must be > 0'; END IF;

  -- Validar oferta
  SELECT t.product_id, t.supplier_profile_id, t.price_cents
  INTO v_product_id, v_supplier_profile_id, v_unit_price_cents
  FROM public.marketplace_supplier_products t
  WHERE t.id = v_offer_id
    AND COALESCE(t.is_active_by_supplier, true) = true
    AND t.status <> 'INACTIVE'
  LIMIT 1;
  
  IF v_product_id IS NULL THEN
    RAISE EXCEPTION 'Invalid or inactive offer_id=%', v_offer_id;
  END IF;

  -- Obter carrinho ativo
  v_cart_id := public._get_or_create_active_cart(v_buyer_profile_id);

  -- Verificar fornecedor único
  v_supplier_check := public._cart_has_single_supplier(v_cart_id);

  -- Se carrinho tem itens e é de fornecedor diferente
  IF (v_supplier_check->>'is_single_supplier')::boolean = true 
     AND (v_supplier_check->>'current_supplier_id')::uuid IS NOT NULL
     AND (v_supplier_check->>'current_supplier_id')::uuid != v_supplier_profile_id THEN
    
    -- Se não foi forçada a limpeza, retornar erro com opção
    IF NOT v_force_clear THEN
      -- Buscar nome do novo fornecedor
      SELECT COALESCE(
        org.company_name,
        org.trade_name,
        ind.full_name,
        'Fornecedor não identificado'
      )
      INTO v_new_supplier_name
      FROM public.iam_profiles prof
      LEFT JOIN public.iam_organization_details org ON org.profile_id = prof.id
      LEFT JOIN public.iam_individual_details ind ON ind.profile_id = prof.id
      WHERE prof.id = v_supplier_profile_id;

      RETURN jsonb_build_object(
        'success', false,
        'error_type', 'DIFFERENT_SUPPLIER',
        'message', 'Cannot mix products from different suppliers in the same cart',
        'current_supplier', jsonb_build_object(
          'id', v_supplier_check->>'current_supplier_id',
          'name', v_supplier_check->>'current_supplier_name'
        ),
        'new_supplier', jsonb_build_object(
          'id', v_supplier_profile_id,
          'name', v_new_supplier_name
        ),
        'action_required', 'Call rpc_cart_clear_and_add_item or add force_clear: true to replace current cart'
      );
    ELSE
      -- Forçar limpeza e adicionar novo item
      RETURN public.rpc_cart_clear_and_add_item(p_data);
    END IF;
  END IF;

  -- Adicionar/atualizar item normalmente (mesmo fornecedor ou carrinho vazio)
  INSERT INTO public.marketplace_cart_items (
    cart_id, offer_id, product_id, supplier_profile_id, quantity, unit_price_cents, note
  ) VALUES (
    v_cart_id, v_offer_id, v_product_id, v_supplier_profile_id, v_qty, v_unit_price_cents, v_note
  ) ON CONFLICT (cart_id, offer_id)
  DO UPDATE SET quantity = public.marketplace_cart_items.quantity + EXCLUDED.quantity,
                note = COALESCE(EXCLUDED.note, public.marketplace_cart_items.note),
                updated_at = now();

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Item added to cart successfully',
    'cart_data', public._cart_snapshot(v_cart_id)
  );
END;$$;

COMMENT ON FUNCTION public.rpc_cart_add_item(JSONB) IS 'Adiciona item ao carrinho com validação de fornecedor único.';

/**********************************************************************************************************************
*   SEÇÃO 5: FUNÇÃO PARA VERIFICAR STATUS DO CARRINHO
**********************************************************************************************************************/

-- Função para verificar status e validações do carrinho
CREATE OR REPLACE FUNCTION public.rpc_cart_validate()
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_buyer_profile_id UUID := public._get_active_buyer_profile_for_user();
  v_cart_id UUID := public._get_or_create_active_cart(v_buyer_profile_id);
  v_supplier_check JSONB;
  v_items_count INT;
  v_total_cents BIGINT;
BEGIN
  -- Contar itens e total
  SELECT COUNT(*), COALESCE(SUM(quantity * unit_price_cents), 0)
  INTO v_items_count, v_total_cents
  FROM public.marketplace_cart_items
  WHERE cart_id = v_cart_id;

  -- Verificar fornecedor único
  v_supplier_check := public._cart_has_single_supplier(v_cart_id);

  RETURN jsonb_build_object(
    'cart_id', v_cart_id,
    'items_count', v_items_count,
    'total_cents', v_total_cents,
    'is_empty', v_items_count = 0,
    'supplier_validation', v_supplier_check,
    'is_valid', (v_supplier_check->>'is_single_supplier')::boolean AND v_items_count > 0
  );
END;$$;

COMMENT ON FUNCTION public.rpc_cart_validate() IS 'Valida o carrinho atual e retorna status detalhado.';
GRANT EXECUTE ON FUNCTION public.rpc_cart_validate() TO authenticated;
