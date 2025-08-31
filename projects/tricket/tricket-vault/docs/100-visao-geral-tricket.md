---
id: 8cmaqrd-4173
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
# Visão Geral do Projeto Tricket

## 1. Resumo Executivo

A Tricket é um **ecossistema digital** projetado para otimizar as operações financeiras e a cadeia de suprimentos de **Perfis Individuais (Pessoas Físicas - PF)** e **Perfis de Organização (Pessoas Jurídicas - PJ)**. A plataforma integra um sistema de Ponto de Venda (POS) para Comerciantes, um marketplace para compra e venda de produtos/insumos, e uma robusta gestão financeira através de contas digitais fornecidas pela Asaas (BaaS).

O objetivo central é simplificar processos críticos, oferecendo uma solução unificada que conecta Consumidores (PF e PJ), Comerciantes (PJ) e Fornecedores (PJ), agregando valor e eficiência a todas as partes.

## 2. Modelo de Negócio e Pilares Funcionais

A Tricket opera sobre três pilares principais:

- **Sistema de Pagamentos via POS (para Comerciantes PJ):**
    
    - Comerciantes utilizam maquininhas POS (via Cappta) para suas vendas.
        
    - Os valores são creditados como saldo na conta digital Asaas da empresa Comerciante, gerenciada pela Tricket.
        
- **Marketplace Integrado:**
    
    - Fornecedores (PJ) listam seus produtos e ofertas em um catálogo base gerenciado pela Tricket.
        
    - Consumidores (PF e PJ) e Comerciantes (PJ) compram produtos neste marketplace **exclusivamente utilizando o saldo disponível em suas contas digitais Tricket/Asaas.**
        
    - É possível **adicionar saldo** à conta digital Tricket/Asaas através de diversos métodos de pagamento (ex: Cartão, PIX), facilitando as transações no marketplace.
        
- **Gestão Financeira Centralizada (via Asaas BaaS):**
    
    - A Tricket gerencia contas digitais individuais (PF) e empresariais (PJ) fornecidas pela Asaas.
        
    - A plataforma facilita transferências internas (ex: pagamentos no marketplace) e o processamento de saques dos saldos para contas bancárias externas.
        

## 3. Principais Participantes e Estrutura de Perfis

A Tricket atende a diversos perfis, cada um com funcionalidades e processos de onboarding específicos:

- **Perfis Individuais (PF):** Podem atuar como **Consumidores** (comprando no marketplace, requerem aprovação e conta Asaas) ou como **Colaboradores** de organizações (acesso via convite, sem necessidade de conta Asaas pessoal para esta função).
    
- **Perfis de Organização (PJ):** Podem ser **Consumidores PJ**, **Fornecedores** (vendendo no marketplace) ou **Comerciantes** (utilizando o sistema POS). Todos os perfis PJ que transacionam necessitam de aprovação e uma conta Asaas empresarial. Comerciantes também requerem integração com a Cappta.
    
- **Equipe Interna Tricket:** Administradores e equipe de suporte gerenciam a plataforma e auxiliam os usuários.
    

A estrutura permite que um mesmo indivíduo (com uma única conta de acesso) possa ter um perfil de consumidor pessoal e também ser membro de uma ou mais organizações. O sistema permitirá que o usuário selecione ativamente com qual perfil deseja operar (seja o pessoal ou o de uma das organizações), garantindo clareza e controle sobre suas ações na plataforma.

## 4. Tecnologias Chave

- **Supabase:** Backend as a Service (Banco de Dados PostgreSQL com PostGIS, Autenticação, APIs, Funções), com auto-hospedagem (self-hosted).
    
- **Asaas:** Banking as a Service (Contas digitais, pagamentos, transferências, saques).
    
- **Cappta:** Solução de adquirência para POS.
    
- **WeWeb:** Plataforma No-Code/Low-Code para o frontend, com o código exportado para auto-hospedagem em servidores VPS.
    
- **GS1 Brasil:** Integração com banco de dados de produtos.

## 5. Objetivos do Projeto

