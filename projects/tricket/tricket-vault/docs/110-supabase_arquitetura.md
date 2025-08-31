---
id: 8cmaqrd-4193
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
# Arquitetura do Banco (Supabase)

Este documento inventaria a arquitetura definida pelas migrações em `tricket-backend/supabase/migrations/`. Abrange schemas, tabelas, tipos, funções, triggers, políticas (RLS), views, índices, grants e chaves estrangeiras, com referência aos arquivos de migração onde cada objeto é definido.

- Base: PostgreSQL (Supabase)
- Schema principal: `public` (alguns objetos CMS sem prefixo, portanto também no schema padrão `public`)
- Convenções: nomes por domínio (iam_, rbac_, ui_, cms_, marketplace_, asaas_, cappta_, gs1_)

## Sumário por Domínio

- IAM & RBAC: perfis, dados pessoais/organizacionais, membros, convites, endereços, contatos, rejeições; papéis e associação usuário↔papéis.
- UI: configurações de app, páginas, elementos, grids, permissões e cores.
- CMS (Blog): categorias, tags, posts, versões, comentários, relacionamentos post↔tag e aceite de termos de uso por post.
- Marketplace: departamentos, categorias e subcategorias, marcas, produtos, imagens e fornecedores; mapeamento GPC.
- Integrações
  - Asaas: contas, clientes, cobranças/pagamentos, webhooks e views de consolidação.
  - Cappta: contas, transações, webhooks, respostas da API e processamento de net amount.
  - GS1: armazenamento de respostas da API GS1.

---

## Schemas

 - `public` (principal) — múltiplos objetos; ver arquivos: todos os principais (ex.: `100_global_settings.sql`, `120_rbac.sql`, `200_iam_tables.sql`, etc.)

## Tipos (ENUM)

 Fonte: `100_global_settings.sql`, `130_cms_blog_structure.sql`

- public.profile_type_enum
- public.onboarding_status_enum
- public.invitation_status_enum
- public.individual_profile_role_enum
- public.organization_platform_role_enum
- public.organization_member_role_enum
- public.company_type_enum
- public.address_type_enum
- public.legal_document_type_enum
- public.bank_account_type_enum
- public.rejection_reason_category_enum
- public.notification_type_enum
 - public.element_type_enum (de UI) — `100_global_settings.sql`
 - cms_post_type — `130_cms_blog_structure.sql`
 - cms_post_status — `130_cms_blog_structure.sql`

## Tabelas (CREATE TABLE)

Referências principais:

- RBAC — `120_rbac.sql`
  - public.rbac_roles
  - public.rbac_user_roles

- UI — `140_ui_structure.sql`
  - public.ui_app_settings
  - public.ui_app_pages
  - public.ui_app_elements
  - public.ui_role_element_permissions
  - public.ui_grids
  - public.ui_grid_columns
  - public.ui_app_collors

- CMS — `130_cms_blog_structure.sql`
  - cms_categories
  - cms_tags
  - cms_posts
  - cms_post_tags
  - cms_post_versions
  - cms_post_user_agreements
  - cms_comments

- IAM — `200_iam_tables.sql`
  - public.iam_profiles
  - public.iam_individual_details
  - public.iam_organization_details
  - public.iam_organization_members
  - public.iam_profile_invitations
  - public.iam_addresses
  - public.iam_contacts
  - public.iam_profile_uploaded_documents
  - public.iam_rejection_reasons
  - public.iam_profile_rejections
  - public.iam_user_preferences (IF NOT EXISTS)

- GS1 — `220_gs1_tables.sql`
  - public.gs1_api_responses

- Marketplace — `210_marketplace_tables.sql`
  - public.marketplace_departments
  - public.marketplace_categories
  - public.marketplace_sub_categories
  - public.marketplace_brands
  - public.marketplace_products
  - public.marketplace_product_images
  - public.marketplace_supplier_products
  - public.marketplace_gpc_to_tricket_category_mapping

- Asaas — `230_asaas_integration.sql`
  - public.asaas_accounts
  - public.asaas_customers
  - public.asaas_payments
  - public.asaas_webhooks

- Asaas Master — `231_asaas_master_webhook.sql`
  - public.master_webhook_events
  - public.master_financial_transactions
  - public.subscription_propagation_log

