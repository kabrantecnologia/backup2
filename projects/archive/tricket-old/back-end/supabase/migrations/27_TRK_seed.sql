-- =================================================================
-- SCRIPT PARA POPULAR O MÓDULO CMS (SEEDING)
-- =================================================================
-- Este script insere dados iniciais no módulo CMS, como categorias
-- e os documentos legais básicos da plataforma.

DO $$
DECLARE
    -- Variáveis para armazenar os IDs gerados.
    v_category_id uuid;
    v_terms_post_id uuid;
    v_privacy_post_id uuid;
BEGIN
    -- 1. Inserir a categoria para documentos legais.
    -- Armazena o ID da nova categoria na variável v_category_id.
    INSERT INTO cms_categories (name, slug, description)
    VALUES ('Documentos Legais', 'documentos-legais', 'Termos, políticas e outros documentos legais da plataforma.')
    RETURNING id INTO v_category_id;

    -- 2. Inserir o post "Termos de Uso".
    -- Associa à categoria criada e define como publicado.
    INSERT INTO cms_posts (type, category_id, slug, title, excerpt, status, published_at)
    VALUES (
        'LEGAL_DOCUMENT',
        v_category_id,
        'termos-de-uso',
        'Termos de Uso',
        'Regras e condições para utilização da plataforma Tricket.',
        'PUBLISHED',
        now()
    )
    RETURNING id INTO v_terms_post_id;

    -- 3. Inserir a primeira versão do conteúdo para os "Termos de Uso".
    INSERT INTO cms_post_versions (post_id, version, content)
    VALUES (
        v_terms_post_id,
        1,
        '{ "markdown": "# Termos de Uso\n\n**1. Aceitação dos Termos**\n\nAo acessar e usar a plataforma Tricket, você concorda em cumprir estes Termos de Uso. Se você não concorda, não utilize nossos serviços.\n\n**2. Descrição dos Serviços**\n\nA Tricket fornece um ecossistema digital que integra pagamentos, um marketplace e gestão financeira para conectar Comerciantes, Fornecedores e Consumidores.\n\n*Conteúdo completo a ser adicionado...*" }'
    );

    -- 4. Inserir o post "Política de Privacidade".
    -- Associa à mesma categoria e define como publicado.
    INSERT INTO cms_posts (type, category_id, slug, title, excerpt, status, published_at)
    VALUES (
        'LEGAL_DOCUMENT',
        v_category_id,
        'politica-de-privacidade',
        'Política de Privacidade',
        'Como coletamos, usamos e protegemos seus dados.',
        'PUBLISHED',
        now()
    )
    RETURNING id INTO v_privacy_post_id;

    -- 5. Inserir a primeira versão do conteúdo para a "Política de Privacidade".
    INSERT INTO cms_post_versions (post_id, version, content)
    VALUES (
        v_privacy_post_id,
        1,
        '{ "markdown": "# Política de Privacidade\n\n**1. Coleta de Dados**\n\nColetamos informações que você nos fornece durante o cadastro, como nome, e-mail, CPF/CNPJ, e dados de transações financeiras.\n\n**2. Uso das Informações**\n\nUtilizamos seus dados para operar a plataforma, processar transações, fornecer suporte e cumprir obrigações legais.\n\n*Conteúdo completo a ser adicionado...*" }'
    );

    RAISE NOTICE 'CMS populado com sucesso!';
END $$;

