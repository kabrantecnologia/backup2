---
id: 
status: 
version: 1
source: clickup
type: docs
action: create
space: tricket
folder: "901311317509"
list: 
parent_id: 
created: 
due_date: ""
start_date: 
tags:
  - projetos/tricket
summary: 
path: /home/joaohenrique/clickup/tricket/docs/
---
# Padrão de Desenvolvimento de Funções RPC (Supabase/Postgres)

Este documento define as diretrizes oficiais para criação e uso de funções RPC no backend da Tricket, consumidas por clientes como o front-end WeWeb (integração nativa Supabase).

- Repositório: `tricket-backend/supabase/migrations/`
- Vault de referência: `tricket-vault/resources/`

---

## Objetivos
- __[Segurança]__ Minimizar riscos de RLS bypass e search_path attacks.
- __[Consistência]__ Padronizar assinatura, naming, permissões e retornos.
- __[DX]__ Retornos prontos para consumo pelo front-end (JSONB), com mensagens claras.

---

## Naming, Organização e Versão
- __[Schema]__ Todas as RPCs no schema `public`.
- __[Prefixo]__ Para ações administrativas sensíveis, usar prefixo `rpc_`.
  - Ex.: `public.rpc_approve_user_profile()`.
- __[Arquivos de migração]__
  - Funções utilitárias: faixa 500.
  - RPCs administrativas: faixa 600.
  - Ex.: `600_rpc_admin_functions.sql`, `605_rpc_debug_request.sql`.

---

## Segurança
- __[Definer vs Invoker]__
  - Padrão: `SECURITY DEFINER` + checagem explícita de permissão dentro da função.
  - Exceção: helpers de RLS como `check_user_has_role(text)` devem ser `SECURITY INVOKER`.
- __[search_path]__ Sempre fixar: `SET search_path = ''` ou `SET search_path = public`.
- __[Qualificação]__ Sempre qualificar objetos: `public.*`, `auth.users`, `extensions.*`.
- __[Grants]__ Conceder execução a `authenticated`:
  - `GRANT EXECUTE ON FUNCTION ... TO authenticated;`
  - Autorização fina é feita dentro da função (via RBAC/policies).

---

## Identidade do Chamador e RBAC
- __[Identidade]__ Usar `auth.uid()` para identificar o usuário logado.
- __[RBAC Admin]__ Validar privilégios com join em `public.rbac_user_roles` + `public.rbac_roles`.
- __[Ponto importante]__ Mesmo com `SECURITY DEFINER`, a identidade JWT do chamador chega em `auth.uid()` e `current_setting('request.jwt.claims', true)`.

---

## Assinatura e Parâmetros
- __[Parâmetros nomeados]__ O corpo da requisição (PostgREST/Supabase RPC) deve conter chaves iguais aos nomes dos parâmetros.
  - Ex.: função `public.my_fn(p_payload jsonb, p_id uuid)` espera body `{ "p_payload": { ... }, "p_id": "..." }`.
- __[Tipos indicados]__ Preferir `JSONB` para payloads de entrada complexos.
- __[Defaults]__ Para payloads opcionais, usar `DEFAULT '{}'::jsonb`.

Exemplo (arquivo `605_rpc_debug_request.sql`):
```sql
CREATE OR REPLACE FUNCTION public.rpc_debug_request(
  p_payload jsonb DEFAULT '{}'::jsonb
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
-- ...
$$;
GRANT EXECUTE ON FUNCTION public.rpc_debug_request(jsonb) TO authenticated;
```

---

## Retornos
- __[Formato]__ Favor retornar `JSONB` em leitura e respostas de ação.
  - Incluir `status`, `message` para ações; objetos estruturados para leitura.
- __[Coerência]__ Campos previsíveis e prontos para UI, p.ex. `user_data`, `active_profile`, `available_profiles`.

---