- Cappta — `240_cappta_integration.sql`
  - public.cappta_accounts
  - public.cappta_transactions
  - public.cappta_webhooks
  - public.cappta_api_responses

- Cappta Opções (popular/lookup) — `241_cappta_populate_options.sql`
  - public.cappta_mcc_options
  - public.cappta_legal_nature_options
  - public.cappta_status_options
  - public.cappta_account_type_options
  - public.cappta_plan_types
  - public.cappta_product_types

Obs.: Existem arquivos de import massivo (28, 29, 30, 31, 33) focados em carga de dados, não em DDL principal.

## Views (CREATE OR REPLACE VIEW)

- `300_views_global.sql`
  - public.view_cities_with_states
  - public.view_products_with_image
  - public.view_supplier_products
- `310_views_admin.sql`
  - public.view_admin_profile_approval
- `320_views_asaas.sql`
  - public.view_asaas_accounts_with_profiles
  - public.view_asaas_accounts_summary
  - public.view_asaas_webhook_logs
- `330_cms_views.sql`
  - view_published_posts
- `231_asaas_master_webhook.sql`
  - public.v_master_webhook_summary

## Funções (CREATE OR REPLACE FUNCTION)

- Core/Utilitárias
  - public.handle_updated_at() — `100_global_settings.sql`
  - public.calculate_geolocation(p_latitude NUMERIC, p_longitude NUMERIC) — `530_functions_calculate_geolocation.sql`

- Checks/Validation — `500_functions_check.sql`
  - public.check_if_email_exists(email_to_check TEXT)
  - public.check_email_details(p_email TEXT)
  - public.is_email_available(p_email TEXT)
  - public.check_multiple_emails(p_emails TEXT[])
  - public.check_cpf_exists(p_cpf TEXT)
  - public.check_user_has_role(p_role_name TEXT)

- Contexto/Navegação — `510_functions_user_contexts.sql`
  - public.get_user_contexts()
  - public.get_navigation_for_user()

- IAM — `560_iam_functions.sql`
  - public.set_active_profile(p_profile_id UUID)

- Onboarding/Termos — `520_functions_terms.sql`
  - public.handle_user_confirmation_agreement()

- Registro de perfis — `550_functions_register_profiles.sql`
  - public.register_organization_profile(JSONB, JSONB, JSONB)
  - public.register_individual_profile(JSONB, JSONB)

- Marketplace/Produtos — `540_functions_check_product_exists.sql`
  - public.get_product_by_gtin(p_gtin TEXT)

- Asaas — `570_functions_asaas.sql`
  - public.process_asaas_webhook(webhook_id UUID)
  - public.sync_asaas_customer_with_profile(...)

- Asaas Master — `231_asaas_master_webhook.sql`
  - update_updated_at_column()

- Cappta — `580_functions_cappta.sql`
  - public.calculate_cappta_net_amount()
  - public.process_cappta_webhook(webhook_id UUID)

## Triggers (CREATE TRIGGER)

- RBAC/IAM
  - on_rbac_roles_update — `120_rbac.sql`
  - on_iam_profiles_update — `200_iam_tables.sql`

- Onboarding/Termos — `17_function_e_triggers_aceite_termos.sql`
  - zz_user_email_confirmation_agreement
  - zz_new_confirmed_user_agreement

- Asaas — `230_asaas_integration.sql`
  - on_asaas_accounts_update
  - on_asaas_customers_update
  - on_asaas_payments_update
  - on_asaas_webhooks_update

- Cappta — `240_cappta_integration.sql`
  - on_cappta_accounts_update
  - on_cappta_transactions_update
  - on_cappta_webhooks_update
  - calculate_cappta_net_amount_trigger

- Asaas Master — `231_asaas_master_webhook.sql`
  - update_master_webhook_events_updated_at
  - update_master_financial_transactions_updated_at
  - update_subscription_propagation_log_updated_at

## Políticas e RLS

- Habilitação de RLS
  - ALTER TABLE public.rbac_roles ENABLE ROW LEVEL SECURITY — `500_functions_check.sql`

- Policies
  - "Allow authenticated read access to profile_roles" — `500_functions_check.sql`

(Outras políticas podem existir em arquivos não capturados pelos padrões iniciais; sugerido varrer novas políticas ao evoluir este documento.)

## Índices (CREATE INDEX)

