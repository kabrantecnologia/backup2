# Edge Function: `cappta_pos_create`

## Descrição

Esta Edge Function é responsável por cadastrar um novo dispositivo POS (Point of Sale) na API da Cappta e registrar a associação no banco de dados do sistema. A função é acionada por um usuário autenticado e autorizado.

## URL do Endpoint
`POST /functions/v1/cappta_pos_create`

## Headers Obrigatórios
-   `Authorization`: Token `Bearer` JWT válido de um usuário com permissão `ADMIN` ou `pos_operator`.
-   `Content-Type`: `application/json`

## Payload da Requisição (Formato do Front-end)

O front-end deve enviar os dados com o prefixo `p_`. O campo `resellerDocument` **não** deve ser enviado, pois é obtido de forma segura através das variáveis de ambiente do servidor.

```json
{
  "p_serial_key": "6C123457",
  "p_model_id": 3,
  "p_keys": {
    "chave_exemplo": "valor_exemplo"
  }
}
```

### Campos do Payload
-   `p_serial_key` (string, **obrigatório**): O número de série único do dispositivo POS.
-   `p_model_id` (number, **obrigatório**): O ID do modelo do dispositivo POS.
-   `p_keys` (object, opcional): Um objeto JSON para armazenar quaisquer chaves ou metadados adicionais associados ao dispositivo.

## Resposta de Sucesso
```json
{
  "id": 41085
}
```

### Campos da Resposta
- `id`: (number) ID do dispositivo POS cadastrado na Cappta

## Respostas de Erro

### Erro de Autenticação (401)
```json
{
  "error": "Não autenticado",
  "details": "Detalhes do erro"
}
```

### Resposta de Sucesso (200 OK)

```json
{
  "data": {
    "cappta_pos_id": "algum-uuid-gerado-pela-cappta",
    "p_serial_key": "6C123457",
    "p_model_id": 3,
    "status": "CREATED"
  },
  "message": "Dispositivo POS criado e registrado com sucesso."
}
```

---

## Respostas de Erro

### 400 Bad Request (Payload Inválido)

Ocorre quando campos obrigatórios estão ausentes no corpo da requisição.

```json
{
  "error": "Dados da requisição inválidos.",
  "details": "Campos obrigatórios ausentes: p_serial_key, p_model_id"
}
```

### 401 Unauthorized (Não Autenticado)

Ocorre se o token JWT de autenticação não for fornecido ou for inválido.

```json
{
  "error": "Autenticação necessária.",
  "details": "O token de autenticação é inválido ou está ausente."
}
```

### 403 Forbidden (Sem Permissão)

Ocorre se o usuário autenticado não possuir um dos papéis necessários (`ADMIN` ou `pos_operator`).

```json
{
  "error": "Permissões insuficientes",
  "details": "O usuário não tem permissão para executar esta ação."
}
```

### 500 Internal Server Error

Ocorre em caso de falhas inesperadas, como:
-   Erro de comunicação com a API da Cappta.
-   Falha ao salvar os dados no banco de dados.
-   Variáveis de ambiente essenciais não configuradas.

```json
{
  "error": "Erro Interno do Servidor",
  "details": "Falha na comunicação com a API da Cappta: {mensagem de erro da Cappta}"
}
```


## Fluxo de Execução
1. Validação da autenticação do usuário através do token JWT
2. Verificação se o usuário tem permissão de ADMIN ou SUPER_ADMIN
3. Obtenção das chaves da Cappta do Vault
4. Validação dos dados do payload
5. Chamada à API da Cappta para cadastrar o POS
6. Armazenamento do POS no banco de dados
7. Retorno do ID do POS cadastrado

## Segurança
- Requer autenticação com token JWT válido
- Requer permissão de ADMIN ou SUPER_ADMIN
- Utiliza chaves de API armazenadas no Vault
- Registra logs detalhados de todas as operações

## Dependências
- Supabase Auth para autenticação e autorização
- Supabase Database para armazenamento de dados
- Supabase Vault para gerenciamento de chaves sensíveis
- API da Cappta para cadastro de dispositivos POS

## Observações
- O ID do modelo (`modelId`) deve corresponder a um modelo válido na Cappta
- A chave serial (`serialKey`) deve ser única para cada dispositivo
- O revendedor (`resellerDocument`) deve estar previamente cadastrado na Cappta
- As chaves adicionais (`keys`) são opcionais e dependem do modelo do dispositivo
- O POS recém-cadastrado fica com status "Available" até ser vinculado a um lojista
