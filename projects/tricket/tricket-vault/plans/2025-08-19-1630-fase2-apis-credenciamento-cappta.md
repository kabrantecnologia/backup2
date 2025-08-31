# Fase 2: APIs de Credenciamento - Cappta Simulator

**Data**: 2025-08-19 16:30  
**Responsável**: Claude Code  
**Branch**: feat/cappta-fase2-apis-credenciamento  
**Objetivo**: Implementar APIs completas de credenciamento (Terminais, POS, Planos)

## Contexto

Com a Fase 1 (Infraestrutura + Compatibilidade) concluída, agora implementaremos as APIs de credenciamento que são essenciais para o processo de onboarding de merchants na plataforma Cappta. Estas APIs permitem:

- Gestão completa de terminais
- Configuração de dispositivos POS
- Administração de planos de merchant
- Integração completa com o fluxo de credenciamento

## 📋 Estado Atual (Pós Fase 1)

### ✅ Já Implementado
- ✅ Sistema de resellers compatível com API oficial
- ✅ Autenticação Bearer token (CAPPTA_API_TOKEN)
- ✅ Banco de dados com 12 tabelas
- ✅ Middleware completo (auth, rate limiting, audit)
- ✅ APIs básicas (merchants, transactions, settlements)
- ✅ Integração Asaas funcional
- ✅ Webhooks para Tricket

### 🔄 Próximas Implementações
- 🟡 **APIs de Terminais**: CRUD completo
- 🟡 **APIs de POS Devices**: Gestão de dispositivos
- 🟡 **APIs de Planos**: Configuração de taxas
- 🟡 **Validações de negócio**: Regras de credenciamento
- 🟡 **Testes automatizados**: Coverage completo

## 🎯 Objetivos da Fase 2

### Meta Principal
Implementar **100% das APIs de credenciamento** necessárias para onboarding de merchants, mantendo compatibilidade total com a API oficial da Cappta.

### Metas Específicas
1. **Terminais**: CRUD + validações + relacionamentos
2. **POS Devices**: Gestão completa de dispositivos físicos
3. **Planos**: Sistema flexível de taxas e configurações
4. **Integração**: Fluxo completo merchant → terminal → POS
5. **Testes**: Cobertura de 90%+ das novas APIs

## 📊 Análise de APIs - Credenciamento

### API 1: **Terminals Management** 
```http
POST   /terminals              # Criar terminal
GET    /terminals              # Listar terminais
GET    /terminals/{id}         # Buscar terminal específico
PUT    /terminals/{id}         # Atualizar terminal
DELETE /terminals/{id}         # Desativar terminal
POST   /terminals/{id}/activate # Ativar terminal
```

### API 2: **POS Devices Management**
```http
POST   /terminals/{id}/pos-devices     # Associar dispositivo POS
GET    /terminals/{id}/pos-devices     # Listar dispositivos do terminal
GET    /pos-devices/{id}               # Buscar dispositivo específico
PUT    /pos-devices/{id}               # Atualizar configuração
DELETE /pos-devices/{id}               # Remover dispositivo
POST   /pos-devices/{id}/config        # Configurar parâmetros
```

### API 3: **Merchant Plans**
```http
POST   /plans                    # Criar plano de merchant
GET    /plans                    # Listar planos
GET    /plans/{id}               # Buscar plano específico
PUT    /plans/{id}               # Atualizar plano
DELETE /plans/{id}               # Desativar plano
POST   /merchants/{id}/plan      # Associar plano ao merchant
```

## 🏗️ Implementação Detalhada

### **2.1 - APIs de Terminais** (Prioridade: ALTA)

#### Estrutura de Dados
```python
# Já implementado no banco:
class TerminalDB(Base):
    terminal_id: str (PK)
    merchant_id: str (FK)
    serial_number: str (unique)
    brand_acceptance: JSON  # ["visa", "mastercard", "elo"]
    capture_mode: str       # "smartpos", "manual"
    status: TerminalStatus  # ACTIVE, INACTIVE, SUSPENDED
    terminal_metadata: JSON
```

