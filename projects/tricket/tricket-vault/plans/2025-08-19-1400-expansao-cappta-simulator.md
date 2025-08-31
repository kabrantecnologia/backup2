# Plano de Expansão do Cappta Simulator - Operações Completas

**Data**: 2025-08-19  
**Responsável**: Claude Code  
**Objetivo**: Expandir o simulador Cappta para 100% das operações da API oficial, preparando para integração plug-and-play

## Contexto e Objetivo

O simulador atual (`captta-simulator/`) implementa funcionalidades básicas de comerciantes, transações e liquidações. Objetivo é expandir para cobrir 100% das operações da API Cappta oficial, tornando a futura migração praticamente plug-and-play.

### Infraestrutura Disponível
- **Subdomínio**: `simulador-cappta.kabran.com.br` → apontado para ambiente dev2
- **Conta Asaas**: Configurada para transferências reais
- **Estrutura Base**: FastAPI + SQLite + Docker

## Análise de Gap - APIs Faltantes

### ✅ Implementado Atualmente
- Gerenciamento básico de comerciantes
- Transações simples (create/read/update)
- Sistema de liquidação D+1
- Webhooks básicos
- Integração Asaas para transferências

### ❌ APIs Faltantes (Baseadas na Doc Cappta)

#### 1. **Autenticação Avançada**
- Gestão completa de tokens
- Refresh tokens
- Rate limiting por cliente
- Auditoria de acesso

#### 2. **Cadastro e Credenciamento**
- **Terminals**: Gestão completa de terminais
- **POS Devices**: Dispositivos físicos associados
- **Plans**: Planos de taxa por comerciante
- **Address**: Validação e normalização de endereços
- **KYC**: Simulação de verificação documental

#### 3. **Transações Avançadas**
- **Autorização vs Captura**: Fluxo em duas etapas
- **Cancelamentos**: Parciais e totais
- **Estornos**: Com diferentes motivos
- **Parcelamento**: Lojista e administradora
- **Múltiplas bandeiras**: Visa, Mastercard, Elo, PIX
- **Consultas**: Por período, status, filtros avançados

#### 4. **Liquidações Refinadas**
- **Antecipação**: Simulação de ARV
- **Agendamentos**: Liquidações programadas
- **Retenções**: Por chargebacks ou disputas
- **Relatórios**: Extratos detalhados
- **Conciliação**: Matching de transações

#### 5. **Webhooks Robustos**
- **Retry Policy**: Tentativas automáticas
- **Assinatura Digital**: Verificação HMAC completa
- **Eventos Granulares**: 20+ tipos de evento
- **Batch Notifications**: Agrupamento de eventos

#### 6. **Monitoramento e Admin**
- **Health Checks**: Métricas detalhadas
- **Status Pages**: Simulação de incidentes
- **Rate Limiting**: Por cliente/endpoint
- **Analytics**: Dashboard de uso
- **Audit Logs**: Trilha completa

## Plano de Implementação

### **Fase 1: Infraestrutura e Configuração** (3-5 dias)

#### 1.1 Configuração de Ambiente
- [ ] Criar arquivo `.env` com API key Asaas para transferências
- [ ] Configurar subdomínio no ambiente dev2
- [ ] Implementar SSL/TLS para HTTPS
- [ ] Setup de logging estruturado (JSON)

#### 1.2 Autenticação Robusta
- [ ] Sistema de múltiplos tokens (por cliente)
- [ ] Rate limiting com Redis/memory cache
- [ ] Middleware de auditoria
- [ ] Refresh token mechanism

#### 1.3 Database Schema Expandido
- [ ] Tabelas para terminals, pos_devices, plans
- [ ] Índices otimizados para consultas
- [ ] Migrations com versionamento
- [ ] Backup/restore automatizado

### **Fase 2: APIs de Credenciamento** (5-7 dias)

#### 2.1 Terminals Management
```python
# Endpoints a implementar:
POST   /terminals
GET    /terminals/{terminal_id}
PUT    /terminals/{terminal_id}
DELETE /terminals/{terminal_id}
GET    /terminals?merchant_id={id}&status={status}
PUT    /terminals/{terminal_id}/status
```

