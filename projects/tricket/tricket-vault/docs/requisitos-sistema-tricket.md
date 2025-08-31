---
id: 8cmaqrd-4233
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
# Requisitos do Sistema - Tricket

Este documento detalha os requisitos funcionais e não funcionais para a plataforma Tricket.

## 1. Introdução

*   **Propósito:** Descrever os requisitos que o sistema Tricket deve atender.
*   **Escopo:** Definir os limites do sistema, funcionalidades incluídas e excluídas.
*   **Público:** Desenvolvedores, QAs, Product Owners, Stakeholders.
*   **Definições e Acrônimos:** Glossário de termos técnicos e de negócio.

## 2. Requisitos Funcionais

Descrevem *o que* o sistema deve fazer. Serão detalhados com base nos fluxos operacionais e regras de negócio.

*   **RF001 - Cadastro de Usuário:**
    *   [ ] Permitir cadastro inicial via Email/Senha.
    *   [ ] Enviar email de confirmação com link de verificação.
    *   [ ] Permitir finalização de cadastro com dados pessoais (PF) e empresariais (PJ).
    *   [ ] Permitir seleção de tipo de conta (Consumidor, Comerciante e Fornecedor).
    *   [ ] Validar formato e unicidade de CPF/CNPJ.
    *   [ ] Permitir upload de documentos comprobatórios para análise da equipe Tricket.
    *   [ ] Integrar com processo de onboarding do Asaas, que inclui verificação de identidade e validação facial.
    *   [ ] Permitir cadastro de conta bancária externa.
*   **RF002 - Autenticação e Autorização:**
    *   [ ] Autenticar usuários via Email/Senha.
    *   [ ] Implementar 2FA (TOTP) - Obrigatório para Admin, opcional para outros.
    *   [ ] Aplicar política de senha (complexidade, expiração).
    *   [ ] Controlar acesso baseado em Papéis e Permissões (RBAC).
    *   [ ] Permitir que um usuário com múltiplos perfis (PF e PJs) selecione o perfil ativo para a sessão.
*   **RF003 - Gestão de Catálogo (Admin):**
    *   [ ] CRUD de Categorias (até 3 níveis).
    *   [ ] Garantir unicidade de nome de Categoria por nível.
    *   [ ] CRUD de Produtos Base.
    *   [ ] Garantir unicidade de Nome e Código Interno de Produto Base.
    *   [ ] Implementar fluxo para Aprovar/Rejeitar solicitações de novos Produtos Base enviadas por Fornecedores.
*   **RF004 - Gestão de Ofertas (Fornecedor):**
    *   [ ] CRUD de Ofertas vinculadas a Produtos Base.
    *   [ ] Permitir solicitar a criação de um novo Produto Base (caso não exista no catálogo).
    *   [ ] Garantir unicidade de Oferta por Fornecedor/Produto Base.
    *   [ ] Definir Preço, Qtd Mín/Máx, Prazo de Entrega por Oferta.
    *   [ ] Permitir importação CSV de Ofertas.
*   **RF005 - Marketplace e Pedidos (Comprador):**
    *   [ ] Buscar/Filtrar produtos (texto, categoria, filtros avançados).
    *   [ ] Adicionar itens ao carrinho.
    *   [ ] Aplicar timeout de 15 min no carrinho (checkout).
    *   [ ] Calcular frete baseado na distância (PostGIS) e nas regras do fornecedor (raio de atendimento, frete grátis por valor).
    *   [ ] Realizar pagamento (Asaas - PIX, Boleto, Cartão, Saldo POS).
    *   [ ] Visualizar histórico de pedidos.
    *   [ ] Solicitar cancelamento de pedido (antes da confirmação do fornecedor).
    *   [ ] Abrir disputa (pós-entrega/prazo expirado).
    *   [ ] Confirmar recebimento de pedido.
*   **RF006 - Gestão de Pedidos (Fornecedor):**
    *   [ ] Visualizar novos pedidos.
    *   [ ] Confirmar/Rejeitar pedidos (com motivo) dentro do SLA (4h úteis).
    *   [ ] Atualizar status do pedido (Expedido).
    *   [ ] Informar dados de envio (NF, Rastreio).
    *   [ ] Solicitar cancelamento de pedido (pré-expedição).
    *   [ ] Responder a disputas (dentro do prazo).
