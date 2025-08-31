/**********************************************************************************************************************
*   SEÇÃO 1: TABELA DE RESPOSTAS DA API GS1
*   Descrição: Criação da tabela para armazenar as respostas da API.
**********************************************************************************************************************/

-- Tabela: gs1_api_responses
-- Armazena as respostas brutas da API GS1 para processamento posterior.
CREATE TABLE public.gs1_api_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    gtin TEXT NOT NULL,
    raw_response JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING'::text, -- PENDING, PROCESSED, ERROR
    error_message TEXT,
    created_by_user_id UUID NOT NULL DEFAULT auth.uid(),
    processed_at TIMESTAMPTZ
);

COMMENT ON TABLE public.gs1_api_responses IS 'Armazena as respostas brutas da API GS1 para processamento assíncrono.';
COMMENT ON COLUMN public.gs1_api_responses.gtin IS 'O GTIN (código de barras) que foi consultado.';
COMMENT ON COLUMN public.gs1_api_responses.raw_response IS 'A resposta JSON completa recebida da API GS1.';
COMMENT ON COLUMN public.gs1_api_responses.status IS 'Status do processamento da resposta: PENDING, PROCESSED, ERROR.';
COMMENT ON COLUMN public.gs1_api_responses.error_message IS 'Mensagem de erro, caso o processamento falhe.';
COMMENT ON COLUMN public.gs1_api_responses.created_by_user_id IS 'ID do usuário que iniciou a consulta à API.';
COMMENT ON COLUMN public.gs1_api_responses.processed_at IS 'Timestamp de quando a resposta foi processada com sucesso.';