# Changelog - Bulk Onboarding Idempotente e Reset de DB

Data/Hora: 2025-08-16 20:39 (BRT)
Branch: feat/bulk-onboarding-idempotente

## Resumo
- Tornado o fluxo de cadastro em lote (opção 3) reproduzível após resets, com ajustes de idempotência no login/criação de contas.
- Reset do banco via Supabase CLI e reaplicação de todas as migrações.
- Execução do cadastro em lote com sucesso (7 usuários criados com perfis).

## Detalhes das Alterações
- `tricket-tests/operations/auth.py`
  - Ajustes para não falhar quando o e-mail já está cadastrado: realiza login e segue o fluxo.
- `tricket-tests/main.py`
  - Bootstrap do interpretador para usar o Python do venv local.
  - Carregamento de variáveis de ambiente do backend (`tricket-backend/.env`) antes de executar as operações.

## Operações Executadas
- Supabase DB Reset e migrações aplicadas com sucesso.
- Test Runner (`main.py`) -> Operação 3: Cadastrar TODOS os Usuários.
- Resultado: 7/7 usuários com "Conta e perfil criados" (100% sucesso).

## Impacto
- Ambiente de desenvolvimento pronto para rodadas repetidas de testes de onboarding sem erros por registros pré-existentes.
- Melhoria de DX ao garantir que o runner sempre use o venv corretamente e carregue o `.env` do backend.

## Próximos Passos
- Opcional: Tratar RPCs de perfis para retornarem sucesso idempotente quando o perfil já existir (melhor resiliência a reexecuções).
- Automatizar verificação pós-bulk (asserts) na suíte para garantir consistência dos perfis gerados.