#### Endpoints a Implementar
1. **POST /terminals** - Criar terminal
   - Validação de serial number único
   - Associação automática ao merchant do reseller
   - Configuração padrão de bandeiras aceitas

2. **GET /terminals** - Listar terminais
   - Filtros: merchant_id, status, serial_number
   - Paginação: skip/limit
   - Ordenação: created_at desc

3. **GET /terminals/{id}** - Buscar terminal
   - Incluir relacionamentos (merchant, pos_devices)
   - Dados de transações (últimas N transações)

4. **PUT /terminals/{id}** - Atualizar terminal
   - Atualização parcial (PATCH semantics)
   - Validações de negócio
   - Audit log automático

5. **POST /terminals/{id}/activate** - Ativação
   - Validação de requisitos para ativação
   - Webhook de notificação
   - Log de auditoria

#### Validações de Negócio
- ✅ Serial number único no sistema
- ✅ Merchant deve existir e estar ativo
- ✅ Brand acceptance não pode estar vazia
- ✅ Terminal não pode ter transações pendentes para desativação

#### Modelos Pydantic
```python
class TerminalCreate(BaseModel):
    serial_number: str = Field(..., min_length=10, max_length=50)
    brand_acceptance: List[CardBrand]
    capture_mode: str = "smartpos"
    terminal_metadata: Optional[Dict[str, Any]] = None

class TerminalResponse(BaseModel):
    terminal_id: str
    merchant_id: str
    serial_number: str
    brand_acceptance: List[str]
    status: TerminalStatus
    pos_devices_count: int = 0
    created_at: datetime
```

### **2.2 - APIs de Dispositivos POS** (Prioridade: ALTA)

#### Endpoints a Implementar
1. **POST /terminals/{terminal_id}/pos-devices**
   - Associar dispositivo físico ao terminal
   - Configuração inicial automática
   - Validação de compatibilidade

2. **GET /terminals/{terminal_id}/pos-devices**
   - Listar dispositivos do terminal
   - Status de cada dispositivo
   - Configurações ativas

3. **PUT /pos-devices/{id}/config**
   - Atualizar parâmetros de configuração
   - Validação de configurações
   - Versionamento de configs

#### Modelos Pydantic
```python
class POSDeviceCreate(BaseModel):
    device_type: str = "smartpos"
    model: str
    firmware_version: Optional[str]
    configuration: Dict[str, Any]

class POSDeviceResponse(BaseModel):
    device_id: str
    terminal_id: str
    device_type: str
    model: str
    status: TerminalStatus
    configuration: Dict[str, Any]
    last_activity: Optional[datetime]
```

### **2.3 - APIs de Planos de Merchant** (Prioridade: MÉDIA)

#### Endpoints a Implementar
1. **POST /plans** - Criar plano personalizado
2. **GET /plans** - Listar planos disponíveis
3. **PUT /plans/{id}** - Atualizar estrutura de taxas
4. **POST /merchants/{id}/plan** - Associar plano

#### Estrutura de Taxas
```python
class FeeStructure(BaseModel):
    credit: Dict[str, Union[float, int]]  # {"percentage": 3.0, "fixed": 30}
    debit: Dict[str, Union[float, int]]   # {"percentage": 2.0, "fixed": 20}
    pix: Dict[str, Union[float, int]]     # {"percentage": 0.0, "fixed": 10}
    installment_fee: Dict[str, float]     # {"percentage": 0.5}

class MerchantPlanCreate(BaseModel):
    plan_name: str
    description: Optional[str]
    fee_structure: FeeStructure
    is_default: bool = False
```

## 🧪 Testes e Validação

### Estratégia de Testes
1. **Unit Tests**: Cada endpoint individual
2. **Integration Tests**: Fluxo completo de credenciamento
3. **Load Tests**: Performance com múltiplos terminais
4. **Contract Tests**: Compatibilidade com Edge Functions

