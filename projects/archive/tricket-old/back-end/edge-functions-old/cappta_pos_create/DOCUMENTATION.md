# Edge Function: `pos_create`

## Descrição

Esta Edge Function é responsável por cadastrar um novo dispositivo POS (Point of Sale) na Cappta. Permite registrar um terminal de pagamento com suas informações essenciais como código serial, modelo e revendedor associado.

## URL do Endpoint
```
POST /functions/v1/Cappta/POS/pos_create
```

## Headers obrigatórios
- `Authorization`: Token Bearer JWT válido de um usuário com permissão ADMIN ou SUPER_ADMIN
- `Content-Type`: application/json

## Payload da Requisição
```json
{
  "resellerDocument": "12345678901234",
  "serialKey": "6C123457",
  "modelId": 3,
  "keys": {
    "key1": "value1",
    "key2": "value2"
  }
}
```

### Campos do Payload
- `resellerDocument`: (string, obrigatório) Documento do revendedor associado ao POS (CNPJ)
- `serialKey`: (string, obrigatório) Chave serial do dispositivo POS
- `modelId`: (number, obrigatório) ID do modelo do dispositivo POS
- `keys`: (object, opcional) Chaves adicionais para configuração do dispositivo

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

### Erro de Permissão (403)
```json
{
  "error": "Acesso negado",
  "details": "Você não tem permissão para executar esta ação"
}
```

### Erro de Validação (400)
```json
{
  "error": "Dados inválidos",
  "details": "resellerDocument é obrigatório"
}
```

### Erro na API da Cappta (variável)
```json
{
  "error": "Erro na requisição para API da Cappta",
  "details": { /* Resposta de erro da API da Cappta */ }
}
```

### Erro Interno (500)
```json
{
  "error": "Erro interno",
  "details": "Detalhes do erro interno"
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
