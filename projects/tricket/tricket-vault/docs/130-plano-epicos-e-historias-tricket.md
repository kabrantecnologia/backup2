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
summary: Plano de Épicos e Histórias de Usuário do projeto Tricket, consolidado a partir dos documentos de visão, requisitos, arquitetura e UX.
path: /home/joaohenrique/clickup/tricket/docs/
---

# Plano de Épicos e Histórias de Usuário — Tricket

Fonte: `tricket-vault/docs/`
- Escopo e pilares: `100-visao-geral-tricket.md`
- Arquitetura DB/RPC: `110-supabase_arquitetura.md`, `rpc-functions-standard.md`
- Requisitos funcionais: `requisitos-sistema-tricket.md`
- Rotas UX: `estrutura-de-paginas-e-links.md`
- Dados/GS1: `120_dicionario_de_dados.md`, `analise-compatibilidade-gs1.md`

## Tabela de Rastreabilidade

| Épico | Histórias (IDs) | Requisitos (RF/RNF) | Fase/Roadmap | Status |
|---|---|---|---|---|
| Épico 1 — IAM, Cadastro e Onboarding | PF/PJ cadastro; Verificação; Convites; Seletor de perfil; Aprovação | RF001, RF002, RF009 | MVP 1 | Em planejamento |
| Épico 2 — RBAC e Navegação de UI | Definição de papéis; Permissões de elementos/menus | RF002 | MVP 1 | Em planejamento |
| Épico 3 — Integração Asaas | Saldo; Adicionar saldo; Saques; Webhooks | RF008 | MVP 1 | Em planejamento |
| Épico 4 — Integração POS (Cappta) | Conectar POS; Ver transações; Reconciliação | RF008 | MVP 2 | Em planejamento |
| Épico 5 — Catálogo do Marketplace | CRUD categorias e produtos base; Aprovação | RF003 | MVP 1 | Em planejamento |
| Épico 6 — Integração GS1 | Enriquecimento por GTIN; Aprovação de marca | RF003 | MVP 2 | Em planejamento |
| Épico 7 — Ofertas de Fornecedor | Criar/editar ofertas; Importar CSV | RF004 | MVP 1 | Em planejamento |
| Épico 8 — Marketplace | Busca; Carrinho/timeout; Checkout | RF005, RF008 | MVP 1–3 | Em planejamento |
| Épico 9 — Gestão de Pedidos | Confirmação; Expedição; Admin visão | RF006, RF007 | MVP 2 | Em planejamento |
| Épico 10 — Disputas | Abrir disputa; Mediação/decisão | RF011 | MVP 3 | Em planejamento |
| Épico 11 — Notificações | Preferências; Envios | RF010 | MVP 2 | Em planejamento |
| Épico 12 — Área Administrativa | Gestão de entidades; Métricas | RF001–RF011 (transversal) | MVP 1 | Em planejamento |
| Épico 13 — Segurança/Observabilidade | LGPD; RLS; Logs; Alertas | RNF (segurança/operacional) | MVP 3 | Em planejamento |

## Épico 1 — IAM, Cadastro e Onboarding
- Contexto: perfis PF/PJ, convites, verificação e aprovação administrativa.
- Telas/rotas: `/cadastro`, `/cadastro/perfil`, `/cadastro/status`, `/verificar-email`, `/trocar-perfil`
- Tabelas/funcs: `iam_profiles`, `iam_individual_details`, `iam_organization_details`, `iam_profile_invitations`, `iam_user_preferences`, `set_active_profile(UUID)`
- Histórias:
  - PF/PJ: Como usuário, quero me cadastrar com e-mail/senha e concluir perfil PF/PJ para operar. [RF001, RF009]
  - Verificação: Como usuário, quero confirmar e-mail e (futuramente) 2FA. [RF002]
  - Convites: Como admin/org, quero convidar colaboradores via token expira em X. [RF009]
  - Seletor de perfil: Como usuário com múltiplos perfis, quero trocar o perfil ativo. [RF002]
  - Aprovação: Como admin, quero aprovar/rejeitar perfis e anexos. [RF001]
- Critérios:
  - Unicidade de CPF/CNPJ validada; status de onboarding por etapa; logs de rejeição em `iam_profile_rejections`.

