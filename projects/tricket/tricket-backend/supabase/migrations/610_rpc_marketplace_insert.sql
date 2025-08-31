/**********************************************************************************************************************
*   Arquivo: 610_rpc_marketplace_insert.sql
*   Objetivo: RPCs para inserção nas tabelas do marketplace (admin-only) seguindo o padrão Tricket.
*   Tabelas: marketplace_departments, marketplace_categories, marketplace_sub_categories, marketplace_brands, marketplace_products
**********************************************************************************************************************/

/**********************************************************************************************************************
*   SEÇÃO 0: HELPERS
**********************************************************************************************************************/

-- Helper: slugify
CREATE OR REPLACE FUNCTION public.slugify(p_text TEXT)
RETURNS TEXT
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
AS $$
DECLARE
  v TEXT := COALESCE(p_text, '');
BEGIN
  -- Normaliza acentos, troca não alfa-num por '-', remove duplicados e trim '-'
  v := translate(lower(v),
       'àáâãäåçèéêëìíîïñòóôõöùúûüýÿÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ',
       'aaaaaaceeeeiiiinooooouuuuyyAAAAAACEEEEIIIINOOOOOUUUUY');
  v := regexp_replace(v, '[^a-z0-9]+', '-', 'g');
  v := regexp_replace(v, '(^-+|-+$)', '', 'g');
  RETURN NULLIF(v, '');
END;$$;
COMMENT ON FUNCTION public.slugify(TEXT) IS 'Converte texto em slug URL-safe em minúsculas.';

-- Helper: checar se caller é ADMIN
CREATE OR REPLACE FUNCTION public._ensure_admin()
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_is_admin BOOLEAN;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;
  SELECT EXISTS (
    SELECT 1 FROM public.rbac_user_roles ur
    JOIN public.rbac_roles r ON r.id = ur.role_id
    WHERE ur.user_id = v_uid AND r.name = 'ADMIN'
  ) INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Permission denied: ADMIN only';
  END IF;
