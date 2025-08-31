/**********************************************************************************************************************
*   Arquivo: 611_rpc_marketplace_update_delete.sql
*   Objetivo: RPCs de atualização e remoção (soft delete quando aplicável) para tabelas do marketplace.
*   Tabelas: marketplace_departments, marketplace_categories, marketplace_sub_categories, marketplace_brands, marketplace_products
*   Padrões: SECURITY DEFINER, SET search_path = '', validação ADMIN, objetos qualificados, retorno JSONB.
**********************************************************************************************************************/

/**********************************************************************************************************************
*   SEÇÃO 1: marketplace_departments
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_update_marketplace_department(
  p_id UUID,
  p_data JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_exists BOOLEAN;
  v_name TEXT := CASE WHEN p_data ? 'name' THEN NULLIF(trim(p_data->>'name'), '') END;
  v_slug TEXT := CASE WHEN p_data ? 'slug' THEN NULLIF(trim(p_data->>'slug'), '') END;
  v_description TEXT := CASE WHEN p_data ? 'description' THEN p_data->>'description' END;
  v_icon_url TEXT := CASE WHEN p_data ? 'icon_url' THEN p_data->>'icon_url' END;
  v_is_active BOOLEAN := CASE WHEN p_data ? 'is_active' THEN (p_data->>'is_active')::boolean END;
  v_sort_order INT := CASE WHEN p_data ? 'sort_order' THEN (p_data->>'sort_order')::int END;
  v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  SELECT EXISTS(SELECT 1 FROM public.marketplace_departments WHERE id = p_id) INTO v_exists;
  IF NOT v_exists THEN RAISE EXCEPTION 'Not found: marketplace_departments.id=%', p_id; END IF;

  IF v_slug IS NULL AND v_name IS NOT NULL THEN
    v_slug := public.slugify(v_name);
  END IF;

  UPDATE public.marketplace_departments SET
    name = COALESCE(v_name, name),
    slug = COALESCE(v_slug, slug),
    description = COALESCE(v_description, description),
    icon_url = COALESCE(v_icon_url, icon_url),
    is_active = COALESCE(v_is_active, is_active),
    sort_order = COALESCE(v_sort_order, sort_order),
    updated_at = now()
  WHERE id = p_id;

  SELECT to_jsonb(t) FROM public.marketplace_departments t WHERE t.id = p_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_update_marketplace_department(UUID, JSONB) IS 'Atualiza um departamento do marketplace (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_update_marketplace_department(UUID, JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION public.rpc_delete_marketplace_department(
  p_id UUID
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  -- Soft delete: set is_active = false
  UPDATE public.marketplace_departments SET is_active = false, updated_at = now() WHERE id = p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Not found: marketplace_departments.id=%', p_id; END IF;
  SELECT to_jsonb(t) || jsonb_build_object('soft_deleted', true) FROM public.marketplace_departments t WHERE t.id = p_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_delete_marketplace_department(UUID) IS 'Soft delete: marca departamento como inativo (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_delete_marketplace_department(UUID) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 2: marketplace_categories
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_update_marketplace_category(
  p_id UUID,
  p_data JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_exists BOOLEAN;
  v_department_id UUID := CASE WHEN p_data ? 'department_id' THEN (p_data->>'department_id')::uuid END;
  v_name TEXT := CASE WHEN p_data ? 'name' THEN NULLIF(trim(p_data->>'name'), '') END;
  v_slug TEXT := CASE WHEN p_data ? 'slug' THEN NULLIF(trim(p_data->>'slug'), '') END;
  v_description TEXT := CASE WHEN p_data ? 'description' THEN p_data->>'description' END;
  v_icon_url TEXT := CASE WHEN p_data ? 'icon_url' THEN p_data->>'icon_url' END;
  v_is_active BOOLEAN := CASE WHEN p_data ? 'is_active' THEN (p_data->>'is_active')::boolean END;
  v_sort_order INT := CASE WHEN p_data ? 'sort_order' THEN (p_data->>'sort_order')::int END;
  v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  SELECT EXISTS(SELECT 1 FROM public.marketplace_categories WHERE id = p_id) INTO v_exists;
  IF NOT v_exists THEN RAISE EXCEPTION 'Not found: marketplace_categories.id=%', p_id; END IF;

  IF v_slug IS NULL AND v_name IS NOT NULL THEN
    v_slug := public.slugify(v_name);
  END IF;

  UPDATE public.marketplace_categories SET
    department_id = COALESCE(v_department_id, department_id),
    name = COALESCE(v_name, name),
    slug = COALESCE(v_slug, slug),
    description = COALESCE(v_description, description),
    icon_url = COALESCE(v_icon_url, icon_url),
    is_active = COALESCE(v_is_active, is_active),
    sort_order = COALESCE(v_sort_order, sort_order),
    updated_at = now()
  WHERE id = p_id;

  SELECT to_jsonb(t) FROM public.marketplace_categories t WHERE t.id = p_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_update_marketplace_category(UUID, JSONB) IS 'Atualiza uma categoria do marketplace (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_update_marketplace_category(UUID, JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION public.rpc_delete_marketplace_category(
  p_id UUID
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  -- Soft delete: set is_active = false
  UPDATE public.marketplace_categories SET is_active = false, updated_at = now() WHERE id = p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Not found: marketplace_categories.id=%', p_id; END IF;
  SELECT to_jsonb(t) || jsonb_build_object('soft_deleted', true) FROM public.marketplace_categories t WHERE t.id = p_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_delete_marketplace_category(UUID) IS 'Soft delete: marca categoria como inativa (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_delete_marketplace_category(UUID) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 3: marketplace_sub_categories
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_update_marketplace_sub_category(
  p_id UUID,
  p_data JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_exists BOOLEAN;
  v_category_id UUID := CASE WHEN p_data ? 'category_id' THEN (p_data->>'category_id')::uuid END;
  v_name TEXT := CASE WHEN p_data ? 'name' THEN NULLIF(trim(p_data->>'name'), '') END;
  v_slug TEXT := CASE WHEN p_data ? 'slug' THEN NULLIF(trim(p_data->>'slug'), '') END;
  v_description TEXT := CASE WHEN p_data ? 'description' THEN p_data->>'description' END;
  v_icon_url TEXT := CASE WHEN p_data ? 'icon_url' THEN p_data->>'icon_url' END;
  v_is_active BOOLEAN := CASE WHEN p_data ? 'is_active' THEN (p_data->>'is_active')::boolean END;
  v_sort_order INT := CASE WHEN p_data ? 'sort_order' THEN (p_data->>'sort_order')::int END;
  v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  SELECT EXISTS(SELECT 1 FROM public.marketplace_sub_categories WHERE id = p_id) INTO v_exists;
  IF NOT v_exists THEN RAISE EXCEPTION 'Not found: marketplace_sub_categories.id=%', p_id; END IF;

  IF v_slug IS NULL AND v_name IS NOT NULL THEN
    v_slug := public.slugify(v_name);
  END IF;

  UPDATE public.marketplace_sub_categories SET
    category_id = COALESCE(v_category_id, category_id),
    name = COALESCE(v_name, name),
    slug = COALESCE(v_slug, slug),
    description = COALESCE(v_description, description),
    icon_url = COALESCE(v_icon_url, icon_url),
    is_active = COALESCE(v_is_active, is_active),
    sort_order = COALESCE(v_sort_order, sort_order),
    updated_at = now()
  WHERE id = p_id;

  SELECT to_jsonb(t) FROM public.marketplace_sub_categories t WHERE t.id = p_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_update_marketplace_sub_category(UUID, JSONB) IS 'Atualiza uma subcategoria do marketplace (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_update_marketplace_sub_category(UUID, JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION public.rpc_delete_marketplace_sub_category(
  p_id UUID
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  -- Soft delete: set is_active = false
  UPDATE public.marketplace_sub_categories SET is_active = false, updated_at = now() WHERE id = p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Not found: marketplace_sub_categories.id=%', p_id; END IF;
  SELECT to_jsonb(t) || jsonb_build_object('soft_deleted', true) FROM public.marketplace_sub_categories t WHERE t.id = p_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_delete_marketplace_sub_category(UUID) IS 'Soft delete: marca subcategoria como inativa (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_delete_marketplace_sub_category(UUID) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 4: marketplace_brands
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_update_marketplace_brand(
  p_id UUID,
  p_data JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_exists BOOLEAN;
  v_name TEXT := CASE WHEN p_data ? 'name' THEN NULLIF(trim(p_data->>'name'), '') END;
  v_slug TEXT := CASE WHEN p_data ? 'slug' THEN NULLIF(trim(p_data->>'slug'), '') END;
  v_description TEXT := CASE WHEN p_data ? 'description' THEN p_data->>'description' END;
  v_logo_url TEXT := CASE WHEN p_data ? 'logo_url' THEN p_data->>'logo_url' END;
  v_official_website TEXT := CASE WHEN p_data ? 'official_website' THEN p_data->>'official_website' END;
  v_country_of_origin_code TEXT := CASE WHEN p_data ? 'country_of_origin_code' THEN p_data->>'country_of_origin_code' END;
  v_gs1_company_prefix TEXT := CASE WHEN p_data ? 'gs1_company_prefix' THEN p_data->>'gs1_company_prefix' END;
  v_gln_brand_owner TEXT := CASE WHEN p_data ? 'gln_brand_owner' THEN p_data->>'gln_brand_owner' END;
  v_status TEXT := CASE WHEN p_data ? 'status' THEN p_data->>'status' END;
  v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  SELECT EXISTS(SELECT 1 FROM public.marketplace_brands WHERE id = p_id) INTO v_exists;
  IF NOT v_exists THEN RAISE EXCEPTION 'Not found: marketplace_brands.id=%', p_id; END IF;

  IF v_slug IS NULL AND v_name IS NOT NULL THEN
    v_slug := public.slugify(v_name);
  END IF;

  UPDATE public.marketplace_brands SET
    name = COALESCE(v_name, name),
    slug = COALESCE(v_slug, slug),
    description = COALESCE(v_description, description),
    logo_url = COALESCE(v_logo_url, logo_url),
    official_website = COALESCE(v_official_website, official_website),
    country_of_origin_code = COALESCE(v_country_of_origin_code, country_of_origin_code),
    gs1_company_prefix = COALESCE(v_gs1_company_prefix, gs1_company_prefix),
    gln_brand_owner = COALESCE(v_gln_brand_owner, gln_brand_owner),
    status = COALESCE(v_status, status),
    updated_at = now()
  WHERE id = p_id;

  SELECT to_jsonb(t) FROM public.marketplace_brands t WHERE t.id = p_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_update_marketplace_brand(UUID, JSONB) IS 'Atualiza uma marca do marketplace (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_update_marketplace_brand(UUID, JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION public.rpc_delete_marketplace_brand(
  p_id UUID
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  -- Soft delete: set status = 'INACTIVE'
  UPDATE public.marketplace_brands SET status = 'INACTIVE', updated_at = now() WHERE id = p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Not found: marketplace_brands.id=%', p_id; END IF;
  SELECT to_jsonb(t) || jsonb_build_object('soft_deleted', true) FROM public.marketplace_brands t WHERE t.id = p_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_delete_marketplace_brand(UUID) IS 'Soft delete: marca marca como INACTIVE (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_delete_marketplace_brand(UUID) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 5: marketplace_products
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_update_marketplace_product(
  p_id UUID,
  p_data JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_exists BOOLEAN;
  v_sub_category_id UUID := CASE WHEN p_data ? 'sub_category_id' THEN (p_data->>'sub_category_id')::uuid END;
  v_brand_id UUID := CASE WHEN p_data ? 'brand_id' THEN (p_data->>'brand_id')::uuid END;
  v_name TEXT := CASE WHEN p_data ? 'name' THEN NULLIF(trim(p_data->>'name'), '') END;
  v_description TEXT := CASE WHEN p_data ? 'description' THEN p_data->>'description' END;
  v_sku_base TEXT := CASE WHEN p_data ? 'sku_base' THEN p_data->>'sku_base' END;
  v_attributes JSONB := CASE WHEN p_data ? 'attributes' THEN p_data->'attributes' END;
  v_status TEXT := CASE WHEN p_data ? 'status' THEN p_data->>'status' END;
  v_gtin TEXT := CASE WHEN p_data ? 'gtin' THEN NULLIF(trim(p_data->>'gtin'), '') END;
  v_gpc_category_code TEXT := CASE WHEN p_data ? 'gpc_category_code' THEN p_data->>'gpc_category_code' END;
  v_ncm_code TEXT := CASE WHEN p_data ? 'ncm_code' THEN p_data->>'ncm_code' END;
  v_cest_code TEXT := CASE WHEN p_data ? 'cest_code' THEN p_data->>'cest_code' END;
  v_net_content NUMERIC := CASE WHEN p_data ? 'net_content' THEN (p_data->>'net_content')::NUMERIC END;
  v_net_content_unit TEXT := CASE WHEN p_data ? 'net_content_unit' THEN p_data->>'net_content_unit' END;
  v_gross_weight NUMERIC := CASE WHEN p_data ? 'gross_weight' THEN (p_data->>'gross_weight')::NUMERIC END;
  v_net_weight NUMERIC := CASE WHEN p_data ? 'net_weight' THEN (p_data->>'net_weight')::NUMERIC END;
  v_weight_unit TEXT := CASE WHEN p_data ? 'weight_unit' THEN p_data->>'weight_unit' END;
  v_height NUMERIC := CASE WHEN p_data ? 'height' THEN (p_data->>'height')::NUMERIC END;
  v_width NUMERIC := CASE WHEN p_data ? 'width' THEN (p_data->>'width')::NUMERIC END;
  v_depth NUMERIC := CASE WHEN p_data ? 'depth' THEN (p_data->>'depth')::NUMERIC END;
  v_dimension_unit TEXT := CASE WHEN p_data ? 'dimension_unit' THEN p_data->>'dimension_unit' END;
  v_country_of_origin_code TEXT := CASE WHEN p_data ? 'country_of_origin_code' THEN p_data->>'country_of_origin_code' END;
  v_gs1_company_name TEXT := CASE WHEN p_data ? 'gs1_company_name' THEN p_data->>'gs1_company_name' END;
  v_gs1_company_gln TEXT := CASE WHEN p_data ? 'gs1_company_gln' THEN p_data->>'gs1_company_gln' END;
  v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  SELECT EXISTS(SELECT 1 FROM public.marketplace_products WHERE id = p_id) INTO v_exists;
  IF NOT v_exists THEN RAISE EXCEPTION 'Not found: marketplace_products.id=%', p_id; END IF;

  UPDATE public.marketplace_products SET
    sub_category_id = COALESCE(v_sub_category_id, sub_category_id),
    brand_id = COALESCE(v_brand_id, brand_id),
    name = COALESCE(v_name, name),
    description = COALESCE(v_description, description),
    sku_base = COALESCE(v_sku_base, sku_base),
    attributes = COALESCE(v_attributes, attributes),
    status = COALESCE(v_status, status),
    gtin = COALESCE(v_gtin, gtin),
    gpc_category_code = COALESCE(v_gpc_category_code, gpc_category_code),
    ncm_code = COALESCE(v_ncm_code, ncm_code),
    cest_code = COALESCE(v_cest_code, cest_code),
    net_content = COALESCE(v_net_content, net_content),
    net_content_unit = COALESCE(v_net_content_unit, net_content_unit),
    gross_weight = COALESCE(v_gross_weight, gross_weight),
    net_weight = COALESCE(v_net_weight, net_weight),
    weight_unit = COALESCE(v_weight_unit, weight_unit),
    height = COALESCE(v_height, height),
    width = COALESCE(v_width, width),
    depth = COALESCE(v_depth, depth),
    dimension_unit = COALESCE(v_dimension_unit, dimension_unit),
    country_of_origin_code = COALESCE(v_country_of_origin_code, country_of_origin_code),
    gs1_company_name = COALESCE(v_gs1_company_name, gs1_company_name),
    gs1_company_gln = COALESCE(v_gs1_company_gln, gs1_company_gln),
    updated_at = now()
  WHERE id = p_id;

  SELECT to_jsonb(t) FROM public.marketplace_products t WHERE t.id = p_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_update_marketplace_product(UUID, JSONB) IS 'Atualiza um produto do catálogo do marketplace (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_update_marketplace_product(UUID, JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION public.rpc_delete_marketplace_product(
  p_id UUID
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  -- Soft delete: set status = 'INACTIVE'
  UPDATE public.marketplace_products SET status = 'INACTIVE', updated_at = now() WHERE id = p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Not found: marketplace_products.id=%', p_id; END IF;
  SELECT to_jsonb(t) || jsonb_build_object('soft_deleted', true) FROM public.marketplace_products t WHERE t.id = p_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_delete_marketplace_product(UUID) IS 'Soft delete: marca produto como INACTIVE (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_delete_marketplace_product(UUID) TO authenticated;
