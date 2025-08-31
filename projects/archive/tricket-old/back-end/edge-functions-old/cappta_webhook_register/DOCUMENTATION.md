# Edge Function: webhook_register

## Visão Geral
Esta Edge Function permite registrar endpoints de webhook para receber notificações da Cappta relacionadas ao credenciamento de lojistas ou transações. A função valida os parâmetros, verifica permissões, gera um token de segurança e armazena a configuração no banco de dados.

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
  - `profile_id`: ID do perfil ao qual o webhook estará associado
  - `webhook_type`: Tipo de webhook ('MERCHANT_ACCREDITATION' ou 'TRANSACTION')
  - `webhook_url`: URL para onde as notificações de webhook serão enviadas

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

4. **Geração de Token**:
   - Gera um token seguro de 14 caracteres para autenticar requisições de webhook

5. **Persistência**:
   - Registra ou atualiza o webhook na tabela `cappta_webhooks`
   - Utiliza upsert para evitar duplicidades (baseado em profile_id e webhook_type)

6. **Resposta**:
   - Retorna detalhes do webhook registrado, incluindo ID, URL e token
   - Em caso de erro, retorna o código de status apropriado com detalhes

## Tratamento de Erros
- **Status 400**: Parâmetros inválidos ou ausentes
- **Status 401**: Usuário não autenticado
- **Status 403**: Usuário sem permissões suficientes
- **Status 500**: Erros internos ou falhas de comunicação com o banco/vault

## Considerações de Segurança
- Apenas usuários com permissões administrativas podem registrar webhooks
- O token gerado é armazenado no banco e será usado para autenticar requisições recebidas
- As variáveis sensíveis são obtidas do vault seguro do Supabase
- Todas as ações são registradas em log para auditoria e depuração

## Integração com Outros Componentes
- Os webhooks registrados serão utilizados pelas funções `webhook_merchant_accreditation` e `webhook_transaction`
- Os tokens gerados devem ser configurados na plataforma Cappta para validar requisições
