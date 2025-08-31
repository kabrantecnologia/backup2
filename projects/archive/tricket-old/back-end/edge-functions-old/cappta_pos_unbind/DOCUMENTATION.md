# Edge Function: `pos_unbind`

## Descrição

Esta Edge Function é responsável por desvincular um dispositivo POS (Point of Sale) de um lojista na Cappta. Esta operação remove a associação entre um terminal de pagamento e um estabelecimento comercial, deixando o dispositivo disponível para ser vinculado a outro lojista.

## URL do Endpoint
```
PATCH /functions/v1/Cappta/POS/pos_unbind/{posId}/unbind
```

## Headers obrigatórios
- `Authorization`: Token Bearer JWT válido de um usuário com permissão ADMIN ou SUPER_ADMIN

## Parâmetros de Rota
- `posId` (obrigatório): ID do dispositivo POS a ser desvinculado do lojista

## Resposta de Sucesso
```json
{
  "message": "POS desvinculado com sucesso"
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
5. Busca de informações do dispositivo no banco de dados para registro histórico
6. Chamada à API da Cappta para desvincular o POS do lojista
7. Atualização do registro do POS no banco de dados
8. Registro do histórico de desvinculação
9. Retorno da confirmação de desvinculação

## Segurança
- Requer autenticação com token JWT válido
- Requer permissão de ADMIN ou SUPER_ADMIN
- Utiliza chaves de API armazenadas no Vault
- Registra logs detalhados de todas as operações

## Dependências
- Supabase Auth para autenticação e autorização
- Supabase Database para armazenamento de dados
- Supabase Vault para gerenciamento de chaves sensíveis
- API da Cappta para desvinculação de dispositivos POS

## Observações
- O dispositivo POS deve estar com status "Associated" (vinculado) para poder ser desvinculado
- Após a desvinculação, o dispositivo fica com status "Available" e pode ser vinculado a outro lojista
- É importante manter o histórico de desvinculações para auditoria e rastreabilidade
- O token de vinculação anterior é invalidado após a desvinculação
- A desvinculação interrompe a capacidade do dispositivo de processar transações para o lojista anterior
- Em casos de manutenção ou transferência de dispositivos entre lojistas, é necessário realizar esta operação
