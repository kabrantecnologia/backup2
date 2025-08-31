/**********************************************************************************************************************
*   SEÇÃO 1: CONTROLE DE ACESSO BASEADO EM FUNÇÕES (RBAC)
*   Descrição: Define as tabelas para o sistema de RBAC, permitindo a criação de papéis (roles) e a associação
*              de usuários a esses papéis para controle de permissões em nível de sistema.
**********************************************************************************************************************/

-- Tabela: rbac_roles
-- Armazena os papéis de acesso globais do sistema (ex: ADMIN, SUPORTE).
CREATE TABLE public.rbac_roles (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    level INTEGER,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.rbac_roles IS 'Armazena as funções de controle de acesso baseado em papéis (RBAC) globais do sistema.';
COMMENT ON COLUMN public.rbac_roles.name IS 'Nome único da função (ex: "ADMIN", "SUPPORT").';
COMMENT ON COLUMN public.rbac_roles.level IS 'Nível hierárquico da função, para controle de precedência (ex: 1 para Admin).';

-- Gatilho para atualizar o campo `updated_at` na tabela `rbac_roles`.
CREATE TRIGGER on_rbac_roles_update
BEFORE UPDATE ON public.rbac_roles
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Tabela: rbac_user_roles
-- Tabela de associação que vincula um usuário a um ou mais papéis de sistema.
CREATE TABLE public.rbac_user_roles (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES public.rbac_roles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, role_id)
);
COMMENT ON TABLE public.rbac_user_roles IS 'Associa usuários (auth.users) a papéis (rbac_roles) para controle de acesso global.';

