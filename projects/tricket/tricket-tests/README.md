# Sistema de Testes Tricket - Atualização

## Resumo das Mudanças Implementadas

### ✅ 1. Remoção da Seleção de Projetos
- O script agora é **exclusivo do projeto Tricket**
- Removido o sistema de seleção de projetos
- Simplificado para uso direto com configuração fixa

### ✅ 2. Unificação do Processo de Criação
- Nova operação: **"Criar Conta + Perfil Completo"**
- Processo unificado que cria conta de usuário + perfil completo (individual + organização)
- Automatiza todo o fluxo em uma única operação

### ✅ 3. Sistema de Armazenamento de Tokens
- **Armazenamento persistente** de tokens de acesso
- Suporte para **múltiplos usuários**
- Sistema de **gerenciamento de tokens** via interface interativa

## Como Usar

### Operações Disponíveis
- **Criar Conta + Perfil Completo** — Cria usuário e perfil completo (detecta automaticamente tipo)
- **Criar Perfil Individual** — Cria apenas perfil individual (para CONSUMER)
- **Cadastrar TODOS os Usuários** — Cria todos os usuários de uma vez (detecta tipos automaticamente)
- **Login de Usuário** — Autentica e armazena tokens
- **Supabase DB Push (Aplicar Migrações)** — Aplica migrações
- **Supabase DB Reset (Resetar Banco)** — Reseta banco
- **DB Reset Forçado + Cadastro Usuário** — Reset + novo usuário
- **Gerenciar Tokens** — Interface completa de gerenciamento
- **Ver Resumo de Tokens** — Visualização rápida
- **Ver Profiles para Aprovação (Admin)** — Lista profiles pendentes via RPC (requer login como admin)
- **Aprovar Profile (Admin)** — Solicita um ID de profile e tenta aprovar via RPC
- **RPCs Marketplace (Admin)** — Menu para criar/atualizar/deletar (soft) Departments, Categories, SubCategories, Brands e Products

### Arquivos de Configuração
- **Configuração**: `config/tricket.json`
- **Tokens**: `~/.testing_system_tokens.json`
- **Sessão**: `~/.testing_system_session.json`

### Perfis de Teste Disponíveis
- **admin** — Admin do sistema (email: `admin@tricket.com.br`)
- **fornecedor** — José Fornecedor (Coca-Cola)
- **comerciante** — Maria Comerciante (Padaria)
- **consumidor** — João Henrique (Pessoa Física)

## Exemplo de Uso

### RPCs do Marketplace (Admin)
- Requer login como `admin@tricket.com.br`.
- Oferece operações para:
  - Criar/Atualizar/Soft-delete `Departments`, `Categories`, `SubCategories`, `Brands`, `Products`.
- Campos obrigatórios e validações seguem as RPCs definidas nas migrações:
  - Inserções: `610_rpc_marketplace_insert.sql`
  - Update/Delete: `611_rpc_marketplace_update_delete.sql`

```bash
# (Opcional) Criar venv e instalar dependências
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Executar o sistema
python main.py

# No menu, selecione a operação desejada conforme o nome exibido (os números podem variar)
# Exemplos:
# - Criar Conta + Perfil Completo
# - Cadastrar TODOS os Usuários
# - Gerenciar Tokens
```

## Operação de Cadastro em Lote

### **"Cadastrar TODOS os Usuários"**

Esta operação processa **todos os usuários** do arquivo de configuração em sequência:

#### **Funcionalidades:**
- ✅ **Progresso visual** com barra de progresso
- ✅ **Relatório detalhado** de cada usuário
- ✅ **Armazenamento automático** de tokens
- ✅ **Tratamento de erros** individual por usuário
- ✅ **Estatísticas finais** de sucesso/falha

#### **Fluxo de Execução:**
1. Lista todos os usuários do `config/tricket.json`
2. Para cada usuário:
   - Cria conta de usuário
   - Faz login e obtém tokens
   - Armazena tokens
   - Cria perfil completo (individual + organização)
   - Registra resultado
3. Exibe relatório final com estatísticas

#### **Exemplo de Saída:**
```
RELATÓRIO FINAL
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Resultados do Cadastro em Lote                                        ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Usuário    │ Email                │ Status    │ Detalhes              ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ admin      │ admin@...           │ ✅ Sucesso │ Conta e perfil criados┃
┃ fornecedor │ fornecedor@...      │ ✅ Sucesso │ Conta e perfil criados┃
┃ comerciante│ comerciante@...     │ ✅ Sucesso │ Conta e perfil criados┃
┃ consumidor │ consumidor@...      │ ✅ Sucesso │ Conta e perfil criados┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Operações de Aprovação (Admin)

- A operação `Ver Profiles para Aprovação (Admin)` executa `rpc_get_profiles_for_approval` e exibe uma tabela com os profiles pendentes.
- A operação `Aprovar Profile (Admin)` solicita um `ID` e tenta aprovar chamando as RPCs `rpc_approve_user_profile` ou `approve_user_profile` (fallback automático).
- Pré-requisitos:
  - Realize o login como `admin@tricket.com.br` usando `Login de Usuário`.
  - Garanta que o token do admin esteja salvo em `~/.testing_system_tokens.json`.

## Arquitetura dos Tokens

### Estrutura de Armazenamento
```json
{
  "users": {
    "usuario@email.com": {
      "access_token": "jwt_token_aqui",
      "refresh_token": "refresh_token_aqui",
      "expires_at": 1234567890,
      "user_id": "uuid_do_usuario",
      "created_at": "2024-01-01T00:00:00",
      "last_used": "2024-01-01T00:00:00"
    }
  }
}
```

### Funções de Gerenciamento
- `save_user_token()` - Salva tokens
- `get_user_token()` - Recupera tokens
- `remove_user_token()` - Remove tokens
- `get_current_token()` - Token do usuário atual
- `get_all_tokens()` - Lista todos os tokens

## Próximos Passos

O sistema está pronto para implementar novas operações que exigem autenticação, utilizando os tokens armazenados automaticamente.


## Execução da Suíte de Testes

Com o arquivo `pytest.ini` incluído neste diretório, o `pythonpath` já é configurado para o diretório atual, permitindo imports como `core.*` e `operations.*` nos testes.

```bash
# (opcional) ativar venv e instalar dependências
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# executar todos os testes em modo quiet
pytest -q
```

Observações:
- O `pytest.ini` define `pythonpath = .` e `addopts = -q`.
- Caso deseje mais verbosidade, execute `pytest -vv`.

