---
id: 86aacvnrd
status: 
version: 1
source: Clickup
type: task
action: update
space: Projetos
folder: Tricket
list: Tricket
parent_id: 
created: 2025-07-16 09:11
start_date: 
due_date: ""
tags:
  - projetos/tricket
summary: Documentação da estrutura de links e rotas do frontend da plataforma Tricket
path: /home/joaohenrique/Obsidian/01-PROJETOS/tricket/pages
---

# Estrutura de Links do Frontend - Projeto Tricket


## Onboarding e Perfil

- [ ] /entrar                      # Login de usuários
- [ ] /cadastro                   # Cadastro inicial (PF/PJ)
- [ ] /cadastro/perfil
- [ ] /cadastro/status
- [ ] /verificar-email            # Verificação de e-mail
- [ ] /verificar-celular
- [ ] /recuperar-senha            # Recuperação de senha
- [ ] /nova-senha


## Legal e Suporte
- [ ] /termos-de-uso              # Termos de uso da plataforma
- [ ] /politica-de-privacidade    # Política de privacidade
- [ ] /ajuda                      # Central de ajuda

## 1. Estrutura Base (Comum a todos os perfis)

```
/                           # Página inicial/Landing Page
/entrar                     # Login de usuários
/cadastro                   # Cadastro inicial (PF/PJ)
/cadastro/perfil
/cadastro/status
/verificar-email            # Verificação de e-mail
/verificar-celular
/recuperar-senha            # Recuperação de senha
/nova-senha
/termos-de-uso              # Termos de uso da plataforma
/politica-de-privacidade    # Política de privacidade
/ajuda                      # Central de ajuda
```

## 2. Área Autenticada - Estrutura Comum

```
/dashboard                  # Dashboard inicial (personalizado por tipo de perfil)
/perfil                     # Configurações de perfil do usuário
/perfil/dados               # Dados pessoais/empresariais
/perfil/seguranca           # Configurações de segurança (senha, 2FA)
/perfil/notificacoes        # Preferências de notificações
/perfil/contas-bancarias    # Gerenciamento de contas bancárias
/trocar-perfil              # Troca entre perfis (PF/PJs) do usuário
/notificacoes               # Centro de notificações
/suporte                    # Canal de suporte
/financeiro                 # Gestão financeira (saldo, extrato)
/financeiro/adicionar-saldo # Adicionar saldo à conta digital
/financeiro/saques          # Solicitar/gerenciar saques
/financeiro/transferencias  # Histórico de transferências
```

## 3. Perfil Consumidor (PF/PJ)

```
/marketplace                # Página principal do marketplace
/marketplace/categorias     # Navegação por categorias
/marketplace/pesquisa       # Resultados de pesquisa
/marketplace/produto/:id    # Detalhes do produto/oferta
/carrinho                   # Carrinho de compras
/checkout                   # Processo de finalização da compra
/pedidos                    # Lista de pedidos realizados
/pedidos/:id                # Detalhes de um pedido específico
/pedidos/:id/disputa        # Abertura/acompanhamento de disputa
```

## 4. Perfil Fornecedor (PJ)

```
/fornecedor/dashboard       # Dashboard do fornecedor
/fornecedor/ofertas         # Gerenciamento de ofertas
/fornecedor/ofertas/nova    # Criar nova oferta
/fornecedor/ofertas/:id     # Editar oferta existente
/fornecedor/produtos        # Produtos base disponíveis 
/fornecedor/produtos/solicitar # Solicitar novo produto base
/fornecedor/pedidos         # Pedidos recebidos
/fornecedor/pedidos/:id     # Detalhes de pedido recebido
/fornecedor/envios          # Gerenciamento de envios
/fornecedor/disputas        # Gerenciamento de disputas
/fornecedor/relatorios      # Relatórios de vendas
/fornecedor/configuracoes   # Configurações do fornecedor (frete, etc)
```

## 5. Perfil Comerciante (PJ)

```
/comerciante/dashboard      # Dashboard do comerciante
/comerciante/pos            # Integração/status POS (Cappta)
/comerciante/pos/transacoes # Transações POS realizadas
/comerciante/vendas         # Histórico de vendas
/comerciante/colaboradores  # Gestão de colaboradores
/comerciante/relatorios     # Relatórios de vendas e financeiro
```

## 6. Área Administrativa (Equipe Tricket)

```
/admin                      # Dashboard administrativo
/admin/usuarios             # Gerenciamento de usuários
/admin/usuarios/:id         # Detalhes/edição de usuário
/admin/aprovacoes           # Aprovações pendentes (cadastros, docs)
/admin/categorias           # Gerenciamento de categorias
/admin/produtos             # Gerenciamento de produtos base
/admin/produtos/solicitacoes # Solicitações de novos produtos
/admin/pedidos              # Visualização de todos os pedidos
/admin/disputas             # Gestão de disputas
/admin/disputas/:id         # Detalhe e mediação de disputa
/admin/financeiro           # Gestão financeira (taxas, repasses)
/admin/configuracoes        # Configurações da plataforma
/admin/logs                 # Logs do sistema
```

