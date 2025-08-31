/**********************************************************************************************************************
*   Arquivo: 614_rpc_marketplace_cart.sql
*   Objetivo: Tabelas e RPCs para gerenciar carrinho de compras no marketplace.
*   Padrões: SECURITY DEFINER, SET search_path = '', objetos qualificados, retorno JSONB, GRANT para authenticated.
**********************************************************************************************************************/

/**********************************************************************************************************************
*   SEÇÃO 0: TABELAS (se ainda não existirem)
**********************************************************************************************************************/

-- Tabela de carrinhos (um ativo por perfil comprador)
CREATE TABLE IF NOT EXISTS public.marketplace_carts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_profile_id UUID NOT NULL REFERENCES public.iam_profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | ORDERED | ABANDONED
  created_by_user_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT marketplace_carts_one_active_per_profile UNIQUE (buyer_profile_id, status)
);

-- Tabela de itens do carrinho
CREATE TABLE IF NOT EXISTS public.marketplace_cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cart_id UUID NOT NULL REFERENCES public.marketplace_carts(id) ON DELETE CASCADE,
  offer_id UUID NOT NULL REFERENCES public.marketplace_supplier_products(id) ON DELETE RESTRICT,
  product_id UUID NOT NULL REFERENCES public.marketplace_products(id) ON DELETE RESTRICT,
  supplier_profile_id UUID NOT NULL REFERENCES public.iam_profiles(id) ON DELETE RESTRICT,
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price_cents INT NOT NULL CHECK (unit_price_cents >= 0),
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT marketplace_cart_items_unique_offer_per_cart UNIQUE (cart_id, offer_id)
);

/**********************************************************************************************************************
*   SEÇÃO 1: HELPERS
**********************************************************************************************************************/

-- Obtém o perfil ativo do usuário autenticado (aceita INDIVIDUAL ou ORGANIZATION) e valida que está ativo
CREATE OR REPLACE FUNCTION public._get_active_buyer_profile_for_user()
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_profile_id UUID;
  v_is_active BOOLEAN;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT active_profile_id INTO v_profile_id
  FROM public.iam_user_preferences
  WHERE user_id = v_uid;

  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Active profile not set for user';
  END IF;

  SELECT p.active INTO v_is_active
  FROM public.iam_profiles p
  WHERE p.id = v_profile_id;

  IF NOT COALESCE(v_is_active, false) THEN
    RAISE EXCEPTION 'Active profile is not enabled';
  END IF;

  RETURN v_profile_id;
END;$$;
COMMENT ON FUNCTION public._get_active_buyer_profile_for_user() IS 'Obtém o perfil ativo do usuário autenticado (comprador) e valida que está ativo.';
GRANT EXECUTE ON FUNCTION public._get_active_buyer_profile_for_user() TO authenticated;

-- Cria ou obtém carrinho ativo para o perfil comprador
CREATE OR REPLACE FUNCTION public._get_or_create_active_cart(p_buyer_profile_id UUID)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_cart_id UUID;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT id INTO v_cart_id
  FROM public.marketplace_carts
  WHERE buyer_profile_id = p_buyer_profile_id AND status = 'ACTIVE'
  LIMIT 1;

  IF v_cart_id IS NULL THEN
    INSERT INTO public.marketplace_carts (buyer_profile_id, status, created_by_user_id)
    VALUES (p_buyer_profile_id, 'ACTIVE', v_uid)
    RETURNING id INTO v_cart_id;
  END IF;

  RETURN v_cart_id;
END;$$;
COMMENT ON FUNCTION public._get_or_create_active_cart(UUID) IS 'Retorna o carrinho ativo do perfil comprador, criando se necessário.';
GRANT EXECUTE ON FUNCTION public._get_or_create_active_cart(UUID) TO authenticated;

-- Snapshot do carrinho (cabeçalho + itens + totais)
CREATE OR REPLACE FUNCTION public._cart_snapshot(p_cart_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_header JSONB;
  v_items JSONB;
  v_total_qty INT;
  v_total_cents BIGINT;
BEGIN
  SELECT to_jsonb(c) INTO v_header FROM public.marketplace_carts c WHERE c.id = p_cart_id;

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
             'updated_at', i.updated_at
           )
         ), '[]'::jsonb)
  INTO v_items
  FROM public.marketplace_cart_items i
  WHERE i.cart_id = p_cart_id;

  SELECT COALESCE(SUM(i.quantity),0), COALESCE(SUM(i.quantity * i.unit_price_cents),0)
  INTO v_total_qty, v_total_cents
  FROM public.marketplace_cart_items i
  WHERE i.cart_id = p_cart_id;

  RETURN jsonb_build_object(
    'cart', v_header,
    'items', v_items,
    'summary', jsonb_build_object('total_quantity', v_total_qty, 'total_cents', v_total_cents)
  );
END;$$;
COMMENT ON FUNCTION public._cart_snapshot(UUID) IS 'Retorna um snapshot JSONB do carrinho com itens e totais.';
GRANT EXECUTE ON FUNCTION public._cart_snapshot(UUID) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 2: RPCs DO CARRINHO
**********************************************************************************************************************/

-- Adicionar item ao carrinho (incrementa se já existir)
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
  v_cart_id UUID;
  v_product_id UUID;
  v_supplier_profile_id UUID;
  v_unit_price_cents INT;
