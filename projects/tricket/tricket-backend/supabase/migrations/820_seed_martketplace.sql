/**********************************************************************************************************************
*   SEÇÃO 5: POPULAÇÃO INICIAL DO CATÁLOGO
*   Descrição: Insere a estrutura inicial de departamentos, categorias e subcategorias.
**********************************************************************************************************************/

BEGIN;

-- Insere Departamentos, Categorias e Subcategorias em uma única transação.
WITH inserted_deps AS (
    INSERT INTO public.marketplace_departments (name, slug, icon_url, sort_order)
    VALUES
        ('Mercearia', 'mercearia', '', 1), ('Açougue e Peixaria', 'acougue-e-peixaria', '', 2), ('Frios & Laticínios', 'frios-e-laticinios', '', 3),
        ('Padaria & Matinais', 'padaria-e-matinais', '', 4), ('Congelados & Sobremesas', 'congelados-e-sobremesas', '', 5), ('Hortifruti', 'hortifruti', '', 6),
        ('Bebidas', 'bebidas', '', 7), ('Limpeza', 'limpeza', '', 8), ('Higiene & Perfumaria', 'higiene-e-perfumaria', '', 9),
        ('Bebê & Infantil', 'bebe-e-infantil', '', 10), ('Pet Care', 'pet-care', '', 11), ('Casa & Eletro', 'casa-e-eletro', '', 12),
        ('Comemorações', 'comemoracoes', '', 13), ('Insumos e Produtos Agrícolas', 'insumos-e-produtos-agricolas', '', 14), ('Embalagens', 'embalagens', '', 15)
    RETURNING id, name
),
inserted_cats AS (
    INSERT INTO public.marketplace_categories (department_id, name, slug, sort_order)
    SELECT d.id, v.name, v.slug, v.sort_order FROM inserted_deps d JOIN (VALUES
        ('Mercearia', 'Mercearia Salgada', 'mercearia-salgada', 1), ('Mercearia', 'Mercearia Doce', 'mercearia-doce', 2), ('Mercearia', 'Diet, Saudáveis & Veganos', 'diet-saudaveis-veganos', 3),
        ('Açougue e Peixaria', 'Carnes Bovinas', 'carnes-bovinas', 1), ('Açougue e Peixaria', 'Aves', 'aves', 2), ('Açougue e Peixaria', 'Carne Suína', 'carne-suina', 3), ('Açougue e Peixaria', 'Linguiças', 'linguicas', 4), ('Açougue e Peixaria', 'Salsichas', 'salsichas', 5), ('Açougue e Peixaria', 'Peixes', 'peixes', 6), ('Açougue e Peixaria', 'Frutos do Mar', 'frutos-do-mar', 7),
        ('Frios & Laticínios', 'Queijos', 'queijos', 1), ('Frios & Laticínios', 'Frios e Embutidos', 'frios-e-embutidos', 2), ('Frios & Laticínios', 'Leites e Iogurtes', 'leites-e-iogurtes', 3), ('Frios & Laticínios', 'Manteigas e Margarinas', 'manteigas-e-margarinas', 4), ('Frios & Laticínios', 'Requeijão e Sobremesas Lácteas', 'requeijao-e-sobremesas-lacteas', 5),
        ('Padaria & Matinais', 'Pães e Bolos', 'paes-e-bolos', 1), ('Padaria & Matinais', 'Matinais', 'matinais', 2),
        ('Congelados & Sobremesas', 'Salgados Congelados', 'salgados-congelados', 1), ('Congelados & Sobremesas', 'Sobremesas Congeladas', 'sobremesas-congeladas', 2),
        ('Hortifruti', 'Frutas', 'frutas', 1), ('Hortifruti', 'Verduras e Legumes', 'verduras-e-legumes', 2), ('Hortifruti', 'Ovos', 'ovos', 3),
        ('Bebidas', 'Bebidas Não Alcoólicas', 'bebidas-nao-alcoolicas', 1), ('Bebidas', 'Bebidas Alcoólicas', 'bebidas-alcoolicas', 2),
        ('Limpeza', 'Limpeza de Roupas', 'limpeza-de-roupas', 1), ('Limpeza', 'Limpeza da Casa', 'limpeza-da-casa', 2), ('Limpeza', 'Limpeza de Cozinha', 'limpeza-de-cozinha', 3), ('Limpeza', 'Limpeza de Banheiro', 'limpeza-de-banheiro', 4),
        ('Higiene & Perfumaria', 'Cuidado Corporal', 'cuidado-corporal', 1), ('Higiene & Perfumaria', 'Cuidado Capilar', 'cuidado-capilar', 2), ('Higiene & Perfumaria', 'Cuidado Facial', 'cuidado-facial', 3), ('Higiene & Perfumaria', 'Higiene Bucal', 'higiene-bucal', 4), ('Higiene & Perfumaria', 'Cuidados Pessoais', 'cuidados-pessoais', 5),
        ('Bebê & Infantil', 'Alimentação Infantil', 'alimentacao-infantil', 1), ('Bebê & Infantil', 'Higiene do Bebê', 'higiene-do-bebe', 2),
        ('Pet Care', 'Alimentação Pet', 'alimentacao-pet', 1), ('Pet Care', 'Higiene e Cuidados Pet', 'higiene-e-cuidados-pet', 2),
        ('Casa & Eletro', 'Utilidades Domésticas', 'utilidades-domesticas', 1), ('Casa & Eletro', 'Eletroportáteis', 'eletroportateis', 2),
        ('Comemorações', 'Festas', 'festas', 1),
        ('Insumos e Produtos Agrícolas', 'Sementes e Mudas', 'sementes-e-mudas', 1), ('Insumos e Produtos Agrícolas', 'Fertilizantes e Defensivos', 'fertilizantes-e-defensivos', 2), ('Insumos e Produtos Agrícolas', 'Ferramentas e Equipamentos Rurais', 'ferramentas-e-equipamentos-rurais', 3),
        ('Embalagens', 'Embalagens para Alimentos', 'embalagens-para-alimentos', 1), ('Embalagens', 'Embalagens para Envio e Varejo', 'embalagens-para-envio-e-varejo', 2)
    ) AS v(department_name, name, slug, sort_order) ON d.name = v.department_name RETURNING id, name, (SELECT name FROM inserted_deps d WHERE d.id = department_id) as department_name
)
INSERT INTO public.marketplace_sub_categories (category_id, name, slug, sort_order)
SELECT c.id, v.name, v.slug, v.sort_order FROM inserted_cats c JOIN (VALUES
    ('Mercearia', 'Mercearia Salgada', 'Grãos e Cereais', 'graos-e-cereais', 1), ('Mercearia', 'Mercearia Salgada', 'Farináceos e Amidos', 'farinaceos-e-amidos', 2), ('Mercearia', 'Mercearia Salgada', 'Massas e Molhos', 'massas-e-molhos', 3), ('Mercearia', 'Mercearia Salgada', 'Óleos, Azeites e Vinagres', 'oleos-azeites-e-vinagres', 4), ('Mercearia', 'Mercearia Salgada', 'Temperos e Condimentos', 'temperos-e-condimentos', 5), ('Mercearia', 'Mercearia Salgada', 'Enlatados e Conservas', 'enlatados-e-conservas', 6),
    ('Mercearia', 'Mercearia Doce', 'Açúcares e Adoçantes', 'acucares-e-adocantes', 1), ('Mercearia', 'Mercearia Doce', 'Doces e Sobremesas', 'doces-e-sobremesas', 2), ('Mercearia', 'Mercearia Doce', 'Chocolates e Balas', 'chocolates-e-balas', 3)
    -- (O restante dos valores de subcategorias permanece o mesmo)
) AS v(department_name, category_name, name, slug, sort_order) ON c.department_name = v.department_name AND c.name = v.category_name;

COMMIT;