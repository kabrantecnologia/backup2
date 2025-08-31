# Deployment do Cappta Simulator - Ambiente dev2

**Objetivo**: Configurar o subdomínio `simulador-cappta.kabran.com.br` para rotear tráfego para o Cappta Simulator no ambiente dev2.

## Visão Geral da Arquitetura

```
Internet → Cloudflare → Traefik (dev2) → Cappta Simulator Container
```

### Fluxo de Requisições
1. **DNS**: `simulador-cappta.kabran.com.br` → Cloudflare
2. **Tunnel**: Cloudflare Tunnel → Traefik (porta 80/443)
3. **Routing**: Traefik → Cappta Simulator (porta 8000)
4. **Response**: Simulator → Cliente via caminho inverso

## Configuração Required

### 1. Provider Traefik para o Cappta Simulator

Criar arquivo: `/providers/cappta-simulator.yml`

```yaml
# Cappta Simulator Provider for Traefik
# File: /providers/cappta-simulator.yml

http:
  services:
    cappta-simulator:
      loadBalancer:
        servers:
          - url: "http://cappta-simulator:8000"
        healthCheck:
          path: "/health/ready"
          interval: "30s"
          timeout: "5s"
          
  routers:
    cappta-simulator:
      rule: "Host(`simulador-cappta.kabran.com.br`)"
      service: cappta-simulator
      entryPoints:
        - websecure
      tls:
        certResolver: cloudflare
      middlewares:
        - cappta-cors
        - cappta-headers
        - cappta-ratelimit
        
    cappta-simulator-http:
      rule: "Host(`simulador-cappta.kabran.com.br`)"
      service: cappta-simulator
      entryPoints:
        - web
      middlewares:
        - https-redirect

  middlewares:
    cappta-cors:
      headers:
        accessControlAllowOriginList:
          - "https://dev2.tricket.kabran.com.br"
          - "https://simulador-cappta.kabran.com.br"
        accessControlAllowMethods:
          - "GET"
          - "POST"
          - "PUT"
          - "DELETE"
          - "PATCH"
          - "OPTIONS"
        accessControlAllowHeaders:
          - "Content-Type"
          - "Authorization"
          - "X-Requested-With"
          - "X-Request-ID"
        accessControlExposeHeaders:
          - "X-Request-ID"
          - "X-Processing-Time"
          - "X-RateLimit-Limit"
          - "X-RateLimit-Remaining"
          - "X-RateLimit-Reset"
        accessControlMaxAge: 86400
        
    cappta-headers:
      headers:
        customRequestHeaders:
          X-Forwarded-Proto: "https"
          X-Forwarded-Host: "simulador-cappta.kabran.com.br"
        customResponseHeaders:
          X-Content-Type-Options: "nosniff"
          X-Frame-Options: "DENY"
          X-XSS-Protection: "1; mode=block"
          Referrer-Policy: "strict-origin-when-cross-origin"
          
    cappta-ratelimit:
      rateLimit:
        average: 100
        burst: 200
        period: "1m"
        
    https-redirect:
      redirectScheme:
        scheme: https
        permanent: true
```

### 2. Docker Compose para o Cappta Simulator

Criar/atualizar: `docker-compose.cappta.yml`

