# Edge Function: `plan_create`

## Descrição

Esta Edge Function é responsável por criar um novo plano de taxas na Cappta. Ela interage com a API da Cappta e armazena as informações do plano no banco de dados do Tricket.

## URL do Endpoint
```
POST /functions/v1/Cappta/Planos/plan_create
```

## Headers obrigatórios
- `Authorization`: Token Bearer JWT válido de um usuário com permissão ADMIN ou SUPER_ADMIN

## Payload da Requisição
```json
{
  "Name": "Meu Plano de Taxas",
  "product": "POS",
  "type": "Merchant",
  "basePlanId": "c1de2a2c-2d6e-46ce-9e07-24839a99c3b7",
  "settlementDays": 1,
  "schemes": [
    {
      "id": "62824ffc-cccf-4cef-a864-8adb7d191c52",
      "fees": [
        {
          "installments": 1,
          "rate": 1.90
        },
        {
          "installments": 2,
          "rate": 2.60
        }
      ]
    },
    {
      "id": "a25f7f06-1a0e-431b-9080-b4b4ca98b29f",
      "fees": [
        {
          "installments": 1,
          "rate": 2.50
        }
      ]
    }
  ]
}
```

### Campos do Payload
- `Name`: (string, obrigatório) Nome do plano
- `product`: (string, obrigatório) Produto associado ao plano (geralmente "POS")
- `type`: (string, obrigatório) Tipo do plano (ex: "Merchant", "Reseller")
- `basePlanId`: (string, obrigatório) ID do plano base
- `settlementDays`: (number, obrigatório) Dias para liquidação
- `schemes`: (array, obrigatório) Lista de arranjos de pagamento com suas taxas
  - `id`: (string, obrigatório) ID do arranjo de pagamento (bandeira/tipo)
  - `fees`: (array, obrigatório) Lista de taxas por parcela
    - `installments`: (number, obrigatório) Número de parcelas
    - `rate`: (number, obrigatório) Taxa em decimal (ex: 1.90 = 1.90%)

## Resposta de Sucesso
```json
{
  "id": "c1de2a2c-2d6e-46ce-9e07-24839a99c3b7"
}
```

### Campos da Resposta
- `id`: (string) ID do plano criado na Cappta

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
  "details": "Detalhes do erro de validação"
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
5. Chamada à API da Cappta para criar o plano
6. Armazenamento do plano criado no banco de dados
7. Retorno do ID do plano criado

## Segurança
- Requer autenticação com token JWT válido
- Requer permissão de ADMIN ou SUPER_ADMIN
- Utiliza chaves de API armazenadas no Vault
- Registra logs detalhados de todas as operações

## Dependências
- Supabase Auth para autenticação e autorização
- Supabase Database para armazenamento de dados
- Supabase Vault para gerenciamento de chaves sensíveis
- API da Cappta para criação de planos

## Observações
- É importante fornecer todas as taxas necessárias para cada arranjo de pagamento
- O tipo e o produto do plano não podem ser alterados após a criação
- O ID do plano base deve ser obtido previamente através da listagem de planos disponíveis
