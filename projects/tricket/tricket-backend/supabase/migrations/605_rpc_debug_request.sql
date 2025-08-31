/**********************************************************************************************************************
*   Arquivo: 605_rpc_debug_request.sql
*   Objetivo: Expor uma função RPC para inspecionar como a requisição do cliente chega ao Postgres (via Supabase).
*   Uso: Chamar via client (ex.: WeWeb -> Supabase RPC) passando um JSON opcional com argumentos.
**********************************************************************************************************************/

-- Função: rpc_debug_request
-- Descrição: Retorna informações de contexto da requisição (auth.uid, JWT claims, headers, papel atual e eco do payload).
CREATE OR REPLACE FUNCTION public.rpc_debug_request(
    p_payload JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_headers JSONB;
    v_claims JSONB;
    v_uid UUID;
    v_db_role TEXT;
    v_raw_ip TEXT;
    v_client_ip TEXT;
    v_user_agent TEXT;
    v_has_auth_header BOOLEAN := FALSE;
BEGIN
    -- Captura do contexto Supabase
    v_uid := auth.uid();
    v_db_role := current_user;  -- papel do banco em execução

    -- Headers e Claims (podem ser nulos dependendo do ambiente)
    v_headers := nullif(current_setting('request.headers', true), '')::jsonb;
    v_claims  := nullif(current_setting('request.jwt.claims', true), '')::jsonb;

    -- Extração segura de alguns headers comuns
    IF v_headers ? 'authorization' THEN
        v_has_auth_header := TRUE;
    END IF;

    v_raw_ip := COALESCE(v_headers->>'x-forwarded-for', v_headers->>'remote-addr');
    IF v_raw_ip IS NOT NULL AND position(',' IN v_raw_ip) > 0 THEN
        v_client_ip := trim(split_part(v_raw_ip, ',', 1));
    ELSE
        v_client_ip := v_raw_ip;
    END IF;

    v_user_agent := v_headers->>'user-agent';

    RETURN jsonb_build_object(
        'received_arguments', COALESCE(p_payload, '{}'::jsonb),
        'is_authenticated', v_uid IS NOT NULL,
        'auth_uid', v_uid,
        'db_role', v_db_role,
        'jwt_claims', COALESCE(v_claims, '{}'::jsonb),
        'headers', COALESCE(v_headers, '{}'::jsonb),
        'headers_summary', jsonb_build_object(
            'has_authorization_header', v_has_auth_header,
            'client_ip', v_client_ip,
            'user_agent', v_user_agent
        )
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'error', SQLERRM,
            'sqlstate', SQLSTATE
        );
END;
$$;

COMMENT ON FUNCTION public.rpc_debug_request(JSONB) IS 'Função de diagnóstico para inspecionar como a requisição chega ao Postgres via Supabase (uid, claims, headers, papel DB e eco do payload).';

-- Permissões: permitir chamada por usuários autenticados (o próprio contexto é autoexplicativo)
GRANT EXECUTE ON FUNCTION public.rpc_debug_request(JSONB) TO authenticated;

-- Exemplos de uso (referência):
-- SELECT public.rpc_debug_request('{"example": true, "note": "hello from weweb"}'::jsonb);