- **Desenvolver uma plataforma digital multifuncional** que integre funcionalidades de Ponto de Venda (POS), marketplace B2B/B2C e gestão financeira.
    
- **Otimizar as operações financeiras** de Comerciantes, permitindo o recebimento de vendas POS diretamente em uma conta digital e o uso desse saldo para compras no marketplace.
    
- **Facilitar a cadeia de suprimentos** conectando Fornecedores a uma rede de Comerciantes, outros negócios (Consumidores PJ) e Consumidores Pessoa Física (PF).
    
- **Proporcionar uma experiência de usuário intuitiva e segura** para todos os tipos de perfis, desde o cadastro e onboarding até as transações diárias.
    
- **Integrar com parceiros tecnológicos chave** (Asaas, Cappta) para oferecer serviços financeiros e de pagamento robustos.
    
- **Garantir a conformidade** com a LGPD e as regulações financeiras aplicáveis.
    

## 6. Escopo do Produto/Plataforma (Funcionalidades Principais)

A plataforma Tricket incluirá os seguintes pilares funcionais:

- **Módulo de Gestão de Perfis e Onboarding:**
    
    - Cadastro e autenticação de usuários (PF e PJ).
        
    - Processo de onboarding com aprovação administrativa pela equipe Tricket e verificação de identidade (incluindo facial) via Asaas.
        
    - Gestão de múltiplos perfis (PF e PJ) por um único usuário autenticado, com um seletor de perfil ativo.
        
    - Sistema de convites para adição de Colaboradores a organizações.
        
- **Módulo de Ponto de Venda (POS) - para Comerciantes PJ:**
    
    - Integração com a adquirente Cappta para processamento de pagamentos.
        
    - Visualização de saldo e transações POS na conta digital Tricket/Asaas do Comerciante.
        
- **Módulo de Marketplace:**
    
    - Catálogo de produtos base gerenciado pela equipe Tricket.
        
    - Funcionalidade para Fornecedores (PJ) criarem e gerenciarem suas ofertas (preço, estoque) vinculadas aos produtos do catálogo base, além de poderem solicitar a inclusão de novos produtos ao catálogo (sujeito à aprovação da equipe Tricket).
        
    - Busca, navegação e visualização de produtos/ofertas para todos os compradores.
        
    - Funcionalidade de carrinho de compras.
        
    - Processo de checkout para compra de produtos **exclusivamente com saldo da conta digital Tricket/Asaas**.
        
    - Cálculo de frete utilizando a extensão PostGIS para medir distâncias. O fornecedor poderá configurar regras como raio de atendimento e frete grátis acima de um determinado valor.
        
- **Módulo de Gestão Financeira (Integrado com Asaas):**
    
    - Visualização de saldo e extrato da conta digital Tricket/Asaas para PFs e PJs.
        
    - Funcionalidade para **adicionar saldo** à conta digital Tricket/Asaas (via Cartão, PIX, etc.).
        
    - Transferências internas entre contas Tricket/Asaas (ex: pagamento de comprador para fornecedor).
        
    - Solicitação e processamento de saques do saldo para contas bancárias externas.
        
    - Gestão de taxas e comissões da plataforma.
        
- **Módulo Administrativo (para Equipe Tricket):**
    
    - Gerenciamento de usuários e perfis (aprovações, status).
        
    - Gerenciamento do catálogo de produtos base.
        
    - Moderação de ofertas (se aplicável).
        
    - Configuração de taxas e comissões.
        
    - Ferramentas de suporte ao usuário.
        

## 7. Público-Alvo/Principais Participantes

- **Perfis Individuais (Pessoas Físicas - PF):**
    
    - **Consumidores:** Compram no marketplace.
        
    - **Colaboradores:** Atuam em nome de organizações.
        
- **Perfis de Organização (Pessoas Jurídicas - PJ):**
    
    - **Comerciantes:** Varejistas que usam POS e compram no marketplace.
        
    - **Fornecedores:** Vendem produtos/insumos no marketplace.
        
    - **Consumidores PJ:** Empresas que compram no marketplace.
        
- **Equipe Interna Tricket:** Administradores e Suporte.