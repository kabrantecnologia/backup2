# Plano: Reorganização do Simulador Cappta para Diretório Raiz

**Data**: 2025-08-19 07:03  
**Contexto**: Reorganização da estrutura do monorepo  
**Objetivo**: Mover `tricket-backend/simulators/cappta-fake/` para `cappta-simulator/` no diretório raiz

## Motivação

### Problemas Identificados
- Simulador aninhado em `tricket-backend/simulators/` sugere dependência do backend
- Docker context complexo para builds independentes
- Dificulta reutilização por outros projetos
- Organização não reflete a independência funcional do simulador

### Benefícios Esperados
- **Independência Organizacional**: Simulador como projeto autônomo
- **Docker Simplificado**: Context paths diretos sem aninhamento
- **Facilita Manutenção**: Desenvolvimento e deploy independentes
- **Melhora Clareza**: Estrutura mais intuitiva do monorepo

## Análise de Impacto

### ✅ Impacto BAIXO - Mudança Segura

**Dependências Analisadas**:
- ✅ Caminhos relativos em `config/settings.py` - funcionam normalmente
- ✅ `DATABASE_URL: "sqlite:///./cappta_simulator.db"` - path relativo OK
- ✅ Docker Compose usa `context: .` - funcionará na nova localização
- ✅ URLs de integração (localhost:54321) - independentes do path
- ✅ Webhooks para Edge Functions - não afetados

**Arquivos que Requerem Atualização**:
- Documentação (README.md, changelogs, plans)
- Eventuais referências em `docker-compose.yml` principal
- Scripts de build/deploy (se existirem)

## Estrutura Proposta

### Estado Atual
```
/tricket/
├── tricket-backend/
│   ├── supabase/
│   ├── volumes/
│   └── simulators/
│       └── cappta-fake/          ← Localização atual
│           ├── app/
│           ├── config/
│           ├── docker-compose.yml
│           └── README.md
├── tricket-tests/
└── tricket-vault/
```

### Estado Futuro
```
/tricket/
├── tricket-backend/              # Backend Supabase
├── tricket-tests/                # Testes Python
├── tricket-vault/                # Documentação
└── cappta-simulator/             ← Nova localização
    ├── app/
    ├── config/
    ├── docker-compose.yml
    └── README.md
```

## Plano de Execução

### Fase 1: Preparação e Análise
- [x] ✅ Analisar dependências e referências existentes
- [x] ✅ Confirmar que mudança é segura
- [x] ✅ Documentar impactos e benefícios

### Fase 2: Movimentação
- [ ] 🔄 Criar diretório `cappta-simulator/` na raiz
- [ ] 🔄 Mover todo conteúdo de `tricket-backend/simulators/cappta-fake/`
- [ ] 🔄 Remover diretório vazio `tricket-backend/simulators/`

### Fase 3: Atualizações de Documentação
- [ ] 📝 Atualizar README.md do simulador com novos paths
- [ ] 📝 Atualizar CLAUDE.md se houver referências
- [ ] 📝 Revisar changelogs existentes sobre o simulador

### Fase 4: Validação e Testes
- [ ] 🧪 Executar simulador na nova localização
- [ ] 🧪 Testar build do Docker Compose
- [ ] 🧪 Verificar funcionamento da integração Tricket
- [ ] 🧪 Validar que webhooks continuam funcionando

### Fase 5: Finalização
- [ ] 📋 Criar changelog documentando a reorganização
- [ ] 🔗 Atualizar eventuais scripts que referenciem o path antigo
- [ ] ✅ Commit das mudanças

## Comandos de Execução

### Movimentação dos Arquivos
```bash
# No diretório raiz do projeto
mkdir cappta-simulator
mv tricket-backend/simulators/cappta-fake/* cappta-simulator/
rmdir tricket-backend/simulators/cappta-fake
rmdir tricket-backend/simulators  # se vazio
```

### Teste da Nova Configuração
```bash
cd cappta-simulator
docker-compose up -d
curl -H "Authorization: Bearer cappta_fake_token_dev_123" http://localhost:8000/ready
docker-compose down
```

### Atualização do CLAUDE.md
```bash
# Atualizar referências de paths se necessário
sed -i 's|tricket-backend/simulators/cappta-fake|cappta-simulator|g' CLAUDE.md
```

## Riscos e Mitigações

### Risco: Referências Hardcoded Perdidas
**Probabilidade**: Baixa  
**Mitigação**: Análise prévia mostrou que não existem dependências hardcoded críticas

### Risco: Docker Context Issues  
**Probabilidade**: Baixa  
**Mitigação**: Docker Compose usa paths relativos que funcionam em qualquer localização

### Risco: Scripts de Deploy Quebrados
**Probabilidade**: Média  
**Mitigação**: Revisar e atualizar scripts após movimentação

## Critérios de Sucesso

- [ ] Simulador executa normalmente na nova localização
- [ ] Docker Compose builda e roda sem erros
- [ ] Integração com Tricket backend mantida (webhooks funcionando)
- [ ] Documentação atualizada reflete nova estrutura
- [ ] Nenhuma funcionalidade perdida na movimentação

## Rollback

Se necessário, reverter executando:
```bash
mkdir -p tricket-backend/simulators
mv cappta-simulator tricket-backend/simulators/cappta-fake
```

## Notas Importantes

- Mudança puramente organizacional, sem impacto funcional
- Mantém compatibilidade total com integrações existentes
- Facilita futuras expansões do simulador
- Melhora clareza da arquitetura do monorepo

---

**Status**: 📋 Planejamento Concluído  
**Próximo Passo**: Executar Fase 2 (Movimentação)