-- 9023_migration_sync_core_users_emails.sql
-- Sincroniza o campo email de public.core_users a partir de auth.users para todos os usuários vinculados.
-- Regra: quando o email de core_users for nulo ou diferente do de auth.users, atualiza com o de auth.users.

BEGIN;

UPDATE public.core_users AS cu
SET email = u.email,
    updated_at = NOW()
FROM auth.users AS u
WHERE cu.id = u.id
  AND (cu.email IS NULL OR cu.email IS DISTINCT FROM u.email);

COMMIT;
