/**********************************************************************************************************************
*   SEÇÃO 1: FUNÇÃO DE GEOLOCALIZAÇÃO
*   Descrição: Função utilitária para converter coordenadas em um ponto geográfico.
**********************************************************************************************************************/

-- Função: calculate_geolocation
-- Converte um par de coordenadas (latitude, longitude) em um ponto geográfico do tipo `geography`.
-- Requer a extensão PostGIS habilitada.
CREATE OR REPLACE FUNCTION public.calculate_geolocation(p_latitude NUMERIC, p_longitude NUMERIC)
RETURNS extensions.geography
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
    -- Verifica se a latitude e a longitude foram fornecidas.
    IF p_latitude IS NOT NULL AND p_longitude IS NOT NULL THEN
        -- Cria o ponto geográfico usando o SRID 4326 (padrão WGS 84 para lat/lon).
        -- A ordem no PostGIS é (longitude, latitude).
        RETURN extensions.ST_SetSRID(extensions.ST_MakePoint(p_longitude, p_latitude), 4326)::extensions.geography;
    ELSE
        -- Retorna nulo se uma das coordenadas estiver faltando.
        RETURN NULL;
    END IF;
END;
$$;
COMMENT ON FUNCTION public.calculate_geolocation(NUMERIC, NUMERIC) IS 'Calcula e retorna um valor do tipo geography com base na latitude e longitude fornecidas. Requer a extensão PostGIS.';

