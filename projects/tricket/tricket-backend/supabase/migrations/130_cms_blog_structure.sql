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



