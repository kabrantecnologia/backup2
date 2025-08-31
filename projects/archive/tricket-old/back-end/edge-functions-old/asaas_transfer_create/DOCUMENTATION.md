# Documentação: Supabase Edge Function - `Asaas/transfer_create`

## 1. Visão Geral

A função `transfer_create` é uma Supabase Edge Function projetada para iniciar transferências financeiras entre contas de clientes na plataforma Asaas. Esta função autentica o usuário, valida os parâmetros da transferência, descriptografa a API Key da conta pagadora e cria a transferência na API Asaas.

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
*   `ENCRYPTION_SECRET`: Um segredo forte usado como base para derivar a chave de descriptografia para as API Keys criptografadas das subcontas Asaas.

### 2.3. Constantes Internas da Função

*   `PBKDF2_SALT_STRING`: Salt fixo usado com PBKDF2 para derivar a chave de descriptografia. **Crucial que seja o mesmo utilizado na criptografia**.
*   `PBKDF2_ITERATIONS`: Número de iterações para PBKDF2 (atualmente `100000`).
*   `ENCRYPTION_ALGORITHM`: Algoritmo de criptografia (atualmente `"AES-GCM"`).
*   `KEY_LENGTH`: Tamanho da chave AES em bits (atualmente `256`).
*   `IV_LENGTH`: Tamanho do Vetor de Inicialização em bytes (atualmente `12`).

### 2.4. Dependências de Banco de Dados Supabase

*   **Tabela `asaas_accounts`**: Contém as contas Asaas registradas e suas API Keys criptografadas.
    *   Campos utilizados: `asaas_id`, `apikey`, `profile_id`.

*   **Tabela `role_check`**: Usada para verificar as permissões do usuário autenticado.
    *   Campos esperados: `user_id`, `role_name`.

*   **Tabela `asaas_transfers`**: Armazena os registros das transferências realizadas.
    *   Campos incluem:
        *   `payer_profile_id` (ID do perfil do pagador)
        *   `receiver_profile_id` (ID do perfil do recebedor)
        *   `transfer_id` (ID da transferência no Asaas)
        *   `value` (valor da transferência)
        *   `description` (descrição opcional)
        *   `status` (status da transferência)
        *   `created_at`, `updated_at` (timestamps)

## 3. Endpoint

*   **Método HTTP**: `POST`
*   **Path Padrão da Edge Function**: `/functions/v1/Asaas/transfer_create`

## 4. Requisição

### 4.1. Cabeçalhos (Headers)

*   `Authorization: Bearer <supabase_user_jwt_token>`: Token JWT do usuário Supabase para autenticação.
*   `Content-Type: application/json`: Indica que o corpo da requisição é JSON.

### 4.2. Corpo (Body - JSON)

```json
{
  "value": number (valor da transferência),
  "payerProfileId": "string (UUID do perfil do pagador)",
  "receiverProfileId": "string (UUID do perfil do recebedor)",
  "description": "string (descrição opcional da transferência)"
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
    *   Obtém chaves adicionais do Vault, incluindo `ENCRYPTION_SECRET`.

4.  **Autenticação e Autorização**:
    *   Extrai o token JWT do cabeçalho `Authorization`.
    *   Verifica a validade do token e obtém os dados do usuário.
    *   Consulta a tabela `role_check` para garantir que o usuário tem permissão (deve ter role `ADMIN` ou `SUPER_ADMIN`).

5.  **Processamento do Payload**:
    *   Analisa o corpo JSON da requisição.
    *   Valida campos obrigatórios (`value`, `payerProfileId`, `receiverProfileId`).
    *   Verifica se o valor da transferência é positivo e maior que zero.

6.  **Busca e Validação das Contas Asaas**:
    *   Consulta a tabela `asaas_accounts` para obter dados das contas do pagador e do recebedor.
    *   Descriptografa a API Key da conta do pagador usando AES-GCM com a função `decryptApiKey()`.
    *   Verifica se a conta do pagador tem saldo disponível.

7.  **Criação da Transferência na API do Asaas**:
    *   Constrói o payload para a API de transferência do Asaas.
    *   Envia requisição `POST` para o endpoint de transferências do Asaas usando a API Key do pagador.
    *   Processa e valida a resposta da API Asaas.

8.  **Registro da Transferência no Banco de Dados**:
    *   Insere um novo registro na tabela `asaas_transfers` com os detalhes da transferência criada.

9.  **Resposta**:
    *   Retorna HTTP 200 com detalhes da transferência criada em caso de sucesso.
    *   Em caso de erro, retorna um status HTTP apropriado com detalhes do erro.

## 6. Sistema de Logging

A função utiliza um sistema de logging estruturado para facilitar o monitoramento e depuração:

* Logger inicializado com o nome `AsaasTransferCreate`
* Logs detalhados para cada etapa do processo, incluindo:
  * Inicialização da função
  * Autenticação e autorização
  * Comunicação com a API Asaas
  * Operações de banco de dados
  * IDs de erro exclusivos para erros críticos

## 7. Tratamento de Erros

A função inclui tratamento para diversos cenários de erro, retornando respostas JSON com status HTTP apropriados:

*   **405 Method Not Allowed**: Se o método HTTP não for POST.
*   **500 Internal Server Error**: Para falhas ao carregar configurações, erros inesperados ou falhas na comunicação com a API Asaas.
*   **401 Unauthorized**: Token de autenticação ausente ou inválido.
*   **403 Forbidden**: Usuário sem permissões adequadas.
*   **400 Bad Request**: Payload inválido ou parâmetros incorretos.
*   **404 Not Found**: Contas Asaas não encontradas para um ou ambos os perfis.

## 8. Funções Auxiliares

*   `decryptApiKey(encryptedBase64ApiKey, masterSecret)`: Descriptografa a API Key armazenada no banco de dados usando AES-GCM. Deriva uma chave de criptografia do `masterSecret` e `PBKDF2_SALT_STRING` usando PBKDF2.
*   `removeEmptyFields(obj)`: Remove chaves com valores nulos ou vazios de um objeto.
*   `generateErrorId()`: Gera um ID único para identificação de erros críticos nos logs.

## 9. Considerações de Segurança

*   **Autenticação e Autorização**: A função é protegida por autenticação JWT e verificação de roles.
*   **Criptografia de Chave**: A API Key do Asaas é armazenada criptografada e descriptografada apenas durante o uso.
*   **Validação de Parâmetros**: Todos os parâmetros da transferência são validados antes de qualquer operação.
*   **Comunicação Segura**: Todas as comunicações com o Supabase e Asaas são realizadas sobre HTTPS.

## 10. Dependências Externas

*   **Módulos de `_shared`**:
    *   `vault.ts`: Para acessar secrets armazenados no Vault do Supabase.
    *   `env.ts`: Para obter variáveis de ambiente necessárias.

Este documento deve fornecer uma compreensão abrangente da função `transfer_create`. Mantenha-o atualizado caso haja modificações na lógica ou nas dependências da função.
