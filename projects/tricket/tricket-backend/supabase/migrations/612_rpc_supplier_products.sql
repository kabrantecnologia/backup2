/**********************************************************************************************************************
*   Arquivo: 612_rpc_supplier_products.sql
*   Objetivo: RPCs para o usuário fornecedor gerenciar ofertas em marketplace_supplier_products.
*   Regras: Usuário deve estar autenticado, ter perfil ativo do tipo ORGANIZATION e ser membro da organização.
*   Padrões: SECURITY DEFINER, SET search_path = '', objetos qualificados, retorno JSONB, GRANT para authenticated.
**********************************************************************************************************************/

/**********************************************************************************************************************
*   SEÇÃO 0: HELPERS
**********************************************************************************************************************/

-- Retorna o perfil ativo do usuário autenticado, validando que é ORGANIZATION e que o usuário é membro ativo
CREATE OR REPLACE FUNCTION public._get_active_org_profile_for_user()
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_profile_id UUID;
  v_is_member BOOLEAN;
  v_is_org BOOLEAN;
  v_is_active BOOLEAN;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT active_profile_id
  INTO v_profile_id
  FROM public.iam_user_preferences
  WHERE user_id = v_uid;

  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Active profile not set for user';
  END IF;

  SELECT (p.profile_type = 'ORGANIZATION'), p.active
  INTO v_is_org, v_is_active
  FROM public.iam_profiles p
  WHERE p.id = v_profile_id;

  IF NOT COALESCE(v_is_org, false) THEN
    RAISE EXCEPTION 'Active profile must be of type ORGANIZATION';
  END IF;
  IF NOT COALESCE(v_is_active, false) THEN
    RAISE EXCEPTION 'Organization profile is not active';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.iam_organization_members m
    WHERE m.organization_profile_id = v_profile_id
      AND m.member_user_id = v_uid
      AND COALESCE(m.is_active, true) = true
  ) INTO v_is_member;

  IF NOT v_is_member THEN
    RAISE EXCEPTION 'Permission denied: User is not a member of the active organization profile';
  END IF;

  RETURN v_profile_id;
