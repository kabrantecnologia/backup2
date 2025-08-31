# Plano: Atualização do Fluxo Tricket (Mermaid)

Data/Hora: 2025-08-18 18:28 BRT
Branch: feat/fluxo-diagrama-update (a partir de dev)

## Objetivo
Atualizar o diagrama `tricket-vault/docs/fluxo_tricket.md` para refletir ramos de exceção e estados adicionais:
- KYC: aprovado, reprovado, pendente (com retorno para complementação de documentos).
- Financeiro: autorização de pagamento, liquidação POS (Cappta → Asaas), validações e falhas de saque.
- Marketplace: estados detalhados do pedido (preparação, trânsito, entregue) e reembolso em cancelamento.
- Disputas: decisão final com ajuste financeiro (estorno/repasse/multa).
- IAM: anotações de papéis em perfis pessoais/organizações.
- Legenda visual simples para externos/decisões.

## Escopo
- Apenas documentação (Mermaid) sem impacto em schema/migrations.
- Sem alterações em código de backend/frontend.

## Entregáveis
- Arquivo `tricket-vault/docs/fluxo_tricket.md` atualizado.
- Changelog descrevendo as mudanças.

## Critérios de Aceite
- Mermaid compila e permanece legível/conciso.
- Estados de exceção mapeados.
- Sem conflito de nomenclatura com termos de domínio atuais.

## Observações
- Em iterações futuras, linkar nós a entidades Supabase (tabelas/RPC/RLS) e documentação PRD.
