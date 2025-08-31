# Documentação: Supabase Edge Function - `Asaas/event_processor`

## 1. Visão Geral

A função `event_processor` é uma Supabase Edge Function projetada para processar eventos recebidos via webhooks do Asaas que foram previamente armazenados no banco de dados. Esta função executa em lote, buscando eventos com status `PENDING` e aplicando atualizações apropriadas com base no tipo de evento e seu conteúdo.

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

*   **Tabela `asaas_webhook_events`**: Armazena os eventos recebidos via webhook.
    *   Campos utilizados:
        *   `id`: ID único do registro do evento
        *   `asaas_event_id`: ID do evento no Asaas
        *   `event_type`: Tipo do evento (ex: `ACCOUNT_STATUS_DOCUMENT_APPROVED`)
        *   `payload`: Conteúdo do evento em formato JSON
        *   `profile_id`: ID do perfil associado ao evento
        *   `received_at`: Data/hora de recebimento
        *   `processing_status`: Status de processamento (ex: `PENDING`, `PROCESSED`, `ERROR_PROCESSING`)
        *   `processed_at`: Data/hora de processamento
        *   `processing_error_details`: Detalhes de erro, se houver

*   **Tabela `asaas_accounts`**: Contém as contas Asaas que serão atualizadas com base nos eventos.
    *   Campos atualizados:
        *   `status_bank`: Status de verificação da conta bancária
        *   `status_commercial`: Status de verificação das informações comerciais
        *   `status_document`: Status de verificação de documentos
        *   `status_general`: Status geral de aprovação
        *   `status_reason`: Motivo de rejeição, se aplicável
        *   `last_webhook_event`: Último tipo de evento recebido
        *   `last_webhook_received_at`: Data/hora de recebimento do último evento

## 3. Endpoint

*   **Método HTTP**: `POST`
*   **Path Padrão da Edge Function**: `/functions/v1/Asaas/event_processor`

## 4. Configurações e Constantes

*   `EVENT_BATCH_SIZE`: Define o número máximo de eventos a serem processados por execução (atualmente `10`).
*   `corsHeaders`: Cabeçalhos CORS configurados para permitir requisições cross-origin.

## 5. Fluxo de Processamento Principal

1.  **Inicialização e Configuração**:
    *   Registra o início da execução com timestamp.
    *   Configura cabeçalhos CORS para permitir requisições cross-origin.
    *   Inicializa o cliente Supabase com as credenciais obtidas.

2.  **Busca de Eventos Pendentes**:
    *   Consulta a tabela `asaas_webhook_events` para obter eventos com `processing_status = 'PENDING'`.
    *   Ordena os eventos por `received_at` (mais antigos primeiro).
    *   Limita a quantidade de eventos processados por execução ao valor definido em `EVENT_BATCH_SIZE`.

3.  **Processamento de Eventos**:
    *   Para cada evento pendente, executa a função `processEvent()`.
    *   Mapeia os tipos de eventos do Asaas para estados de status internos.
    *   Atualiza os campos de status apropriados na tabela `asaas_accounts` com base no tipo de evento.
    *   Extrai e armazena motivos de rejeição quando o status é `REJECTED`.
    *   Registra o resultado do processamento, incluindo sucesso ou falha.

4.  **Atualização do Status do Evento**:
    *   Após o processamento de cada evento, atualiza seu status para `PROCESSED` ou `ERROR_PROCESSING`.
    *   Registra a data/hora de processamento e detalhes do erro, se houver.

5.  **Resposta**:
    *   Retorna HTTP 200 com resumo do processamento, incluindo total de eventos processados, sucessos e erros.
    *   Em caso de erro global, retorna status HTTP 500 com detalhes do erro.

## 6. Mapeamento de Eventos para Status

A função mapeia os tipos de eventos recebidos do Asaas para os status internos:

*   **Sufixos de eventos**:
    *   `_AWAITING_APPROVAL` → `'AWAITING_APPROVAL'`
    *   `_PENDING` → `'PENDING'`
    *   `_APPROVED` → `'APPROVED'`
    *   `_REJECTED` → `'REJECTED'`

*   **Prefixos de eventos e campos atualizados**:
    *   `ACCOUNT_STATUS_BANK_ACCOUNT_INFO_` → atualiza `status_bank`
    *   `ACCOUNT_STATUS_COMMERCIAL_INFO_` → atualiza `status_commercial`
    *   `ACCOUNT_STATUS_DOCUMENT_` → atualiza `status_document`
    *   `ACCOUNT_STATUS_GENERAL_APPROVAL_` → atualiza `status_general`

## 7. Sistema de Logging

A função utiliza logs estruturados através do `console.log` para facilitar o monitoramento e depuração:

* Logs são prefixados com `[EventProcessor-{timestamp}]` para facilitar identificação
* Logs detalhados para cada etapa do processo, incluindo:
  * Inicialização da função
  * Busca e processamento de eventos
  * Atualizações realizadas no banco de dados
  * Resultados de processamento

## 8. Tratamento de Erros

A função inclui múltiplos níveis de tratamento de erros:

*   **Nível Global**: Catch para erros não tratados durante a execução principal da função.
*   **Nível de Lote**: Catch para erros durante o processamento do lote de eventos.
*   **Nível de Evento Individual**: Tratamento de erros específicos para cada evento processado.

Em caso de erro, o evento é marcado como `ERROR_PROCESSING` e os detalhes do erro são armazenados, evitando que o mesmo evento seja reprocessado indefinidamente.

## 9. Execução Periódica

Esta função é projetada para ser executada periodicamente, seja por:

*   **Invocação Manual**: Chamada diretamente para processamento imediato.
*   **Job Agendado**: Configurada como tarefa cron no Supabase para execução em intervalos regulares.

Para configurar como tarefa agendada, adicione uma entrada ao arquivo `crontab` para a execução periódica da função.

## 10. Dependências Externas

*   **Módulos de `_shared`**:
    *   `vault.ts`: Para acessar secrets armazenados no Vault do Supabase.
    *   `env.ts`: Para obter variáveis de ambiente necessárias.

Este documento deve fornecer uma compreensão abrangente da função `event_processor`. Mantenha-o atualizado caso haja modificações na lógica ou nas dependências da função.