## Épico 2 — RBAC e Navegação de UI
- Contexto: menus e permissões por papel.
- Telas: `/app/...` e menus
- Tabelas: `rbac_roles`, `rbac_user_roles`, `ui_app_pages`, `ui_app_elements`, `ui_role_element_permissions`
- Histórias:
  - Como admin, defino papéis e vínculos usuário↔papel.
  - Como usuário, vejo apenas elementos de menu permitidos pelo meu papel/perfil.
- Critérios:
  - Navegação derivada de `get_navigation_for_user()`; testes de permissão por role.

## Épico 3 — Integração Asaas (Contas Digitais, Saldos e Pagamentos)
- Contexto: contas digitais por perfil, adicionar saldo, extrato, saques.
- Telas: `/financeiro`, `/financeiro/adicionar-saldo`, `/financeiro/saques`
- Tabelas: `asaas_accounts`, `asaas_customers`, `asaas_payments`, `asaas_webhooks`, views `view_asaas_*`
- Histórias:
  - Como PF/PJ, vejo saldo e extrato da minha conta digital.
  - Como PF/PJ, adiciono saldo via PIX/Boleto/Cartão. [RF008]
  - Como PF/PJ, solicito saque; bloqueio 24h após alterar dados bancários. [RF008]
  - Como sistema, processo webhooks e reconcilio pagamentos. [RF008]
- Critérios:
  - Split/fees aplicados; retries e timeouts configurados; segurança de tokens de webhook.

## Épico 4 — Integração POS (Cappta)
- Contexto: Comerciantes PJ, transações POS, consolidação em saldo.
- Telas: `/comerciante/pos`, `/comerciante/pos/transacoes`
- Tabelas: `cappta_accounts`, `cappta_transactions`, `cappta_webhooks`, `cappta_api_responses`
- Histórias:
  - Como comerciante, conecto minha conta Cappta e vejo transações POS.
  - Como sistema, calculo net amount (`calculate_cappta_net_amount`) e reconcilio webhooks.
- Critérios:
  - Índices de performance aplicados; trilhas de auditoria em responses.

## Épico 5 — Catálogo do Marketplace (Produtos base)
- Contexto: catálogo centralizado e curadoria (Admin).
- Telas: `/admin/produtos`, `/admin/categorias`
- Tabelas: `marketplace_departments/categories/sub_categories`, `marketplace_brands`, `marketplace_products`, `marketplace_product_images`
- Histórias:
  - Como admin, CRUD de categorias (3 níveis) e produtos base. [RF003]
  - Como admin, aprovo/rejeito novas solicitações de produtos. [RF003]
- Critérios:
  - Unicidades por nível; `gtin` único; imagens com `image_type_code`.

## Épico 6 — Integração GS1 (Enriquecimento por GTIN)
- Contexto: consulta “Verified by GS1”, enriquecimento de produto.
- Telas: `/fornecedor/produtos/solicitar`, `/fornecedor/ofertas/nova`
- Tabelas: `gs1_api_responses`, `marketplace_products`, `marketplace_gpc_to_tricket_category_mapping`
- Histórias:
  - Como fornecedor, informo GTIN e recebo pré-preenchimento de dados/brand. 
  - Como admin, reviso/aceito marca nova com status `PENDING_APPROVAL`.
  - Como sistema, sugiro subcategoria via mapeamento GPC→Tricket. 
- Critérios:
  - Cache/resposta bruta em `gs1_api_responses`; enriquecimento persistido; fallback manual.

## Épico 7 — Ofertas de Fornecedor
- Contexto: preço, estoque/regra de venda por fornecedor.
- Telas: `/fornecedor/ofertas`, `/fornecedor/ofertas/nova`, `/fornecedor/produtos`
- Tabelas: `marketplace_supplier_products`
- Histórias:
  - Como fornecedor, crio/edito ofertas vinculadas a produto base. [RF004]
  - Importo CSV de ofertas. [RF004]
- Critérios:
  - Unicidade (produto_id + supplier_profile_id); períodos de promoção; min/max por pedido.

