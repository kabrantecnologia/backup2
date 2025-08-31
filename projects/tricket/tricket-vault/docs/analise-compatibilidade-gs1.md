---
id: 8cmaqrd-4253
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
# Análise de Compatibilidade: Estrutura Tricket vs. API Verified by GS1

Esta análise avalia a compatibilidade da arquitetura de banco de dados planejada para a Tricket com os dados fornecidos pela API "Verified by GS1" do Brasil, com o objetivo de cadastrar e enriquecer produtos no marketplace.

## 1. Avaliação de Compatibilidade Geral

A estrutura atual é um ótimo ponto de partida. A separação entre `products` (catálogo base) e `supplier_products` (ofertas) é uma excelente prática e se alinha bem com o conceito da GS1, onde o GTIN representa um produto universal. No entanto, para uma integração completa, precisaremos enriquecer nossas tabelas para armazenar os dados padronizados da GS1.

## 2. Análise Detalhada por Entidade

### a) Categorização (Departamentos, Categorias, Subcategorias)

- **Estrutura Tricket:** Temos um sistema de hierarquia com três níveis (`departments` -> `categories` -> `sub_categories`) focado na experiência de navegação do usuário (ex: "Açougue e Peixaria" -> "Carnes Bovinas" -> "Cortes para Churrasco").
    
- **Estrutura GS1:** A GS1 utiliza a **GPC (Classificação Global de Produtos)**, que é um código de 8 dígitos (`gpcCategoryCode`) com um nome associado (`gpcCategoryName`), como "Calçados Esportivos Uso Geral" (`10001070`).
    
- **Compatibilidade:** **Baixa.** Não há uma correspondência direta ou automática entre a GPC e a nossa categorização de loja. São sistemas com propósitos diferentes: GPC é para padronização global, e a nossa é para a navegação no marketplace.
    
- **Conclusão:** Não devemos substituir nossa estrutura. Devemos **armazenar a GPC como um atributo adicional** do produto e, se desejado, criar uma tabela de mapeamento para sugerir uma categoria Tricket com base na GPC.
    

### b) Marcas (`brands`)

- **Estrutura Tricket:** Temos uma tabela `brands` completa, com nome, slug, logo, status de aprovação, etc.
    
- **Estrutura GS1:** A API retorna um campo `brandName` (ou `brandNameInformationLang` na versão nacional).
    
- **Compatibilidade:** **Alta.** O `brandName` da GS1 pode ser usado para preencher ou validar o campo `brands.name` da nossa tabela.
    
- **Conclusão:** O fluxo está correto. Ao consultar um GTIN, podemos usar o `brandName` retornado para verificar se a marca já existe em nossa base. Se não existir, podemos criar um novo registro em `brands` com um status como `'PENDING_APPROVAL'`, dando à equipe Tricket o controle sobre as marcas que entram no sistema.
    

### c) Produtos (`products`)

- **Estrutura Tricket:** Temos uma tabela `products` para o catálogo base com `name`, `description`, `sku_base`, e `attributes` (JSONB).
    
- **Estrutura GS1:** A API retorna uma vasta gama de atributos do produto.
    
- **Compatibilidade:** **Média.** Nossa estrutura é funcional, mas faltam campos dedicados para dados padronizados importantes da GS1, que atualmente teriam que ser armazenados no campo genérico `attributes`.
    
- **Conclusão:** Esta é a área que necessita de mais atenção. Adicionar campos específicos para os dados da GS1 tornará nossa base muito mais poderosa para buscas, filtros e integrações futuras.
    

## 3. Recomendações de Ajuste na Estrutura

Para tornar nossa estrutura totalmente compatível e robusta, sugiro as seguintes alterações no Canvas **`tricket_marketplace_products`**:

### a) Tabela `products` (Catálogo Base)

Adicionar os seguintes campos para armazenar os dados mestres do GTIN:

- **`gtin`**: `TEXT` (UNIQUE, NOT NULL) - Para armazenar o código GTIN-13 ou GTIN-14. Este será o principal elo com a GS1.
    
- **`gpc_category_code`**: `TEXT` (opcional) - Para armazenar o código de 8 dígitos da GPC.
    
