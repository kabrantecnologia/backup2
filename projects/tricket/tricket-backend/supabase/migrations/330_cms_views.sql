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