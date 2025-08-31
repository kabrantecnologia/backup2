# Edge Function: `plan_update`

## Descrição

Esta Edge Function é responsável por atualizar um plano de taxas existente na Cappta. Permite modificar o nome do plano e as taxas por bandeira e parcelas, mantendo o registro atualizado no banco de dados do Tricket.

## URL do Endpoint
```
PUT /functions/v1/Cappta/Planos/plan_update/{planId}
```

## Headers obrigatórios
- `Authorization`: Token Bearer JWT válido de um usuário com permissão ADMIN ou SUPER_ADMIN

## Parâmetros de Rota
- `planId` (obrigatório): ID do plano a ser atualizado

## Payload da Requisição
```json
{
  "name": "Meu Plano de Taxas Atualizado",
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
          "rate": 1.95
        },
        {
          "installments": 2,
          "rate": 2.65
        }
      ]
    },
    {
      "id": "a25f7f06-1a0e-431b-9080-b4b4ca98b29f",
      "fees": [
        {
          "installments": 1,
          "rate": 2.55
        }
      ]
    }
  ]
}
```

### Campos do Payload
- `name`: (string, obrigatório) Nome do plano
- `product`: (string, obrigatório) Produto associado ao plano (geralmente "POS")
- `type`: (string, obrigatório) Tipo do plano (ex: "Merchant", "Reseller")
- `basePlanId`: (string, obrigatório) ID do plano base
- `settlementDays`: (number, obrigatório) Dias para liquidação
- `schemes`: (array, obrigatório) Lista de arranjos de pagamento com suas taxas
  - `id`: (string, obrigatório) ID do arranjo de pagamento (bandeira/tipo)
  - `fees`: (array, obrigatório) Lista de taxas por parcela
    - `installments`: (number, obrigatório) Número de parcelas
    - `rate`: (number, obrigatório) Taxa em decimal (ex: 1.95 = 1.95%)

## Resposta de Sucesso
```json
{
  "message": "Plano atualizado com sucesso"
}
```

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

### Erro de Parâmetros (400)
```json
{
  "error": "ID do plano não especificado"
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
4. Extração do ID do plano a partir da URL
5. Validação dos dados do payload
6. Chamada à API da Cappta para atualizar o plano
7. Atualização do plano no banco de dados
8. Retorno da confirmação de atualização

## Segurança
- Requer autenticação com token JWT válido
- Requer permissão de ADMIN ou SUPER_ADMIN
- Utiliza chaves de API armazenadas no Vault
- Registra logs detalhados de todas as operações

## Dependências
- Supabase Auth para autenticação e autorização
- Supabase Database para armazenamento de dados
- Supabase Vault para gerenciamento de chaves sensíveis
- API da Cappta para atualização de planos

## Observações
- É necessário enviar todos os campos obrigatórios, mesmo aqueles que não serão alterados
- Apenas o nome do plano e as taxas podem ser alterados efetivamente
- O tipo, produto e plano base não podem ser alterados, embora devam ser enviados
- Esta operação substitui todas as taxas existentes, então é necessário enviar a lista completa atualizada
- É necessário fornecer o ID correto do plano, que pode ser obtido através do endpoint `plan_list`