## 7. URLs Específicas para Funcionalidades Transversais

```
/convites/:token            # Aceite de convite para organização
/verificacao-asaas/:token   # Retorno da verificação Asaas
/notificacoes/webhook       # Endpoints para webhooks (Asaas, Cappta)
```

## 8. Estrutura para Aplicação Mobile (Opcional)

```
/app/...                    # Espelhamento das rotas principais adaptadas para mobile
```

--- 
Com certeza. Um bom planejamento de rotas (as URLs das páginas) é fundamental para a organização e escalabilidade do projeto.

Com base nos perfis de usuário (Administrador, Fornecedor, Comerciante) e nas funcionalidades descritas nos documentos, sugiro uma estrutura de páginas que busca ser lógica e intuitiva.

Vamos usar um padrão como `/app/{contexto}/{modulo}/{sub-modulo}`.

---

### 1. Páginas Públicas / Autenticação

Estas páginas ficam fora da área logada da aplicação.

- `/login`: Página de entrada do usuário.
    
- `/cadastro`: Página de registro de um novo usuário.
    
- `/recuperar-senha`: Fluxo para redefinição de senha.
    
- `/termos-de-uso`: Página pública para os Termos de Uso.
    
- `/politica-de-privacidade`: Página pública para a Política de Privacidade.
    

---

### 2. Páginas Comuns (Acessíveis a todos os perfis logados)

Após o login, o usuário é direcionado para a `visao-geral` do seu perfil ativo.

- `/app/minha-conta`: Para o usuário editar suas informações pessoais, senha, etc.
    
- `/app/notificacoes`: Central de notificações do usuário.
    
- `/app/selecionar-perfil`: Caso o usuário tenha múltiplos perfis (ex: um perfil pessoal e acesso a uma empresa), esta página permite a troca.
    

---

### 3. Contexto: Administrador (`/app/admin`)

Esta área concentra todo o gerenciamento da plataforma.

- **Visão Geral**
    
    - `/app/admin/visao-geral`: Dashboard com os principais indicadores da plataforma. 1
        
- **Cadastros**
    
    - `/app/admin/cadastros/usuarios`: Listagem e gerenciamento de todos os usuários (PF e PJ). 2
        
    - `/app/admin/cadastros/produtos`: Catálogo geral de produtos. 3
        
    - `/app/admin/cadastros/categorias`: Gerenciamento das categorias e departamentos do marketplace. 4
        
    - `/app/admin/cadastros/marcas`: Gerenciamento das marcas dos produtos.
        
    - `/app/admin/cadastros/terminais`: Gerenciamento dos terminais POS da Cappta. 5
        
- **Financeiro**
    
    - `/app/admin/financeiro/conta-master`: Visão da conta master da Tricket (saldo, extrato).
        
    - `/app/admin/financeiro/taxas`: Relatório de taxas arrecadadas.
        
    - `/app/admin/financeiro/transacoes`: Log de todas as transações financeiras na plataforma.
        
- **Suporte**
    
    - `/app/admin/suporte/tickets`: Ferramenta para responder a chamados de suporte.
        
    - `/app/admin/suporte/base-de-conhecimento`: Gerenciamento dos artigos de ajuda (CMS).
        
- **Configurações**
    
    - `/app/admin/configuracoes/geral`: Configurações da aplicação (modo manutenção, etc.).
        
    - `/app/admin/configuracoes/permissoes`: Gerenciamento de papéis e permissões (RBAC).
        

---

### 4. Contexto: Fornecedor (`/app/fornecedor`)

Foco nas ferramentas para quem vende produtos no marketplace.

- `/app/fornecedor/visao-geral`: Dashboard com resumo de vendas, pedidos e saldo. 6
    
- `/app/fornecedor/produtos`: Listagem dos seus produtos ofertados.
    
- `/app/fornecedor/produtos/novo`: Formulário para cadastrar um novo produto.
    
- `/app/fornecedor/pedidos`: Listagem dos pedidos recebidos.
    
- `/app/fornecedor/financeiro`: Extrato da sua conta e solicitação de saques.
    
- `/app/fornecedor/perfil-loja`: Configuração das informações públicas da sua loja.
    

---

### 5. Contexto: Comerciante (`/app/comerciante`)

Foco nas ferramentas para quem compra no marketplace e usa o sistema POS.

- `/app/comerciante/visao-geral`: Dashboard com resumo de compras, saldo e vendas no POS. 7
    
- `/app/comerciante/marketplace`: A "loja" para navegar e comprar produtos dos fornecedores.
    
- `/app/comerciante/pedidos`: Histórico dos seus pedidos de compra.
    
- `/app/comerciante/financeiro`: Extrato da sua conta, vendas do POS e solicitação de saques.
    
- `/app/comerciante/terminais`: Visualização dos seus terminais POS ativos.
    

Esta estrutura busca ser lógica e escalável. Podemos ajustar ou detalhar qualquer uma das seções conforme a sua necessidade.