*   **RF007 - Gestão de Pedidos (Admin):**
    *   [ ] Visualizar todos os pedidos.
    *   [ ] Mediar disputas não resolvidas.
*   **RF008 - Pagamentos e Financeiro:**
    *   [ ] Integrar com Asaas para processar pagamentos, saques, reembolsos.
    *   [ ] Aplicar taxas conforme Pacote de Taxas do cliente (Fluxo 26).
    *   [ ] Aplicar taxa zero para uso de Saldo POS.
    *   [ ] Calcular e aplicar taxa de adquirência no saque (apenas sobre saldo não-POS).
    *   [ ] Realizar split automático de pagamentos (Fornecedor, Tricket) via Asaas.
    *   [ ] Repassar valor ao Fornecedor (D+2 pós-confirmação de entrega, fallback D+X).
    *   [ ] Implementar retentativas de pagamento (Retry).
    *   [ ] Aplicar timeouts de pagamento por método.
    *   [ ] Bloquear saques por 24h após alteração de dados bancários.
*   **RF009 - Gestão de Perfil e Cadastro:**
    *   [ ] Permitir visualização/edição de dados cadastrais.
    *   [ ] Submeter alterações críticas (CNPJ, Razão Social, Bancários) para aprovação do Admin.
    *   [ ] Gerenciar colaboradores (CRUD) respeitando limite do pacote.
*   **RF010 - Notificações:**
    *   [ ] Enviar notificações (Email, In-App, Push?) para eventos relevantes (novo pedido, status atualizado, disputa, etc.).
    *   [ ] Permitir configuração de preferências de notificação pelo usuário.
*   **RF011 - Gestão de Disputas (Admin) (Fluxo 11, Regra 7.1):**
    *   **RF011.1 - Visualização e Acompanhamento de Disputas:**
        *   [ ] Exibir um painel/lista para o Admin com todas as disputas abertas na plataforma.
        *   [ ] Para cada disputa, mostrar: ID do Subpedido, Comerciante, Fornecedor, Motivo da Disputa, Data de Abertura, Status Atual da Disputa (Ex: Aberta, Em Análise, Aguardando Resposta [Comerciante/Fornecedor], Resolvida).
        *   [ ] Permitir filtrar e ordenar a lista de disputas por status, data, comerciante, fornecedor.
        *   [ ] Permitir acesso à visualização completa da disputa, incluindo:
            *   Detalhes do subpedido associado.
            *   Histórico de comunicação entre Comerciante e Fornecedor (RF005.4, RF006.3).
            *   Evidências anexadas por ambas as partes.
            *   Linha do tempo dos eventos da disputa.
    *   **RF011.2 - Mediação e Intervenção:**
        *   [ ] Permitir que o Admin adicione comentários internos (visíveis apenas para outros Admins) ou comentários visíveis para Comerciante e Fornecedor na thread da disputa.
        *   [ ] Permitir que o Admin solicite informações/evidências adicionais a uma ou ambas as partes.
    *   **RF011.3 - Resolução da Disputa:**
        *   [ ] Permitir que o Admin tome uma decisão final sobre a disputa, selecionando uma resolução padrão:
            *   `Decisão Favorável ao Comerciante (Reembolso Total)`: O valor total do subpedido é estornado ao Comerciante. Implica ajuste financeiro via Asaas.
            *   `Decisão Favorável ao Comerciante (Reembolso Parcial)`: O Admin define um valor parcial a ser estornado ao Comerciante. Implica ajuste financeiro via Asaas.
            *   `Decisão Favorável ao Fornecedor (Sem Reembolso)`: O pagamento ao Fornecedor é mantido/liberado conforme as regras normais (Regra 6.6).
            *   `Outra Resolução (Acordo)`: Registrar um acordo específico (ex: reenvio do produto) - requer ação manual externa ou integração futura.
        *   [ ] Exigir que o Admin adicione uma justificativa detalhada para a decisão tomada.
        *   [ ] Mudar o status da disputa para `Resolvida`.
        *   [ ] Notificar Comerciante e Fornecedor sobre a decisão final e a justificativa.
    *   **RF011.4 - Gestão de Prazos e Alertas:**
        *   [ ] Monitorar prazos para respostas de Comerciantes/Fornecedores durante a mediação do Admin.
        *   [ ] Alertar o Admin sobre disputas próximas do vencimento do SLA de resolução.

