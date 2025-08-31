# Edge Function: merchant_register

## Visão Geral
Esta Edge Function permite o cadastro de um novo lojista na plataforma Cappta através da API de onboarding. A função recebe os dados do lojista, valida os campos necessários, envia a requisição para a API da Cappta e registra o documento do merchant e seu status no perfil do Tricket.

## Pré-requisitos
- Configuração do Supabase URL e Service Role Key
- Acesso ao Vault do Supabase com as chaves:
  - `CAPPTA_API_KEY`: Chave de API para autenticação com a Cappta
  - `CAPPTA_API_URL`: URL base da API da Cappta
- Permissão de administrador (ADMIN ou SUPER_ADMIN)
- Tabela `profiles` com os campos necessários para armazenar dados do merchant Cappta:
  - `cappta_merchant_document`: CNPJ/CPF do lojista na Cappta
  - `cappta_status`: Status numérico do lojista na Cappta
  - `cappta_status_description`: Descrição textual do status

## Parâmetros de Entrada
A função recebe requisições HTTP POST com:
- Headers:
  - `Authorization`: Bearer token para autenticação do usuário
- Query Parameters:
  - `profile_id`: ID do perfil no Tricket
- Body:
  - `resellerDocument`: Documento do revendedor (CNPJ)
  - `bankAccount`: Objeto com dados bancários (account, bankCode, branch, accountType)
  - `merchant`: Objeto com dados do lojista (document, companyName, tradingName, mccId, etc)
  - `owner`: Objeto com dados do responsável (name, gender, email, phone, cpf, etc)
  - `address`: Objeto com dados do endereço (postalCode, streetName, houseNumber, etc)
  - `planId`: ID do plano (opcional)

## Fluxo de Execução
1. **Inicialização e Configuração**:
   - Inicializa o logger
   - Configura o cliente Supabase com a Service Role Key
   - Verifica a disponibilidade das chaves necessárias no vault

2. **Autenticação e Autorização**:
   - Valida o token de autenticação
   - Verifica se o usuário tem permissões de ADMIN ou SUPER_ADMIN

3. **Validação de Parâmetros**:
   - Valida os campos obrigatórios no payload
   - Busca dados do perfil para complementar informações, se necessário

4. **Integração com API**:
   - Envia requisição para a API da Cappta com os dados do lojista
   - Processa a resposta da API

5. **Persistência**:
   - Atualiza o perfil com o documento do merchant na Cappta e seu status
   - Registra logs detalhados das operações

6. **Resposta**:
   - Retorna os dados de resposta da API da Cappta
   - Em caso de erro, retorna detalhes do problema

## Tratamento de Erros
- **Status 400**: Parâmetros inválidos ou ausentes
- **Status 401**: Usuário não autenticado
- **Status 403**: Usuário sem permissões suficientes
- **Status 404**: Profile não encontrado
- **Status 500**: Erros internos, falhas de comunicação com o banco/vault ou API da Cappta

## Possíveis Status do Merchant
- **Enabled (1)**: O lojista está habilitado
- **Processing (2)**: O cadastro do lojista está em processamento
- **InvalidBank (3)**: Informações bancárias inválidas
- **Disabled (4)**: O lojista está desabilitado
- **AnalyzingRisk (5)**: O cadastro do lojista está em análise de risco
- **Error (99)**: Houve um erro no cadastro do lojista

## Integração com Outros Componentes
- Utiliza a tabela `profiles` para armazenar dados do merchant na Cappta
- Utiliza a view `view_admin_profile_approval` para obter dados consolidados do perfil
- Se relaciona com a função `merchant_status` para consultas posteriores de status
