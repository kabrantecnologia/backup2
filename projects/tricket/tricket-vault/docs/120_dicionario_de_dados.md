---
id: 8cmaqrd-4213
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
# Dicionário de Dados — Tricket (Supabase/PostgreSQL)

Fonte de verdade: `tricket-backend/supabase/migrations/`
Este dicionário será expandido iterativamente até conter colunas, tipos, defaults, constraints, índices e RLS/policies de cada tabela.

Estrutura por domínios: IAM, RBAC, UI, CMS, Marketplace, Asaas, Cappta, GS1.

Legenda de campos a preencher por tabela:
- Colunas (nome, tipo, null, default)
- Constraints (PK, FKs com ON DELETE/UPDATE, UNIQUE, CHECK)
- Índices (nome, colunas, unique?)
- RLS/Policies (habilitado? policies por operação/role)
- Comentários (descrições)
- Origem (arquivo de migração)

---

## 1. RBAC — (origem: `03_rbac.sql`)

### Tabela: `public.rbac_roles`
- Colunas:
  - `id UUID PK DEFAULT extensions.uuid_generate_v4()`
  - `name TEXT NOT NULL UNIQUE`
  - `description TEXT`
  - `level INTEGER`
  - `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints:
  - PK(`id`). UNIQUE(`name`).
- Índices:
  - [não há índices além de UNIQUE(name)]
- RLS/Policies:
  - RLS habilitado em `12_functions_check.sql` (ALTER TABLE public.rbac_roles ENABLE ROW LEVEL SECURITY)
  - Políticas específicas não definidas neste arquivo
- Comentários:
  - Tabela e colunas comentadas nas migrações (descrição, nível hierárquico)
- Origem: `tricket-backend/supabase/migrations/03_rbac.sql` (linhas ~9–16)

### Tabela: `public.rbac_user_roles`
- Colunas:
  - `id UUID PK DEFAULT extensions.uuid_generate_v4()`
  - `user_id UUID NOT NULL` → FK `auth.users(id)` ON DELETE CASCADE
  - `role_id UUID NOT NULL` → FK `public.rbac_roles(id)` ON DELETE CASCADE
  - `created_at TIMESTAMPTZ DEFAULT now()`
- Constraints:
  - PK(`id`). UNIQUE(`user_id`, `role_id`). FKs conforme acima.
- Índices:
  - [não há índices adicionais]
- RLS/Policies:
  - [não definido nos arquivos consultados]
- Comentários:
  - Tabela de associação entre usuários e papéis
- Origem: `tricket-backend/supabase/migrations/03_rbac.sql` (linhas ~28–35)

---

## 2. UI — (origem: `04_ui_structure.sql`)

### Tabela: `public.ui_app_settings`
- Colunas: `key TEXT PK`, `value TEXT`, `description TEXT`
- Constraints: PK(`key`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Configurações chave‑valor
- Origem: `04_ui_structure.sql` (linhas ~24–33)

### Tabela: `public.ui_app_pages`
- Colunas: `id TEXT PK`, `path TEXT NOT NULL UNIQUE`, `name TEXT NOT NULL`, `description TEXT`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`), UNIQUE(`path`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Páginas da aplicação
- Origem: `04_ui_structure.sql` (linhas ~36–43)

### Tabela: `public.ui_app_elements`
- Colunas: `id TEXT PK`, `element_type public.element_type_enum NOT NULL`, `parent_id TEXT FK ui_app_elements(id) ON DELETE CASCADE`,
  `page_id TEXT FK ui_app_pages(id) ON DELETE CASCADE`, `label TEXT NOT NULL`, `icon TEXT`, `path TEXT`, `position SMALLINT DEFAULT 0`,
  `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`), FKs conforme acima
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Elementos de navegação (menus/abas)
- Origem: `04_ui_structure.sql` (linhas ~51–62)