#### 2.2 POS Devices
```python
# Endpoints a implementar:
POST   /pos-devices
GET    /pos-devices/{device_id}
PUT    /pos-devices/{device_id}
POST   /pos-devices/{device_id}/associate
DELETE /pos-devices/{device_id}/dissociate
GET    /pos-devices?terminal_id={id}
```

#### 2.3 Plans & Pricing
```python
# Endpoints a implementar:
POST   /plans
GET    /plans/{plan_id}
PUT    /plans/{plan_id}
GET    /merchants/{merchant_id}/plan
PUT    /merchants/{merchant_id}/plan
```

### **Fase 3: Transações Avançadas** (7-10 dias)

#### 3.1 Fluxo de Autorização/Captura
```python
# Endpoints a implementar:
POST   /transactions/authorize      # Apenas autorizar
POST   /transactions/{id}/capture   # Capturar depois
POST   /transactions/{id}/void      # Cancelar autorização
```

#### 3.2 Cancelamentos e Estornos
```python
# Endpoints a implementar:
POST   /transactions/{id}/cancel
POST   /transactions/{id}/refund
GET    /transactions/{id}/refunds
PUT    /refunds/{refund_id}/status
```

#### 3.3 Parcelamento e Bandeiras
- [ ] Lógica de cálculo para parcelamento lojista vs administradora
- [ ] Simulação específica por bandeira (Visa, Master, Elo)
- [ ] Taxas diferenciadas por tipo de cartão
- [ ] Validação de BIN ranges

#### 3.4 Consultas Avançadas
```python
# Endpoints a implementar:
GET /transactions?merchant_id={id}&date_from={date}&date_to={date}
GET /transactions?status={status}&payment_method={method}
GET /transactions?nsu={nsu}&authorization_code={auth}
GET /transactions/{id}/timeline  # Histórico de status
```

### **Fase 4: Liquidações e Financeiro** (5-7 dias)

#### 4.1 Antecipação (ARV)
```python
# Endpoints a implementar:
POST   /settlements/anticipation/simulate
POST   /settlements/anticipation/request
GET    /settlements/anticipation/{id}/status
PUT    /settlements/anticipation/{id}/approve
```

#### 4.2 Agendamentos
```python
# Endpoints a implementar:
GET    /settlements/schedule?merchant_id={id}
PUT    /settlements/schedule/{id}/reschedule
POST   /settlements/batch-schedule
```

#### 4.3 Retenções e Disputas
```python
# Endpoints a implementar:
POST   /settlements/{id}/hold
POST   /settlements/{id}/release
GET    /settlements/{id}/disputes
POST   /disputes/{id}/evidence
```

#### 4.4 Relatórios Financeiros
```python
# Endpoints a implementar:
GET    /reports/settlement-extract?merchant_id={id}&period={period}
GET    /reports/reconciliation?date={date}
GET    /reports/transaction-summary?merchant_id={id}
POST   /reports/custom-export
```

### **Fase 5: Webhooks e Integração** (3-5 days)

#### 5.1 Sistema de Retry
- [ ] Exponential backoff para falhas
- [ ] Dead letter queue para webhooks falhados
- [ ] Dashboard de monitoring de webhooks
- [ ] Alertas para falhas críticas

#### 5.2 Eventos Granulares
```python
# Eventos a implementar:
transaction.authorized
transaction.captured  
transaction.settled
transaction.cancelled
transaction.refunded
settlement.created
settlement.processing
settlement.completed
settlement.failed
merchant.created
merchant.updated
merchant.suspended
terminal.created
terminal.activated
terminal.deactivated
plan.updated
dispute.opened
dispute.resolved
anticipation.approved
anticipation.denied
```

#### 5.3 Assinatura Digital
- [ ] HMAC-SHA256 completo com timestamp
- [ ] Validação de headers obrigatórios
- [ ] Prevenção de replay attacks
- [ ] Rotação automática de secrets

### **Fase 6: Monitoramento e Observabilidade** (3-4 dias)

#### 6.1 Health Checks Detalhados
```python
# Endpoints a implementar:
GET /health/detailed          # Status completo
GET /health/database         # Status DB
GET /health/external-apis    # Asaas, Tricket
GET /health/webhooks         # Taxa de sucesso
GET /metrics/prometheus      # Métricas para Grafana
```

#### 6.2 Admin Dashboard
- [ ] Interface simples para monitoring
- [ ] Visualização de transações em tempo real
- [ ] Logs estruturados consultáveis
- [ ] Alertas configuráveis

