# Edge Function: `pos_bind`

## Descrição

Esta Edge Function é responsável por vincular um dispositivo POS (Point of Sale) a um lojista na Cappta. Esta operação associa um terminal de pagamento a um estabelecimento comercial específico, permitindo que ele processe transações para este lojista.

## URL do Endpoint
```
PATCH /functions/v1/Cappta/POS/pos_bind/{posId}/bind
```

## Headers obrigatórios
- `Authorization`: Token Bearer JWT válido de um usuário com permissão ADMIN ou SUPER_ADMIN
- `Content-Type`: application/json

## Parâmetros de Rota
- `posId` (obrigatório): ID do dispositivo POS a ser vinculado ao lojista

## Payload da Requisição
```json
{
  "resellerDocument": "12345678901234",
  "merchantDocument": "98765432109876"
}
```

### Campos do Payload
- `resellerDocument`: (string, obrigatório) Documento do revendedor associado ao lojista
- `merchantDocument`: (string, obrigatório) Documento do lojista ao qual o POS será vinculado

## Resposta de Sucesso
```json
{
  "token": "123456789"
}
```

### Campos da Resposta
- `token`: (string) Token gerado para autenticação do POS após a vinculação

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

### Erro de Parâmetros (400)
```json
{
  "error": "ID do dispositivo POS não especificado"
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
4. Extração do ID do POS a partir da URL
5. Validação dos dados do payload
6. Chamada à API da Cappta para vincular o POS ao lojista
7. Atualização do registro do POS no banco de dados
8. Registro do histórico de vinculação
9. Retorno do token gerado

## Segurança
- Requer autenticação com token JWT válido
- Requer permissão de ADMIN ou SUPER_ADMIN
- Utiliza chaves de API armazenadas no Vault
- Registra logs detalhados de todas as operações

## Dependências
- Supabase Auth para autenticação e autorização
- Supabase Database para armazenamento de dados
- Supabase Vault para gerenciamento de chaves sensíveis
- API da Cappta para vinculação de dispositivos POS

## Observações
- O dispositivo POS deve estar com status "Available" (não vinculado) para poder ser vinculado
- O lojista deve estar previamente credenciado na Cappta
- O token retornado deve ser armazenado para possíveis referências futuras
- A vinculação altera o status do dispositivo para "Associated"
- É importante manter o histórico de vinculações para auditoria e rastreabilidade
- O revendedor informado deve ter permissão para vincular o POS ao lojista
