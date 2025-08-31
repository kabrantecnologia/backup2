# Documentação: Supabase Edge Function - `Asaas/webhook_account_status`

## 1. Visão Geral

A função `webhook_account_status` é uma Supabase Edge Function projetada para receber e processar notificações de eventos relacionados a contas (subcontas) na plataforma Asaas. Esta função autentica o remetente pelo token, valida e armazena o evento recebido em uma fila para processamento posterior.

## 2. Pré-requisitos e Configuração

Para que esta função opere corretamente, as seguintes configurações e dependências devem estar estabelecidas:

### 2.1. Variáveis de Ambiente (Supabase Function Settings)

Estas variáveis devem ser configuradas nas definições da Edge Function no painel do Supabase ou em um arquivo `.env` na raiz da função para desenvolvimento local:

*   `SUPABASE_URL`: A URL do seu projeto Supabase.
*   `SUPABASE_SERVICE_ROLE_KEY`: A chave de serviço (service_role key) do seu projeto Supabase (opcional, pode ser obtida do Vault).

O código utiliza a função `getServiceRoleKey()` do módulo compartilhado para carregar estas variáveis.

### 2.2. Segredos do Supabase Vault

Os seguintes segredos devem estar armazenados de forma segura no Supabase Vault e acessíveis pela função:

*   `SERVICE_ROLE_KEY`: Chave de serviço do Supabase que permite acesso às tabelas sem restrições de RLS.

### 2.3. Dependências de Banco de Dados Supabase

*   **Tabela `asaas_accounts`**: Contém as contas Asaas registradas e seus tokens de webhook.
    *   Campos utilizados: `profile_id`, `webhook_auth_token`.

*   **Tabela `asaas_webhook_events`**: Armazena os eventos recebidos via webhook para processamento posterior.
    *   Campos incluem:
        *   `asaas_event_id` (ID do evento no Asaas)
        *   `event_type` (tipo do evento Asaas)
        *   `payload` (conteúdo completo do evento)
        *   `headers` (cabeçalhos HTTP do webhook)
        *   `received_at` (timestamp de recebimento)
        *   `profile_id` (ID do perfil relacionado)
        *   `processing_status` (ex: 'PENDING', 'PROCESSED', etc.)

## 3. Endpoint

*   **Método HTTP**: `POST`
*   **Path Padrão da Edge Function**: `/functions/v1/Asaas/webhook_account_status`

## 4. Requisição

### 4.1. Cabeçalhos (Headers)

*   `asaas-access-token`: Token de autenticação configurado na criação da conta Asaas (obrigatório).
*   `Content-Type: application/json`: Indica que o corpo da requisição é JSON.

### 4.2. Corpo (Body - JSON)

O payload do webhook deve conter pelo menos:

```json
{
  "id": "string (ID do evento Asaas)",
  "event": "string (Tipo do evento Asaas)",
  "... outros campos específicos do evento ..."
}
```

## 5. Fluxo de Processamento Principal

1.  **Inicialização e Configuração**:
    *   Inicializa o logger para rastreamento de operações.
    *   Configura cabeçalhos CORS para permitir requisições cross-origin.
    *   Trata requisições OPTIONS para preflight CORS.

2.  **Validação de Método**:
    *   Verifica se a requisição utiliza o método HTTP POST.
    *   Retorna erro 405 para métodos não permitidos.

3.  **Inicialização do Supabase**:
    *   Obtém `SUPABASE_URL` e `SERVICE_ROLE_KEY`.
    *   Inicializa o cliente Supabase com essas credenciais.
    *   Obtém chaves adicionais do Vault se necessário.

4.  **Autenticação**:
    *   Extrai o token do cabeçalho `asaas-access-token`.
    *   Valida existência e formato básico do token.
    *   Consulta a tabela `asaas_accounts` para verificar se o token existe.
    *   Rejeita (status 401/403) caso o token seja inválido ou não encontrado.

5.  **Processamento do Payload**:
    *   Analisa o corpo JSON da requisição.
    *   Valida campos obrigatórios (`id` e `event`).
    *   Rejeita (status 400) caso o JSON seja inválido ou os campos obrigatórios estejam ausentes.

6.  **Registro do Evento**:
    *   Insere o evento na tabela `asaas_webhook_events` com status `PENDING`.
    *   Inclui dados completos do evento, cabeçalhos, timestamp e associa ao `profile_id`.
    *   Detecta e trata eventos duplicados (ID já existente).

7.  **Resposta**:
    *   Retorna HTTP 200 com confirmação de recebimento.
    *   Inclui o ID do evento registrado na resposta.

## 6. Sistema de Logging

A função utiliza um sistema de logging estruturado para facilitar o monitoramento e depuração:

* Logger inicializado com o nome `WebhookAccountStatus`
* Configuração para salvar logs em arquivos no diretório `./logs` quando executando localmente
* Nível mínimo de log definido como `INFO`
* Logs detalhados para cada etapa do processo, incluindo:
  * Inicialização da função
  * Validação de token
  * Processamento do payload
  * Registros de erros

## 7. Tratamento de Erros

A função inclui tratamento para diversos cenários de erro, retornando respostas JSON com status HTTP apropriados:

*   **405 Method Not Allowed**: Se o método HTTP não for POST.
*   **500 Internal Server Error**: Para falhas ao carregar configurações ou erros inesperados.
*   **401 Unauthorized**: Token de autenticação ausente.
*   **403 Forbidden**: Token inválido ou desconhecido.
*   **400 Bad Request**: JSON inválido ou faltando campos obrigatórios.
*   **409 Conflict**: ID de evento duplicado (já processado anteriormente).

## 8. Considerações de Segurança

*   **Autenticação de Webhook**: Utiliza um token de autenticação dedicado ao webhook para verificar que o remetente é legítimo.
*   **Validação de Evento**: Não processa eventos com estrutura inválida ou IDs duplicados.
*   **TOKEN** Este token deve ser o mesmo utilizado na configuração do webhook dentro da conta Asaas.

## 9. Processamento Posterior

Esta função atua apenas como um receptor e registrador dos eventos. O processamento real dos eventos acontece de forma assíncrona, possivelmente por uma função separada que consome eventos da tabela `asaas_webhook_events` com status `PENDING`.

## 10. Dependências Externas

*   **Módulos de `_shared`**:
    *   `vault.ts`: Para acessar secrets armazenados no Vault do Supabase.
    *   `logger.ts`: Para logging estruturado e consistente.
    *   `env.ts`: Para obter variáveis de ambiente necessárias.

Este documento deve fornecer uma compreensão abrangente da função `webhook_account_status`. Mantenha-o atualizado caso haja modificações na lógica ou nas dependências da função.