## Tratamento de Erros
- __[Autenticação/Autorização]__ `RAISE EXCEPTION` com mensagens claras quando apropriado.
- __[Falhas inesperadas]__ Capturar `WHEN OTHERS` e retornar estrutura JSON de erro:
```sql
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM, 'sqlstate', SQLSTATE);
```
- __[Erros de unicidade]__ Interceptar `unique_violation` e retornar mensagens amigáveis.

---

## Exemplo de RPC (Admin) – Padrão Completo
```sql
CREATE OR REPLACE FUNCTION public.rpc_approve_user_profile(p_profile_id uuid)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_caller uuid := auth.uid();
  v_is_admin boolean;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.rbac_user_roles ur
    JOIN public.rbac_roles r ON r.id = ur.role_id
    WHERE ur.user_id = v_caller AND r.name = 'ADMIN'
  ) INTO v_is_admin;

  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;

  -- ... ação ...
  RETURN json_build_object('status','success','message','ok');
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('status','error','message', SQLERRM);
END; $$;

GRANT EXECUTE ON FUNCTION public.rpc_approve_user_profile(uuid) TO authenticated;
```

---

## Padrão de Chamada (WeWeb / Supabase)
- __[WeWeb]__ Nó “Call a Postgres function”
  - Function name: `rpc_debug_request` (exemplo)
  - Arguments:
    - Key: `p_payload`
    - Value: objeto JSON, ex.: `{ "teste": "teste" }`
- __[supabase-js]__
```js
const { data, error } = await supabase
  .rpc('rpc_debug_request', { p_payload: { teste: 'teste' } });
```
- __[cURL]__
```bash
curl -X POST 'https://<project>.supabase.co/rest/v1/rpc/rpc_debug_request' \
  -H 'apikey: <ANON_OR_SERVICE_KEY>' \
  -H 'Authorization: Bearer <USER_JWT>' \
  -H 'Content-Type: application/json' \
  -d '{"p_payload":{"teste":"teste"}}'
```

---

## Anti‑padrões a evitar
- __[Sem search_path fixo]__ Não omitir `SET search_path`.
- __[Sem qualificação]__ Não referenciar tabelas sem schema.
- __[GRANT errado]__ Não conceder a `anon` se a função exige usuário autenticado.
- __[Autorização só via GRANT]__ Não delegar autorização somente ao GRANT; validar RBAC dentro da função.
- __[Retornos inconsistentes]__ Evitar misturar tipos de retorno; padronize em `JSONB`.

---

## Checklist antes de subir
- __[1]__ Nome e schema padronizados (public, `rpc_*` se admin).
- __[2]__ `SECURITY DEFINER` + `SET search_path` fixo.
- __[3]__ Objetos totalmente qualificados.
- __[4]__ `GRANT EXECUTE TO authenticated` (ou apropriado).
- __[5]__ Uso de `auth.uid()` e validações RBAC quando necessário.
- __[6]__ Retorno `JSONB` estruturado, mensagens claras.
- __[7]__ Tratamento de erros e exceções conhecido.
- __[8]__ Teste com `rpc_debug_request` para conferir headers/claims/payload.

---

## Referências no código
- `tricket-backend/supabase/migrations/500_functions_check.sql`
- `tricket-backend/supabase/migrations/510_functions_user_contexts.sql`
- `tricket-backend/supabase/migrations/540_functions_check_product_exists.sql`
- `tricket-backend/supabase/migrations/550_functions_register_profiles.sql`
- `tricket-backend/supabase/migrations/560_iam_functions.sql`
- `tricket-backend/supabase/migrations/600_rpc_admin_functions.sql`
- `tricket-backend/supabase/migrations/605_rpc_debug_request.sql`

---

## Notas finais
- Para RPCs que precisam operar sob RLS mas dependem do chamador, avalie `SECURITY INVOKER` cuidadosamente (casos específicos como helpers de policy).
- Prefira sempre validar intenção/escopo no corpo da função (ex.: ownership, membership), não apenas em views externas.
