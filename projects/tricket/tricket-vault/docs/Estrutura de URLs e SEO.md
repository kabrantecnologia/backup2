---
source: NotebookLM
type: task
id: 1FNOiMy6L5HTT3mHdKgC9sWbg9mJHmpoh9CYnInKqp6U
action: create
space: Projetos
folder: Tricket
list: Dev. Marketplace
parent_id: 
due_date: ""
created: 2025-06-18
path: /home/joaohenrique/Obsidian/01-PROJETOS/tricket-revisar/Revisar
---


## 1. Estrutura Base de URLs

### 1.1. Domínio Principal
```
https://tricket.com.br/
```

### 1.2. Subdomínios
- **App**: `https://app.tricket.com.br/`
- **Documentação**: `https://docs.tricket.com.br/`
- **Status**: `https://status.tricket.com.br/`
- **Blog**: `https://blog.tricket.com.br/`

## 2. URLs Públicas (SEO-Friendly)

### 2.1. Landing Pages
```
/                         # Home
/comerciante              # Landing específica para comerciantes
/fornecedor               # Landing específica para fornecedores
/sobre                    # Sobre a Tricket
/contato                  # Página de contato
```

### 2.2. Blog e Conteúdo
```
/blog/
/blog/{categoria}/
/blog/{categoria}/{slug}/
/blog/tags/{tag}/
```

Exemplo:
```
/blog/guias/como-aumentar-vendas-no-varejo
/blog/casos-de-sucesso/padaria-silva-dobra-faturamento
/blog/tags/gestao-financeira
```

### 2.3. Documentação Legal
```
/legal/termos-de-uso
/legal/politica-de-privacidade
/legal/politica-de-cookies
/legal/termos-comerciante
/legal/termos-fornecedor
```

### 2.4. Autenticação
```
/login
/cadastro
/recuperar-senha
/redefinir-senha/{token}
/verificar-email/{token}
```

## 3. URLs da Aplicação (App)

### 3.1. Estrutura por Perfil
```
/app/{perfil}/{recurso}/{acao}
```

Exemplos:
```
/app/comerciante/dashboard
/app/fornecedor/produtos/novo
/app/admin/usuarios/lista
```

### 3.2. Parâmetros de URL

#### 3.2.1. Listagens e Filtros
```
/app/{perfil}/{recurso}?
  page={numero}&
  limit={quantidade}&
  sort={campo},{direcao}&
  filter={campo}:{operador}:{valor}
```

Exemplos:
```
/app/comerciante/pedidos?status=pendente&data=2025-04
/app/fornecedor/produtos?categoria=bebidas&estoque=baixo
/app/admin/usuarios?tipo=comerciante&status=pendente
```

#### 3.2.2. Busca
```
/app/{perfil}/{recurso}/busca?
  q={termo}&
  filtros={json_encoded}
```

#### 3.2.3. Detalhes e Ações
```
/app/{perfil}/{recurso}/{id}
/app/{perfil}/{recurso}/{id}/{acao}
```

## 4. Estratégias de SEO

### 4.1. Meta Tags
```html
<!-- Básicas -->
<title>Título Único por Página | Tricket</title>
<meta name="description" content="Descrição única e relevante">

<!-- Open Graph -->
<meta property="og:title" content="Título para Compartilhamento">
<meta property="og:description" content="Descrição para Compartilhamento">
<meta property="og:image" content="URL da Imagem">
<meta property="og:url" content="URL Canônica">

<!-- Twitter -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Título para Twitter">
```

### 4.2. Estrutura de URLs para SEO
- Usar hífens para separar palavras
- URLs em minúsculas
- Evitar caracteres especiais
- Manter URLs curtas e descritivas
- Usar palavras-chave relevantes

### 4.3. Canonical URLs
```html
<link rel="canonical" href="https://tricket.com.br/path/to/page" />
```

### 4.4. Sitemap
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://tricket.com.br/</loc>
    <lastmod>2025-04-18</lastmod>
    <changefreq>daily</changefreq>
    <priority>1.0</priority>
  </url>
</urlset>
```

### 4.5. Robots.txt
```txt
User-agent: *
Allow: /
Disallow: /app/
Disallow: /admin/
Disallow: /api/
Sitemap: https://tricket.com.br/sitemap.xml
```

## 5. Redirecionamentos e Status HTTP

### 5.1. Redirecionamentos 301 (Permanente)
- URLs antigas para novas
- Correção de URLs com/sem trailing slash
- Normalização de maiúsculas/minúsculas

### 5.2. Redirecionamentos 302 (Temporário)
- Manutenção temporária
- Testes A/B
- Campanhas sazonais

### 5.3. Status HTTP Semânticos
```
200 - OK
301 - Redirecionamento Permanente
302 - Redirecionamento Temporário
404 - Página não encontrada
410 - Conteúdo removido permanentemente
500 - Erro interno do servidor
```

## 6. Estratégias Avançadas

### 6.1. Schema.org Markup
```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Tricket",
  "url": "https://tricket.com.br",
  "logo": "https://tricket.com.br/logo.png"
}
</script>
```

### 6.2. Breadcrumbs
```
Home > Comerciante > Pedidos > #123456
```

### 6.3. Paginação SEO-Friendly
```html
<link rel="prev" href="?page=1">
<link rel="next" href="?page=3">
```

### 6.4. Internacionalização (Futuro)
```
/{lang}/{path}
/pt-br/sobre
/en/about
```

## 7. Monitoramento

### 7.1. Métricas a Monitorar
- Tempo de carregamento
- Taxa de rejeição
- Páginas por sessão
- Tempo médio na página
- Rankings de palavras-chave

### 7.2. Ferramentas
- Google Search Console
- Google Analytics
- Lighthouse
- SEMrush/Ahrefs