END;$$;
COMMENT ON FUNCTION public._ensure_admin() IS 'Lança exceção se o chamador não for ADMIN.';
GRANT EXECUTE ON FUNCTION public._ensure_admin() TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 1: marketplace_departments
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_create_marketplace_department(
  p_data JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_name TEXT := NULLIF(trim(p_data->>'name'), '');
  v_slug TEXT := COALESCE(NULLIF(trim(p_data->>'slug'), ''), public.slugify(p_data->>'name'));
  v_description TEXT := NULLIF(p_data->>'description', '');
  v_icon_url TEXT := NULLIF(p_data->>'icon_url', '');
  v_sort_order INT := COALESCE((p_data->>'sort_order')::INT, 0);
  v_id UUID;
  v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  IF v_name IS NULL THEN RAISE EXCEPTION 'Field "name" is required'; END IF;
  IF v_slug IS NULL THEN RAISE EXCEPTION 'Field "slug" could not be derived'; END IF;

  INSERT INTO public.marketplace_departments (name, slug, description, icon_url, sort_order)
  VALUES (v_name, v_slug, v_description, v_icon_url, v_sort_order)
  RETURNING id INTO v_id;

  UPDATE public.marketplace_departments SET created_at = created_at, updated_at = now() WHERE id = v_id; -- touch
  SELECT to_jsonb(t) FROM public.marketplace_departments t WHERE t.id = v_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_create_marketplace_department(JSONB) IS 'Cria um departamento do marketplace (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_create_marketplace_department(JSONB) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 2: marketplace_categories
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_create_marketplace_category(
  p_data JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_department_id UUID := (p_data->>'department_id')::uuid;
  v_name TEXT := NULLIF(trim(p_data->>'name'), '');
  v_slug TEXT := COALESCE(NULLIF(trim(p_data->>'slug'), ''), public.slugify(p_data->>'name'));
  v_description TEXT := NULLIF(p_data->>'description', '');
  v_icon_url TEXT := NULLIF(p_data->>'icon_url', '');
  v_sort_order INT := COALESCE((p_data->>'sort_order')::INT, 0);
  v_id UUID; v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  IF v_department_id IS NULL THEN RAISE EXCEPTION 'Field "department_id" is required'; END IF;
  IF v_name IS NULL THEN RAISE EXCEPTION 'Field "name" is required'; END IF;
  IF v_slug IS NULL THEN RAISE EXCEPTION 'Field "slug" could not be derived'; END IF;

  INSERT INTO public.marketplace_categories (department_id, name, slug, description, icon_url, sort_order)
  VALUES (v_department_id, v_name, v_slug, v_description, v_icon_url, v_sort_order)
  RETURNING id INTO v_id;

  SELECT to_jsonb(t) FROM public.marketplace_categories t WHERE t.id = v_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_create_marketplace_category(JSONB) IS 'Cria uma categoria vinculada a um departamento (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_create_marketplace_category(JSONB) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 3: marketplace_sub_categories
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_create_marketplace_sub_category(
  p_data JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_category_id UUID := (p_data->>'category_id')::uuid;
  v_name TEXT := NULLIF(trim(p_data->>'name'), '');
  v_slug TEXT := COALESCE(NULLIF(trim(p_data->>'slug'), ''), public.slugify(p_data->>'name'));
  v_description TEXT := NULLIF(p_data->>'description', '');
  v_icon_url TEXT := NULLIF(p_data->>'icon_url', '');
  v_sort_order INT := COALESCE((p_data->>'sort_order')::INT, 0);
  v_id UUID; v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  IF v_category_id IS NULL THEN RAISE EXCEPTION 'Field "category_id" is required'; END IF;
  IF v_name IS NULL THEN RAISE EXCEPTION 'Field "name" is required'; END IF;
  IF v_slug IS NULL THEN RAISE EXCEPTION 'Field "slug" could not be derived'; END IF;

  INSERT INTO public.marketplace_sub_categories (category_id, name, slug, description, icon_url, sort_order)
  VALUES (v_category_id, v_name, v_slug, v_description, v_icon_url, v_sort_order)
  RETURNING id INTO v_id;

  SELECT to_jsonb(t) FROM public.marketplace_sub_categories t WHERE t.id = v_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_create_marketplace_sub_category(JSONB) IS 'Cria uma subcategoria vinculada a uma categoria (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_create_marketplace_sub_category(JSONB) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 4: marketplace_brands
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_create_marketplace_brand(
  p_data JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_name TEXT := NULLIF(trim(p_data->>'name'), '');
  v_slug TEXT := COALESCE(NULLIF(trim(p_data->>'slug'), ''), public.slugify(p_data->>'name'));
  v_description TEXT := NULLIF(p_data->>'description', '');
  v_logo_url TEXT := NULLIF(p_data->>'logo_url', '');
  v_official_website TEXT := NULLIF(p_data->>'official_website', '');
  v_country_of_origin_code TEXT := NULLIF(p_data->>'country_of_origin_code', '');
  v_gs1_company_prefix TEXT := NULLIF(p_data->>'gs1_company_prefix', '');
  v_gln_brand_owner TEXT := NULLIF(p_data->>'gln_brand_owner', '');
  v_status TEXT := COALESCE(NULLIF(p_data->>'status',''), 'PENDING_APPROVAL');
  v_id UUID; v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  IF v_name IS NULL THEN RAISE EXCEPTION 'Field "name" is required'; END IF;
  IF v_slug IS NULL THEN RAISE EXCEPTION 'Field "slug" could not be derived'; END IF;

  INSERT INTO public.marketplace_brands (
    name, slug, description, logo_url, official_website, country_of_origin_code,
    gs1_company_prefix, gln_brand_owner, status, created_by_user_id
  ) VALUES (
    v_name, v_slug, v_description, v_logo_url, v_official_website, v_country_of_origin_code,
    v_gs1_company_prefix, v_gln_brand_owner, v_status, v_uid
  ) RETURNING id INTO v_id;

  SELECT to_jsonb(t) FROM public.marketplace_brands t WHERE t.id = v_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_create_marketplace_brand(JSONB) IS 'Cria uma marca do marketplace (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_create_marketplace_brand(JSONB) TO authenticated;

/**********************************************************************************************************************
*   SEÇÃO 5: marketplace_products
**********************************************************************************************************************/

CREATE OR REPLACE FUNCTION public.rpc_create_marketplace_product(
  p_data JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_sub_category_id UUID := (p_data->>'sub_category_id')::uuid;
  v_brand_id UUID := (p_data->>'brand_id')::uuid;
  v_name TEXT := NULLIF(trim(p_data->>'name'), '');
  v_description TEXT := NULLIF(p_data->>'description', '');
  v_sku_base TEXT := NULLIF(p_data->>'sku_base', '');
  v_attributes JSONB := COALESCE(p_data->'attributes', '{}'::jsonb);
  v_status TEXT := COALESCE(NULLIF(p_data->>'status',''), 'ACTIVE');
  v_gtin TEXT := NULLIF(trim(p_data->>'gtin'), '');
  v_gpc_category_code TEXT := NULLIF(p_data->>'gpc_category_code', '');
  v_ncm_code TEXT := NULLIF(p_data->>'ncm_code', '');
  v_cest_code TEXT := NULLIF(p_data->>'cest_code', '');
  v_net_content NUMERIC := NULLIF(p_data->>'net_content','')::NUMERIC;
  v_net_content_unit TEXT := NULLIF(p_data->>'net_content_unit','');
  v_gross_weight NUMERIC := NULLIF(p_data->>'gross_weight','')::NUMERIC;
  v_net_weight NUMERIC := NULLIF(p_data->>'net_weight','')::NUMERIC;
  v_weight_unit TEXT := NULLIF(p_data->>'weight_unit','');
  v_height NUMERIC := NULLIF(p_data->>'height','')::NUMERIC;
  v_width NUMERIC := NULLIF(p_data->>'width','')::NUMERIC;
  v_depth NUMERIC := NULLIF(p_data->>'depth','')::NUMERIC;
  v_dimension_unit TEXT := NULLIF(p_data->>'dimension_unit','');
  v_country_of_origin_code TEXT := NULLIF(p_data->>'country_of_origin_code','');
  v_gs1_company_name TEXT := NULLIF(p_data->>'gs1_company_name','');
  v_gs1_company_gln TEXT := NULLIF(p_data->>'gs1_company_gln','');
  v_id UUID; v_row JSONB;
BEGIN
  PERFORM public._ensure_admin();
  IF v_name IS NULL THEN RAISE EXCEPTION 'Field "name" is required'; END IF;
  IF v_gtin IS NULL THEN RAISE EXCEPTION 'Field "gtin" is required'; END IF;

  INSERT INTO public.marketplace_products (
    sub_category_id, brand_id, name, description, sku_base, attributes, status,
    gtin, gpc_category_code, ncm_code, cest_code, net_content, net_content_unit,
    gross_weight, net_weight, weight_unit, height, width, depth, dimension_unit,
    country_of_origin_code, gs1_company_name, gs1_company_gln, created_by_user_id
  ) VALUES (
    v_sub_category_id, v_brand_id, v_name, v_description, v_sku_base, v_attributes, v_status,
    v_gtin, v_gpc_category_code, v_ncm_code, v_cest_code, v_net_content, v_net_content_unit,
    v_gross_weight, v_net_weight, v_weight_unit, v_height, v_width, v_depth, v_dimension_unit,
    v_country_of_origin_code, v_gs1_company_name, v_gs1_company_gln, v_uid
  ) RETURNING id INTO v_id;

  SELECT to_jsonb(t) FROM public.marketplace_products t WHERE t.id = v_id INTO v_row;
  RETURN v_row;
EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
END;$$;
COMMENT ON FUNCTION public.rpc_create_marketplace_product(JSONB) IS 'Cria um produto do catálogo do marketplace (ADMIN).';
GRANT EXECUTE ON FUNCTION public.rpc_create_marketplace_product(JSONB) TO authenticated;