```yaml
# Docker Compose for Cappta Simulator
# File: docker-compose.cappta.yml

version: '3.8'

services:
  cappta-simulator:
    build:
      context: ./cappta-simulator
      dockerfile: Dockerfile
    container_name: cappta-simulator
    restart: unless-stopped
    environment:
      # Environment Configuration
      - ENVIRONMENT=production
      - DEBUG=false
      - LOG_LEVEL=info
      
      # API Configuration
      - API_HOST=0.0.0.0
      - API_PORT=8000
      - BASE_URL=https://simulador-cappta.kabran.com.br
      
      # Authentication & Security
      - API_TOKEN=${CAPPTA_API_TOKEN}
      - ALLOWED_IPS=["0.0.0.0/0"]
      - TOKEN_EXPIRY_HOURS=24
      
      # Rate Limiting
      - RATE_LIMIT_REQUESTS_PER_MINUTE=1000
      - RATE_LIMIT_BURST=100
      - RATE_LIMIT_ENABLED=true
      
      # Asaas Integration
      - ASAAS_API_KEY=${CAPPTA_ASAAS_API_KEY}
      - ASAAS_BASE_URL=https://sandbox.asaas.com/api/v3
      - CAPPTA_MASTER_ACCOUNT_ID=${CAPPTA_ASAAS_ACCOUNT_ID}
      
      # Tricket Integration
      - TRICKET_WEBHOOK_URL=https://dev2.tricket.kabran.com.br/functions/v1/cappta_webhook_receiver
      - TRICKET_WEBHOOK_SECRET=${CAPPTA_WEBHOOK_SECRET}
      - TRICKET_API_BASE=https://dev2.tricket.kabran.com.br
      
      # Webhook System
      - WEBHOOK_SIGNATURE_SECRET=${CAPPTA_WEBHOOK_SIGNATURE_SECRET}
      - WEBHOOK_TIMEOUT=30
      - WEBHOOK_RETRY_ATTEMPTS=5
      - WEBHOOK_RETRY_DELAY=60
      
      # Database
      - DATABASE_URL=sqlite:///./data/cappta_simulator_prod.db
      - DATABASE_POOL_SIZE=20
      - DATABASE_ECHO=false
      
      # Monitoring
      - PROMETHEUS_ENABLED=true
      - HEALTH_CHECK_INTERVAL=30
      
    ports:
      - "8000:8000"
    volumes:
      - cappta-data:/app/data
      - cappta-logs:/app/logs
    networks:
      - traefik-network
      - cappta-internal
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health/ready"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik-network"
      - "traefik.http.services.cappta-simulator.loadbalancer.server.port=8000"

volumes:
  cappta-data:
    driver: local
  cappta-logs:
    driver: local

networks:
  traefik-network:
    external: true
  cappta-internal:
    driver: bridge
```

### 3. Variáveis de Ambiente

Criar/atualizar arquivo `.env` no ambiente dev2:

```bash
# Cappta Simulator Environment Variables
# Add to existing .env file in dev2

# Cappta Simulator Configuration
CAPPTA_API_TOKEN=cappta_prod_token_dev2_secure_xyz
CAPPTA_WEBHOOK_SECRET=webhook_secret_prod_secure_xyz  
CAPPTA_WEBHOOK_SIGNATURE_SECRET=signature_secret_prod_secure_xyz

# Asaas Integration (SUBSTITUIR PELOS VALORES REAIS)
CAPPTA_ASAAS_API_KEY=SUBSTITUIR_PELA_API_KEY_REAL_DA_CONTA_ASAAS
CAPPTA_ASAAS_ACCOUNT_ID=SUBSTITUIR_PELO_ACCOUNT_ID_REAL_DA_CONTA_ASAAS
```

### 4. Configuração DNS (Cloudflare)

#### Verificar se já existe:
1. Acesse o painel do Cloudflare
2. Verifique se `simulador-cappta.kabran.com.br` já aponta para o tunnel do dev2

#### Se não existir, adicionar:
```
Type: CNAME
Name: simulador-cappta
Content: tunnel-dev2.kabran.com.br (ou o endpoint do tunnel)
Proxy: Enabled (nuvem laranja)
TTL: Auto
```

## Instruções de Deploy

### 1. Preparação do Ambiente

```bash
# Navegar para o diretório do projeto no dev2
cd /path/to/tricket-dev2

# Fazer pull do código
git pull origin feat/cappta-simulator-expansion

# Verificar se os arquivos foram criados
ls -la providers/
ls -la cappta-simulator/
```

### 2. Configurar Provider Traefik

```bash
# Copiar o provider para o diretório correto
cp providers/cappta-simulator.yml /path/to/traefik/providers/

# Verificar se o Traefik carregou o provider
docker logs traefik | grep cappta-simulator

# OU verificar via API do Traefik
curl -s http://localhost:8080/api/http/routers | jq '.[] | select(.rule | contains("simulador-cappta"))'
```

### 3. Configurar Secrets

```bash
# Gerar tokens seguros
CAPPTA_API_TOKEN=$(openssl rand -hex 32)
CAPPTA_WEBHOOK_SECRET=$(openssl rand -hex 32)  
CAPPTA_WEBHOOK_SIGNATURE_SECRET=$(openssl rand -hex 32)

# Adicionar ao .env (SUBSTITUIR OS VALORES ASAAS PELOS REAIS)
echo "CAPPTA_API_TOKEN=$CAPPTA_API_TOKEN" >> .env
echo "CAPPTA_WEBHOOK_SECRET=$CAPPTA_WEBHOOK_SECRET" >> .env
echo "CAPPTA_WEBHOOK_SIGNATURE_SECRET=$CAPPTA_WEBHOOK_SIGNATURE_SECRET" >> .env
echo "CAPPTA_ASAAS_API_KEY=SUBSTITUIR_PELA_API_KEY_REAL" >> .env
echo "CAPPTA_ASAAS_ACCOUNT_ID=SUBSTITUIR_PELO_ACCOUNT_ID_REAL" >> .env
```

