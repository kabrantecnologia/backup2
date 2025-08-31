# Edge Function: `cappta_webhook_manager`

## Descrição

Esta função centraliza o gerenciamento de webhooks com a API da Cappta. Ela permite registrar, consultar e inativar webhooks para o revendedor configurado no ambiente, sem a necessidade de expor múltiplos endpoints ou passar o documento do revendedor em cada requisição.

## URL do Endpoint
`POST /functions/v1/cappta_webhook_manager`

## Headers Obrigatórios
-   `Authorization`: Token `Bearer` JWT válido de um usuário com permissão `ADMIN`.
-   `Content-Type`: `application/json`

## Payload da Requisição

O corpo da requisição deve conter a ação a ser executada e o tipo de webhook a ser gerenciado.

```json
{
  "action": "register",
  "type": "merchantAccreditation"
}
```

### Campos do Payload
-   `action` (string, **obrigatório**): A operação a ser realizada. Valores possíveis:
    -   `register`: Cadastra o webhook na Cappta. A URL de destino é gerada automaticamente pela função.
    -   `query`: Consulta o status do webhook na Cappta.
    -   `inactivate`: Inativa o webhook na Cappta.
-   `type` (string, **obrigatório**): O tipo de evento do webhook. Valores possíveis:
    -   `merchantAccreditation`: Notificações sobre credenciamento de lojistas.
    -   `transaction`: Notificações sobre transações.

## Respostas

### Resposta de Sucesso (200 OK)

O corpo da resposta conterá os dados retornados pela API da Cappta para a ação solicitada.

```json
{
  "data": { /* Dados da API da Cappta */ },
  "message": "Ação 'register' executada com sucesso."
}
```

### Respostas de Erro
-   **400 Bad Request**: Se os campos `action` ou `type` forem inválidos ou estiverem ausentes.
-   **401 Unauthorized**: Se o token de autenticação for inválido.
-   **403 Forbidden**: Se o usuário autenticado não tiver o papel `ADMIN`.
-   **500 Internal Server Error**: Em caso de falha na comunicação com a API da Cappta ou outro erro inesperado.
