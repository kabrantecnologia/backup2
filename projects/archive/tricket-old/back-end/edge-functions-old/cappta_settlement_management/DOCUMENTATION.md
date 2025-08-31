# Edge Function: settlement_management

## Visão Geral
Esta Edge Function permite configurar o gerenciamento de liquidação para um lojista na plataforma Cappta através da API de onboarding. A função recebe os parâmetros de dias para liquidação de débito e crédito, envia a requisição para a API da Cappta e atualiza os dados de liquidação no perfil do Tricket.

## Pré-requisitos
- Configuração do Supabase URL e Service Role Key
- Acesso ao Vault do Supabase com as chaves:
  - `CAPPTA_API_KEY`: Chave de API para autenticação com a Cappta
  - `CAPPTA_API_URL`: URL base da API da Cappta
- Permissão de administrador (ADMIN ou SUPER_ADMIN)
- Tabela `profiles` com os campos necessários para armazenar dados de liquidação:
  - `cappta_settlement_days_credit`: Dias para liquidação de transações de crédito
  - `cappta_settlement_days_debit`: Dias para liquidação de transações de débito

## Parâmetros de Entrada
A função recebe requisições HTTP PUT com:
- Headers:
  - `Authorization`: Bearer token para autenticação do usuário
- Query Parameters:
  - `profile_id`: ID do perfil no Tricket
- Body:
  - `settlementManagementDaysCredit`: Dias para liquidação de transações de crédito (inteiro >= 0)
  - `settlementManagementDaysDebit`: Dias para liquidação de transações de débito (inteiro >= 0)

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
   - Verifica se os valores de dias são números inteiros não negativos
   - Busca o merchant document associado ao perfil

4. **Integração com API**:
   - Envia requisição para a API da Cappta com os parâmetros de liquidação
   - Processa a resposta da API

5. **Persistência**:
   - Atualiza o perfil com os dados de liquidação configurados
   - Registra logs detalhados das operações

6. **Resposta**:
   - Retorna os dados de resposta da API da Cappta
   - Em caso de erro, retorna detalhes do problema

## Tratamento de Erros
- **Status 400**: Parâmetros inválidos ou ausentes
- **Status 401**: Usuário não autenticado
- **Status 403**: Usuário sem permissões suficientes
- **Status 404**: Profile não encontrado ou sem merchant document associado
- **Status 500**: Erros internos, falhas de comunicação com o banco/vault ou API da Cappta

## Contexto de Uso
Esta função permite definir o número de dias que o sistema Cappta levará para processar a liquidação de transações de débito e crédito para o lojista. Isso impacta diretamente o fluxo financeiro do lojista e normalmente é configurado após o credenciamento inicial do lojista, quando ele já está habilitado na plataforma.

## Integração com Outros Componentes
- Utiliza a tabela `profiles` para buscar dados do merchant na Cappta e armazenar configurações de liquidação
- É parte do fluxo de configuração financeira do lojista após seu credenciamento
- Relaciona-se com o sistema financeiro que processa transações e liquidações
