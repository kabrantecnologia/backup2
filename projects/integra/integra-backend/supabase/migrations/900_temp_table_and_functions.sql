/**********************************************************************************************************************
*   -- INFORMAÇÕES DO SCRIPT --
*   NOME DO ARQUIVO: 20_temp_admin_role_trigger.sql
*   VERSÃO: 1.0
*   CRIADO POR: Gemini
*   DATA DE CRIAÇÃO: 2025-07-25
*
*   -- SUMÁRIO --
*   Este script cria uma automação TEMPORÁRIA para fins de desenvolvimento e teste. O objetivo é atribuir
*   automaticamente o papel (role) de 'ADMIN' a um usuário específico (`admin@kabran.com.br`) no momento em
*   que ele é criado na tabela `auth.users`. A automação é implementada através de uma função de gatilho e um
*   gatilho (trigger). Uma função manual de fallback também é fornecida para garantir a atribuição caso o
*   gatilho falhe. Este script inclui instruções claras para sua remoção após a conclusão dos testes.
*
*   AVISO: Esta é uma solução exclusiva para ambientes de desenvolvimento e não deve ser usada em produção.
*
**********************************************************************************************************************/

/**********************************************************************************************************************
*   SEÇÃO 1: FUNÇÃO DE GATILHO (TRIGGER FUNCTION)
*   Descrição: Função que contém a lógica para atribuir o papel de ADMIN ao usuário de teste.
**********************************************************************************************************************/

-- Função: temp_auto_assign_admin_role
-- Verifica se o novo usuário é o usuário de teste e, em caso afirmativo, atribui o papel de ADMIN.
CREATE OR REPLACE FUNCTION public.temp_auto_assign_admin_role()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    admin_role_id UUID;
BEGIN
    -- Verifica se o email do novo usuário é o alvo da automação.
    IF NEW.email = 'admin@kabran.com.br' THEN
        -- Busca o ID do papel 'ADMIN'.
        SELECT id INTO admin_role_id FROM public.rbac_roles WHERE name = 'ADMIN';

        IF admin_role_id IS NOT NULL THEN
            -- Insere a associação na tabela de papéis do usuário, ignorando se já existir.
            INSERT INTO public.rbac_user_roles (user_id, role_id) 
            VALUES (NEW.id, admin_role_id)
            ON CONFLICT (user_id, role_id) DO NOTHING;
            
            RAISE NOTICE 'SUCESSO: Papel de ADMIN atribuído automaticamente para o usuário: %', NEW.email;
        ELSE
            RAISE WARNING 'FALHA: O papel de ADMIN não foi encontrado na tabela rbac_roles.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;
COMMENT ON FUNCTION public.temp_auto_assign_admin_role() IS 'Função de gatilho temporária para atribuir o papel de ADMIN ao usuário de teste especificado.';

/**********************************************************************************************************************
*   SEÇÃO 2: GATILHO (TRIGGER)
*   Descrição: Associa a função de gatilho ao evento de inserção na tabela `auth.users`.
**********************************************************************************************************************/

-- Gatilho: temp_trigger_auto_assign_admin_role
-- Dispara a função `temp_auto_assign_admin_role` sempre que um novo usuário é inserido.
CREATE TRIGGER temp_trigger_auto_assign_admin_role
AFTER INSERT ON auth.users
FOR EACH ROW
WHEN (NEW.email = 'admin@kabran.com.br') -- Otimização: o gatilho só é chamado para o email específico.
EXECUTE FUNCTION public.temp_auto_assign_admin_role();
COMMENT ON TRIGGER temp_trigger_auto_assign_admin_role ON auth.users IS 'Gatilho temporário para atribuir automaticamente o papel de ADMIN ao usuário de teste.';

/**********************************************************************************************************************
*   SEÇÃO 3: FUNÇÃO MANUAL DE FALLBACK
*   Descrição: Uma função para ser executada manualmente caso o gatilho falhe ou precise ser contornado.
**********************************************************************************************************************/

-- Função: manual_assign_admin_role_to_test_user
-- Permite atribuir manualmente o papel de ADMIN ao usuário de teste.
CREATE OR REPLACE FUNCTION public.manual_assign_admin_role_to_test_user()
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    target_user_id UUID;
    admin_role_id UUID;
BEGIN
    SELECT id INTO target_user_id FROM auth.users WHERE email = 'admin@kabran.com.br';
    IF target_user_id IS NULL THEN RETURN 'ERRO: Usuário admin@kabran.com.br não encontrado.'; END IF;

    SELECT id INTO admin_role_id FROM public.rbac_roles WHERE name = 'ADMIN';
    IF admin_role_id IS NULL THEN RETURN 'ERRO: Papel de ADMIN não encontrado.'; END IF;

    INSERT INTO public.rbac_user_roles (user_id, role_id) VALUES (target_user_id, admin_role_id) ON CONFLICT DO NOTHING;
    
    RETURN 'SUCESSO: Papel de ADMIN atribuído manualmente para admin@kabran.com.br.';
END;
$$;
COMMENT ON FUNCTION public.manual_assign_admin_role_to_test_user() IS 'Função manual de fallback para atribuir o papel de ADMIN ao usuário de teste.';

/**********************************************************************************************************************
*   SEÇÃO 4: INSTRUÇÕES DE REMOÇÃO
*   Descrição: Comandos SQL para reverter e limpar os objetos temporários criados por este script.
**********************************************************************************************************************/

/*
-- Para remover esta configuração temporária após os testes, execute os seguintes comandos:

DROP TRIGGER IF EXISTS temp_trigger_auto_assign_admin_role ON auth.users;
DROP FUNCTION IF EXISTS public.temp_auto_assign_admin_role();
DROP FUNCTION IF EXISTS public.manual_assign_admin_role_to_test_user();

*/