#### 6.3 Rate Limiting
- [ ] Por cliente/token (ex: 1000 req/min)
- [ ] Por endpoint crítico (ex: 100 req/min em /transactions)
- [ ] Headers informativos (X-RateLimit-*)
- [ ] Whitelist para IPs confiáveis

### **Fase 7: Testes e Validação** (3-4 dias)

#### 7.1 Test Suite Completa
- [ ] Testes unitários (>90% coverage)
- [ ] Testes de integração com Asaas
- [ ] Testes de carga (stress testing)
- [ ] Testes de webhook delivery

#### 7.2 Documentação API
- [ ] OpenAPI 3.0 completa
- [ ] Exemplos para todos endpoints
- [ ] Collection do Postman
- [ ] Guias de integração

#### 7.3 Deploy e Configuração
- [ ] Docker multi-stage otimizado
- [ ] CI/CD pipeline básico
- [ ] Configuração no ambiente dev2
- [ ] DNS e certificados SSL

## Estrutura de Arquivos Expandida

```
cappta-simulator/
├── app/
│   ├── main.py
│   ├── api/
│   │   ├── auth.py              ✅ Existente
│   │   ├── merchants.py         ✅ Existente  
│   │   ├── terminals.py         ❌ Novo
│   │   ├── pos_devices.py       ❌ Novo
│   │   ├── plans.py             ❌ Novo
│   │   ├── transactions.py      ✅ Existente (expandir)
│   │   ├── settlements.py       ✅ Existente (expandir)
│   │   ├── reports.py           ❌ Novo
│   │   ├── webhooks.py          ❌ Novo
│   │   ├── health.py            ✅ Existente (expandir)
│   │   └── admin.py             ❌ Novo
│   ├── models/
│   │   ├── common.py            ✅ Existente
│   │   ├── merchant.py          ✅ Existente
│   │   ├── terminal.py          ❌ Novo
│   │   ├── pos_device.py        ❌ Novo
│   │   ├── plan.py              ❌ Novo
│   │   ├── transaction.py       ✅ Existente (expandir)
│   │   ├── settlement.py        ✅ Existente (expandir)
│   │   ├── refund.py            ❌ Novo
│   │   ├── webhook.py           ❌ Novo
│   │   └── report.py            ❌ Novo
│   ├── services/
│   │   ├── asaas_client.py      ✅ Existente
│   │   ├── auth_service.py      ❌ Novo
│   │   ├── terminal_service.py  ❌ Novo
│   │   ├── plan_service.py      ❌ Novo
│   │   ├── transaction_processor.py  ✅ Existente (expandir)
│   │   ├── settlement_processor.py   ✅ Existente (expandir)
│   │   ├── refund_processor.py  ❌ Novo
│   │   ├── webhook_sender.py    ✅ Existente (expandir)
│   │   ├── webhook_retry.py     ❌ Novo
│   │   └── report_generator.py  ❌ Novo
│   ├── database/
│   │   ├── connection.py        ✅ Existente
│   │   ├── models.py            ✅ Existente (expandir)
│   │   └── migrations.py        ❌ Novo
│   ├── middleware/
│   │   ├── auth.py              ❌ Novo
│   │   ├── rate_limit.py        ❌ Novo
│   │   └── audit.py             ❌ Novo
│   └── utils/
│       ├── validators.py        ❌ Novo
│       ├── formatters.py        ❌ Novo
│       └── crypto.py            ❌ Novo
├── config/
│   ├── settings.py              ✅ Existente (expandir)
│   └── logging.py               ❌ Novo
├── tests/
│   ├── unit/                    ❌ Novo
│   ├── integration/             ❌ Novo
│   └── load/                    ❌ Novo
├── docs/
│   ├── api/                     ❌ Novo
│   └── integration-guide.md     ❌ Novo
├── scripts/
│   ├── deploy.sh                ❌ Novo
│   └── setup-env.sh             ❌ Novo
├── .env.example                 ❌ Novo
├── docker-compose.prod.yml      ❌ Novo
└── Makefile                     ❌ Novo
```

## Configuração .env Completa

