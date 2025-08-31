from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime
import psutil
import os

from app.database.connection import test_connection
from app.services.asaas_client import AsaasClient
from config.settings import settings

router = APIRouter()

@router.get("/")
async def health_check():
    """Health check básico da API"""
    return {
        "status": "healthy",
        "service": "Cappta Fake Simulator",
        "version": settings.API_VERSION,
        "timestamp": datetime.now().isoformat(),
        "environment": settings.ENVIRONMENT.value
    }

@router.get("/detailed")
async def detailed_health_check():
    """Health check detalhado com verificações de dependências"""
    
    health_data = {
        "status": "healthy",
        "service": "Cappta Fake Simulator",
        "version": settings.API_VERSION,
        "timestamp": datetime.now().isoformat(),
        "environment": settings.ENVIRONMENT.value,
        "checks": {}
    }
    
    overall_healthy = True
    
    # Verifica conexão com banco de dados
    try:
        db_healthy = test_connection()
        health_data["checks"]["database"] = {
            "status": "healthy" if db_healthy else "unhealthy",
            "details": "SQLite connection test"
        }
        if not db_healthy:
            overall_healthy = False
    except Exception as e:
        health_data["checks"]["database"] = {
            "status": "unhealthy",
            "details": f"Database error: {str(e)}"
        }
        overall_healthy = False
    
    # Verifica conectividade com Asaas (se configurado)
    try:
        if settings.ASAAS_API_KEY and settings.ASAAS_API_KEY != "sandbox_key_change_me":
            asaas_client = AsaasClient()
            # Teste simples de conectividade (sem fazer chamada real)
            health_data["checks"]["asaas"] = {
                "status": "configured",
                "details": f"Asaas client configured for {settings.ASAAS_BASE_URL}"
            }
        else:
            health_data["checks"]["asaas"] = {
                "status": "not_configured",
                "details": "Asaas API key not configured"
            }
    except Exception as e:
        health_data["checks"]["asaas"] = {
            "status": "error",
            "details": f"Asaas client error: {str(e)}"
        }
    
    # Verifica configuração do webhook
    health_data["checks"]["webhook"] = {
        "status": "configured" if settings.TRICKET_WEBHOOK_URL else "not_configured",
        "details": f"Webhook URL: {settings.TRICKET_WEBHOOK_URL}"
    }
    
    # Informações do sistema
    try:
        health_data["system"] = {
            "cpu_percent": psutil.cpu_percent(interval=1),
            "memory_percent": psutil.virtual_memory().percent,
            "disk_percent": psutil.disk_usage('/').percent,
            "process_id": os.getpid()
        }
    except Exception as e:
        health_data["system"] = {
            "error": f"Unable to get system info: {str(e)}"
        }
    
    # Status geral
    health_data["status"] = "healthy" if overall_healthy else "unhealthy"
    
    if not overall_healthy:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=health_data
        )
    
    return health_data

@router.get("/ready")
async def readiness_check():
    """Verifica se o serviço está pronto para receber tráfego"""
    
    # Verifica dependências críticas
    checks = []
    
    # Database
    try:
        if test_connection():
            checks.append({"name": "database", "status": "ready"})
        else:
            checks.append({"name": "database", "status": "not_ready"})
    except Exception as e:
        checks.append({"name": "database", "status": "error", "error": str(e)})
    
    # Configurações essenciais
    config_ok = bool(
        settings.API_TOKEN and 
        settings.API_TOKEN != "cappta_simulator_token_dev_change_me"
    )
    checks.append({
        "name": "configuration", 
        "status": "ready" if config_ok else "not_ready"
    })
    
    all_ready = all(check["status"] == "ready" for check in checks)
    
    response_data = {
        "ready": all_ready,
        "checks": checks,
        "timestamp": datetime.now().isoformat()
    }
    
    if not all_ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=response_data
        )
    
    return response_data

@router.get("/live")
async def liveness_check():
    """Verifica se o serviço está vivo (para k8s liveness probe)"""
    return {
        "alive": True,
        "timestamp": datetime.now().isoformat()
    }