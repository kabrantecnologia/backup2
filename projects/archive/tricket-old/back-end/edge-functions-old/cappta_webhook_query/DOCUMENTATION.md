# Edge Function: webhook_query

## Visão Geral
Esta Edge Function permite consultar webhooks registrados para integrações com a Cappta. A função verifica a autenticação do usuário, processa parâmetros de filtro e retorna os webhooks configurados em formato compatível com a API da Cappta.

## Pré-requisitos
- Configuração do Supabase URL e Service Role Key
- Acesso ao Vault do Supabase com as chaves:
  - `CAPPTA_API_KEY`: Chave de API para autenticação com a Cappta
  - `CAPPTA_API_URL`: URL base da API da Cappta
- Tabela `cappta_webhooks` configurada no banco de dados

## Parâmetros de Entrada
A função recebe requisições HTTP GET com:
- Headers:
  - `Authorization`: Bearer token para autenticação do usuário
- Query Parameters:
  - `profile_id` (opcional): Filtrar por ID do perfil
  - `webhook_type` (opcional): Filtrar por tipo de webhook ('MERCHANT_ACCREDITATION' ou 'TRANSACTION')

## Fluxo de Execução
1. **Inicialização e Configuração**:
   - Inicializa o logger
   - Configura o cliente Supabase com a Service Role Key
   - Verifica a disponibilidade das chaves necessárias no vault

2. **Autenticação**:
   - Valida o token de autenticação
   - Verifica se o usuário está autenticado

3. **Processamento de Parâmetros**:
   - Extrai parâmetros de consulta da URL
   - Constrói a consulta ao banco de dados com base nos filtros fornecidos

4. **Recuperação de Dados**:
   - Executa a consulta na tabela `cappta_webhooks`
   - Formata os resultados para compatibilidade com a API da Cappta

5. **Resposta**:
   - Retorna uma lista de webhooks no formato esperado
   - Em caso de erro, retorna o código de status apropriado com detalhes

## Tratamento de Erros
- **Status 401**: Usuário não autenticado
- **Status 500**: Erros internos ou falhas de comunicação com o banco/vault

## Formato de Resposta
A resposta segue o formato da API da Cappta para manter compatibilidade:

```json
{
  "error": false,
  "data": [
    {
      "id": "uuid",
      "profile_id": "uuid",
      "url": "https://webhook.endpoint.url",
      "status": 1,  // 1 para ativo, 0 para inativo
      "created_at": "timestamp",
      "updated_at": "timestamp",
      "type": "merchantAccreditation"  // ou "transaction"
    }
  ]
}
```

## Considerações de Segurança
- A autenticação do usuário é verificada antes de fornecer acesso aos dados
- Apenas os dados relevantes são retornados, sem expor tokens de webhooks
- Todas as ações são registradas em log para auditoria e depuração

## Integração com Outros Componentes
- Esta função é utilizada para verificar configurações de webhook antes de registrar ou inativar webhooks
- Pode ser chamada por interfaces administrativas para gerenciar integrações
