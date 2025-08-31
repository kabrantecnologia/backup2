# Changelog — Cappta Fake Simulator (fase de planejamento)

Data/Hora: 2025-08-18 19:07 BRT
Branch: feat/cappta-fake-simulator (a partir de dev)

## Conteúdo
- Criado plano `tricket-vault/plans/2025-08-18-1906-cappta-fake-simulator.md` descrevendo:
  - Objetivo do simulador (destravar fluxos sem Cappta real) e uso da conta-matriz no Asaas.
  - Arquitetura proposta (FastAPI, endpoints de merchants/terminals/sales/settlements).
  - Contratos de API (alto nível) e autenticação.
  - Integração com o ledger interno via webhook Asaas.
  - Referência à documentação Cappta (White Label): https://integration.cappta.com.br/#4053598f-9566-46a3-9527-4bd72b50c297
- Sem desenvolvimento iniciado nesta fase (apenas organização e documentação).

## Próximos passos
- Modelagem das migrations do ledger e Edge Function de webhook Asaas.
- Scaffold do serviço FastAPI e testes de integração.
