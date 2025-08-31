# Edge Function: `plan_disassociate`

## Descrição

Esta Edge Function é responsável por desassociar um plano de taxas de um lojista na Cappta. Remove o vínculo existente entre um plano específico e um lojista, deixando o lojista sem um plano de taxas associado.

## URL do Endpoint
```
PATCH /functions/v1/Cappta/Planos/plan_disassociate/{planId}
```

## Headers obrigatórios
- `Authorization`: Token Bearer JWT válido de um usuário com permissão ADMIN ou SUPER_ADMIN

## Parâmetros de Rota
- `planId` (obrigatório): ID do plano a ser desassociado do lojista

## Payload da Requisição
```json
{
  "resellerDocument": "12345678000123",
  "merchantDocument": "98765432000198"
}
```

### Campos do Payload
- `resellerDocument`: (string, obrigatório) Documento (CNPJ) do revendedor responsável pelo plano
- `merchantDocument`: (string, obrigatório) Documento (CNPJ/CPF) do lojista do qual o plano será desassociado

## Resposta de Sucesso
```json
{
  "message": "Plano desassociado com sucesso"
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
5. Validação dos dados do payload (resellerDocument e merchantDocument)
6. Chamada à API da Cappta para desassociar o plano do lojista
7. Registro da desassociação no banco de dados do Tricket
8. Retorno da confirmação de desassociação

## Segurança
- Requer autenticação com token JWT válido
- Requer permissão de ADMIN ou SUPER_ADMIN
- Utiliza chaves de API armazenadas no Vault
- Registra logs detalhados de todas as operações

## Dependências
- Supabase Auth para autenticação e autorização
- Supabase Database para armazenamento de dados
- Supabase Vault para gerenciamento de chaves sensíveis
- API da Cappta para desassociação de planos

## Observações
- É importante verificar se o lojista possui o plano associado antes de tentar desassociar
- A desassociação deixará o lojista sem um plano de taxas, o que pode impactar suas transações
- O registro da desassociação é importante para fins de auditoria e histórico de alterações
- Após a desassociação, o lojista precisará ter um novo plano associado para processar transações
- Esta operação não exclui o plano da Cappta, apenas remove o vínculo com o lojista específico
