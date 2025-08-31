# Edge Function: `plan_associate`

## Descrição

Esta Edge Function é responsável por associar um plano de taxas a um lojista na Cappta. Permite vincular um plano específico a um lojista, definindo assim as taxas que serão aplicadas nas transações deste lojista.

## URL do Endpoint
```
PATCH /functions/v1/Cappta/Planos/plan_associate/{planId}
```

## Headers obrigatórios
- `Authorization`: Token Bearer JWT válido de um usuário com permissão ADMIN ou SUPER_ADMIN

## Parâmetros de Rota
- `planId` (obrigatório): ID do plano a ser associado ao lojista

## Payload da Requisição
```json
{
  "resellerDocument": "12345678000123",
  "merchantDocument": "98765432000198"
}
```

### Campos do Payload
- `resellerDocument`: (string, obrigatório) Documento (CNPJ) do revendedor responsável pelo plano
- `merchantDocument`: (string, obrigatório) Documento (CNPJ/CPF) do lojista ao qual o plano será associado

## Resposta de Sucesso
```json
{
  "id": "f7e8d9c0-b1a2-43c4-95e6-87f9h0i1j2k3"
}
```

### Campos da Resposta
- `id`: (string) ID da associação criada

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
6. Chamada à API da Cappta para associar o plano ao lojista
7. Registro da associação no banco de dados do Tricket
8. Retorno do ID da associação criada

## Segurança
- Requer autenticação com token JWT válido
- Requer permissão de ADMIN ou SUPER_ADMIN
- Utiliza chaves de API armazenadas no Vault
- Registra logs detalhados de todas as operações

## Dependências
- Supabase Auth para autenticação e autorização
- Supabase Database para armazenamento de dados
- Supabase Vault para gerenciamento de chaves sensíveis
- API da Cappta para associação de planos

## Observações
- O lojista deve estar previamente credenciado na Cappta
- O revendedor deve ter permissão para associar planos aos seus lojistas
- Um lojista pode ter apenas um plano associado por vez; associar um novo plano automaticamente sobrescreve o anterior
- O plano deve existir e estar ativo na Cappta
- É importante registrar esta associação para fins de auditoria e histórico de alterações
- O ID da associação retornado deve ser armazenado para possível referência futura
