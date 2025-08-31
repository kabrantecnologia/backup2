# Guia Rápido de Operações

Este documento descreve as principais operações disponíveis no sistema de testes `testing-tricket/`.

## Requisitos
- Python 3.10+
- Dependências instaladas:
```bash
pip install -r testing-tricket/requirements.txt
```
- Arquivo `.env` configurado em `testing-tricket/.env` (copiado de `.env.example`).

## Execução do Menu Principal
```bash
python testing-tricket/main.py
```
Operações principais:
- Criar Conta + Perfil Completo
- Criar Perfil Individual
- Cadastrar TODOS os Usuários
- Login de Usuário
- Supabase DB Push (Aplicar Migrações)
- Supabase DB Reset (Resetar Banco)
- DB Reset Forçado + Cadastro Usuário
- Gerenciar Tokens
- Ver Resumo de Tokens
- Ver Profiles para Aprovação (Admin)
- Aprovar Profile (Admin)
- RPCs Marketplace (Admin)
- Ofertas do Fornecedor (RPCs)

## Aprovação de Profiles (Admin)
Pré-requisitos: estar logado como `admin@tricket.com.br` no menu principal.

Via menu:
1. Ver Profiles para Aprovação (Admin) — lista pendentes com IDs.
2. Aprovar Profile (Admin) — informa o ID e confirma.

Via script dedicado:
```bash
# Listar pendentes
python testing-tricket/scripts/approve_profile.py --list

# Aprovar por ID
python testing-tricket/scripts/approve_profile.py --id <UUID>

# Interativo
python testing-tricket/scripts/approve_profile.py
```

## Dicas
- Tokens e sessões são armazenados automaticamente (ver `core/session_manager.py`).
- Variáveis sensíveis (URL e chave) são lidas do `.env` e não ficam mais no `config/tricket.json`.
- Para automatizar cenários, veja `automation/` ou crie scripts em `scripts/` usando funções em `operations/`.
