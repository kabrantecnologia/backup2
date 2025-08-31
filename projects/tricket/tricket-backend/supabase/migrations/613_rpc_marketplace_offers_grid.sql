/**********************************************************************************************************************
*   Arquivo: 613_rpc_marketplace_offers_grid.sql
*   Objetivo: RPC para montar o grid de ofertas do marketplace, incluindo nome do fornecedor e distância (km)
*   Fontes: marketplace_supplier_products, marketplace_products, marketplace_brands,
*           marketplace_product_images, iam_organization_details, iam_addresses, iam_user_preferences
*   Observação: Usa PostGIS (geography) em iam_addresses.geolocation
**********************************************************************************************************************/

-- Idempotência para execução direta no editor do Supabase
DROP FUNCTION IF EXISTS public.rpc_marketplace_offers_grid(JSONB);
DROP FUNCTION IF EXISTS public._get_active_profile_geolocation();

/**********************************************************************************************************************
*   SEÇÃO 0: HELPER - localização do usuário
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public._get_active_profile_geolocation()
RETURNS extensions.geography(POINT, 4326)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_profile_id UUID;
  v_geo extensions.geography(POINT, 4326);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT active_profile_id INTO v_profile_id
  FROM public.iam_user_preferences WHERE user_id = v_uid;

  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Active profile not set for user';
  END IF;

  -- Escolhe o endereço padrão (preferindo MAIN e is_default=true)
  SELECT a.geolocation
  INTO v_geo
  FROM public.iam_addresses a
  WHERE a.profile_id = v_profile_id
  ORDER BY a.is_default DESC,
           (CASE WHEN a.address_type = 'MAIN' THEN 0 ELSE 1 END),
           a.created_at ASC
  LIMIT 1;

  IF v_geo IS NULL THEN
    RAISE EXCEPTION 'Active profile has no address with geolocation';
  END IF;

  RETURN v_geo;
END;$$;
COMMENT ON FUNCTION public._get_active_profile_geolocation() IS 'Obtém a geolocalização (geography - extensions.geography) do endereço padrão do perfil ativo do usuário autenticado.';
GRANT EXECUTE ON FUNCTION public._get_active_profile_geolocation() TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 1: RPC - grid de ofertas com distância
**********************************************************************************************************************/

-- Filtros suportados em p_filters (JSONB):
--   q: texto (busca em product_name, brand_name)
--   brand_id: UUID
--   sub_category_id: UUID
--   max_distance_km: NUMERIC
--   limit: INT (default 20)
--   offset: INT (default 0)
CREATE OR REPLACE FUNCTION public.rpc_marketplace_offers_grid(
  p_filters JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_user_geo extensions.geography(POINT, 4326) := public._get_active_profile_geolocation();
  v_q TEXT := NULLIF(p_filters->>'q', '');
  v_brand_id UUID := (p_filters->>'brand_id')::uuid;
  v_sub_category_id UUID := (p_filters->>'sub_category_id')::uuid;
  v_max_distance_km NUMERIC := NULLIF(p_filters->>'max_distance_km','')::NUMERIC;
  v_limit INT := COALESCE((p_filters->>'limit')::int, 20);
  v_offset INT := COALESCE((p_filters->>'offset')::int, 0);
  v_items JSONB;
  v_total BIGINT;
BEGIN
  -- Coleta itens com nome do fornecedor e distância (km)
  WITH supplier_base AS (
    SELECT
      sp.id AS offer_id,
      sp.product_id,
      p.name AS product_name,
      p.description AS product_description,
      p.gtin AS product_gtin,
      p.sub_category_id,
      b.id AS brand_id,
      b.name AS brand_name,
      COALESCE(iod.trade_name, iod.company_name) AS supplier_name,
      sp.supplier_profile_id,
      sp.supplier_sku,
      sp.price_cents,
      sp.status AS offer_status,
      p.status AS product_status,
      -- imagem principal
      (
        SELECT img.image_url FROM public.marketplace_product_images img
        WHERE img.product_id = p.id
        ORDER BY img.sort_order
        LIMIT 1
      ) AS image_url,
      -- geolocalização do fornecedor (endereço padrão)
      (
        SELECT a.geolocation FROM public.iam_addresses a
        WHERE a.profile_id = sp.supplier_profile_id
        ORDER BY a.is_default DESC,
                 (CASE WHEN a.address_type = 'MAIN' THEN 0 ELSE 1 END),
                 a.created_at ASC
        LIMIT 1
      ) AS supplier_geo
    FROM public.marketplace_supplier_products sp
    JOIN public.marketplace_products p ON p.id = sp.product_id
    JOIN public.marketplace_brands b ON b.id = p.brand_id
    LEFT JOIN public.iam_organization_details iod ON iod.profile_id = sp.supplier_profile_id
    WHERE COALESCE(sp.is_active_by_supplier, true) = true
      AND sp.status = 'ACTIVE'
      AND p.status = 'ACTIVE'
  ), enriched AS (
    SELECT
      sb.*,
      CASE WHEN sb.supplier_geo IS NOT NULL THEN round(CAST(extensions.ST_Distance(sb.supplier_geo, v_user_geo) / 1000.0 AS numeric), 3) ELSE NULL END AS distance_km
    FROM supplier_base sb
  ), filtered AS (
    SELECT * FROM enriched e
    WHERE (v_brand_id IS NULL OR e.brand_id = v_brand_id)
      AND (v_sub_category_id IS NULL OR e.sub_category_id = v_sub_category_id)
      AND (v_q IS NULL OR (
            e.product_name ILIKE '%' || v_q || '%' OR
            e.brand_name ILIKE '%' || v_q || '%' OR
            e.supplier_name ILIKE '%' || v_q || '%'
          ))
      AND (v_max_distance_km IS NULL OR e.distance_km <= v_max_distance_km)
  ), paged AS (
    SELECT *, COUNT(*) OVER() AS total_count
    FROM filtered
    ORDER BY distance_km NULLS LAST, price_cents ASC, offer_id
    LIMIT v_limit OFFSET v_offset
  )
  SELECT 
    jsonb_agg(jsonb_build_object(
      'offer_id', offer_id,
      'product_id', product_id,
      'product_name', product_name,
      'product_description', product_description,
      'product_gtin', product_gtin,
      'brand_id', brand_id,
      'brand_name', brand_name,
      'image_url', image_url,
      'supplier_profile_id', supplier_profile_id,
      'supplier_name', supplier_name,
      'supplier_sku', supplier_sku,
      'price_cents', price_cents,
      'distance_km', distance_km
    )) AS items,
    COALESCE(MAX(total_count), 0) AS total
  INTO v_items, v_total
  FROM paged;

  RETURN jsonb_build_object(
    'items', COALESCE(v_items, '[]'::jsonb),
    'total', v_total,
    'limit', v_limit,
    'offset', v_offset
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_marketplace_offers_grid(JSONB) IS 'Retorna grid de ofertas com nome do fornecedor e distância (km) a partir do endereço do perfil ativo do usuário.';
GRANT EXECUTE ON FUNCTION public.rpc_marketplace_offers_grid(JSONB) TO authenticated;
