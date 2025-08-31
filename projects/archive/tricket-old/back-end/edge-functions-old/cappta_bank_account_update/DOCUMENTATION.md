# Edge Function: bank_account_update

## Visão Geral
Esta Edge Function permite atualizar as informações bancárias de um lojista já cadastrado na plataforma Cappta através da API de onboarding. A função recebe os novos dados bancários, valida os campos necessários, envia a requisição para a API da Cappta e atualiza o status do lojista no sistema.

## Pré-requisitos
- Configuração do Supabase URL e Service Role Key
- Acesso ao Vault do Supabase com as chaves:
  - `CAPPTA_API_KEY`: Chave de API para autenticação com a Cappta
  - `CAPPTA_API_URL`: URL base da API da Cappta
- Permissão de administrador (ADMIN ou SUPER_ADMIN)
- Tabela `profiles` com os campos necessários para armazenar dados do merchant Cappta

## Parâmetros de Entrada
A função recebe requisições HTTP PUT com:
- Headers:
  - `Authorization`: Bearer token para autenticação do usuário
- Query Parameters:
  - `profile_id`: ID do perfil no Tricket
  - `reseller_document` (opcional): CNPJ do revendedor, caso não informado usa valor padrão
- Body:
  - `account`: Número da conta bancária
  - `bankCode`: Código do banco
  - `branch`: Número da agência
  - `accountType`: Tipo da conta (0 para corrente, 1 para poupança)

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
   - Busca o merchant document associado ao perfil

4. **Validação de Status**:
   - Verifica se o status atual do lojista permite atualização de dados bancários
   - Apenas os status Enabled (1) ou InvalidBank (3) permitem atualização

5. **Integração com API**:
   - Envia requisição para a API da Cappta com os novos dados bancários
   - Processa a resposta da API

6. **Resposta**:
   - Retorna os dados de resposta da API da Cappta
   - Em caso de erro, retorna detalhes do problema

## Tratamento de Erros
- **Status 400**: Parâmetros inválidos, ausentes ou status atual não permite atualização
- **Status 401**: Usuário não autenticado
- **Status 403**: Usuário sem permissões suficientes
- **Status 404**: Profile não encontrado ou sem merchant document associado
- **Status 500**: Erros internos, falhas de comunicação com o banco/vault ou API da Cappta

## Contexto de Uso
Esta função é especialmente importante quando um lojista tem o status `InvalidBank (3)`, indicando que há problemas com os dados bancários que impediram a ativação completa do lojista na plataforma. A atualização via esta função permite corrigir esses dados e possibilitar o processamento correto do credenciamento.

## Integração com Outros Componentes
- Utiliza a tabela `profiles` para buscar dados do merchant na Cappta
- Relaciona-se com a função `merchant_status` para monitorar o resultado da atualização
- Faz parte do fluxo de credenciamento do lojista após o registro inicial
