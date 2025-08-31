# Changelog — Atualização do Fluxo Tricket (Mermaid)

Data/Hora: 2025-08-18 18:35 BRT
Branch: feat/fluxo-diagrama-update (a partir de dev)

## Alterações
- Atualizado `tricket-vault/docs/fluxo_tricket.md` com:
  - Ramos KYC: aprovado, reprovado, pendente com retorno para complementação.
  - Financeiro: decisão de autorização de pagamento, liquidação POS (Cappta → Asaas), validações e falhas de saque com reversão.
  - Marketplace: estados detalhados (em preparação, em trânsito, entregue) e fluxo de reembolso em cancelamento.
  - Disputas: decisão final com ajuste financeiro (estorno/repasse/multa).
  - IAM: papéis anotados em perfil pessoal/organização.
  - Legenda simples para destacar externos/decisões.
- Encapsulado diagrama com cercas de código `mermaid` para renderização.

## Observações
- Apenas documentação; sem impacto em migrations ou código.
- Próximos passos potenciais: mapear nós do diagrama para entidades Supabase (tabelas/RPC/RLS) e referenciar PRD/overview.