END;$$;
COMMENT ON FUNCTION public._get_active_org_profile_for_user() IS 'Obtém o perfil ativo ORGANIZATION do usuário autenticado e valida a associação.';
GRANT EXECUTE ON FUNCTION public._get_active_org_profile_for_user() TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 1: CREATE supplier_product (oferta do fornecedor)
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_supplier_create_product_offer(
  p_data JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_supplier_profile_id UUID := public._get_active_org_profile_for_user();
  v_product_id UUID := (p_data->>'product_id')::uuid;
  v_supplier_sku TEXT := NULLIF(p_data->>'supplier_sku','');
  v_price_cents INT := (p_data->>'price_cents')::int;
  v_cost_price_cents INT := NULLIF(p_data->>'cost_price_cents','')::int;
  v_promotional_price_cents INT := NULLIF(p_data->>'promotional_price_cents','')::int;
  v_promo_start TIMESTAMPTZ := NULLIF(p_data->>'promotion_start_date','')::timestamptz;
  v_promo_end TIMESTAMPTZ := NULLIF(p_data->>'promotion_end_date','')::timestamptz;
  v_min_order INT := COALESCE(NULLIF(p_data->>'min_order_quantity','')::int, 1);
  v_max_order INT := NULLIF(p_data->>'max_order_quantity','')::int;
  v_barcode_ean TEXT := NULLIF(p_data->>'barcode_ean','');
  v_status TEXT := COALESCE(NULLIF(p_data->>'status',''), 'DRAFT');
  v_is_active_by_supplier BOOLEAN := COALESCE((p_data->>'is_active_by_supplier')::boolean, true);
  v_id UUID; v_row JSONB;
BEGIN
  IF v_product_id IS NULL THEN RAISE EXCEPTION 'Field "product_id" is required'; END IF;
  IF v_price_cents IS NULL THEN RAISE EXCEPTION 'Field "price_cents" is required'; END IF;
  IF v_min_order < 1 THEN RAISE EXCEPTION 'min_order_quantity must be >= 1'; END IF;
  IF v_max_order IS NOT NULL AND v_max_order < v_min_order THEN RAISE EXCEPTION 'max_order_quantity must be >= min_order_quantity'; END IF;
  IF v_promotional_price_cents IS NOT NULL AND v_promo_start IS NULL THEN RAISE EXCEPTION 'promotion_start_date required with promotional_price_cents'; END IF;
  IF v_promotional_price_cents IS NOT NULL AND v_promo_end IS NOT NULL AND v_promo_end < v_promo_start THEN RAISE EXCEPTION 'promotion_end_date must be >= promotion_start_date'; END IF;

  -- Garante unicidade por (product_id, supplier_profile_id)
  INSERT INTO public.marketplace_supplier_products (
    product_id, supplier_profile_id, supplier_sku, price_cents, cost_price_cents,
    promotional_price_cents, promotion_start_date, promotion_end_date,
    min_order_quantity, max_order_quantity, barcode_ean, status, is_active_by_supplier,
    created_by_user_id
  ) VALUES (
    v_product_id, v_supplier_profile_id, v_supplier_sku, v_price_cents, v_cost_price_cents,
    v_promotional_price_cents, v_promo_start, v_promo_end,
    v_min_order, v_max_order, v_barcode_ean, v_status, v_is_active_by_supplier,
    v_uid
  ) RETURNING id INTO v_id;

  SELECT to_jsonb(t) FROM public.marketplace_supplier_products t WHERE t.id = v_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN foreign_key_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_supplier_create_product_offer(JSONB) IS 'Cria oferta do fornecedor para um produto (para a organização ativa do usuário).';
GRANT EXECUTE ON FUNCTION public.rpc_supplier_create_product_offer(JSONB) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 2: UPDATE supplier_product (somente da própria organização)
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_supplier_update_product_offer(
  p_id UUID,
  p_data JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_supplier_profile_id UUID := public._get_active_org_profile_for_user();
  v_owner_check UUID;
  v_supplier_sku TEXT := CASE WHEN p_data ? 'supplier_sku' THEN NULLIF(p_data->>'supplier_sku','') END;
  v_price_cents INT := CASE WHEN p_data ? 'price_cents' THEN (p_data->>'price_cents')::int END;
  v_cost_price_cents INT := CASE WHEN p_data ? 'cost_price_cents' THEN (p_data->>'cost_price_cents')::int END;
  v_promotional_price_cents INT := CASE WHEN p_data ? 'promotional_price_cents' THEN (p_data->>'promotional_price_cents')::int END;
  v_promo_start TIMESTAMPTZ := CASE WHEN p_data ? 'promotion_start_date' THEN (p_data->>'promotion_start_date')::timestamptz END;
  v_promo_end TIMESTAMPTZ := CASE WHEN p_data ? 'promotion_end_date' THEN (p_data->>'promotion_end_date')::timestamptz END;
  v_min_order INT := CASE WHEN p_data ? 'min_order_quantity' THEN (p_data->>'min_order_quantity')::int END;
  v_max_order INT := CASE WHEN p_data ? 'max_order_quantity' THEN (p_data->>'max_order_quantity')::int END;
  v_barcode_ean TEXT := CASE WHEN p_data ? 'barcode_ean' THEN NULLIF(p_data->>'barcode_ean','') END;
  v_status TEXT := CASE WHEN p_data ? 'status' THEN p_data->>'status' END;
  v_is_active_by_supplier BOOLEAN := CASE WHEN p_data ? 'is_active_by_supplier' THEN (p_data->>'is_active_by_supplier')::boolean END;
  v_row JSONB;
BEGIN
  -- Confirma que a oferta pertence à org ativa do usuário
  SELECT supplier_profile_id INTO v_owner_check
  FROM public.marketplace_supplier_products WHERE id = p_id;
  IF v_owner_check IS NULL THEN RAISE EXCEPTION 'Not found: marketplace_supplier_products.id=%', p_id; END IF;
  IF v_owner_check <> v_supplier_profile_id THEN
    RAISE EXCEPTION 'Permission denied: Offer does not belong to your organization';
  END IF;

  -- Validações relacionais simples
  IF v_max_order IS NOT NULL AND v_min_order IS NOT NULL AND v_max_order < v_min_order THEN
    RAISE EXCEPTION 'max_order_quantity must be >= min_order_quantity';
  END IF;
  IF v_promotional_price_cents IS NOT NULL AND v_promo_start IS NULL THEN
    RAISE EXCEPTION 'promotion_start_date required with promotional_price_cents';
  END IF;
  IF v_promo_end IS NOT NULL AND v_promo_start IS NOT NULL AND v_promo_end < v_promo_start THEN
    RAISE EXCEPTION 'promotion_end_date must be >= promotion_start_date';
  END IF;

  UPDATE public.marketplace_supplier_products SET
    supplier_sku = COALESCE(v_supplier_sku, supplier_sku),
    price_cents = COALESCE(v_price_cents, price_cents),
    cost_price_cents = COALESCE(v_cost_price_cents, cost_price_cents),
    promotional_price_cents = COALESCE(v_promotional_price_cents, promotional_price_cents),
    promotion_start_date = COALESCE(v_promo_start, promotion_start_date),
    promotion_end_date = COALESCE(v_promo_end, promotion_end_date),
    min_order_quantity = COALESCE(v_min_order, min_order_quantity),
    max_order_quantity = COALESCE(v_max_order, max_order_quantity),
    barcode_ean = COALESCE(v_barcode_ean, barcode_ean),
    status = COALESCE(v_status, status),
    is_active_by_supplier = COALESCE(v_is_active_by_supplier, is_active_by_supplier),
    updated_at = now()
  WHERE id = p_id;

  SELECT to_jsonb(t) FROM public.marketplace_supplier_products t WHERE t.id = p_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_supplier_update_product_offer(UUID, JSONB) IS 'Atualiza oferta do fornecedor pertencente à organização ativa.';
GRANT EXECUTE ON FUNCTION public.rpc_supplier_update_product_offer(UUID, JSONB) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 3: DELETE supplier_product (soft delete pelo fornecedor)
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_supplier_delete_product_offer(
  p_id UUID
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_supplier_profile_id UUID := public._get_active_org_profile_for_user();
  v_owner_check UUID;
  v_row JSONB;
BEGIN
  SELECT supplier_profile_id INTO v_owner_check
  FROM public.marketplace_supplier_products WHERE id = p_id;
  IF v_owner_check IS NULL THEN RAISE EXCEPTION 'Not found: marketplace_supplier_products.id=%', p_id; END IF;
  IF v_owner_check <> v_supplier_profile_id THEN
    RAISE EXCEPTION 'Permission denied: Offer does not belong to your organization';
  END IF;

  -- Soft delete pelo fornecedor: desativa sem apagar
  UPDATE public.marketplace_supplier_products
  SET is_active_by_supplier = false,
      status = CASE WHEN status <> 'INACTIVE' THEN 'INACTIVE' ELSE status END,
      updated_at = now()
  WHERE id = p_id;

  SELECT to_jsonb(t) || jsonb_build_object('soft_deleted', true)
  FROM public.marketplace_supplier_products t WHERE t.id = p_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_supplier_delete_product_offer(UUID) IS 'Soft delete da oferta do fornecedor (desativa a oferta).';
GRANT EXECUTE ON FUNCTION public.rpc_supplier_delete_product_offer(UUID) TO authenticated;