BEGIN
  IF v_offer_id IS NULL THEN RAISE EXCEPTION 'Field "offer_id" is required'; END IF;
  IF v_qty IS NULL OR v_qty <= 0 THEN RAISE EXCEPTION 'quantity must be > 0'; END IF;

  -- Valida oferta
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

  -- Carrinho ativo
  v_cart_id := public._get_or_create_active_cart(v_buyer_profile_id);

  -- Upsert item: incrementa quantidade se já existir
  INSERT INTO public.marketplace_cart_items (
    cart_id, offer_id, product_id, supplier_profile_id, quantity, unit_price_cents, note
  ) VALUES (
    v_cart_id, v_offer_id, v_product_id, v_supplier_profile_id, v_qty, v_unit_price_cents, v_note
  ) ON CONFLICT (cart_id, offer_id)
  DO UPDATE SET quantity = public.marketplace_cart_items.quantity + EXCLUDED.quantity,
                note = COALESCE(EXCLUDED.note, public.marketplace_cart_items.note),
                updated_at = now();

  RETURN public._cart_snapshot(v_cart_id);
END;$$;
COMMENT ON FUNCTION public.rpc_cart_add_item(JSONB) IS 'Adiciona uma oferta ao carrinho ativo do perfil atual (incrementa se já existir).';
GRANT EXECUTE ON FUNCTION public.rpc_cart_add_item(JSONB) TO authenticated;

-- Atualizar quantidade de um item do carrinho (deleta se quantidade <= 0)
CREATE OR REPLACE FUNCTION public.rpc_cart_update_item_quantity(p_item_id UUID, p_quantity INT)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_buyer_profile_id UUID := public._get_active_buyer_profile_for_user();
  v_cart_id UUID;
  v_cart_id_item UUID;
BEGIN
  IF p_item_id IS NULL THEN RAISE EXCEPTION 'p_item_id is required'; END IF;

  SELECT i.cart_id INTO v_cart_id_item FROM public.marketplace_cart_items i WHERE i.id = p_item_id;
  IF v_cart_id_item IS NULL THEN RAISE EXCEPTION 'Cart item not found'; END IF;

  -- Garante que o item pertence ao carrinho do perfil atual
  SELECT c.id INTO v_cart_id
  FROM public.marketplace_carts c
  WHERE c.id = v_cart_id_item AND c.buyer_profile_id = v_buyer_profile_id AND c.status = 'ACTIVE';
  IF v_cart_id IS NULL THEN RAISE EXCEPTION 'Permission denied for this cart item'; END IF;

  IF p_quantity IS NULL OR p_quantity <= 0 THEN
    DELETE FROM public.marketplace_cart_items WHERE id = p_item_id;
  ELSE
    UPDATE public.marketplace_cart_items
    SET quantity = p_quantity,
        updated_at = now()
    WHERE id = p_item_id;
  END IF;

  RETURN public._cart_snapshot(v_cart_id);
END;$$;
COMMENT ON FUNCTION public.rpc_cart_update_item_quantity(UUID, INT) IS 'Atualiza a quantidade de um item do carrinho (remove se <= 0).';
GRANT EXECUTE ON FUNCTION public.rpc_cart_update_item_quantity(UUID, INT) TO authenticated;

-- Remover item do carrinho
CREATE OR REPLACE FUNCTION public.rpc_cart_remove_item(p_item_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_buyer_profile_id UUID := public._get_active_buyer_profile_for_user();
  v_cart_id UUID;
  v_cart_id_item UUID;
BEGIN
  IF p_item_id IS NULL THEN RAISE EXCEPTION 'p_item_id is required'; END IF;

  SELECT i.cart_id INTO v_cart_id_item FROM public.marketplace_cart_items i WHERE i.id = p_item_id;
  IF v_cart_id_item IS NULL THEN RAISE EXCEPTION 'Cart item not found'; END IF;

  -- Garante que o item pertence ao carrinho do perfil atual
  SELECT c.id INTO v_cart_id
  FROM public.marketplace_carts c
  WHERE c.id = v_cart_id_item AND c.buyer_profile_id = v_buyer_profile_id AND c.status = 'ACTIVE';
  IF v_cart_id IS NULL THEN RAISE EXCEPTION 'Permission denied for this cart item'; END IF;

  DELETE FROM public.marketplace_cart_items WHERE id = p_item_id;

  RETURN public._cart_snapshot(v_cart_id);
END;$$;
COMMENT ON FUNCTION public.rpc_cart_remove_item(UUID) IS 'Remove um item do carrinho do perfil atual.';
GRANT EXECUTE ON FUNCTION public.rpc_cart_remove_item(UUID) TO authenticated;

-- Obter carrinho atual (snapshot)
CREATE OR REPLACE FUNCTION public.rpc_cart_get()
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_buyer_profile_id UUID := public._get_active_buyer_profile_for_user();
  v_cart_id UUID := public._get_or_create_active_cart(v_buyer_profile_id);
BEGIN
  RETURN public._cart_snapshot(v_cart_id);
END;$$;
COMMENT ON FUNCTION public.rpc_cart_get() IS 'Retorna o snapshot do carrinho ativo do perfil atual (cria se necessário).';
GRANT EXECUTE ON FUNCTION public.rpc_cart_get() TO authenticated;