### 4. Deploy do Simulador

```bash
# Build e deploy do container
docker-compose -f docker-compose.cappta.yml up -d --build

# Verificar logs
docker-compose -f docker-compose.cappta.yml logs -f cappta-simulator

# Verificar health check
curl -f https://simulador-cappta.kabran.com.br/health/ready
```

### 5. Testes de Conectividade

```bash
# Teste básico de conectividade
curl -I https://simulador-cappta.kabran.com.br/

# Teste com autenticação
curl -H "Authorization: Bearer $CAPPTA_API_TOKEN" \
     https://simulador-cappta.kabran.com.br/health

# Teste de CORS
curl -H "Origin: https://dev2.tricket.kabran.com.br" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Authorization,Content-Type" \
     -X OPTIONS \
     https://simulador-cappta.kabran.com.br/merchants
```

## Configuração do Edge Function Webhook Receiver

### Verificar se existe:
```bash
# Verificar se o webhook receiver já existe
curl -f https://dev2.tricket.kabran.com.br/functions/v1/cappta_webhook_receiver
```

### Se não existir, criar:
```typescript
// File: tricket-backend/volumes/functions/cappta_webhook_receiver/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-cappta-signature',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verificar assinatura do webhook
    const signature = req.headers.get('x-cappta-signature')
    const body = await req.text()
    
    // TODO: Implementar verificação HMAC
    
    const webhookData = JSON.parse(body)
    
    console.log('Cappta webhook received:', {
      event: webhookData.event,
      merchant_id: webhookData.data?.merchant_id,
      timestamp: webhookData.timestamp
    })
    
    // Processar webhook conforme o tipo de evento
    switch (webhookData.event) {
      case 'transaction.approved':
      case 'transaction.declined':
      case 'transaction.cancelled':
        // Processar eventos de transação
        break
        
      case 'settlement.completed':
      case 'settlement.failed':
        // Processar eventos de liquidação
        break
        
      default:
        console.log('Unknown webhook event:', webhookData.event)
    }

    return new Response(
      JSON.stringify({ received: true }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Webhook processing error:', error)
    return new Response(
      JSON.stringify({ error: 'Webhook processing failed' }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})
```

## Troubleshooting

### 1. Traefik não encontra o serviço

```bash
# Verificar se o provider foi carregado
docker exec traefik cat /etc/traefik/providers/cappta-simulator.yml

# Verificar logs do Traefik
docker logs traefik | grep -i cappta

# Verificar se o container está na rede correta
docker network ls
docker network inspect traefik-network
```

### 2. Problemas de SSL/TLS

```bash
# Verificar certificados
curl -vI https://simulador-cappta.kabran.com.br/

# Forçar renovação do certificado
docker exec traefik traefik version
```

### 3. Health Check falhando

```bash
# Verificar logs do container
docker logs cappta-simulator

# Testar health check diretamente
docker exec cappta-simulator curl -f http://localhost:8000/health/ready

# Verificar banco de dados
docker exec cappta-simulator ls -la /app/data/
```

### 4. Problemas de Rate Limiting

```bash
# Verificar configuração
curl -I https://simulador-cappta.kabran.com.br/
# Procurar headers: X-RateLimit-*

# Ajustar limites no provider se necessário
```

## Monitoramento

### Logs importantes:
```bash
# Traefik
docker logs traefik | grep cappta-simulator

# Cappta Simulator  
docker logs cappta-simulator

# Verificar métricas
curl https://simulador-cappta.kabran.com.br/metrics
```

### Health Checks:
- **Liveness**: `https://simulador-captta.kabran.com.br/health/live`
- **Readiness**: `https://simulador-captta.kabran.com.br/health/ready`
- **Detailed**: `https://simulador-captta.kabran.com.br/health`

### URLs de Teste:
- **Root**: `https://simulador-captta.kabran.com.br/`
- **Docs**: `https://simulador-captta.kabran.com.br/docs` (se DEBUG=true)
- **Merchants**: `https://simulador-captta.kabran.com.br/merchants`

## Próximos Passos

1. ✅ Configurar DNS no Cloudflare
2. ✅ Criar provider Traefik
3. ✅ Configurar variáveis de ambiente com secrets reais
4. ✅ Deploy do container
5. ✅ Testes de conectividade
6. ✅ Configurar webhook receiver no Supabase
7. ✅ Validar integração completa

---

**Nota**: Lembrar de substituir as variáveis `SUBSTITUIR_PELA_*` pelos valores reais da conta Asaas antes do deploy em produção.