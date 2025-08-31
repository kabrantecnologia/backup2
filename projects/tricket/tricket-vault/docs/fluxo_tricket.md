```mermaid
graph TD
    subgraph "Fluxo de Onboarding e Gestão de Perfis"
        A[Início] --> B{Cadastro de Usuário};
        B --> C{Tipo de Perfil?};
        C --> D[Pessoa Física (PF)];
        C --> E[Pessoa Jurídica (PJ)];
        D --> F[Preenche Dados Pessoais];
        E --> G[Preenche Dados da Empresa];
        F --> H{Verificação de Identidade (KYC)};
        G --> H;
        H --> H1[Aprovado];
        H --> H2[Reprovado];
        H --> H3[Pendente • Solicitar/Anexar Docs];
        H3 --> H;  
        H2 --> H2a[Encerrar/Correções Necessárias];
        H1 --> I[Aprovação Tricket];
        I --> J[Conta Asaas: criada];
        J --> K[Usuário Ativo na Plataforma];
        K --> L{Acessa como?};
        L --> M[Perfil Pessoal (IAM: user)];
        L --> N[Membro de Organização (IAM: owner/manager/operator)];
    end

    subgraph "Fluxo Financeiro (Contas e Transações)"
        O[Usuário Logado] --> P{Qual Operação?};
        P --> Q[Adicionar Saldo na Conta];
        P --> R[Usar Saldo para Compras];
        P --> S[Receber de Vendas POS (Comerciante)];
        P --> T[Solicitar Saque];
        Q --> U[PIX, Boleto, Cartão via Asaas];
        U --> V[Saldo Atualizado];
        R --> W[Pagamento no Marketplace];
        W --> W1{Autorizado?};
        W1 --> X[Autorizado → Split: Fornecedor + Tricket];
        W1 --> W2[Negado];
        S --> Y[Venda na Maquininha Cappta];
        Y --> Z[Crédito na Conta Asaas];
        Z --> Z1[Liquidação (D+X) e Conciliação];
        T --> T0{Validações (KYC, limites, saldo)};
        T0 --> T1[Processar Saque];
        T0 --> T2[Negado];
        T1 --> AA[Transferência para Conta Bancária Externa];
        AA --> AA1[Concluído];
        AA --> AA2[Falhou • Reverter Saldo/Notificar];
    end

    subgraph "Fluxo do Marketplace"
        AB[Usuário Logado] --> AC{Ação no Marketplace?};
        AC --> AD[Comprar Produtos];
        AC --> AE[Vender Produtos (Fornecedor)];
        AC --> AF[Gerenciar Catálogo (Admin)];
        
        AD --> AG[Busca e Filtra Produtos];
        AG --> AH[Adiciona ao Carrinho];
        AH --> AI[Checkout com Saldo Tricket];
        AI --> AJ[Criação do Pedido];
        AJ --> AK{Status do Pedido};
        AK --> AL[Confirmado pelo Fornecedor];
        AL --> AM[Em Preparação];
        AM --> AN[Em Trânsito];
        AN --> AO[Entregue ao Comprador];
        AO --> AOfim[Fim do Fluxo de Compra];
        AK --> AP[Cancelado];
        AP --> AP1[Reembolso/Estorno (se aplicável)];
        
        AE --> AQ[Cria/Gerencia Ofertas];
        AQ --> AR[Vincula a Produto do Catálogo Base];
        AR --> AS[Define Preço e Estoque];
        AE --> AT[Recebe e Gerencia Pedidos];
        AT --> AL;

        AF --> AU[CRUD de Categorias e Produtos Base];
        AF --> AV[Aprova/Rejeita Solicitações de Novos Produtos];
    end

    subgraph "Fluxo de Disputas"
        AZ[Comprador] --> BA[Abre Disputa];
        BB[Fornecedor] --> BC[Responde à Disputa];
        BA --> BD{Resolução};
        BC --> BD;
        BD --> BE[Acordo entre as Partes];
        BD --> BF[Mediação do Admin Tricket];
        BF --> BG[Decisão Final];
        BG --> BH[Ajuste Financeiro];
        BH --> BH1[Estorno/Repasse/Multa];
    end

    subgraph "Legenda"
        L1[Asaas/Cappta]:::externo
        L2((Decisão)):::decisao
        classDef externo fill:#eef,stroke:#88a;
        classDef decisao fill:#fff,stroke:#333,stroke-dasharray: 3 3;
    end
```