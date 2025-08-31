-- Migration script to create a temporary table and functions for data migration

CREATE TABLE IF NOT EXISTS public.migration_id_mapping (
legacy_table_name TEXT NOT NULL,
legacy_id TEXT NOT NULL,
new_table_name TEXT NOT NULL,
new_uuid UUID NOT NULL
);

COMMENT ON TABLE public.migration_id_mapping IS 'Tabela para mapear IDs legados (numéricos) para os novos UUIDs da arquitetura.';