# Integração Cappta — White Label API

Fonte oficial: https://integration.cappta.com.br/#4053598f-9566-46a3-9527-4bd72b50c297

Este documento consolida referências e decisões para a integração com a Cappta.

## Visão Geral
- Padrão: REST + JSON
- Autenticação: token via header (conforme doc Cappta)
- Objetivo: recebimento de eventos de vendas/autorizações, captura e liquidação para crédito aos comerciantes.

## Recursos (a detalhar conforme documentação oficial)
- Autenticação e obtenção de token
- Cadastro/gestão de estabelecimentos (merchants) e terminais
- Criação/consulta de transações (vendas)
- Eventos de captura/liquidação
- Webhooks/retornos (se aplicável)

## Contratos (rascunho de campos relevantes)
- Identificadores: `nsu`, `authorization_code`, `merchant_id`, `terminal_id`, `external_event_id`
- Valores: `gross_amount`, `fee_amount`, `installments`
- Datas: `captured_at`, `settlement_date`

## Decisões de Projeto
- Enquanto a Cappta real não estiver disponível, utilizaremos um simulador (Cappta Fake) e uma conta-matriz no Asaas para realizar transferências aos comerciantes, mantendo o mesmo contrato de eventos para facilitar a futura troca pela Cappta real.

## Pendências
- Levantar endpoints específicos, headers de autenticação e exemplos de payload/respostas diretamente na documentação da Cappta.
- Definir estratégia de idempotência alinhada aos identificadores fornecidos (NSU/autorização/event ID).

---

## Autenticação (simulador compatível Cappta)
- Header: `Authorization: Bearer <TOKEN>`
- Header: `Content-Type: application/json`
- Em DEV, considerar allowlist de IP.

## Idempotência
- Merchants: `external_merchant_id` (único no domínio Tricket)
- Terminals: `external_terminal_id` (único no domínio Tricket)
- Replays com mesmo identificador retornam 200/201 com o recurso existente (sem duplicar)

## Endpoints de Cadastro (Simulador Cappta Fake)

### POST /merchants
- Cria/atualiza comerciante; retorna `merchant_id` do simulador.
- Request (exemplo):
```json
{
  "external_merchant_id": "e0a1f1c6-0f1a-4d4d-9a2c-901234abcd00",
  "document": "12345678000199",
  "business_name": "ACME LTDA",
  "trade_name": "ACME Loja Centro",
  "mcc": "5399",
  "contact": {"email": "owner@acme.com", "phone": "+55 11 99999-0000"},
  "address": {"street": "Rua A", "number": "100", "city": "São Paulo", "state": "SP", "zip": "01000-000"}
}
```
- Response 201 (exemplo):
```json
{
  "merchant_id": "sim-merchant-123",
  "status": "active",
  "external_merchant_id": "e0a1f1c6-0f1a-4d4d-9a2c-901234abcd00",
  "created_at": "2025-08-19T09:30:00Z",
  "updated_at": "2025-08-19T09:30:00Z"
}
```
- Erros comuns:
  - 400: `document_invalid`, `missing_required_field`
  - 409: `merchant_already_exists` (idempotente)

### POST /terminals
- Cria/atualiza terminal atrelado ao merchant.
- Request (exemplo):
```json
{
  "external_terminal_id": "term-0001",
  "merchant_id": "sim-merchant-123",
  "serial_number": "SN-ABC-123",
  "brand_acceptance": ["visa", "mastercard", "elo"],
  "capture_mode": "smartpos",
  "status": "active"
}
```
- Response 201 (exemplo):
```json
{
  "terminal_id": "sim-term-001",
  "status": "active",
  "external_terminal_id": "term-0001",
  "merchant_id": "sim-merchant-123",
  "created_at": "2025-08-19T09:31:00Z"
}
```
- Erros comuns:
  - 404: `merchant_not_found`
  - 409: `terminal_already_exists` (idempotente)

### POST /pos-devices (opcional)
- Associa um dispositivo físico ao terminal (separação de concerns).
- Request (exemplo):
```json
{
  "terminal_id": "sim-term-001",
  "device_type": "smartpos",
  "model": "PAX-A920",
  "firmware": "1.2.3",
  "status": "active"
}
```

### GET /merchants/{id} | /merchants?external_id=...
### GET /terminals/{id} | /terminals?external_id=...
- Retorna dados atuais; útil para sincronização e verificação de idempotência.

## Mapeamento backend (Supabase)
- Tabelas propostas (migrations futuras):
  - `merchant_integrations(external_merchant_id UNIQUE, sim_merchant_id, status, payload jsonb, created_at, updated_at)`
  - `terminal_integrations(external_terminal_id UNIQUE, sim_terminal_id, merchant_ref, status, payload jsonb)`
  - `pos_devices(sim_terminal_id, device_type, model, firmware, status)`
  - `merchant_accounts(merchant_ref, asaas_customer_id)`
- RPCs futuras: `upsert_merchant_from_cappta()`, `upsert_terminal_from_cappta()`

## Observações
- Campos devem ser ajustados para refletir exatamente a nomenclatura da Cappta quando avançarmos com a integração real.
- Manter logs estruturados e payloads brutos (JSONB) para auditoria e troubleshooting.
