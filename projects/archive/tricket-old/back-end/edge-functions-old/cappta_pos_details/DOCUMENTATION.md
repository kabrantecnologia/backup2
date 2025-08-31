# Edge Function: `pos_details`

## Descrição

Esta Edge Function é responsável por obter os detalhes de um dispositivo POS (Point of Sale) específico da Cappta a partir do seu ID. Permite consultar informações completas sobre um terminal de pagamento, incluindo seu status, documentos associados e dados técnicos.

## URL do Endpoint
```
GET /functions/v1/Cappta/POS/pos_details/{posId}
```

## Headers obrigatórios
- `Authorization`: Token Bearer JWT válido de um usuário autenticado

## Parâmetros de Rota
- `posId` (obrigatório): ID do dispositivo POS a ser consultado

## Resposta de Sucesso
```json
{
  "id": 52221,
  "resellerDocument": "12345678901234",
  "modelId": 3,
  "serialKey": "1C123457",
  "status": 1,
  "statusDescription": "Available",
  "merchantDocument": null
}
```

### Campos da Resposta
- `id`: (number) ID do dispositivo POS na Cappta
- `resellerDocument`: (string) Documento do revendedor associado ao POS
- `modelId`: (number) ID do modelo do dispositivo POS
- `serialKey`: (string) Chave serial do dispositivo POS
- `status`: (number) Status do dispositivo (1=Available, 2=Associated)
- `statusDescription`: (string) Descrição textual do status
- `merchantDocument`: (string|null) Documento do lojista ao qual o POS está vinculado, ou null se não estiver vinculado

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
  "error": "ID do dispositivo POS não especificado"
}
```

### POS Não Encontrado (variável, geralmente 404)
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
3. Extração do ID do POS a partir da URL
4. Validação do ID do POS
5. Chamada à API da Cappta para obter os detalhes do POS
6. Atualização ou inserção dos dados do POS no banco de dados local
7. Retorno dos detalhes do POS para o cliente

## Segurança
- Requer autenticação com token JWT válido
- Utiliza chaves de API armazenadas no Vault
- Registra logs detalhados de todas as operações

## Dependências
- Supabase Auth para autenticação
- Supabase Database para armazenamento de dados
- Supabase Vault para gerenciamento de chaves sensíveis
- API da Cappta para consulta de detalhes de dispositivos POS

## Observações
- Esta função retorna os detalhes de um único dispositivo POS específico
- O ID do dispositivo deve ser especificado na URL como um parâmetro de caminho
- A função sincroniza automaticamente os dados retornados com o banco de dados local
- Útil para verificar o status atual de um dispositivo antes de realizar operações como vinculação ou exclusão
