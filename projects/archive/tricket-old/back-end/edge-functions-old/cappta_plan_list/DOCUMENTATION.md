# Edge Function: `plan_list`

## Descrição

Esta Edge Function é responsável por listar os planos de taxas disponíveis na Cappta, com suporte a filtros e paginação. A função age como um proxy para a API da Cappta, permitindo a consulta de planos disponíveis para o revendedor.

## URL do Endpoint
```
GET /functions/v1/Cappta/Planos/plan_list
```

## Headers obrigatórios
- `Authorization`: Token Bearer JWT válido de um usuário autenticado

## Parâmetros de Query
- `pageId` (obrigatório): Número da página para paginação (começa em 1)
- `totalPage` (opcional): Número de itens por página, padrão é 10
- `type` (opcional): Filtro por tipo de plano ('Scheme', 'Partner', 'Reseller', 'Merchant')
- `product` (opcional): Filtro por produto (ex: 'POS')
- `name` (opcional): Filtro por nome do plano
- `withFees` (opcional): Se deve incluir as taxas detalhadas (true/false)
- `resellerDocument` (opcional): Documento do revendedor para filtrar planos específicos

## Resposta de Sucesso
```json
{
  "plans": [
    {
      "id": "c1de2a2c-2d6e-46ce-9e07-24839a99c3b7",
      "name": "Meu Plano de Taxas",
      "product": "POS",
      "type": "Merchant",
      "basePlanId": "a5e7f9b2-3c5d-46a8-9f12-b8c2d6e5f4g3",
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
        }
      ]
    },
    // ... outros planos
  ],
  "actualPage": 1,
  "lastPage": 3
}
```

### Campos da Resposta
- `plans`: (array) Lista de planos
  - `id`: (string) ID do plano
  - `name`: (string) Nome do plano
  - `product`: (string) Produto associado ao plano
  - `type`: (string) Tipo do plano
  - `basePlanId`: (string) ID do plano base
  - `settlementDays`: (number) Dias para liquidação
  - `schemes`: (array) Lista de arranjos de pagamento com suas taxas (presente apenas se withFees=true)
- `actualPage`: (number) Página atual
- `lastPage`: (number) Última página disponível

## Respostas de Erro

### Erro de Autenticação (401)
```json
{
  "error": "Não autenticado",
  "details": "Detalhes do erro"
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
2. Obtenção das chaves da Cappta do Vault
3. Extração e validação dos parâmetros de query
4. Construção da URL de consulta para a API da Cappta
5. Chamada à API da Cappta para listar os planos
6. Retorno da lista de planos para o cliente

## Segurança
- Requer autenticação com token JWT válido
- Utiliza chaves de API armazenadas no Vault
- Registra logs detalhados de todas as operações

## Dependências
- Supabase Auth para autenticação
- Supabase Vault para gerenciamento de chaves sensíveis
- API da Cappta para listagem de planos

## Observações
- A resposta inclui informações de paginação que devem ser utilizadas para navegar entre páginas
- Para obter as taxas detalhadas, use o parâmetro `withFees=true`
- Os resultados são paginados, então pode ser necessário fazer múltiplas chamadas para obter todos os planos
- Para consultar informações detalhadas de um plano específico, use o endpoint `plan_details` com o ID do plano
