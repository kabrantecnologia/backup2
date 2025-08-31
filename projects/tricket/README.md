# Projeto Tricket

## 📜 Sobre o Projeto

A Tricket é um **ecossistema digital** projetado para otimizar as operações financeiras e a cadeia de suprimentos de **Perfis Individuais (Pessoas Físicas - PF)** e **Perfis de Organização (Pessoas Jurídicas - PJ)**. A plataforma integra um sistema de Ponto de Venda (POS) para Comerciantes, um marketplace para compra e venda de produtos/insumos, e uma robusta gestão financeira através de contas digitais fornecidas pela Asaas (BaaS).

O objetivo central é simplificar processos críticos, oferecendo uma solução unificada que conecta Consumidores (PF e PJ), Comerciantes (PJ) e Fornecedores (PJ), agregando valor e eficiência a todas as partes.
## 🏛️ Arquitetura de Repositórios

```
/tricket/
├── tricket-backend/
│   ├── supabase/
│   │   ├── migrations/      — database migrations SQL
│   ├── volumes/
│   │   └── functions/       — Edge Functions (SOURCE OF TRUTH)
│   ├── tests/               — Python integration tests (pytest)
│   └── pytest.ini           — test discovery config
└── tricket-frontend/     
└── tricket-vault/        — markdown vault
    └── agents/              — AI agents and automation scripts
    └── changelogs/          — Detailed project changelogs
    └── docs/                — General project documentation
    └── plans/               — Project planning and roadmaps
    └── wiki/                — Collaborative knowledge base
```

## 🛠️ Tecnologias Utilizadas

- **Backend**: [Ex: Supabase, PostgreSQL, Deno]
    
- **Frontend**: [Ex: WeWeb, Vue.js, Node.js]
    
- **Documentação**: [Ex: Markdown, Obsidian]
    
- **Infraestrutura**: [Ex: Docker]
    

## 📈 Versionamento e Commits

Este projeto utiliza o **Versionamento Semântico (SemVer)** e segue um tricket de **Git Flow com a branch `staging`**. As mensagens de commit devem seguir o padrão **Conventional Commits**.

### Guia de Tipos de Commit

|   |   |   |
|---|---|---|
|**Tipo**|**Quando Usar**|**Exemplo**|
|**`feat`**|Para adicionar uma nova funcionalidade visível ao usuário.|`feat: adiciona login com conta Google`|
|**`fix`**|Para corrigir um bug que causava um comportamento inesperado.|`fix: corrige cálculo de impostos no carrinho`|
|**`docs`**|Apenas para alterações na documentação (ex: README, guias).|`docs: atualiza o README com instruções`|
|**`chore`**|Para tarefas de manutenção que não afetam o código de produção.|`chore: atualiza dependências do npm`|
|**`refactor`**|Para melhorar o código existente sem alterar seu comportamento.|`refactor: simplifica a função de validação`|
|**`style`**|Apenas para mudanças de formatação de código (espaços, etc.).|`style: formata o código com o Prettier`|
|**`test`**|Para adicionar ou corrigir testes.|`test: adiciona testes unitários para o login`|

## 👤 Contato

**João Henrique** - Sócio Fundador e CTO - [Kabran Tecnologia](https://kabran.com.br "null")