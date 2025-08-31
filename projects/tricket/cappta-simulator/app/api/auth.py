from fastapi import APIRouter, HTTPException, Security, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional
import ipaddress
from starlette.requests import Request

from config.settings import settings
from app.models.common import BaseResponse

router = APIRouter()

security = HTTPBearer()

async def verify_token_and_ip(
    request: Request,
    credentials: HTTPAuthorizationCredentials = Security(security)
) -> str:
    """Verifica token de autorização e IP permitido"""
    
    # Verifica token
    if credentials.credentials != settings.API_TOKEN:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verifica IP (apenas em desenvolvimento)
    if settings.ENVIRONMENT.value == "dev":
        client_ip = get_client_ip(request)
        if not is_ip_allowed(client_ip):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"IP {client_ip} not allowed"
            )
    
    return credentials.credentials

def get_client_ip(request: Request) -> str:
    """Extrai IP do cliente da requisição"""
    
    # Verifica headers de proxy
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    
    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip
    
    # IP direto
    client_host = request.client.host if request.client else "unknown"
    return client_host

def is_ip_allowed(ip: str) -> bool:
    """Verifica se o IP está na lista de IPs permitidos"""
    
    if not ip or ip == "unknown":
        return False
    
    # Normaliza IPs locais
    if ip in ["127.0.0.1", "localhost", "::1", "0.0.0.0"]:
        return "localhost" in settings.ALLOWED_IPS or "127.0.0.1" in settings.ALLOWED_IPS
    
    try:
        client_ip = ipaddress.ip_address(ip)
        
        for allowed_ip in settings.ALLOWED_IPS:
            try:
                # Verifica se é uma rede ou IP específico
                if "/" in allowed_ip:
                    if client_ip in ipaddress.ip_network(allowed_ip, strict=False):
                        return True
                else:
                    if client_ip == ipaddress.ip_address(allowed_ip):
                        return True
            except ValueError:
                # Permite comparação de strings para casos especiais
                if ip == allowed_ip:
                    return True
        
        return False
        
    except ValueError:
        # IP inválido
        return False


@router.post("/validate", response_model=BaseResponse)
async def validate_token(
    request: Request,
    token: str = Depends(verify_token_and_ip)
):
    """Endpoint para validar token de autenticação"""
    client_ip = get_client_ip(request)
    
    return BaseResponse(
        success=True,
        message=f"Token valid for IP {client_ip}"
    )