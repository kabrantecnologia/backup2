# Documentação: Supabase Edge Function - `Asaas/account_create`

## 1. Visão Geral

A função `asaas_account_create` é uma Supabase Edge Function projetada para criar uma nova conta de cliente (subconta) na plataforma Asaas e registrar os detalhes relevantes no banco de dados Supabase. Ela é acionada por uma requisição HTTP e requer autenticação e autorização específicas.

## 2. Pré-requisitos e Configuração

Para que esta função opere corretamente, as seguintes configurações e dependências devem estar estabelecidas:

### 2.1. Variáveis de Ambiente (Supabase Function Settings)

Estas variáveis devem ser configuradas nas definições da Edge Function no painel do Supabase ou em um arquivo `.env` na raiz da função para desenvolvimento local (`/opt/supabase-project/volumes/functions/asaas_account_create/.env`).

*   `SUPABASE_URL`: A URL do seu projeto Supabase.
*   `SUPABASE_SERVICE_ROLE_KEY`: A chave de serviço (service_role key) do seu projeto Supabase.

O código também possui lógica para carregar variáveis de um arquivo `.env` localmente utilizando a função `getServiceRoleKey()`.

### 2.2. Segredos do Supabase Vault

Os seguintes segredos devem estar armazenados de forma segura no Supabase Vault e acessíveis pela função:

*   `ASAAS_MASTER_ACCESS_TOKEN`: O token de acesso mestre (API Key principal) para interagir com a API do Asaas.
*   `ENCRYPTION_SECRET`: Um segredo forte usado como base para derivar a chave de criptografia para a API Key da subconta Asaas criada.
*   `API_EXTERNAL_URL`: A URL externa da API, usada para configurar os endpoints de webhook.

### 2.3. Constantes Internas da Função

*   `PBKDF2_SALT_STRING`: Definida no código (atualmente como `"4BGEdKWWwHuUvfrXjqu5iKCEQbo1aG7Mu9difS36UXzmtm9TRj0Y2oLMIkqep40q"`). Este é um salt fixo usado com PBKDF2 para derivar a chave de criptografia AES-GCM. **É crucial que este valor seja único, aleatório e persistente para a aplicação.**
*   `PBKDF2_ITERATIONS`: Número de iterações para PBKDF2 (atualmente `100000`).
*   `ENCRYPTION_ALGORITHM`: Algoritmo de criptografia (atualmente `"AES-GCM"`).
*   `KEY_LENGTH`: Tamanho da chave AES em bits (atualmente `256`).
*   `IV_LENGTH_BYTES`: Tamanho do Vetor de Inicialização em bytes (atualmente `12`).

### 2.4. Dependências de Banco de Dados Supabase

*   **View `view_admin_profile_approval`**: Esta view é a fonte dos dados do perfil do usuário/organização que será usado para criar a conta no Asaas. A função espera que esta view retorne campos como:
    *   `profile_id` (UUID)
    *   `profile_type` (e.g., `INDIVIDUAL`, `ORGANIZATION`)
    *   `name` (Nome completo ou Razão Social)
    *   `email`
    *   `cpf_cnpj`
    *   `birth_date` (para `INDIVIDUAL`)
    *   `company_type` (para `ORGANIZATION`)
    *   `mobile_phone`
    *   `income_value` (Renda/Faturamento)
    *   `address` (Logradouro)
    *   `address_number`
    *   `complement` (Opcional)
    *   `province` (Bairro)
    *   `postal_code` (CEP)
*   **Tabela `role_check`**: Usada para verificar as permissões do usuário autenticado. A função requer que o usuário tenha a role `ADMIN` ou `SUPER_ADMIN`.
    *   Campos esperados: `user_id`, `role_name`.
*   **Tabela `asaas_accounts`**: Onde os detalhes da conta Asaas criada são armazenados. Campos incluem:
    *   `profile_id` (FK para o perfil no sistema)
    *   `asaas_id` (ID da conta no Asaas)
    *   `wallet_id` (ID da carteira no Asaas)
    *   `apikey` (API Key da subconta Asaas, criptografada)
    *   `agency` (Agência da conta Asaas)
    *   `account` (Número da conta Asaas)
    *   `account_digit` (Dígito da conta Asaas)
    *   `webhook_auth_token` (Token de autenticação para o webhook configurado no Asaas)
    *   `created_at`, `updated_at`

