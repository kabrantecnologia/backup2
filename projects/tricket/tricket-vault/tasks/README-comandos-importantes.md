# Comandos Importantes (Supabase e Testes)

Aplicar migrations:
```bash
cd ~/workspaces/projects/tricket/tricket-backend
supabase db push --yes --db-url "postgresql://postgres.dev_tricket_tenant:yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH@localhost:5408/postgres"
```

Reset (cautela! apaga dados):
```bash
cd ~/workspaces/projects/tricket/tricket-backend
supabase db reset --yes --db-url "postgresql://postgres.dev_tricket_tenant:yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH@localhost:5408/postgres"
```

Executar testes:
```bash
cd ~/workspaces/projects/tricket/tricket-tests
pytest
```