- **`ncm_code`**: `TEXT` (opcional) - Para armazenar o NCM (Nomenclatura Comum do Mercosul), que é crucial para notas fiscais no Brasil.
    
- **`cest_code`**: `TEXT` (opcional) - Para armazenar o CEST (Código Especificador da Substituição Tributária), também importante para a parte fiscal.
    
- **`net_content`**: `NUMERIC` (opcional) - Para o conteúdo líquido principal.
    
- **`net_content_unit`**: `TEXT` (opcional) - Unidade do conteúdo líquido (ex: 'MLT', 'GRM').
    
- **`gross_weight`**: `NUMERIC` (opcional) - Peso bruto.
    
- **`net_weight`**: `NUMERIC` (opcional) - Peso líquido.
    
- **`weight_unit`**: `TEXT` (opcional) - Unidade de peso (ex: 'KGM', 'GRM').
    
- **`height`**: `NUMERIC` (opcional) - Altura do item.
    
- **`width`**: `NUMERIC` (opcional) - Largura do item.
    
- **`depth`**: `NUMERIC` (opcional) - Profundidade do item.
    
- **`dimension_unit`**: `TEXT` (opcional) - Unidade de dimensão (ex: 'MMT', 'CMT').
    
- **`country_of_origin_code`**: `TEXT` (opcional) - Código do país de origem.
    
- **`gs1_company_name`**: `TEXT` (opcional) - Nome da empresa detentora da licença GS1 (`gs1Licence.licenseeName`).
    
- **`gs1_company_gln`**: `TEXT` (opcional) - GLN da empresa detentora (`gs1Licence.LicenseeGLN`).
    

### b) Tabela `product_images`

Adicionar um campo para o tipo de imagem, conforme a especificação da GS1:

- **`image_type_code`**: `TEXT` (opcional) - Para armazenar o `referencedFileTypeCode` da GS1 (ex: `PRODUCT_IMAGE`, `LOGO`, `PLANOGRAM`).
    

### c) Nova Tabela: `gpc_to_tricket_category_mapping` (Opcional, mas Recomendado)

Para automatizar a sugestão de categorias, poderíamos criar uma tabela de mapeamento.

- **Descrição:** Mapeia um `gpcCategoryCode` da GS1 para uma `sub_category_id` da Tricket.
    
- **Campos Sugeridos:** `gpc_category_code` (PK, `TEXT`), `tricket_sub_category_id` (FK para `sub_categories.id`).
    

## 4. Proposta de Fluxo de Integração para Cadastro de Produto

Com a estrutura ajustada, o fluxo de cadastro de um novo produto por um fornecedor seria muito mais eficiente:

1. **Fornecedor Informa GTIN:** Na interface de cadastro de produto, o fornecedor digita o código de barras (GTIN) do item.
    
2. **Consulta à API Tricket:** O frontend chama uma RPC da Tricket (ex: `get_product_data_by_gtin`).
    
3. **Consulta à API GS1:** A função RPC da Tricket faz uma chamada `GET` para a API "Verified by GS1" com o GTIN fornecido.
    
4. **Pré-Preenchimento:**
    
    - **Se o GTIN já existe** na nossa tabela `products`, a função retorna os dados do nosso banco, e a interface simplesmente permite que o fornecedor crie sua oferta (`supplier_products`) para este item.
        
    - **Se o GTIN é novo**, a função retorna os dados da API GS1. O frontend usa esses dados para pré-preencher o formulário de cadastro de produto:
        
        - Nome do Produto (`tradeItemDescription`)
            
        - Marca (`brandName`)
            
        - Descrição (`additionalTradeItemDescription`)
            
        - NCM, peso, dimensões, etc.
            
        - Imagens (a função pode fazer o download e upload para o nosso storage, salvando as referências em `product_images`).
            
5. **Categorização:** O sistema pode usar a tabela `gpc_to_tricket_category_mapping` para sugerir uma categoria Tricket, ou o fornecedor a seleciona manualmente.
    
6. **Finalização:** O fornecedor revisa os dados, adiciona suas informações de preço e estoque (na tabela `supplier_products`) e submete para aprovação.
    

Este fluxo garante um catálogo padronizado, rico em informações e reduz drasticamente o trabalho manual dos fornecedores.