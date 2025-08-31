# Modelo Back-end

## 🎯 Visão Geral

Este é um projeto template usado como base para novas soluções na Kabran Tecnologia. Ele estabelece a estrutura padrão de diretórios, automação, documentação e fluxo de trabalho para garantir consistência e agilidade no desenvolvimento.

## 🏛️ Arquitetura de Repositórios
### Backend

 **Descrição**: Contém todo o código-fonte do backend, construído sobre uma instância Supabase auto-hospedada. É responsável pela lógica de negócio, APIs, banco de dados e autenticação.

 **Link**: `git@github.com:joaohsandrade/modelo-backend.git`
   
### Frontend

 **Descrição**: Contém o código-fonte da interface do usuário (UI), desenvolvido na plataforma WeWeb e exportado para auto-hospedagem. É responsável pela experiência visual e interativa do cliente.
  
 **Link**: `git@github.com:joaohsandrade/modelo-frontend.git`
  
### Vault (Documentação)

**Descrição**: Funciona como o "Cofre" de documentação. Centraliza todo o conhecimento técnico e de negócio, como arquitetura, guias e manuais, seguindo a filosofia "Docs as Code".

**Link**: `git@github.com:joaohsandrade/modelo-vaul.git`

## 📁 Estrutura de Pastas

``` 
~/workspaces/projects/modelo/      # Raiz do projeto
├── back-end                       # Repositório back-end
│   └── supabase                   # Instância supabase
│       └── migrations             # Migrations
│   └── volumes                    # Volumes
│       └── functions              # Supabase Edge Functions
│   └── scripts                    # Scripts
│   └── README                     # README do projeto
├── front-end                      # Repositório fron-end
├── vault                          # Vault Obsidian - Documentação
│	    
```  


## 🛠️ Tecnologias Utilizadas

- **Backend**: Supabase (Self-Hosted), PostgreSQL, Deno
- **Frontend**: WeWeb (Vue.js), Node.js
- **Documentação**: Markdown, Obsidian
- **Infraestrutura**: Docker


## 🛡️ Segurança

- **Row Level Security (RLS)** habilitado em todas as tabelas
- **Funções seguras** com `SECURITY DEFINER` e `search_path = ''`
- **Políticas adaptáveis** conforme estrutura do projeto
- **Validações rigorosas** nas funções de criação
  

## 🚀 Comandos

### Supabase CLI
#### push
```Shell
cd ~/workspaces/projects/modelo/back-end
supabase db push --yes --db-url "postgresql://postgres.dev_modelo_tenant:yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH@localhost:5408/postgres"
```

#### reset
```Shell
cd ~/workspaces/projects/modelo/back-end
supabase db reset --yes --db-url "postgresql://postgres.dev_modelo_tenant:yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH@localhost:5408/postgres"
```


