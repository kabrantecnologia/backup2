# Plano de Execução - Bulk Onboarding Idempotente

Data/Hora: 2025-08-16 20:40 (BRT)
Branch: feat/bulk-onboarding-idempotente
Responsável: Cascade

## Objetivo
Garantir que o fluxo de cadastro em lote (opção 3 do runner) seja estável e reexecutável, evitando falhas por registros já existentes e preparando o ambiente via reset e migrações.

## Escopo
- Ajustes no processo de autenticação para lidar com e-mails já existentes (login em vez de erro).
- Bootstrap do runner para usar venv local e carregar `.env` do backend.
- Reset do banco (Supabase) e reaplicação de migrações para estado conhecido.
- Execução do cadastro em lote e verificação de sucesso.

## Tarefas
1. Criar branch a partir de `dev`: `feat/bulk-onboarding-idempotente`.
2. Atualizar `tricket-tests/operations/auth.py` para idempotência na criação/login.
3. Melhorar bootstrap em `tricket-tests/main.py` (venv + dotenv do backend).
4. Executar:
   - Supabase DB Reset.
   - Test Runner -> Opção 3 (Cadastrar TODOS os Usuários).
5. Registrar changelog com resultados e impactos.
6. Commitar e publicar a branch.

## Critérios de Aceite
- Cadastro em lote reporta 100% de sucesso em ambiente recém-resetado.
- Reexecuções não falham por "usuário já existe".

## Riscos e Mitigações
- Risco: RPCs de perfil retornarem erro de "já existente" em reexecuções.
  - Mitigação futura: tratar RPCs como idempotentes quando aplicável.

## Observações
- Próximos passos incluem tornar RPCs de perfis idempotentes e adicionar asserts pós-bulk na suíte.
