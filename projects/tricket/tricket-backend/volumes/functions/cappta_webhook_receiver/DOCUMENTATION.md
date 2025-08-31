# Edge Function: `cappta_webhook_receiver`

## Descrição

Esta função atua como o endpoint de recebimento para os webhooks enviados pela API da Cappta. Ela é responsável por receber, validar (futuramente) e registrar as notificações de eventos, como credenciamento de lojistas e transações.

**Esta função não deve ser chamada diretamente por clientes ou pelo front-end.** A sua URL é registrada na API da Cappta através da função `cappta_webhook_manager`.

## URL do Endpoint
`POST /functions/v1/cappta_webhook_receiver`

## Segurança

Atualmente, a função apenas recebe e registra o payload. Em uma implementação de produção, seria crucial adicionar um mecanismo de validação de assinatura para garantir que as requisições vêm autenticamente da Cappta. A documentação da Cappta deve ser consultada para obter detalhes sobre como essa assinatura é gerada e como deve ser validada.

## Fluxo de Execução

1.  Recebe uma requisição `POST` da API da Cappta.
2.  Analisa o corpo da requisição (payload JSON).
3.  Registra (loga) o tipo de evento e os dados recebidos para fins de depuração e análise.
4.  Responde imediatamente com um status `200 OK` para confirmar o recebimento à Cappta.

O processamento real dos dados do webhook (por exemplo, atualizar o status de um lojista no banco de dados) deve ser implementado conforme a necessidade do negócio.