## Épico 8 — Marketplace (Busca, Carrinho, Checkout)
- Contexto: UX de compra (PF/PJ e Comerciante).
- Telas: `/marketplace`, `/marketplace/pesquisa`, `/carrinho`, `/checkout`, `/pedidos`
- Dados:
  - Frete PostGIS: `calculate_geolocation`, `iam_addresses`, regras de raio/free-shipping. [RF005]
- Histórias:
  - Como comprador, busco/filtrar produtos e adiciono ao carrinho com timeout 15 min. [RF005]
  - Como comprador, pago usando saldo Tricket/Asaas; split automático ao fornecedor. [RF005, RF008]
- Critérios:
  - Estoque/quantidades respeitados; simulação de frete por distância; pedidos e subpedidos estruturados.

## Épico 9 — Gestão de Pedidos (Fornecedor/Admin)
- Contexto: ciclo de pedido e SLA.
- Telas: `/fornecedor/pedidos`, `/admin/pedidos`
- Histórias:
  - Fornecedor confirma/rejeita pedidos (com motivo) em até 4h úteis; atualiza expedição e tracking. [RF006]
  - Admin visualiza todos pedidos e status. [RF007]
- Critérios:
  - Linha do tempo de eventos; auditabilidade; bloqueios de estado coerentes.

## Épico 10 — Disputas e Mediação
- Contexto: abertura, mediação e resolução.
- Telas: `/pedidos/:id/disputa`, `/fornecedor/disputas`, `/admin/disputas`
- Histórias:
  - Como comprador, abro disputa pós-entrega/prazo. [RF005]
  - Como fornecedor, respondo disputa. [RF006]
  - Como admin, media e decide (reembolso total/parcial, sem reembolso, acordo). [RF011]
- Critérios:
  - SLAs e alertas; registro de evidências; ajustes financeiros via Asaas conforme decisão.

## Épico 11 — Notificações
- Contexto: eventos e preferências.
- Telas: `/perfil/notificacoes`, `/notificacoes`
- Tabelas: `iam_contacts`, `iam_user_preferences` (+ camada de envio)
- Histórias:
  - Como usuário, configuro preferências (email, in-app). [RF010]
  - Como sistema, notifico eventos (pedido, disputa, verificação).
- Critérios:
  - Retry/backoff no envio; templates padronizados.

## Épico 12 — Área Administrativa Completa
- Telas: `/admin/...` (usuários, aprovações, categorias, produtos, pedidos, disputas, financeiro, configurações)
- Histórias:
  - Como admin, gerencio entidades core e acompanho métricas.
- Critérios:
  - RBAC estrito; trilha de auditoria; views de suporte (`view_admin_profile_approval`, etc.).

## Épico 13 — Segurança, Compliance e Observabilidade
- Itens transversais:
  - LGPD, RLS, `SECURITY DEFINER/INVOKER`, `SET search_path` fixo.  
  - Logs, índices críticos, políticas por tabela.  
  - Alertas para webhooks e pagamentos.
- Referências: `rpc-functions-standard.md`, `110-supabase_arquitetura.md`

---

## Roadmap por Fases (MVP → Scale)

- MVP 1 (Fundação):
  - Épicos 1, 2, 3 (básico de saldo), 5 (catálogo mínimo), 7 (ofertas), 8 (checkout PIX/saldo), 12 (admin básico).
- MVP 2 (Integrações e POS):
  - Épicos 4 (POS Cappta), 6 (GS1), frete PostGIS completo, 9 (pedidos fornecedor), 11 (notificações).
- MVP 3 (Operação completa):
  - Épicos 10 (disputas), 8 (carrinho/timeout e métodos adicionais), 13 (observabilidade e segurança avançadas).

---

## Backlog Técnico (prioridade alta)
- Implementar RPCs padronizadas para: onboarding/aprovação, navegação por role, consulta GTIN, criação de oferta, checkout e reconciliação.
- Políticas RLS por domínio; testes de permissão.
- Views otimizadas para grids do admin e fornecedor.
- Webhooks idempotentes (Asaas/Cappta) + dead-letter/retry.

---

## Traços de Implementação
- Backend: migrações em `tricket-backend/supabase/migrations/` conforme padrões de `rpc-functions-standard.md`.
- Frontend: seguir rotas de `estrutura-de-paginas-e-links.md`.
- Dados: seguir campos de `120_dicionario_de_dados.md` e extensões GS1.