## 3. Endpoint

*   **Método HTTP**: `POST`
*   **Path Padrão da Edge Function**: `/functions/v1/Asaas/account_create` (o path exato pode variar conforme a configuração do projeto).

## 4. Requisição

### 4.1. Cabeçalhos (Headers)

*   `Authorization: Bearer <supabase_user_jwt_token>`: Token JWT do usuário Supabase para autenticação.
*   `Content-Type: application/json`: Indica que o corpo da requisição é JSON.

### 4.2. Corpo (Body - JSON)

```json
{
  "profile_id": "string (UUID do perfil a ser usado)",
  "profile_type": "string (e.g., 'INDIVIDUAL' ou 'ORGANIZATION')"
}
```

## 5. Fluxo de Processamento Principal

1.  **Carregamento de Configuração Inicial**:
    *   Tenta carregar variáveis de ambiente de um arquivo `.env` (se em desenvolvimento local).
    *   Inicializa o cliente Supabase usando `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY`.
    *   Busca `ASAAS_MASTER_ACCESS_TOKEN` e `ENCRYPTION_SECRET` do Supabase Vault via RPC `get_key`.
2.  **Autenticação e Autorização**:
    *   Extrai o token JWT do cabeçalho `Authorization`.
    *   Verifica a validade do token e obtém os dados do usuário (`supabase.auth.getUser(token)`).
    *   Consulta a tabela `role_check` para garantir que o `user_id` autenticado possui a role `ADMIN` ou `SUPER_ADMIN`.
3.  **Validação da Requisição de Entrada**:
    *   Analisa o corpo da requisição JSON (`await req.json()`).
    *   Verifica se `profile_id` e `profile_type` foram fornecidos.
4.  **Busca de Dados do Perfil**:
    *   Consulta a view `view_admin_profile_approval` no Supabase, filtrando pelo `profile_id` fornecido.
5.  **Geração de Token de Webhook**:
    *   Chama a função `generateWebhookToken()` para criar um token aleatório de 14 caracteres.
6.  **Construção do Payload para a API do Asaas**:
    *   Seleciona o perfil apropriado (prioriza `ORGANIZATION` se múltiplos perfis forem retornados).
    *   Mapeia os campos da `view_admin_profile_approval` para a estrutura de payload esperada pela API de criação de contas do Asaas (`POST https://api-sandbox.asaas.com/v3/accounts`). Campos mapeados incluem:
        *   `name`, `email`, `cpfCnpj`, `mobilePhone`, `incomeValue`, `address`, `addressNumber`, `complement`, `province`, `postalCode`.
        *   `companyType` (se `ORGANIZATION`) ou `birthDate` (se `INDIVIDUAL`).
    *   Adiciona configurações de webhook ao payload, incluindo:
        *   Webhook para eventos de `ACCOUNT_STATUS` configurado para `Asaas/webhook_account_status`.
        *   Webhook para eventos de `TRANSFER_STATUS` configurado para `Asaas/webhook_transfer_status`.
        *   Ambos os webhooks utilizam o mesmo `webhookToken` gerado.
    *   A função `removeEmptyFields()` é usada para limpar o payload de campos nulos ou vazios.
7.  **Chamada à API do Asaas**:
    *   Envia uma requisição `POST` para `https://api-sandbox.asaas.com/v3/accounts` (endpoint de sandbox do Asaas) com o payload construído.
    *   Utiliza o `ASAAS_MASTER_ACCESS_TOKEN` no cabeçalho `access_token`.
8.  **Criptografia da API Key da Subconta**:
    *   Após a criação bem-sucedida da conta no Asaas, a `apiKey` retornada na resposta é criptografada usando a função `encryptApiKey()` (AES-GCM com PBKDF2, utilizando o `ENCRYPTION_SECRET` do Vault e o `PBKDF2_SALT_STRING` fixo).
9.  **Armazenamento no Banco de Dados Supabase**:
    *   Insere um novo registro na tabela `asaas_accounts` contendo:
        *   `profile_id` original.
        *   `asaas_id` (ID da conta Asaas).
        *   `wallet_id` (ID da carteira Asaas).
        *   `apikey` (a API Key criptografada).
        *   Detalhes da conta bancária Asaas (`agency`, `account`, `account_digit`).
        *   `webhook_auth_token`.