```bash
# Environment
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=info

# API Configuration  
API_TOKEN_ADMIN=cappta_admin_token_prod_xyz
API_HOST=0.0.0.0
API_PORT=8000
BASE_URL=https://simulador-cappta.kabran.com.br

# Rate Limiting
RATE_LIMIT_REQUESTS_PER_MINUTE=1000
RATE_LIMIT_BURST=100

# Asaas Integration (NOVA CONTA)
ASAAS_API_KEY=<API_KEY_CONTA_ASAAS_SIMULADOR>
ASAAS_BASE_URL=https://sandbox.asaas.com/api/v3
CAPPTA_MASTER_ACCOUNT_ID=<ACCOUNT_ID_ASAAS_SIMULADOR>

# Tricket Integration
TRICKET_WEBHOOK_URL=https://dev2.tricket.kabran.com.br/functions/v1/captta_webhook_receiver
TRICKET_WEBHOOK_SECRET=webhook_secret_prod_xyz
TRICKET_API_BASE=https://dev2.tricket.kabran.com.br

# Security
ALLOWED_IPS=["0.0.0.0/0"]  # Produção: IPs específicos
WEBHOOK_SIGNATURE_SECRET=signature_secret_prod_xyz
TOKEN_EXPIRY_HOURS=24

# Database
DATABASE_URL=sqlite:///./cappta_simulator_prod.db
DATABASE_POOL_SIZE=20
DATABASE_ECHO=false

# Monitoring
SENTRY_DSN=<opcional>
PROMETHEUS_ENABLED=true
HEALTH_CHECK_INTERVAL=30

# Webhooks
WEBHOOK_RETRY_ATTEMPTS=5
WEBHOOK_RETRY_DELAY=60
WEBHOOK_TIMEOUT=30
```

## Deliverables

### **Documentação**
1. **API Reference completa** (OpenAPI 3.0)
2. **Integration Guide** para desenvolvedores
3. **Deployment Guide** para ambiente dev2
4. **Troubleshooting Guide** com cenários comuns

### **Código**
1. **Simulador expandido** com todas as APIs
2. **Test suite completa** (unit + integration)
3. **Docker setup** para produção
4. **CI/CD pipeline** básico

### **Infraestrutura**
1. **Deploy em dev2** funcionando
2. **Monitoramento** com health checks
3. **SSL/TLS** configurado
4. **Backup strategy** para dados

## Timeline Estimado

- **Fase 1**: 3-5 dias (infraestrutura)
- **Fase 2**: 5-7 dias (credenciamento) 
- **Fase 3**: 7-10 dias (transações avançadas)
- **Fase 4**: 5-7 dias (liquidações)
- **Fase 5**: 3-5 dias (webhooks)
- **Fase 6**: 3-4 dias (monitoramento)
- **Fase 7**: 3-4 dias (testes e deploy)

**Total**: 29-42 dias (aproximadamente 6-8 semanas)

## Critérios de Sucesso

### **Funcional**
- [ ] 100% dos endpoints da API Cappta oficial implementados
- [ ] Fluxo completo de transação → liquidação → webhook funcionando
- [ ] Integração com Asaas para transferências reais
- [ ] Rate limiting e autenticação robusta

### **Não-Funcional**
- [ ] Resposta < 200ms para 95% das requisições
- [ ] Uptime > 99.5% 
- [ ] Cobertura de testes > 90%
- [ ] Documentação completa e atualizada

### **Integração**
- [ ] Webhook delivery > 99% success rate
- [ ] Zero breaking changes para clientes existentes
- [ ] Compatibilidade com contrato Cappta oficial
- [ ] Logs estruturados para troubleshooting

## Próximos Passos

1. **Aprovação do plano** e ajustes se necessário
2. **Setup da conta Asaas** para transferências
3. **Configuração do ambiente dev2** 
4. **Início da Fase 1** - Infraestrutura

## Riscos e Mitigações

### **Técnicos**
- **Risco**: Diferenças no contrato da API real Cappta
- **Mitigação**: Manter flexibilidade na estrutura de dados, usar JSONB para payloads

### **Infraestrutura**  
- **Risco**: Limitações do ambiente dev2
- **Mitigação**: Testes de carga locais, monitoring proativo

### **Integração**
- **Risco**: Mudanças na API Asaas durante desenvolvimento
- **Mitigação**: Versionamento de clientes, testes automatizados

---

Este plano estabelece uma base sólida para a expansão completa do simulador Cappta, garantindo compatibilidade futura com a API oficial e facilitando a transição plug-and-play.