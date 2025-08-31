# Edge Function: webhook_deactivate

## Visão Geral
Esta Edge Function permite inativar um webhook previamente registrado para a integração com a Cappta. A função valida as permissões do usuário, verifica se o webhook existe e marca-o como inativo no banco de dados.

## Pré-requisitos
- Configuração do Supabase URL e Service Role Key
- Acesso ao Vault do Supabase com as chaves:
  - `CAPPTA_API_KEY`: Chave de API para autenticação com a Cappta
  - `CAPPTA_API_URL`: URL base da API da Cappta
- Permissão de administrador (ADMIN ou SUPER_ADMIN)
- Tabela `cappta_webhooks` configurada no banco de dados

## Parâmetros de Entrada
A função recebe requisições HTTP POST com:
- Headers:
  - `Authorization`: Bearer token para autenticação do usuário
- Body:
  - `profile_id`: ID do perfil associado ao webhook
  - `webhook_type`: Tipo de webhook a ser inativado ('MERCHANT_ACCREDITATION' ou 'TRANSACTION')

## Fluxo de Execução
1. **Inicialização e Configuração**:
   - Inicializa o logger
   - Configura o cliente Supabase com a Service Role Key
   - Verifica a disponibilidade das chaves necessárias no vault

2. **Autenticação e Autorização**:
   - Valida o token de autenticação
   - Verifica se o usuário tem permissões de ADMIN ou SUPER_ADMIN

3. **Validação de Parâmetros**:
   - Valida o formato e presença dos parâmetros obrigatórios
   - Verifica se o tipo de webhook é válido

4. **Verificação de Existência**:
   - Busca o webhook especificado no banco de dados
   - Verifica se o webhook existe para o perfil e tipo informados

5. **Inativação**:
   - Atualiza o registro na tabela `cappta_webhooks` marcando-o como inativo
   - Registra a data de atualização

6. **Resposta**:
   - Retorna detalhes do webhook inativado em formato compatível com a API da Cappta
   - Em caso de erro, retorna o código de status apropriado com detalhes

## Tratamento de Erros
- **Status 400**: Parâmetros inválidos ou ausentes
- **Status 401**: Usuário não autenticado
- **Status 403**: Usuário sem permissões suficientes
- **Status 404**: Webhook não encontrado para o perfil e tipo especificados
- **Status 500**: Erros internos ou falhas de comunicação com o banco/vault

## Formato de Resposta
A resposta segue o formato da API da Cappta para manter compatibilidade:

```json
{
  "error": false,
  "data": {
    "id": "uuid",
    "profile_id": "uuid",
    "url": "https://webhook.endpoint.url",
    "status": 0,  // Sempre 0 para inativo
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "type": "merchantAccreditation"  // ou "transaction"
  }
}
```

## Considerações de Segurança
- Apenas usuários com permissões administrativas podem inativar webhooks
- Todas as ações são registradas em log para auditoria e depuração
- O webhook é inativado mas não removido, mantendo histórico de configurações

## Integração com Outros Componentes
- Após a inativação, as funções `webhook_merchant_accreditation` e `webhook_transaction` não processarão mais requisições com o token associado
- A integração com a API da Cappta pode precisar ser atualizada para refletir a inativação do webhook
