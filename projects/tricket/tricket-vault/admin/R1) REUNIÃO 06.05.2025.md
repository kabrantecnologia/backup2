---
id: 
status: 
version: 1
source: NotebookLM
type: task
action: create
space: Projetos
folder: Tricket
list: Marketplace
parent_id: 
created: 2025-07-08 08:55
due_date: ""
start_date: 
tags:
  - projetos/tricket
summary: 
path: /home/joaohenrique/Obsidian/01-PROJETOS/tricket-revisar/Revisar
---



Regras definidas em reunião no dia 06/05/2025

---
Assinatura NF - Documento
NF Fornecedor na plataforma 

### 2) Integrações

- Cappta
- Asaas
- GS1 Brasil
- Checkout (Split, Cartão)

---

### 3) Processos

Fornecedor deve confirmar pedido
- [ ] Definir prazo confirmação / cancelamento automatico
- [ ] Ao confirmar o fornecedor coloca o prazo de entrega
- [ ] Emitir e anexar nota fiscal eletrônica ou link 

Comerciante deve confirmar recebimento
- [ ] Definir prazo confirmação automática

A assinatura no recibo da nota fiscal será usado como garantia no processo de disputa entre cliente / fornecedor

Fornecedor deve cadastrar regras de frete
- gratuito até raio X
- gratuito / valor do pedido / raio
- preço por km

Saldo fica congelado na conta do cliente até conclusão do pedido

Após a conclusão valor é transferido ao fornecedor deduzindo a taxa (Split)

## Políticas 
- Disputa
- Devolução
- Estorno
- Repasse




### 4) Categorias e Produtos


## Gestão de Catálogo (Categorias, Produtos Base)

**Hierarquia de Categorias:** As categorias de produtos podem ter até 3 níveis hierárquicos (Raiz > Categoria > Subcategoria)

**Unicidade de Categoria:** Nomes de categorias devem ser únicos

**Exclusão de Categoria:** Categorias vinculadas a produtos não podem ser excluídas, apenas inativadas.

**Catálogo Base:** O catálogo central de "Produtos Base" é gerenciado exclusivamente pelo Admin Tricket.

**Unicidade de Produto Base:** Produtos Base devem ter Nome e Código Interno únicos 

**Importação CSV:** Produtos Base podem ser criados/atualizados via importação CSV processada de forma assíncrona.

**Solicitação de Produto:** Fornecedores podem solicitar a inclusão de novos produtos no Catálogo Base, sujeita à análise e aprovação do Admin 

## 3. Gestão de Ofertas (Fornecedor)

**Vínculo ao Catálogo Base:** Ofertas de fornecedores devem ser obrigatoriamente vinculadas a um "Produto Base" existente.

**Unicidade de Oferta:** Um fornecedor não pode criar múltiplas ofertas para o mesmo "Produto Base"; deve editar a existente.

**Dados da Oferta:** Cada oferta deve incluir Preço, Quantidade Mínima por Pedido, Quantidade Máxima por Pedido e Prazo de Entrega.

**Importação CSV:** Ofertas podem ser criadas/atualizadas via importação CSV processada de forma assíncrona.

**Limites de Pedido:** O fornecedor define a quantidade mínima e máxima que um comerciante pode pedir de um produto em uma única ordem.

## 4. Marketplace e Pedidos (Comerciante)

**Busca e Filtros:** Comerciantes podem buscar produtos por texto, categoria e aplicar filtros avançados (preço, fornecedor, prazo, região)

**Checkout Timeout:** O processo de checkout (reserva de itens no carrinho) tem um timeout de 15 minutos.

**Cancelamento pelo Comerciante:** O Comerciante só pode cancelar um pedido antes que o Fornecedor o confirme.

**Abertura de Disputa:** O Comerciante pode abrir uma disputa para pedidos entregues (ou com prazo de entrega expirado) caso haja problemas (item errado, danificado, faltando, não recebido), fornecendo motivo e evidências.

**Confirmação de Recebimento:** O Comerciante deve confirmar o recebimento dos pedidos.

**Avaliação do Fornecedor:** Após a confirmação de recebimento, o Comerciante pode avaliar o Fornecedor.

## 5. Gestão de Pedidos (Fornecedor e Admin)

**Confirmação pelo Fornecedor:** O Fornecedor deve confirmar ou rejeitar (com motivo) novos pedidos dentro de 4 horas úteis. Pedidos não respondidos podem ser cancelados automaticamente.

**Atualização de Status:** O Fornecedor é responsável por atualizar o status do pedido (Confirmado, Expedido) e fornecer informações de envio (NF, Rastreio)

**Cancelamento pelo Fornecedor:** O Fornecedor pode cancelar um pedido já confirmado, desde que seja antes da expedição.

**Resposta a Disputas:** O Fornecedor deve responder a disputas abertas pelo Comerciante dentro de um prazo definido, apresentando seus argumentos e evidências.

