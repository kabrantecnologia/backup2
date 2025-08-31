# Edge Function: merchant_status

## Visão Geral
Esta Edge Function permite consultar o status de um lojista na plataforma Cappta através da API de onboarding. A função busca o merchant document associado ao perfil do Tricket, consulta o status atual na API da Cappta e atualiza o registro do perfil com as informações mais recentes.

## Pré-requisitos
- Configuração do Supabase URL e Service Role Key
- Acesso ao Vault do Supabase com as chaves:
  - `CAPPTA_API_KEY`: Chave de API para autenticação com a Cappta
  - `CAPPTA_API_URL`: URL base da API da Cappta
- Tabela `profiles` com os campos:
  - `cappta_merchant_document`: CNPJ/CPF do lojista na Cappta
  - `cappta_status`: Status numérico do lojista na Cappta
  - `cappta_status_description`: Descrição textual do status

## Parâmetros de Entrada
A função recebe requisições HTTP GET com:
- Headers:
  - `Authorization`: Bearer token para autenticação do usuário
- Query Parameters:
  - `profile_id`: ID do perfil no Tricket
  - `reseller_document` (opcional): CNPJ do revendedor, caso não seja informado usa um padrão

## Fluxo de Execução
1. **Inicialização e Configuração**:
   - Inicializa o logger
   - Configura o cliente Supabase com a Service Role Key
   - Verifica a disponibilidade das chaves necessárias no vault

2. **Autenticação**:
   - Valida o token de autenticação
   - Verifica se o usuário está autenticado

3. **Recuperação de Dados**:
   - Busca o merchant document associado ao profile_id na tabela de profiles
   - Verifica se o merchant document existe

4. **Integração com API**:
   - Envia requisição para a API da Cappta para consultar o status do lojista
   - Processa a resposta da API

5. **Atualização de Dados**:
   - Se o status recebido da API for diferente do armazenado, atualiza o perfil
   - Registra logs detalhados das operações

6. **Resposta**:
   - Retorna os dados de status do lojista da API da Cappta
   - Em caso de erro, retorna detalhes do problema

## Tratamento de Erros
- **Status 400**: Parâmetros inválidos ou ausentes
- **Status 401**: Usuário não autenticado
- **Status 404**: Profile não encontrado ou sem merchant document associado
- **Status 500**: Erros internos, falhas de comunicação com o banco/vault ou API da Cappta

## Possíveis Status do Merchant
- **Enabled (1)**: O lojista está habilitado
- **Processing (2)**: O cadastro do lojista está em processamento
- **InvalidBank (3)**: Informações bancárias inválidas
- **Disabled (4)**: O lojista está desabilitado
- **AnalyzingRisk (5)**: O cadastro do lojista está em análise de risco
- **Error (99)**: Houve um erro no cadastro do lojista

## Integração com Outros Componentes
- Utiliza a tabela `profiles` para buscar e atualizar dados do merchant na Cappta
- Se relaciona com a função `merchant_register` que registra inicialmente o lojista
- Permite monitorar o progresso do credenciamento do lojista
