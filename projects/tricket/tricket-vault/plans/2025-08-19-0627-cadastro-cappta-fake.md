# Plano: Cadastro via Simulador Cappta (Merchants/Terminais/POS)

Data/Hora: 2025-08-19 06:27 BRT
Branch: feat/cappta-fake-simulator (a partir de dev)

## Objetivo
Registrar o planejamento da etapa de cadastro (antes das operações financeiras), usando o simulador Cappta Fake como referência da Cappta real.

## Escopo
- Cadastrar e gerenciar Comerciantes (merchants), Terminais e POS via serviço simulador.
- Persistir no backend (Supabase) com idempotência e rastreabilidade.
- Mapear merchant ↔ conta Asaas (preparação para fase financeira).

## Referências
- Doc Cappta: `tricket-vault/docs/integrations/cappta.md` (fonte oficial: https://integration.cappta.com.br/#4053598f-9566-46a3-9527-4bd72b50c297)
- Docs do projeto: `tricket-vault/docs/project-overview.md`, `PRD-tricket-e.md`, `product-plan-epics-user-stories.md`

## Endpoints do simulador (propostos)
- POST `/merchants`:
  - Request: `external_merchant_id`, `document` (CPF/CNPJ), `business_name`, `trade_name`, `mcc`, `contact`, `address`
  - Response: `merchant_id` (simulador), `status` (active/pending/rejected), timestamps
- POST `/terminals`:
  - Request: `external_terminal_id`, `merchant_id`, `serial_number`, `brand_acceptance`, `capture_mode`, `status`
  - Response: `terminal_id`, `status`, timestamps
- POST `/pos-devices` (opcional):
  - Request: `terminal_id`, `device_type`, `model`, `firmware`, `status`
- GET `/merchants/{id}` e `/terminals/{id}`; GET por `external_*` para idempotência

Autenticação: Bearer token; em DEV, allowlist de IP.

## Modelagem de persistência (Supabase) — a definir nas migrations
- `merchant_integrations` (unique: `external_merchant_id`), armazena `sim_merchant_id`, status e JSON do payload
- `terminal_integrations` (unique: `external_terminal_id`), vinculado ao merchant
- `pos_devices` (opcional, granularidade por dispositivo)
- `merchant_accounts` (vincula merchant ao `asaas_customer_id`)

## Regras e validações
- Merchant: documento válido; `mcc` obrigatório; endereço mínimo; contato
- Terminal/POS: `merchant_id` existente; `serial_number`/modelo válidos; `brand_acceptance` coerente
- Idempotência: UNIQUE por `external_merchant_id` e `external_terminal_id`; replays retornam estado atual

## Observabilidade
- Logs estruturados com `request_id`, `external_*`, `sim_*_id`
- JSONB com payloads brutos para auditoria

## Testes (Pytest)
- Criar merchant idempotente; criar terminal para merchant existente; negar terminal para merchant inexistente; consultas detalhadas e comparação com persistência

## Variáveis de ambiente
- `CAPPTA_FAKE_API_URL`, `CAPPTA_FAKE_API_TOKEN`

## Critérios de aceite
- Plano e changelog registrados
- Contratos documentados em `docs/integrations/cappta.md`
- Sem implementação de código nesta etapa
