# Cappta Simulator - Deployment Guide

## Resumo da Configuração

O Cappta Simulator será deployado no ambiente **dev2** com o subdomínio `simulador-cappta.kabran.com.br`.

### Arquitetura
```
Internet → Cloudflare → Traefik (dev2) → Cappta Simulator Container
```

## Files Criados para Deploy

### 1. **Traefik Provider** (`providers/cappta-simulator.yml`)
- Configuração de roteamento para o subdomínio
- CORS, headers de segurança e rate limiting
- Redirecionamento HTTP → HTTPS automático
- Health checks integrados

### 2. **Docker Compose Produção** (`docker-compose.prod.yml`)
- Configuração otimizada para ambiente de produção
- Volumes persistentes para dados e logs
- Health checks e restart policies
- Redes isoladas para segurança

### 3. **Script de Deploy** (`scripts/deploy-dev2.sh`)
- Automação completa do processo de deploy
- Validação de variáveis de ambiente
- Testes de conectividade automatizados
- Geração automática de secrets seguros

### 4. **Documentação Completa** (`/tricket-vault/docs/integrations/cappta-simulator-deployment.md`)
- Instruções passo-a-passo detalhadas
- Troubleshooting e monitoramento
- Configuração do Edge Function webhook receiver

## Quick Start - Deploy no dev2

### 1. Preparação
```bash
# No servidor dev2
cd /path/to/tricket-project
git pull origin feat/cappta-simulator-expansion
```

### 2. Configurar Secrets
```bash
# Configurar variáveis de ambiente reais (IMPORTANTE!)
export CAPPTA_ASAAS_API_KEY="sua_api_key_real_aqui"
export CAPPTA_ASAAS_ACCOUNT_ID="seu_account_id_real_aqui"
```

### 3. Deploy Automatizado
```bash
# Executar script de deploy (como root/sudo)
sudo ./cappta-simulator/scripts/deploy-dev2.sh
```

### 4. Verificar Deploy
```bash
# Testar conectividade
curl -I https://simulador-cappta.kabran.com.br/
curl https://simulador-cappta.kabran.com.br/health/ready
```

## Configurações Necessárias

### DNS (Cloudflare)
```
Type: CNAME
Name: simulador-cappta
Content: [endpoint-do-tunnel-dev2]
Proxy: Enabled
```

### Variáveis de Ambiente Obrigatórias
```bash
# Geradas automaticamente pelo script
CAPPTA_API_TOKEN=              # Token para autenticação API
CAPPTA_WEBHOOK_SECRET=         # Secret para webhooks Tricket
CAPPTA_WEBHOOK_SIGNATURE_SECRET= # Secret para assinatura HMAC

# DEVEM ser configuradas manualmente
CAPPTA_ASAAS_API_KEY=          # API key da conta Asaas do simulador
CAPPTA_ASAAS_ACCOUNT_ID=       # Account ID da conta Asaas do simulador
```

## URLs de Acesso

### Produção (dev2)
- **API Base**: `https://simulador-cappta.kabran.com.br`
- **Health Check**: `https://simulador-cappta.kabran.com.br/health/ready`
- **API Docs**: `https://simulador-cappta.kabran.com.br/docs` (se DEBUG=true)

### Webhooks
- **Tricket Receiver**: `https://dev2.tricket.kabran.com.br/functions/v1/cappta_webhook_receiver`

## Comandos Úteis

### Gerenciamento do Serviço
```bash
# Ver logs em tempo real
sudo docker-compose -f docker-compose.prod.yml logs -f cappta-simulator

# Status do serviço
sudo ./scripts/deploy-dev2.sh --status

# Restart do serviço
sudo ./scripts/deploy-dev2.sh --restart

# Rebuild completo
sudo ./scripts/deploy-dev2.sh --build
```

### Testes
```bash
# Health check básico
curl https://simulador-cappta.kabran.com.br/health/ready

# Teste com autenticação
curl -H "Authorization: Bearer $CAPPTA_API_TOKEN" \
     https://simulador-cappta.kabran.com.br/health

# Teste de CORS
curl -H "Origin: https://dev2.tricket.kabran.com.br" \
     -X OPTIONS \
     https://simulador-cappta.kabran.com.br/merchants
```

## Monitoramento

### Health Checks Disponíveis
- **Liveness**: `/health/live` - Container está rodando
- **Readiness**: `/health/ready` - Serviço pronto para receber requests
- **Detailed**: `/health` - Status detalhado de componentes

### Logs
- **Aplicação**: `docker logs cappta-simulator`
- **Traefik**: `docker logs traefik | grep cappta`

### Métricas
- **Prometheus**: `/metrics` (se habilitado)
- **Rate Limiting**: Headers `X-RateLimit-*` nas responses

## Troubleshooting

### Problemas Comuns

1. **Container não sobe**
   ```bash
   # Verificar logs
   docker logs captta-simulator
   
   # Verificar variáveis de ambiente
   docker exec captta-simulator env | grep CAPPTA
   ```

2. **Traefik não roteia**
   ```bash
   # Verificar provider carregado
   docker exec traefik cat /etc/traefik/providers/cappta-simulator.yml
   
   # Verificar logs do Traefik
   docker logs traefik | grep cappta
   ```

3. **Health check falha**
   ```bash
   # Testar internamente
   docker exec cappta-simulator curl -f http://localhost:8000/health/ready
   
   # Verificar banco de dados
   docker exec cappta-simulator ls -la /app/data/
   ```

## Segurança

### Headers Configurados
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security`
- `Content-Security-Policy`

### Rate Limiting
- **Traefik**: 100 req/min (burst 200)
- **Aplicação**: 1000 req/min (configurável)

### CORS
- Origens permitidas: `dev2.tricket.kabran.com.br`, `simulador-cappta.kabran.com.br`
- Headers expostos: `X-Request-ID`, `X-Processing-Time`, `X-RateLimit-*`

## Backup

### Dados Persistentes
- **Database**: `/opt/cappta-simulator/data/cappta_simulator_prod.db`
- **Logs**: `/opt/cappta-simulator/logs/`

### Backup Automático
```bash
# Backup manual
sudo tar -czf cappta-backup-$(date +%Y%m%d).tar.gz \
    /opt/cappta-simulator/data/

# Restore
sudo tar -xzf cappta-backup-YYYYMMDD.tar.gz -C /
```

---

## Próximos Passos Após Deploy

1. ✅ Configurar DNS no Cloudflare
2. ✅ Verificar conectividade externa
3. ✅ Configurar webhook receiver no Supabase
4. ✅ Testar fluxo completo de webhook
5. ✅ Monitorar logs e métricas
6. ✅ Implementar Fase 2 (APIs de Credenciamento)

---

**Importante**: Lembrar de substituir `CAPPTA_ASAAS_API_KEY` e `CAPPTA_ASAAS_ACCOUNT_ID` pelos valores reais da conta Asaas antes do deploy!