10. **Resposta ao Cliente**:
    *   Retorna uma resposta JSON ao cliente que originou a requisição.
    *   Em caso de sucesso (HTTP 200), a resposta inclui `success: true`, uma mensagem e dados da conta criada (como `asaas_account_id`, `wallet_id`, `webhook_auth_token`, `profile_id`, `profile_type`, `status`, `webhook_url` e os detalhes da conta no banco de dados).
    *   Em caso de erro, retorna um status HTTP apropriado (e.g., 400, 401, 403, 404, 500) com `success: false` e detalhes do erro.
    *   Todas as respostas incluem cabeçalhos CORS apropriados: `Access-Control-Allow-Origin: *` e `Access-Control-Allow-Headers: authorization, x-client-info, apikey, content-type`.

## 6. Funções Auxiliares Internas

*   `removeEmptyFields(obj)`: Remove chaves de um objeto se seus valores forem `null`, `undefined` ou string vazia.
*   `generateWebhookToken()`: Gera uma string aleatória de 14 caracteres hexadecimais.
*   `arrayBufferToBase64(buffer)`: Converte um `ArrayBuffer` para uma string Base64.
*   `encryptApiKey(apiKey, masterSecret)`: Criptografa a `apiKey` fornecida usando AES-GCM. Deriva uma chave de criptografia do `masterSecret` e `PBKDF2_SALT_STRING` usando PBKDF2. O resultado é `IV + ciphertext` codificado em Base64.

## 6.1. Sistema de Logging

A função utiliza um sistema de logging estruturado para facilitar o monitoramento e depuração:

* Logger inicializado com o nome `AsaasAccountCreate`
* Configuração para salvar logs em arquivos no diretório `./logs` quando executando localmente
* Nível mínimo de log definido como `INFO`
* Logs detalhados para cada etapa do processo, incluindo:
  * Inicialização da função
  * Autenticação e autorização
  * Validação e processamento do payload
  * Comunicação com a API Asaas
  * Criptografia de dados sensíveis
  * Operações de banco de dados
  * Erros e exceções (com IDs únicos gerados para erros críticos)

## 7. Tratamento de Erros

A função inclui tratamento para diversos cenários de erro, retornando respostas JSON com status HTTP apropriados:

*   **500 Internal Server Error**: Para falhas ao carregar configurações do Vault, erros inesperados no processamento, falhas ao salvar no banco de dados, ou erros na comunicação com a API Asaas.
*   **401 Unauthorized**: Se o token de autenticação não for fornecido ou for inválido.
*   **403 Forbidden**: Se o usuário autenticado não possuir a role `ADMIN` ou `SUPER_ADMIN`.
*   **400 Bad Request**: Se `profile_id` ou `profile_type` não forem fornecidos no corpo da requisição, ou se a API do Asaas retornar um erro de validação (como campos ausentes no payload).
*   **404 Not Found**: Se o `profile_id` não for encontrado na `view_admin_profile_approval`.

## 8. Considerações de Segurança

*   **Autenticação e Autorização**: A função é protegida e só pode ser executada por usuários autenticados com roles específicas (`ADMIN`, `SUPER_ADMIN`).
*   **Gerenciamento de Segredos**: Segredos sensíveis como o token mestre do Asaas e o segredo de criptografia são gerenciados através do Supabase Vault.
*   **Criptografia da API Key**: A API Key da subconta Asaas é criptografada em repouso no banco de dados Supabase usando um algoritmo forte (AES-GCM com chave derivada por PBKDF2).
*   **Salt PBKDF2**: A segurança da derivação da chave de criptografia depende da unicidade e da não divulgação do `ENCRYPTION_SECRET` e da robustez do `PBKDF2_SALT_STRING` (que, embora não secreto, deve ser único para esta aplicação/propósito).
*   **Webhooks**: Um token de autenticação (`webhook_auth_token`) é gerado e deve ser usado para validar as requisições de webhook recebidas do Asaas na função `webhook-contas`.
*   **Comunicação**: Todas as comunicações com o Supabase e Asaas são feitas sobre HTTPS.

Este documento deve fornecer uma compreensão abrangente da função `asaas_account_create`. Mantenha-o atualizado caso haja modificações na lógica ou nas dependências da função.