**Mediação de Disputas:** O Admin Tricket atua como mediador em disputas não resolvidas entre Comerciante e Fornecedor, analisando evidências e tomando uma decisão final baseada nas políticas da plataforma.

**Intervenção do Admin:** O Admin pode intervir manualmente em pedidos em casos específicos (conflitos, problemas técnicos, escalações), registrando justificativa.

## 6. Pagamentos, Taxas e Comissões

**Gateway de Pagamento:** As transações financeiras (pagamentos, reembolsos, saques) são processadas via Asaas.

**Pacotes de Taxas:** Empresas (Comerciantes/Fornecedores) são associadas a Pacotes de Taxas que definem as tarifas para diferentes operações.

**Taxa Zero (Saldo POS):** O uso de saldo originado de vendas POS (Cappta) para compras no marketplace Tricket possui taxa zero.

**Taxa de Saque:** A taxa de adquirência é aplicada apenas sobre a porção do saldo *não* originada de vendas POS no momento do saque para conta externa.

**Split Automático:** As taxas e comissões são calculadas e divididas (split) automaticamente via Asaas no momento do pagamento, conforme as regras do pacote de taxa e origem do saldo.

**Repasse ao Fornecedor:** O valor devido ao Fornecedor por uma venda é repassado D+2 (dois dias após) a confirmação de entrega do pedido pelo Comerciante, desde que não haja disputa aberta.

**Reembolsos:** Reembolsos são processados via Asaas, automaticamente para cancelamentos permitidos e manualmente (via Admin) para outros casos (disputas, devoluções)

**Retry de Pagamento:** Falhas no processamento de pagamento possuem uma política de retentativa automática (3 tentativas com backoff exponencial).

**Timeout de Pagamento:** Métodos de pagamento possuem timeouts definidos (PIX/Cartão: 15 min; Boleto: 72h)

**Período de Segurança para Saques:** Alterações nos dados bancários cadastrados acionam um bloqueio temporário de 24 horas para saques.

## 7. Segurança e Permissões

**Alterações Críticas:** Modificações em dados críticos do cadastro (CNPJ, Razão Social, Documentos Principais, Dados Bancários) requerem aprovação do Admin (Fluxo 15).

**Validade de Documentos:** O sistema monitora a validade de documentos e alerta o usuário 30 dias antes do vencimento para renovação.

**Controle de Acesso:** O acesso às funcionalidades da plataforma é controlado por um sistema RBAC (Role-Based Access Control) com papéis, grupos e permissões granulares 

**Níveis de Colaborador:** Existem papéis pré-definidos para colaboradores com níveis de acesso distintos: Operador de Compras, Operador Financeiro, Gerente.

**Logs de Auditoria:** Todas as ações críticas, alterações de dados, operações financeiras e mudanças de status são registradas em logs detalhados para auditoria.

**Retenção de Logs:** Logs possuem política de retenção definida (30 dias hot, 90 dias warm, 5 anos cold).

**Segurança de Dados:** A plataforma segue princípios de Privacy by Design (LGPD) e adota medidas como criptografia, tokenização e segurança em trânsito (TLS 1.3)

**Gestão de Credenciais:** Secrets e chaves de API são gerenciados de forma segura (ex: HashiCorp Vault) com rotação.

**Testes de Segurança:** São realizados testes de segurança periódicos (Pentest trimestral) e mantido um programa de Bug Bounty.

## 8. Integrações e Sistema

**Sincronização:** Alterações cadastrais aprovadas são sincronizadas com as APIs externas (Asaas, Cappta)

**Resiliência de Integrações:** Integrações com APIs externas possuem mecanismos de resiliência como Circuit Breaker e Retry.

**Processamento Assíncrono:** Tarefas demoradas (importação CSV, relatórios complexos) são processadas em background usando um sistema de filas.

**Cache:** A plataforma utiliza múltiplos níveis de cache (Memória, Redis, CDN) para otimizar a performance, com estratégias de invalidação (TTL + Event-based)

**Monitoramento:** A saúde da aplicação e infraestrutura é monitorada continuamente (métricas, logs, traces) com alertas configurados para anomalias e violações de SLOs.

**Infraestrutura como Código (IaC):** A infraestrutura é gerenciada via IaC (Terraform/CDK).

**Deployment:** A estratégia de deploy é Blue/Green com Canary Testing.

**Alta Disponibilidade (HA) e Disaster Recovery (DR):** A plataforma é projetada para HA (Multi-AZ) e possui plano de DR com RTO/RPO definidos.

---

# REVISAR

**Regra 6.6 (Repasse ao Fornecedor):** A regra menciona o repasse D+2 após confirmação de entrega. A redação atual não aborda o cenário onde o Comerciante não confirma a entrega. Se o fluxo define um mecanismo de fallback (ex: auto-confirmação após prazo), seria útil incluir essa informação na regra consolidada para evitar a impressão de um possível bloqueio indefinido.