### Cenários de Teste Críticos
1. **Fluxo Completo**:
   - Criar reseller → merchant → terminal → POS device
   - Validar relacionamentos e constraints
   - Testar ativação/desativação

2. **Validações de Negócio**:
   - Serial numbers únicos
   - Limites de terminais por merchant
   - Configurações de POS válidas

3. **Performance**:
   - 1000+ terminais por reseller
   - Consultas com filtros complexos
   - Bulk operations

## 📅 Cronograma de Desenvolvimento

### Semana 1: Terminais (3-4 dias)
- **Dia 1**: Implementar endpoints CRUD básicos
- **Dia 2**: Validações de negócio e testes
- **Dia 3**: Integração com merchants e audit
- **Dia 4**: Testes e refinamentos

### Semana 1: POS Devices (2-3 dias) 
- **Dia 5**: Endpoints de POS devices
- **Dia 6**: Sistema de configuração
- **Dia 7**: Testes e integração

### Semana 2: Planos (2 dias)
- **Dia 8**: APIs de planos
- **Dia 9**: Associação merchant-plano

### Semana 2: Testes e Finalização (2 dias)
- **Dia 10**: Testes integrados e load testing
- **Dia 11**: Documentação e deploy

## 🚀 Entregáveis da Fase 2

### Código
- ✅ **15+ endpoints** novos de credenciamento
- ✅ **Validações de negócio** robustas
- ✅ **Modelos Pydantic** para todas as operações
- ✅ **Testes automatizados** com 90%+ cobertura

### Documentação
- ✅ **API Documentation** (OpenAPI/Swagger)
- ✅ **Changelog detalhado** da Fase 2
- ✅ **Guia de integração** para Edge Functions
- ✅ **Exemplos de uso** práticos

### Infraestrutura
- ✅ **Migrations** para novas funcionalidades
- ✅ **Seed data** com exemplos de terminais/POS
- ✅ **Monitoring** e health checks
- ✅ **Deploy automatizado** no dev2

## 📊 Métricas de Sucesso

### Funcionais
- ✅ **100% das APIs** de credenciamento implementadas
- ✅ **90%+ cobertura** de testes automatizados
- ✅ **Zero breaking changes** nas APIs existentes
- ✅ **Compatibilidade total** com API oficial

### Performance
- ✅ **<200ms** response time médio
- ✅ **1000+ terminais** por reseller suportados
- ✅ **Rate limiting** funcional (1000 req/min)
- ✅ **99.9% uptime** no ambiente dev2

### Qualidade
- ✅ **Validações robustas** de dados
- ✅ **Error handling** consistente
- ✅ **Audit logging** completo
- ✅ **Security** mantida (autenticação/autorização)

## 🔗 Integração com Fase 1

### Aproveitamento da Infraestrutura
- ✅ **Sistema de resellers** existente
- ✅ **Middleware de autenticação** funcional
- ✅ **Banco de dados** já estruturado
- ✅ **Logging e monitoring** estabelecidos

### Expansão Incremental
- ✅ **Novos endpoints** usando padrões existentes
- ✅ **Modelos de banco** já definidos e relacionados
- ✅ **Sistemas de webhook** prontos para expansão
- ✅ **Deploy pipeline** já configurado

## 🎯 Resultado Esperado

Ao final da Fase 2, teremos:

1. **Sistema de Credenciamento Completo**:
   - Gestão de terminais, POS devices e planos
   - APIs 100% compatíveis com estrutura oficial
   - Validações de negócio robustas

2. **Experiência de Desenvolvimento**:
   - Edge Functions podem consumir todas as APIs
   - Processo de onboarding de merchants automatizável
   - Testing e debugging facilitados

3. **Preparação para Produção**:
   - Performance validada em ambiente dev2
   - Monitoring e alertas configurados
   - Documentação completa para migração

---

**Próximo Passo**: Iniciar implementação dos endpoints de Terminais (2.1)  
**Estimativa Total**: 10-12 dias de desenvolvimento  
**Branch**: feat/cappta-fase2-apis-credenciamento