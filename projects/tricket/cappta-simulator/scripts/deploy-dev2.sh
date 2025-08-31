#!/bin/bash

# Deploy Script for Cappta Simulator on dev2
# Usage: ./scripts/deploy-dev2.sh [--build|--logs|--restart|--status]

set -e

# Configuration
COMPOSE_FILE="docker-compose.prod.yml"
SERVICE_NAME="cappta-simulator"
PROVIDER_FILE="providers/cappta-simulator.yml"
TRAEFIK_PROVIDERS_DIR="/opt/traefik/providers"
DATA_DIR="/opt/cappta-simulator"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Check if running as root or with sudo
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root or with sudo"
    fi
}

# Verify required directories exist
setup_directories() {
    log "Setting up directories..."
    
    mkdir -p "$DATA_DIR/data"
    mkdir -p "$DATA_DIR/logs"
    mkdir -p "$TRAEFIK_PROVIDERS_DIR"
    
    # Set proper permissions
    chown -R 1000:1000 "$DATA_DIR"
    chmod 755 "$DATA_DIR"
    chmod 755 "$DATA_DIR/data"
    chmod 755 "$DATA_DIR/logs"
    
    success "Directories created and configured"
}

# Copy Traefik provider configuration
setup_traefik_provider() {
    log "Configuring Traefik provider..."
    
    if [[ ! -f "$PROVIDER_FILE" ]]; then
        error "Provider file not found: $PROVIDER_FILE"
    fi
    
    cp "$PROVIDER_FILE" "$TRAEFIK_PROVIDERS_DIR/"
    
    # Validate provider file
    if docker exec traefik traefik validate --configfile="/etc/traefik/providers/cappta-simulator.yml" 2>/dev/null; then
        success "Traefik provider configuration is valid"
    else
        warning "Could not validate Traefik provider (traefik container may not be running)"
    fi
}

# Check environment variables
check_environment() {
    log "Checking environment variables..."
    
    required_vars=(
        "CAPPTA_API_TOKEN"
        "CAPPTA_WEBHOOK_SECRET"
        "CAPPTA_WEBHOOK_SIGNATURE_SECRET"
        "CAPPTA_ASAAS_API_KEY"
        "CAPPTA_ASAAS_ACCOUNT_ID"
    )
    
    missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        error "Missing required environment variables: ${missing_vars[*]}"
    fi
    
    # Check for placeholder values
    if [[ "$CAPPTA_ASAAS_API_KEY" == "SUBSTITUIR_PELA_API_KEY_REAL" ]]; then
        error "CAPPTA_ASAAS_API_KEY still contains placeholder value"
    fi
    
    if [[ "$CAPPTA_ASAAS_ACCOUNT_ID" == "SUBSTITUIR_PELO_ACCOUNT_ID_REAL" ]]; then
        error "CAPPTA_ASAAS_ACCOUNT_ID still contains placeholder value"
    fi
    
    success "Environment variables are properly configured"
}

# Generate secure environment variables if they don't exist
generate_secrets() {
    log "Checking and generating secrets..."
    
    ENV_FILE=".env"
    
    # Function to generate and add secret
    add_secret() {
        local var_name="$1"
        local var_value="${!var_name}"
        
        if [[ -z "$var_value" ]]; then
            local new_value=$(openssl rand -hex 32)
            echo "${var_name}=${new_value}" >> "$ENV_FILE"
            export "${var_name}=${new_value}"
            log "Generated ${var_name}"
        fi
    }
    
    add_secret "CAPPTA_API_TOKEN"
    add_secret "CAPPTA_WEBHOOK_SECRET"
    add_secret "CAPPTA_WEBHOOK_SIGNATURE_SECRET"
    
    success "Secrets configured"
}

# Build and deploy the service
deploy_service() {
    log "Deploying Cappta Simulator..."
    
    # Pull latest images
    docker-compose -f "$COMPOSE_FILE" pull
    
    # Build and start the service
    docker-compose -f "$COMPOSE_FILE" up -d --build
    
    # Wait for service to be healthy
    log "Waiting for service to be healthy..."
    
    max_attempts=30
    attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if docker-compose -f "$COMPOSE_FILE" ps | grep -q "healthy"; then
            success "Service is healthy"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    error "Service failed to become healthy within $(($max_attempts * 2)) seconds"
}

# Test the deployment
test_deployment() {
    log "Testing deployment..."
    
    # Test local health check
    if curl -f -s http://localhost:8000/health/ready >/dev/null; then
        success "Local health check passed"
    else
        error "Local health check failed"
    fi
    
    # Test external URL (if DNS is configured)
    if curl -f -s https://simulador-cappta.kabran.com.br/health/ready >/dev/null; then
        success "External health check passed"
    else
        warning "External health check failed (DNS may not be configured yet)"
    fi
    
    # Test with authentication
    if [[ -n "$CAPPTA_API_TOKEN" ]]; then
        if curl -f -s -H "Authorization: Bearer $CAPPTA_API_TOKEN" \
               http://localhost:8000/health >/dev/null; then
            success "Authenticated health check passed"
        else
            warning "Authenticated health check failed"
        fi
    fi
}

# Show service status
show_status() {
    log "Service Status:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    echo ""
    log "Service Logs (last 10 lines):"
    docker-compose -f "$COMPOSE_FILE" logs --tail=10 "$SERVICE_NAME"
    
    echo ""
    log "Health Check:"
    curl -s http://localhost:8000/health | jq '.' 2>/dev/null || curl -s http://localhost:8000/health
}

# Show logs
show_logs() {
    docker-compose -f "$COMPOSE_FILE" logs -f "$SERVICE_NAME"
}

# Restart service
restart_service() {
    log "Restarting Cappta Simulator..."
    docker-compose -f "$COMPOSE_FILE" restart "$SERVICE_NAME"
    success "Service restarted"
}

# Main deployment function
main_deploy() {
    log "Starting Cappta Simulator deployment on dev2..."
    
    check_permissions
    setup_directories
    generate_secrets
    check_environment
    setup_traefik_provider
    deploy_service
    test_deployment
    
    success "Deployment completed successfully!"
    
    echo ""
    log "Service Information:"
    echo "- Container: $SERVICE_NAME"
    echo "- Local URL: http://localhost:8000"
    echo "- External URL: https://simulador-cappta.kabran.com.br"
    echo "- Health Check: https://simulador-cappta.kabran.com.br/health/ready"
    echo "- API Docs: https://simulador-cappta.kabran.com.br/docs (if DEBUG=true)"
    
    echo ""
    log "Useful Commands:"
    echo "- View logs: docker-compose -f $COMPOSE_FILE logs -f $SERVICE_NAME"
    echo "- Check status: docker-compose -f $COMPOSE_FILE ps"
    echo "- Restart: docker-compose -f $COMPOSE_FILE restart $SERVICE_NAME"
    echo "- Stop: docker-compose -f $COMPOSE_FILE down"
}

# Parse command line arguments
case "${1:-}" in
    --build|build)
        log "Building and deploying..."
        main_deploy
        ;;
    --logs|logs)
        show_logs
        ;;
    --restart|restart)
        restart_service
        ;;
    --status|status)
        show_status
        ;;
    --help|help|-h)
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  build     Build and deploy the service (default)"
        echo "  logs      Show service logs"
        echo "  restart   Restart the service"
        echo "  status    Show service status"
        echo "  help      Show this help message"
        ;;
    "")
        main_deploy
        ;;
    *)
        error "Unknown command: $1. Use --help for usage information."
        ;;
esac