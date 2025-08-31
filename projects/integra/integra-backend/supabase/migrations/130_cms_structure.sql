-- =================================================================
-- TIPOS ENUMERADOS (ENUMS)
-- =================================================================

-- Define os tipos de conteúdo possíveis na plataforma.
CREATE TYPE cms_post_type AS ENUM (
    'BLOG_POST',
    'LEGAL_DOCUMENT'
);

-- Define os status possíveis para um post ou documento.
CREATE TYPE cms_post_status AS ENUM (
    'DRAFT',      -- Rascunho, não visível para o público.
    'PUBLISHED',  -- Publicado, visível para o público.
    'ARCHIVED'    -- Arquivado, não mais ativo, mas mantido para histórico.
);


-- =================================================================
-- TABELAS DO MÓDULO CMS
-- =================================================================

-- Tabela 1: cms_categories
-- Organiza os posts em categorias principais (ex: 'Notícias', 'Tutoriais', 'Contratos').
CREATE TABLE cms_categories (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name text NOT NULL UNIQUE,
    slug text NOT NULL UNIQUE,
    description text
);

COMMENT ON TABLE cms_categories IS 'Categorias para organizar os posts e documentos.';

-- Tabela 2: cms_tags
-- Permite a marcação de posts com palavras-chave para facilitar a busca.
CREATE TABLE cms_tags (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name text NOT NULL UNIQUE,
    slug text NOT NULL UNIQUE
);

COMMENT ON TABLE cms_tags IS 'Tags (palavras-chave) para associar aos posts.';

-- Tabela 3: cms_posts
-- Tabela central que armazena os metadados de cada peça de conteúdo.
CREATE TABLE cms_posts (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    type cms_post_type NOT NULL,
    category_id uuid REFERENCES cms_categories(id),
    slug text NOT NULL UNIQUE,
    title text NOT NULL,
    excerpt text, -- Resumo ou chamada para o post.
    cover_image_url text, -- URL para uma imagem de capa.
    author_id uuid REFERENCES auth.users(id),
    status cms_post_status NOT NULL DEFAULT 'DRAFT',
    published_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE cms_posts IS 'Tabela principal para todo o conteúdo (posts, documentos, etc).';

-- Tabela 4: cms_post_tags (Tabela de Junção)
-- Associa posts a múltiplas tags (relação N-para-N).
CREATE TABLE cms_post_tags (
    post_id uuid NOT NULL REFERENCES cms_posts(id) ON DELETE CASCADE,
    tag_id uuid NOT NULL REFERENCES cms_tags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

COMMENT ON TABLE cms_post_tags IS 'Tabela de junção para a relação N-N entre posts e tags.';

-- Tabela 5: cms_post_versions
-- Armazena o histórico de todas as versões de um determinado post.
CREATE TABLE cms_post_versions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id uuid NOT NULL REFERENCES cms_posts(id) ON DELETE CASCADE,
    version integer NOT NULL,
    content jsonb NOT NULL,
    change_log text,
    author_id uuid REFERENCES auth.users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT unique_post_version UNIQUE (post_id, version)
);

COMMENT ON TABLE cms_post_versions IS 'Armazena cada versão de um conteúdo, criando um histórico de alterações.';
COMMENT ON COLUMN cms_post_versions.content IS 'O conteúdo em si, no formato JSON (ex: {"markdown": "..."}).';

-- Tabela 6: cms_post_user_agreements
-- Registra o aceite de um usuário a uma versão específica de um documento legal.
CREATE TABLE cms_post_user_agreements (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id uuid NOT NULL, -- Deverá referenciar 'iam_profiles(id)'.
    post_version_id uuid NOT NULL REFERENCES cms_post_versions(id),
    agreed_at timestamptz NOT NULL DEFAULT now(),
    ip_address inet,
    CONSTRAINT unique_user_agreement UNIQUE (profile_id, post_version_id)
);

COMMENT ON TABLE cms_post_user_agreements IS 'Registra o aceite de um usuário a uma versão específica de um documento legal.';

-- Tabela 7: cms_comments
-- Armazena comentários feitos por usuários nos posts do blog.
CREATE TABLE cms_comments (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id uuid NOT NULL REFERENCES cms_posts(id) ON DELETE CASCADE,
    author_id uuid NOT NULL REFERENCES auth.users(id),
    parent_comment_id uuid REFERENCES cms_comments(id) ON DELETE CASCADE, -- Para respostas aninhadas.
    content text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz
);

COMMENT ON TABLE cms_comments IS 'Armazena comentários dos usuários nos posts.';
COMMENT ON COLUMN cms_comments.parent_comment_id IS 'Referência para criar threads de comentários (respostas).';

-- =================================================================
-- VIEW PARA EXIBIR POSTS PUBLICADOS
-- =================================================================
-- Esta view simplifica a consulta de posts para o front-end,
-- unindo os dados de posts, a versão mais recente do conteúdo,
-- a categoria e o autor.

CREATE OR REPLACE VIEW view_published_posts AS
SELECT
    p.id AS post_id,
    p.slug,
    p.title,
    p.excerpt,
    p.cover_image_url,
    p.published_at,
    p.type AS post_type,
    p.created_at,
    p.updated_at,
    c.name AS category_name,
    c.slug AS category_slug,
    -- Tenta obter o nome completo do autor; se não existir, usa o e-mail.
    COALESCE(u.raw_user_meta_data->>'full_name', u.email) AS author_name,
    pv.content,
    pv.version AS latest_version
FROM
    cms_posts p
-- Junta com a tabela de categorias para obter o nome e slug da categoria.
LEFT JOIN
    cms_categories c ON p.category_id = c.id
-- Junta com a tabela de usuários para obter o nome do autor.
LEFT JOIN
    auth.users u ON p.author_id = u.id
-- Junta com a versão mais recente do conteúdo para cada post.
-- O JOIN LATERAL é eficiente para buscar o "último registro por grupo".
JOIN LATERAL (
    SELECT
        pv_inner.content,
        pv_inner.version
    FROM
        cms_post_versions pv_inner
    WHERE
        pv_inner.post_id = p.id
    ORDER BY
        pv_inner.version DESC
    LIMIT 1
) pv ON true
-- Filtra para mostrar apenas os posts que estão com o status 'PUBLISHED'.
WHERE
    p.status = 'PUBLISHED';

-- Exemplo de como consultar a view:
-- SELECT * FROM cms_published_posts_view WHERE slug = 'termos-de-uso';

