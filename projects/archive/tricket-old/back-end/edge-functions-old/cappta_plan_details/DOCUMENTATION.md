# Edge Function: `plan_details`

## Descrição

Esta Edge Function é responsável por obter os detalhes completos de um plano de taxas específico da Cappta a partir do seu ID. A função consulta a API da Cappta e retorna todas as informações disponíveis sobre o plano, incluindo suas taxas por bandeira e parcelas.

## URL do Endpoint
```
GET /functions/v1/Cappta/Planos/plan_details/{planId}
```

## Headers obrigatórios
- `Authorization`: Token Bearer JWT válido de um usuário autenticado

## Parâmetros de Rota
- `planId` (obrigatório): ID do plano a ser consultado

## Resposta de Sucesso
```json
{
  "id": "c1de2a2c-2d6e-46ce-9e07-24839a99c3b7",
  "partnerDocument": "12345678901234",
  "resellerDocument": "12345678901234",
  "basePlanId": "a5e7f9b2-3c5d-46a8-9f12-b8c2d6e5f4g3",
  "settlementDays": 1,
  "type": "Merchant",
  "product": "POS",
  "name": "Meu Plano de Taxas",
  "schemes": [
    {
      "id": "62824ffc-cccf-4cef-a864-8adb7d191c52",
      "name": "Visa Crédito",
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
      "name": "Mastercard Crédito",
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

### Campos da Resposta
- `id`: (string) ID do plano
- `partnerDocument`: (string) Documento do parceiro associado ao plano
- `resellerDocument`: (string) Documento do revendedor associado ao plano
- `basePlanId`: (string) ID do plano base
- `settlementDays`: (number) Dias para liquidação
- `type`: (string) Tipo do plano
- `product`: (string) Produto associado ao plano
- `name`: (string) Nome do plano
- `schemes`: (array) Lista de arranjos de pagamento com suas taxas
  - `id`: (string) ID do arranjo de pagamento
  - `name`: (string) Nome do arranjo (bandeira/tipo)
  - `fees`: (array) Lista de taxas por parcela
    - `installments`: (number) Número de parcelas
    - `rate`: (number) Taxa em decimal (ex: 1.90 = 1.90%)

## Respostas de Erro

### Erro de Autenticação (401)
```json
{
  "error": "Não autenticado",
  "details": "Detalhes do erro"
}
```

### Erro de Parâmetros (400)
```json
{
  "error": "ID do plano não especificado"
}
```

### Plano Não Encontrado (variável, geralmente 404)
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
3. Extração do ID do plano a partir da URL
4. Validação do ID do plano
5. Chamada à API da Cappta para obter os detalhes do plano
6. Retorno dos detalhes do plano para o cliente

## Segurança
- Requer autenticação com token JWT válido
- Utiliza chaves de API armazenadas no Vault
- Registra logs detalhados de todas as operações

## Dependências
- Supabase Auth para autenticação
- Supabase Vault para gerenciamento de chaves sensíveis
- API da Cappta para consulta de detalhes de planos

## Observações
- Esta função retorna os detalhes completos de um único plano, incluindo todas as taxas por bandeira e parcela
- Necessário fornecer o ID correto do plano, que pode ser obtido através do endpoint `plan_list`
- Os detalhes do plano são úteis para visualização antes de associá-lo a um lojista
- Consulte a documentação da API da Cappta para detalhes sobre os arranjos de pagamento disponíveis