- Cappta — `240_cappta_integration.sql`
  - idx_cappta_accounts_profile_id, idx_cappta_accounts_cappta_account_id, idx_cappta_accounts_account_status, idx_cappta_accounts_merchant_id
  - idx_cappta_transactions_cappta_account_id, idx_cappta_transactions_marketplace_payment_id, idx_cappta_transactions_cappta_transaction_id, idx_cappta_transactions_transaction_status, idx_cappta_transactions_created_at, idx_cappta_transactions_settlement_date
  - idx_cappta_webhooks_cappta_account_id, idx_cappta_webhooks_webhook_event, idx_cappta_webhooks_processed, idx_cappta_webhooks_created_at
  - idx_cappta_api_responses_cappta_account_id, idx_cappta_api_responses_endpoint, idx_cappta_api_responses_response_status, idx_cappta_api_responses_created_at

- Asaas — `230_asaas_integration.sql`, `320_views_asaas.sql`
  - idx_asaas_* múltiplos em contas, clientes, pagamentos e webhooks (IDs externos, status, datas)

- Asaas Master — `231_asaas_master_webhook.sql`
  - idx_master_webhook_events_event_type, idx_master_webhook_events_processed, idx_master_webhook_events_created_at, idx_master_webhook_events_source
  - idx_master_financial_transactions_transfer_id, idx_master_financial_transactions_status, idx_master_financial_transactions_created_at, idx_master_financial_transactions_effective_date
  - idx_subscription_propagation_subscription_id, idx_subscription_propagation_customer_id, idx_subscription_propagation_status, idx_subscription_propagation_created_at

- IAM — `320_views_asaas.sql`
  - idx_iam_profiles_type, idx_iam_profiles_active

## Grants

Fonte: `500_functions_check.sql`, `560_iam_functions.sql`, `510_functions_user_contexts.sql`, `520_functions_terms.sql`, `550_functions_register_profiles.sql`, `540_functions_check_product_exists.sql`

- GRANT EXECUTE ON FUNCTION public.check_if_email_exists(TEXT) TO authenticated
- GRANT EXECUTE ON FUNCTION public.check_email_details(TEXT) TO authenticated
- GRANT EXECUTE ON FUNCTION public.is_email_available(TEXT) TO authenticated
- GRANT EXECUTE ON FUNCTION public.check_multiple_emails(TEXT[]) TO authenticated
- GRANT EXECUTE ON FUNCTION public.check_cpf_exists(TEXT) TO authenticated
- GRANT EXECUTE ON FUNCTION public.check_user_has_role(TEXT) TO authenticated
- GRANT EXECUTE ON FUNCTION public.set_active_profile(UUID) TO authenticated
- GRANT EXECUTE ON FUNCTION public.get_user_contexts() TO authenticated
- GRANT EXECUTE ON FUNCTION public.register_organization_profile(JSONB, JSONB, JSONB) TO authenticated
- GRANT EXECUTE ON FUNCTION public.register_individual_profile(JSONB, JSONB) TO authenticated
- GRANT EXECUTE ON FUNCTION public.get_product_by_gtin(TEXT) TO authenticated
- GRANT EXECUTE ON FUNCTION public.handle_user_confirmation_agreement() TO supabase_auth_admin

## Chaves Estrangeiras (FKs)

Exemplos detectados (não exaustivo):

 - `200_iam_tables.sql`
  - iam_profile_rejections.rejection_reason_id → public.iam_rejection_reasons(id) ON DELETE SET NULL

 - `241_cappta_populate_options.sql`
  - ...cappta_onboarding_status_id → public.cappta_status_options(id)
  - ...status_cappta_id → public.cappta_status_options(id)

(Outras FKs existem embutidas nas definições de tabelas; para mapeamento completo, extrair colunas e constraints de cada CREATE TABLE.)

---

## Observações e Próximos Passos

- Completar colunas e constraints por tabela (PK, FKs, UNIQUE, CHECK, DEFAULTs) com parsing detalhado dos arquivos SQL.
- Revisar políticas RLS por tabela e consolidar permissões efetivas por role (authenticated, anon, service_role, etc.).
- Gerar diagramas (ex.: ERD) a partir deste inventário, se desejado.
- Automatizar atualização deste documento via script que parseia os SQLs e regera este markdown.
