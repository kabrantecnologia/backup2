# Edge Function: `pos_delete`

## Descrição

Esta Edge Function é responsável por excluir um dispositivo POS (Point of Sale) da Cappta. Esta operação remove permanentemente um terminal de pagamento do sistema, impossibilitando seu uso futuro.

## URL do Endpoint
```
DELETE /functions/v1/Cappta/POS/pos_delete/{posId}
```

## Headers obrigatórios
- `Authorization`: Token Bearer JWT válido de um usuário com permissão ADMIN ou SUPER_ADMIN

## Parâmetros de Rota
- `posId` (obrigatório): ID do dispositivo POS a ser excluído

## Resposta de Sucesso
```json
{
  "message": "POS excluído com sucesso"
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
6. Chamada à API da Cappta para excluir o POS
7. Atualização do registro do POS no banco de dados como excluído
8. Registro do histórico de exclusão
9. Retorno da confirmação de exclusão

## Segurança
- Requer autenticação com token JWT válido
- Requer permissão de ADMIN ou SUPER_ADMIN
- Utiliza chaves de API armazenadas no Vault
- Registra logs detalhados de todas as operações

## Dependências
- Supabase Auth para autenticação e autorização
- Supabase Database para armazenamento de dados
- Supabase Vault para gerenciamento de chaves sensíveis
- API da Cappta para exclusão de dispositivos POS

## Observações
- Esta é uma operação irreversível: uma vez excluído, o dispositivo não pode ser recuperado
- Recomenda-se desvincular o dispositivo de qualquer lojista antes de excluí-lo
- A exclusão deve ser realizada apenas quando o dispositivo está defeituoso ou não será mais utilizado
- É importante manter o histórico de exclusões para auditoria e rastreabilidade
- Se o dispositivo estiver vinculado a um lojista no momento da exclusão, a vinculação será automaticamente removida
- Os registros no banco de dados local são mantidos com marcação de exclusão, não removidos fisicamente