### Tabela: `public.ui_role_element_permissions`
- Colunas: `role_id UUID NOT NULL FK rbac_roles(id) ON DELETE CASCADE`, `element_id TEXT NOT NULL FK ui_app_elements(id) ON DELETE CASCADE`
- Constraints: PK(`role_id`, `element_id`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Permissão de elementos por role
- Origem: `04_ui_structure.sql` (linhas ~79–83)

### Tabela: `public.ui_grids`
- Colunas: `id TEXT PK`, `page_id TEXT FK ui_app_pages(id)`, `collection_id UUID`, `description TEXT`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Configuração de grids
- Origem: `04_ui_structure.sql` (linhas ~96–103)

### Tabela: `public.ui_grid_columns`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `grid_id TEXT NOT NULL FK ui_grids(id) ON DELETE CASCADE`, `data_key TEXT NOT NULL`, `label TEXT NOT NULL`,
  `size TEXT DEFAULT '1fr'`, `position INT DEFAULT 0`, `is_visible BOOLEAN DEFAULT true`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`,
  UNIQUE(`grid_id`, `data_key`)
- Constraints: PK(`id`), UNIQUE(`grid_id`,`data_key`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Colunas de grids
- Origem: `04_ui_structure.sql` (linhas ~105–116)

### Tabela: `public.ui_app_collors`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `name TEXT NOT NULL UNIQUE`, `light_theme_hex TEXT NOT NULL`, `dark_theme_hex TEXT NOT NULL`,
  `category TEXT NOT NULL`, `description TEXT`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`), UNIQUE(`name`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Paleta de cores
- Origem: `04_ui_structure.sql` (linhas ~120–129)

---

## 3. CMS — (origem: `06_blog_structure.sql`)

### Tabela: `public.cms_categories`
- Colunas: `id uuid PK DEFAULT uuid_generate_v4()`, `name text NOT NULL UNIQUE`, `slug text NOT NULL UNIQUE`, `description text`
- Constraints: PK(`id`), UNIQUE(`name`), UNIQUE(`slug`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Categorias para organizar posts/documentos
- Origem: `06_blog_structure.sql` (linhas ~26–33)

### Tabela: `public.cms_tags`
- Colunas: `id uuid PK DEFAULT uuid_generate_v4()`, `name text NOT NULL UNIQUE`, `slug text NOT NULL UNIQUE`
- Constraints: PK(`id`), UNIQUE(`name`), UNIQUE(`slug`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Tags (palavras‑chave) para posts
- Origem: `06_blog_structure.sql` (linhas ~39–43)

### Tabela: `public.cms_posts`
- Colunas: `id uuid PK DEFAULT uuid_generate_v4()`, `type cms_post_type NOT NULL`, `category_id uuid FK cms_categories(id)`,
  `slug text NOT NULL UNIQUE`, `title text NOT NULL`, `excerpt text`, `cover_image_url text`, `author_id uuid FK auth.users(id)`,
  `status cms_post_status NOT NULL DEFAULT 'DRAFT'`, `published_at timestamptz`, `created_at timestamptz DEFAULT now()`, `updated_at timestamptz DEFAULT now()`
- Constraints: PK(`id`), UNIQUE(`slug`), FKs conforme acima
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Tabela principal de conteúdo
- Origem: `06_blog_structure.sql` (linhas ~49–62)

### Tabela: `public.cms_post_tags`
- Colunas: `post_id uuid NOT NULL FK cms_posts(id) ON DELETE CASCADE`, `tag_id uuid NOT NULL FK cms_tags(id) ON DELETE CASCADE`
- Constraints: PK(`post_id`, `tag_id`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Junção N‑N entre posts e tags
- Origem: `06_blog_structure.sql` (linhas ~68–72)

### Tabela: `public.cms_post_versions`
- Colunas: `id uuid PK DEFAULT uuid_generate_v4()`, `post_id uuid NOT NULL FK cms_posts(id) ON DELETE CASCADE`,
  `version integer NOT NULL`, `content jsonb NOT NULL`, `change_log text`, `author_id uuid FK auth.users(id)`,
  `created_at timestamptz DEFAULT now()`
- Constraints: PK(`id`), UNIQUE(`post_id`, `version`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Histórico de versões do conteúdo
- Origem: `06_blog_structure.sql` (linhas ~76–87)

### Tabela: `public.cms_post_user_agreements`
- Colunas: `id uuid PK DEFAULT uuid_generate_v4()`, `profile_id uuid NOT NULL`, `post_version_id uuid NOT NULL FK cms_post_versions(id)`,
  `agreed_at timestamptz DEFAULT now()`, `ip_address inet`
- Constraints: PK(`id`), UNIQUE(`profile_id`, `post_version_id`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Registro de aceite de versão específica de documento
- Origem: `06_blog_structure.sql` (linhas ~93–101)

### Tabela: `public.cms_comments`
- Colunas: `id uuid PK DEFAULT uuid_generate_v4()`, `post_id uuid NOT NULL FK cms_posts(id) ON DELETE CASCADE`,
  `author_id uuid NOT NULL FK auth.users(id)`, `parent_comment_id uuid FK cms_comments(id) ON DELETE CASCADE`,
  `content text NOT NULL`, `created_at timestamptz DEFAULT now()`, `updated_at timestamptz`
- Constraints: PK(`id`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Comentários e threads
- Origem: `06_blog_structure.sql` (linhas ~106–118)

---

## 4. IAM — (origem: `11_iam_profiles_and_rbac.sql`)

### Tabela: `public.iam_profiles`
- Colunas: `id UUID PK DEFAULT extensions.uuid_generate_v4()`,
  `profile_type public.profile_type_enum NOT NULL`, `avatar_url TEXT`,
  `onboarding_status public.onboarding_status_enum NOT NULL`,
  `time_zone TEXT DEFAULT 'America/Sao_Paulo'`, `active BOOLEAN DEFAULT true`,
  `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`)
- Índices: [ver `23_views_asaas.sql`: idx_iam_profiles_type, idx_iam_profiles_active]
- RLS/Policies: [não especificado]
- Comentários: Tabela principal de perfis
- Origem: `11_iam_profiles_and_rbac.sql` (linhas ~8–17)

### Tabela: `public.iam_individual_details`
- Colunas: `profile_id UUID PK FK iam_profiles(id) ON DELETE CASCADE`, `auth_user_id UUID NOT NULL UNIQUE FK auth.users(id)`,
  `profile_role public.individual_profile_role_enum NOT NULL`, `full_name TEXT NOT NULL`,
  `cpf TEXT UNIQUE NOT NULL`, `birth_date DATE NOT NULL`, `gender TEXT`, `income_value_cents BIGINT`,
  `contact_email TEXT`, `contact_phone TEXT`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`profile_id`), UNIQUE(`auth_user_id`), UNIQUE(`cpf`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Detalhes de PF
- Origem: `11_iam_profiles_and_rbac.sql` (linhas ~38–51)

### Tabela: `public.iam_organization_details`
- Colunas: `profile_id UUID PK FK iam_profiles(id) ON DELETE CASCADE`,
  `platform_role public.organization_platform_role_enum NOT NULL`, `company_name TEXT NOT NULL`, `trade_name TEXT`,
  `cnpj TEXT UNIQUE NOT NULL`, `company_type public.company_type_enum NOT NULL`, `income_value_cents BIGINT`,
  `contact_email TEXT UNIQUE`, `contact_phone TEXT`, `national_registry_for_legal_entities_status TEXT`,
  `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`profile_id`), UNIQUE(`cnpj`), UNIQUE(`contact_email`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Detalhes de PJ
- Origem: `11_iam_profiles_and_rbac.sql` (linhas ~62–74)

### Tabela: `public.iam_organization_members`
- Colunas: `organization_profile_id UUID NOT NULL FK iam_profiles(id) ON DELETE CASCADE`,
  `member_user_id UUID NOT NULL FK auth.users(id) ON DELETE CASCADE`,
  `role public.organization_member_role_enum NOT NULL`,
  `is_active BOOLEAN DEFAULT true`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`organization_profile_id`, `member_user_id`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Associação de membros a organizações
- Origem: `11_iam_profiles_and_rbac.sql` (linhas ~85–92)

### Tabela: `public.iam_profile_invitations`
- Colunas: `id UUID PK DEFAULT extensions.uuid_generate_v4()`, `email TEXT NOT NULL`, `name TEXT`,
  `invited_as_profile_type public.profile_type_enum NOT NULL`, `role public.organization_member_role_enum`,
  `invited_by_user_id UUID FK auth.users(id) ON DELETE SET NULL`, `org_id UUID FK iam_profiles(id) ON DELETE CASCADE`,
  `token TEXT UNIQUE NOT NULL`, `expires_at TIMESTAMPTZ NOT NULL`,
  `status public.invitation_status_enum NOT NULL DEFAULT 'PENDING'`, `accepted_at TIMESTAMPTZ`,
  `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`), UNIQUE(`token`), CHECK `chk_role_org_id_type` (role só quando org_id não nulo e tipo = 'INDIVIDUAL')
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Convites para perfis/organizações
- Origem: `11_iam_profiles_and_rbac.sql` (linhas ~106–121)

### Tabela: `public.iam_addresses`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `profile_id UUID NOT NULL FK iam_profiles(id) ON DELETE CASCADE`,
  `address_type public.address_type_enum NOT NULL`, `is_default BOOLEAN DEFAULT false`, `street TEXT NOT NULL`, `number TEXT NOT NULL`,
  `complement TEXT`, `neighborhood TEXT NOT NULL`, `city_id INTEGER NOT NULL FK generic_cities(id) ON DELETE RESTRICT`,
  `state_id INTEGER NOT NULL FK generic_states(id) ON DELETE RESTRICT`, `zip_code TEXT NOT NULL`, `country TEXT NOT NULL DEFAULT 'Brasil'`,
  `latitude NUMERIC(10,7)`, `longitude NUMERIC(10,7)`, `geolocation GEOGRAPHY(POINT,4326)`, `notes TEXT`,
  `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Endereços por perfil; inclui geolocalização PostGIS
- Origem: `11_iam_profiles_and_rbac.sql` (linhas ~131–150)

### Tabela: `public.iam_contacts`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `profile_id UUID NOT NULL FK iam_profiles(id) ON DELETE CASCADE`,
  `name TEXT`, `label TEXT`, `email TEXT`, `phone TEXT`, `whatsapp BOOLEAN DEFAULT false`, `is_default BOOLEAN DEFAULT false`,
  `email_verified BOOLEAN DEFAULT false`, `phone_verified BOOLEAN DEFAULT false`, `verified_at TIMESTAMPTZ`,
  `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`), CHECK `at_least_one_contact_info` (email ou phone obrigatórios)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Contatos associados ao perfil
- Origem: `11_iam_profiles_and_rbac.sql` (linhas ~158–173)

### Tabela: `public.iam_profile_uploaded_documents`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `profile_id UUID NOT NULL FK iam_profiles(id) ON DELETE CASCADE`,
  `document_name TEXT NOT NULL`, `status TEXT NOT NULL`, `file_path TEXT NOT NULL`, `storage_bucket TEXT NOT NULL`,
  `verified_by_user_id UUID FK auth.users(id) ON DELETE SET NULL`, `verification_date TIMESTAMPTZ`,
  `rejection_reason_id UUID FK iam_rejection_reasons(id) ON DELETE SET NULL`, `rejection_notes TEXT`, `expires_at TIMESTAMPTZ`,
  `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Documentos enviados para verificação
- Origem: `11_iam_profiles_and_rbac.sql` (linhas ~182–222)

### Tabela: `public.iam_rejection_reasons`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `reason_code VARCHAR(100) NOT NULL UNIQUE`, `description TEXT NOT NULL`,
  `category public.rejection_reason_category_enum NOT NULL`, `source_system TEXT`, `user_action_required TEXT`, `internal_notes TEXT`,
  `is_active BOOLEAN DEFAULT true`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`), UNIQUE(`reason_code`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Catálogo de motivos de rejeição
- Origem: `11_iam_profiles_and_rbac.sql` (linhas ~204–214)

### Tabela: `public.iam_profile_rejections`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `profile_id UUID NOT NULL FK iam_profiles(id) ON DELETE CASCADE`,
  `rejection_reason_id UUID NOT NULL FK iam_rejection_reasons(id) ON DELETE RESTRICT`, `related_entity_id UUID`, `related_entity_type TEXT`,
  `rejected_by_user_id UUID FK auth.users(id) ON DELETE SET NULL`, `rejected_at TIMESTAMPTZ DEFAULT now()`, `notes TEXT`,
  `is_resolved BOOLEAN DEFAULT false`, `resolved_at TIMESTAMPTZ`, `resolution_notes TEXT`,
  `resolved_by_user_id UUID FK auth.users(id) ON DELETE SET NULL`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Histórico de rejeições relacionadas a perfis/entidades
- Origem: `11_iam_profiles_and_rbac.sql` (linhas ~226–241)

### Tabela: `public.iam_user_preferences`
- Colunas: `user_id UUID PK FK auth.users(id) ON DELETE CASCADE`, `active_profile_id UUID FK iam_profiles(id) ON DELETE SET NULL`,
  `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`, `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`
- Constraints: PK(`user_id`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Preferências do usuário incluindo perfil ativo; função `set_active_profile(UUID)` disponível
- Origem: `11_iam_profiles_and_rbac.sql` (linhas ~251–258)

---

## 5. Marketplace — (origem: `18_marketplace_catalogo_ofertas.sql`)

### Tabela: `public.marketplace_departments`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `name TEXT NOT NULL UNIQUE`, `slug TEXT NOT NULL UNIQUE`, `description TEXT`,
  `icon_url TEXT`, `is_active BOOLEAN DEFAULT true`, `sort_order INTEGER DEFAULT 0`,
  `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`), UNIQUE(`name`), UNIQUE(`slug`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Hierarquia de topo (departamentos)
- Origem: `18_marketplace_catalogo_ofertas.sql` (linhas ~8–18)

### Tabela: `public.marketplace_categories`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `department_id UUID NOT NULL FK marketplace_departments(id) ON DELETE CASCADE`,
  `name TEXT NOT NULL`, `slug TEXT NOT NULL`, `description TEXT`, `icon_url TEXT`, `is_active BOOLEAN DEFAULT true`,
  `sort_order INTEGER DEFAULT 0`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`), UNIQUE(`department_id`, `name`), UNIQUE(`department_id`, `slug`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Segundo nível (categorias)
- Origem: `18_marketplace_catalogo_ofertas.sql` (linhas ~23–37)

### Tabela: `public.marketplace_sub_categories`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `category_id UUID NOT NULL FK marketplace_categories(id) ON DELETE CASCADE`,
  `name TEXT NOT NULL`, `slug TEXT NOT NULL`, `description TEXT`, `icon_url TEXT`, `is_active BOOLEAN DEFAULT true`,
  `sort_order INTEGER DEFAULT 0`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`), UNIQUE(`category_id`, `name`), UNIQUE(`category_id`, `slug`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Terceiro nível (subcategorias)
- Origem: `18_marketplace_catalogo_ofertas.sql` (linhas ~41–55)

### Tabela: `public.marketplace_brands`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `name TEXT NOT NULL UNIQUE`, `slug TEXT UNIQUE`, `description TEXT`, `logo_url TEXT`,
  `official_website TEXT`, `country_of_origin_code TEXT`, `gs1_company_prefix TEXT`, `gln_brand_owner TEXT`, `status TEXT DEFAULT 'PENDING_APPROVAL'`,
  `approved_by_user_id UUID FK auth.users(id) ON DELETE SET NULL`, `approved_at TIMESTAMPTZ`,
  `created_by_user_id UUID FK auth.users(id) ON DELETE SET NULL`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`), UNIQUE(`name`), UNIQUE(`slug`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Marcas de produtos
- Origem: `18_marketplace_catalogo_ofertas.sql` (linhas ~63–81)

### Tabela: `public.marketplace_products`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `sub_category_id UUID FK marketplace_sub_categories(id) ON DELETE SET NULL`,
  `brand_id UUID FK marketplace_brands(id) ON DELETE SET NULL`, `name TEXT NOT NULL`, `description TEXT`, `sku_base TEXT`, `attributes JSONB`,
  `status TEXT DEFAULT 'ACTIVE'`, `gtin TEXT UNIQUE NOT NULL`, `gpc_category_code TEXT`, `ncm_code TEXT`, `cest_code TEXT`,
  `net_content NUMERIC`, `net_content_unit TEXT`, `gross_weight NUMERIC`, `net_weight NUMERIC`, `weight_unit TEXT`,
  `height NUMERIC`, `width NUMERIC`, `depth NUMERIC`, `dimension_unit TEXT`, `country_of_origin_code TEXT`, `gs1_company_name TEXT`, `gs1_company_gln TEXT`,
  `created_by_user_id UUID FK auth.users(id) ON DELETE SET NULL`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`), UNIQUE(`gtin`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Catálogo central de produtos
- Origem: `18_marketplace_catalogo_ofertas.sql` (linhas ~85–115)

### Tabela: `public.marketplace_product_images`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `product_id UUID NOT NULL FK marketplace_products(id) ON DELETE CASCADE`,
  `image_url TEXT NOT NULL`, `alt_text TEXT`, `sort_order INT DEFAULT 0`, `image_type_code TEXT`, `created_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Imagens por produto
- Origem: `18_marketplace_catalogo_ofertas.sql` (linhas ~122–132)

### Tabela: `public.marketplace_supplier_products`
- Colunas: `id UUID PK DEFAULT gen_random_uuid()`, `product_id UUID NOT NULL FK marketplace_products(id) ON DELETE CASCADE`,
  `supplier_profile_id UUID NOT NULL FK iam_profiles(id) ON DELETE CASCADE`, `supplier_sku TEXT`, `price_cents INTEGER NOT NULL`,
  `cost_price_cents INTEGER`, `promotional_price_cents INTEGER`, `promotion_start_date TIMESTAMPTZ`, `promotion_end_date TIMESTAMPTZ`,
  `min_order_quantity INTEGER DEFAULT 1`, `max_order_quantity INTEGER`, `barcode_ean TEXT`, `status TEXT DEFAULT 'DRAFT'`,
  `is_active_by_supplier BOOLEAN DEFAULT true`, `approved_at TIMESTAMPTZ`, `created_by_user_id UUID FK auth.users(id) ON DELETE SET NULL`,
  `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`id`), UNIQUE(`product_id`, `supplier_profile_id`)
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Ofertas dos fornecedores
- Origem: `18_marketplace_catalogo_ofertas.sql` (linhas ~140–162)

### Tabela: `public.marketplace_gpc_to_tricket_category_mapping`
- Colunas: `gpc_category_code TEXT PK`, `gpc_category_name TEXT`, `tricket_sub_category_id UUID FK marketplace_sub_categories(id) ON DELETE SET NULL`,
  `status TEXT DEFAULT 'PENDENT' NOT NULL CHECK (status IN ('PENDENT', 'COMPLETED'))`,
  `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints: PK(`gpc_category_code`), CHECK(Status in ('PENDENT','COMPLETED'))
- Índices: [não especificado]
- RLS/Policies: [não especificado]
- Comentários: Mapeamento GPC → subcategoria interna
- Origem: `18_marketplace_catalogo_ofertas.sql` (linhas ~173–184)

- Observação: módulo transacional do marketplace planejado, p.ex. `marketplace_payments` (sem DDL nas migrações atuais). Campos `marketplace_payment_id` referenciam essa intenção em `asaas_payments` e `cappta_transactions`.

---

## 6. Asaas — (origem: `22_tricket_asaas_integration.sql`)

### Tabela: `public.asaas_accounts`
- Colunas:
  - `id UUID PK DEFAULT extensions.uuid_generate_v4()`
  - `profile_id UUID NOT NULL` → FK `public.iam_profiles(id)` ON DELETE CASCADE
  - `asaas_account_id TEXT UNIQUE NOT NULL`
  - `api_key TEXT NOT NULL`
  - `account_status TEXT DEFAULT 'PENDING'`
  - `account_type TEXT DEFAULT 'MERCHANT'`
  - `wallet_id TEXT`, `webhook_url TEXT`, `webhook_token TEXT`
  - `onboarding_status TEXT DEFAULT 'PENDING'`, `verification_status TEXT`
  - `onboarding_data JSONB`, `account_settings JSONB`, `fees_configuration JSONB`
  - `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints:
  - PK(`id`). FK(`profile_id`) → `iam_profiles(id)` CASCADE. UNIQUE(`asaas_account_id`).
- Índices:
  - `idx_asaas_accounts_profile_id(profile_id)`, `idx_asaas_accounts_asaas_account_id(asaas_account_id)`
  - `idx_asaas_accounts_account_status(account_status)`, `idx_asaas_accounts_verification_status(verification_status)`
- RLS/Policies: [não definido neste arquivo]
- Comentários: tabela e colunas documentadas nas migrações.
- Origem: `tricket-backend/supabase/migrations/22_tricket_asaas_integration.sql` (linhas ~6–23, 117–121)

### Tabela: `public.asaas_customers`
- Colunas:
  - `id UUID PK DEFAULT extensions.uuid_generate_v4()`
  - `asaas_account_id UUID NOT NULL` → FK `public.asaas_accounts(id)` ON DELETE CASCADE
  - `profile_id UUID` → FK `public.iam_profiles(id)` ON DELETE SET NULL
  - `asaas_customer_id TEXT UNIQUE NOT NULL`
  - `customer_name TEXT NOT NULL`, `customer_email TEXT`, `customer_phone TEXT`
  - `customer_cpf_cnpj TEXT`, `customer_type TEXT`
  - `address JSONB`, `customer_data JSONB`, `is_active BOOLEAN DEFAULT true`
  - `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints:
  - PK(`id`). UNIQUE(`asaas_customer_id`). FKs conforme acima.
- Índices:
  - `idx_asaas_customers_asaas_account_id(asaas_account_id)`, `idx_asaas_customers_profile_id(profile_id)`
  - `idx_asaas_customers_asaas_customer_id(asaas_customer_id)`, `idx_asaas_customers_customer_cpf_cnpj(customer_cpf_cnpj)`
- RLS/Policies: [não definido neste arquivo]
- Origem: `22_tricket_asaas_integration.sql` (linhas ~32–47, 123–126)

### Tabela: `public.asaas_payments`
- Colunas:
  - `id UUID PK DEFAULT extensions.uuid_generate_v4()`
  - `asaas_account_id UUID NOT NULL` → FK `public.asaas_accounts(id)` ON DELETE CASCADE
  - `asaas_customer_id UUID NOT NULL` → FK `public.asaas_customers(id)` ON DELETE RESTRICT
  - `marketplace_payment_id UUID` [planejada FK para `marketplace_payments.id`]
  - `asaas_payment_id TEXT UNIQUE NOT NULL`
  - `billing_type TEXT NOT NULL`, `payment_status TEXT DEFAULT 'PENDING'`
  - `value_cents INTEGER NOT NULL`, `net_value_cents INTEGER`, `original_value_cents INTEGER`, `interest_value_cents INTEGER`
  - `description TEXT`, `external_reference TEXT`
  - `due_date DATE NOT NULL`, `payment_date DATE`, `credit_date DATE`, `estimated_credit_date DATE`
  - `installment_count INTEGER DEFAULT 1`, `installment_number INTEGER DEFAULT 1`, `installment_value_cents INTEGER`
  - `discount JSONB`, `fine JSONB`, `interest JSONB`
  - `payment_link TEXT`, `bank_slip_url TEXT`, `invoice_url TEXT`
  - `pix_transaction JSONB`, `credit_card JSONB`, `asaas_response JSONB`
  - `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints:
  - PK(`id`). UNIQUE(`asaas_payment_id`). FKs conforme acima. `marketplace_payment_id` sem FK atual.
- Índices:
  - `idx_asaas_payments_asaas_account_id(asaas_account_id)`, `idx_asaas_payments_asaas_customer_id(asaas_customer_id)`
  - `idx_asaas_payments_marketplace_payment_id(marketplace_payment_id)`, `idx_asaas_payments_asaas_payment_id(asaas_payment_id)`
  - `idx_asaas_payments_payment_status(payment_status)`, `idx_asaas_payments_billing_type(billing_type)`
  - `idx_asaas_payments_due_date(due_date)`, `idx_asaas_payments_payment_date(payment_date)`
- RLS/Policies: [não definido neste arquivo]
- Origem: `22_tricket_asaas_integration.sql` (linhas ~55–87, 128–136)

### Tabela: `public.asaas_webhooks`
- Colunas:
  - `id UUID PK DEFAULT extensions.uuid_generate_v4()`
  - `asaas_account_id UUID` → FK `public.asaas_accounts(id)` ON DELETE SET NULL
  - `webhook_event TEXT NOT NULL`, `webhook_data JSONB NOT NULL`
  - `processed BOOLEAN DEFAULT false`, `processed_at TIMESTAMPTZ`, `processing_error TEXT`, `retry_count INTEGER DEFAULT 0`
  - `signature_valid BOOLEAN`, `raw_payload TEXT`
  - `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints:
  - PK(`id`). FK opcional conforme acima.
- Índices:
  - `idx_asaas_webhooks_asaas_account_id(asaas_account_id)`, `idx_asaas_webhooks_webhook_event(webhook_event)`
  - `idx_asaas_webhooks_processed(processed)`, `idx_asaas_webhooks_created_at(created_at)`
- RLS/Policies: [não definido neste arquivo]
- Origem: `22_tricket_asaas_integration.sql` (linhas ~97–110, 137–140)

---

## 7. Cappta — (origens: `24_cappta_integration.sql`, `25_cappta_populate.sql`)

### Tabela: `public.cappta_accounts`
- Colunas:
  - `id UUID PK DEFAULT extensions.uuid_generate_v4()`
  - `profile_id UUID NOT NULL` → FK `public.iam_profiles(id)` ON DELETE CASCADE
  - `cappta_account_id TEXT UNIQUE NOT NULL`
  - `account_status TEXT DEFAULT 'PENDING'`, `account_type TEXT`
  - `merchant_id TEXT`, `terminal_id TEXT`
  - `api_key TEXT`, `secret_key TEXT`, `webhook_url TEXT`, `webhook_secret TEXT`
  - `onboarding_status TEXT DEFAULT 'PENDING'`, `onboarding_data JSONB`, `verification_documents JSONB`, `account_settings JSONB`
  - `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints:
  - PK(`id`). FK(`profile_id`) → `iam_profiles(id)` CASCADE. UNIQUE(`cappta_account_id`).
- Índices:
  - `idx_cappta_accounts_profile_id(profile_id)`, `idx_cappta_accounts_cappta_account_id(cappta_account_id)`
  - `idx_cappta_accounts_account_status(account_status)`, `idx_cappta_accounts_merchant_id(merchant_id)`
- RLS/Policies: [não definido neste arquivo]
- Origem: `24_cappta_integration.sql` (linhas ~7–25, 89–94)

### Tabela: `public.cappta_transactions`
- Colunas:
  - `id UUID PK DEFAULT extensions.uuid_generate_v4()`
  - `cappta_account_id UUID NOT NULL` → FK `public.cappta_accounts(id)` ON DELETE CASCADE
  - `marketplace_payment_id UUID` [planejada FK para `marketplace_payments.id`]
  - `cappta_transaction_id TEXT UNIQUE NOT NULL`
  - `transaction_type TEXT NOT NULL`, `transaction_status TEXT DEFAULT 'PENDING'`
  - `amount_cents INTEGER NOT NULL`, `currency_code TEXT DEFAULT 'BRL'`
  - `payment_method TEXT`, `card_brand TEXT`, `card_last_digits TEXT`
  - `authorization_code TEXT`, `nsu TEXT`, `tid TEXT`, `installments INTEGER DEFAULT 1`
  - `merchant_fee_cents INTEGER`, `gateway_fee_cents INTEGER`, `net_amount_cents INTEGER`
  - `settlement_date DATE`, `transaction_data JSONB`, `cappta_response JSONB`
  - `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints:
  - PK(`id`). UNIQUE(`cappta_transaction_id`). FKs conforme acima. `marketplace_payment_id` sem FK atual.
- Índices:
  - `idx_cappta_transactions_cappta_account_id(cappta_account_id)`, `idx_cappta_transactions_marketplace_payment_id(marketplace_payment_id)`
  - `idx_cappta_transactions_cappta_transaction_id(cappta_transaction_id)`, `idx_cappta_transactions_transaction_status(transaction_status)`
  - `idx_cappta_transactions_created_at(created_at)`, `idx_cappta_transactions_settlement_date(settlement_date)`
- RLS/Policies: [não definido neste arquivo]
- Origem: `24_cappta_integration.sql` (linhas ~35–66, 95–101)

### Tabela: `public.cappta_webhooks`
- Colunas:
  - `id UUID PK DEFAULT extensions.uuid_generate_v4()`
  - `cappta_account_id UUID` → FK `public.cappta_accounts(id)` ON DELETE SET NULL
  - `webhook_event TEXT NOT NULL`, `webhook_data JSONB NOT NULL`
  - `processed BOOLEAN DEFAULT false`, `processed_at TIMESTAMPTZ`, `processing_error TEXT`, `retry_count INTEGER DEFAULT 0`
  - `signature_valid BOOLEAN`, `raw_payload TEXT`
  - `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Constraints:
  - PK(`id`). FK opcional conforme acima.
- Índices:
  - `idx_cappta_webhooks_cappta_account_id(cappta_account_id)`, `idx_cappta_webhooks_webhook_event(webhook_event)`
  - `idx_cappta_webhooks_processed(processed)`, `idx_cappta_webhooks_created_at(created_at)`
- RLS/Policies: [não definido neste arquivo]
- Origem: `24_cappta_integration.sql` (linhas ~68–81, 102–105)

### Tabela: `public.cappta_api_responses`
- Colunas:
  - `id UUID PK DEFAULT extensions.uuid_generate_v4()`
  - `cappta_account_id UUID` → FK `public.cappta_accounts(id)` ON DELETE SET NULL
  - `endpoint TEXT NOT NULL`, `http_method TEXT NOT NULL`
  - `request_data JSONB`, `response_status INTEGER`, `response_data JSONB`, `response_time_ms INTEGER`, `error_message TEXT`
  - `created_at TIMESTAMPTZ DEFAULT now()`
- Constraints:
  - PK(`id`). FK opcional conforme acima.
- Índices:
  - `idx_cappta_api_responses_cappta_account_id(cappta_account_id)`, `idx_cappta_api_responses_endpoint(endpoint)`
  - `idx_cappta_api_responses_response_status(response_status)`, `idx_cappta_api_responses_created_at(created_at)`
- RLS/Policies: [não definido neste arquivo]
- Origem: `24_cappta_integration.sql` (linhas ~112–131, 133–136)

### Tabela: `public.cappta_mcc_options`
- [TODO]

### Tabela: `public.cappta_legal_nature_options`
- [TODO]

### Tabela: `public.cappta_status_options`
- [TODO]

### Tabela: `public.cappta_account_type_options`
- [TODO]

### Tabela: `public.cappta_plan_types`
- [TODO]

### Tabela: `public.cappta_product_types`
- [TODO]

---

## 8. GS1 — (origem: `20_gs1_api_responses_table.sql`)

### Tabela: `public.gs1_api_responses`
 - Colunas:
   - `id UUID PK DEFAULT gen_random_uuid()`
   - `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`
   - `gtin TEXT NOT NULL`
   - `raw_response JSONB NOT NULL`
   - `status TEXT NOT NULL DEFAULT 'PENDING'` — valores esperados: PENDING, PROCESSED, ERROR
   - `error_message TEXT`
   - `created_by_user_id UUID NOT NULL DEFAULT auth.uid()`
   - `processed_at TIMESTAMPTZ`
 - Constraints:
   - PK(`id`)
 - Índices:
   - [não especificado na migração]
 - RLS/Policies:
   - [não especificado na migração]
 - Comentários:
   - Armazena respostas brutas da API GS1 para processamento assíncrono
   - `gtin`: código consultado; `raw_response`: JSON completo; `status`: PENDING/PROCESSED/ERROR
 - Origem: `220_gs1_tables.sql` (linhas 8–17, 19–25)

---

## 9. Views
- `view_cities_with_states`, `view_admin_profile_approval`, `view_products_with_image`, `view_supplier_products`
- `view_asaas_accounts_with_profiles`, `view_asaas_accounts_summary`, `view_asaas_webhook_logs`
- `view_ui_colors_by_category`, `view_published_posts`
 - `v_master_webhook_summary`

[TODO] Adicionar definição e origem de cada view.

---

## 10. Funções e Triggers
- Funções principais: [TODO] listar assinatura, propósito, permissões (GRANT EXECUTE)
- Triggers principais: [TODO] listar gatilhos, tabela alvo, função associada

---

## 11. RLS/Policies
- [TODO] Matriz por tabela/role/operacao

---

## 12. Notas e Diferenças Planejado vs Implementado
- `transaction`, `fee`, `support`, `marketplace_payments`: planejados, sem DDL em migrações atuais.

---

## 13. Apêndice — Como atualizar este dicionário
- Executar script de parsing das migrações para extrair: colunas/constraints/índices/RLS
- Atualizar manualmente comentários e descrições conforme necessário
