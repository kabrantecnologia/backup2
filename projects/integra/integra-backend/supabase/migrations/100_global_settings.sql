/**********************************************************************************************************************
*   -- INFORMAÇÕES DO SCRIPT --
*   NOME DO ARQUIVO: 01_initial_settings.sql
*   VERSÃO: 1.0
*   CRIADO POR: Gemini
*   DATA DE CRIAÇÃO: 2025-07-25
*
*   -- SUMÁRIO --
*   Este script estabelece a configuração inicial do banco de dados para a aplicação. Inclui a configuração de
*   extensões essenciais do PostgreSQL, a criação de buckets de armazenamento para diversos ativos, a implementação
*   de uma função de atualização automática de timestamp para tabelas e a definição de todos os tipos ENUM
*   personalizados utilizados no esquema do banco de dados. Estas configurações são fundamentais para os objetos
*   de banco de dados e a lógica de negócios subsequentes.
*
**********************************************************************************************************************/

/**********************************************************************************************************************
*   SEÇÃO 1: EXTENSÕES
*   Descrição: Habilita as extensões necessárias do PostgreSQL para adicionar novas funcionalidades ao banco de dados.
**********************************************************************************************************************/

-- Habilita o pg_cron para agendamento de tarefas (ex: execução de rotinas periódicas).
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
COMMENT ON EXTENSION pg_cron IS 'Extensão para agendamento de tarefas no PostgreSQL. Utilizada para execução de tarefas agendadas no banco de dados.';

-- Habilita o PostGIS para suporte a dados espaciais e geográficos (ex: cálculos baseados em localização).
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
COMMENT ON EXTENSION postgis IS 'Extensão para suporte a dados espaciais e geográficos. Utilizada para cálculos geográficos e armazenamento de coordenadas.';

/**********************************************************************************************************************
*   SEÇÃO 2: AUTOMAÇÃO - TIMESTAMP `updated_at`
*   Descrição: Implementa uma função de gatilho (trigger) para atualizar automaticamente a coluna `updated_at`
*                em qualquer tabela que a utilize. Isso garante que os horários de modificação dos dados estejam sempre atualizados.
**********************************************************************************************************************/

-- Esta função é projetada para ser usada por um gatilho. Quando uma linha é atualizada,
-- ela define o valor da coluna `updated_at` para o timestamp atual.
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';
COMMENT ON FUNCTION public.handle_updated_at() IS 'Atualiza automaticamente a coluna updated_at para o timestamp atual sempre que uma linha é modificada.';

/**********************************************************************************************************************
*   SEÇÃO 3: TIPOS DE DADOS PERSONALIZADOS (ENUMs)
*   Descrição: Define todos os tipos enumerados (ENUMs) personalizados para a aplicação. ENUMs fornecem uma maneira
*                de criar um conjunto estático e ordenado de valores, garantindo a consistência dos dados para campos específicos.
**********************************************************************************************************************/

-- ENUM: element_type_enum
-- Diferencia elementos da UI para renderização dinâmica.
-- Uso: ui_elements.element_type
CREATE TYPE public.element_type_enum AS ENUM (
    'SIDEBAR_MENU', -- Um item no menu lateral principal.
    'PAGE_TAB'      -- Uma aba dentro de uma página específica.
);
COMMENT ON TYPE public.element_type_enum IS 'Diferencia os elementos da UI: um item do menu lateral ou uma aba dentro de uma página. Referenciado em: ui_elements.element_type.';
