# Edge Function: webhook_merchant_accreditation

## Visão Geral
Esta Edge Function recebe notificações de webhook da Cappta relacionadas ao credenciamento de lojistas (merchantAccreditation). A função autentica a requisição via token, valida o payload recebido e armazena o evento em uma tabela do banco de dados para processamento assíncrono posterior.

## Pré-requisitos
- Configuração do Supabase URL e Service Role Key
- Token de webhook configurado para a integração com a Cappta
- Tabelas no banco de dados:
  - `cappta_webhooks`: Armazena configurações de webhooks
  - `cappta_webhook_events`: Armazena eventos de webhook recebidos

## Parâmetros de Entrada
O webhook recebe requisições HTTP POST com:
- Headers:
  - `X-Webhook-Token`: Token de autenticação para validar a origem da requisição
- Body:
  - Payload JSON com informações do evento de credenciamento de lojista

## Fluxo de Execução
1. **Inicialização e Configuração**:
   - Inicializa o logger
   - Configura o cliente Supabase com a Service Role Key

2. **Autenticação**:
   - Extrai o token de webhook do cabeçalho `X-Webhook-Token`
   - Verifica se o token existe na tabela `cappta_webhooks` e está ativo para o tipo 'MERCHANT_ACCREDITATION'

3. **Validação e Processamento**:
   - Extrai e valida o payload JSON
   - Registra no log informações sobre o payload recebido

4. **Persistência**:
   - Salva o evento na tabela `cappta_webhook_events` com status 'PENDING'
   - Inclui o `profile_id` associado ao webhook para processamento posterior

5. **Resposta**:
   - Retorna um JSON de confirmação com status 200 em caso de sucesso
   - Em caso de erro, retorna o código de status apropriado com detalhes do erro

## Tratamento de Erros
- **Status 400**: Payload inválido ou malformado
- **Status 401**: Token de autenticação ausente ou inválido
- **Status 500**: Erros internos do servidor ou falhas de comunicação com o banco

## Considerações de Segurança
- O token de webhook é verificado para garantir que apenas requisições autênticas sejam processadas
- Todas as ações são registradas em log para auditoria e depuração
- Nenhum dado sensível é exposto nas respostas

## Integração com Outros Componentes
- O evento armazenado no banco será processado posteriormente por um processador dedicado
- Os dados do evento podem influenciar o estado de credenciamento de um lojista no sistema Tricket
