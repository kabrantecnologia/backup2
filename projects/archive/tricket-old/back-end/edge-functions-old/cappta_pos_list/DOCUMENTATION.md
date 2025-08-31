# Edge Function: `pos_list`

## Descrição

Esta Edge Function é responsável por listar os dispositivos POS (Point of Sale) cadastrados na Cappta. Permite consultar os terminais de pagamento com filtros por revendedor, lojista, status ou chave serial.

## URL do Endpoint
```
GET /functions/v1/Cappta/POS/pos_list
```

## Headers obrigatórios
- `Authorization`: Token Bearer JWT válido de um usuário autenticado

## Parâmetros de Query
- `resellerDocument`: (string, opcional) Documento do revendedor para filtrar os dispositivos
- `merchantDocument`: (string, opcional) Documento do lojista para filtrar os dispositivos
- `status`: (string, opcional) Status dos dispositivos (Available|Associated)
- `serialKey`: (string, opcional) Chave serial específica de um dispositivo

## Resposta de Sucesso
```json
[
  {
    "id": 123,
    "resellerDocument": "12345678901234",
    "modelId": 3,
    "serialKey": "1C123456",
    "status": 1,
    "statusDescription": "Available",
    "merchantDocument": null
  },
  {
    "id": 1234,
    "resellerDocument": "12345678901234",
    "modelId": 3,
    "serialKey": "1M123456",
    "status": 2,
    "statusDescription": "Associated",
    "merchantDocument": "98765432109876"
  }
]
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
3. Extração dos parâmetros de consulta da URL
4. Chamada à API da Cappta para listar os dispositivos POS
5. Sincronização dos dados recebidos com o banco de dados local
6. Retorno da lista de dispositivos POS para o cliente

## Segurança
- Requer autenticação com token JWT válido
- Utiliza chaves de API armazenadas no Vault
- Registra logs detalhados de todas as operações

## Dependências
- Supabase Auth para autenticação
- Supabase Database para armazenamento de dados
- Supabase Vault para gerenciamento de chaves sensíveis
- API da Cappta para listagem de dispositivos POS

## Observações
- Os filtros são opcionais e podem ser combinados para refinar a busca
- A função sincroniza automaticamente os dados retornados com o banco de dados local
- Os dispositivos com status "Associated" mostram o documento do lojista associado
- Essa função é útil para verificar quais dispositivos estão disponíveis ou já vinculados
- A resposta é um array vazio se nenhum dispositivo corresponder aos filtros aplicados
