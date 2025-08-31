from fastapi import HTTPException, Request, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional
from sqlalchemy.orm import Session

from app.database.connection import get_db_session
from app.services.reseller_service import ResellerService
from app.models.reseller import ResellerAuth, CapptaAuthContext
from config.settings import settings
from config.logging import get_logger

logger = get_logger(__name__)

security = HTTPBearer(auto_error=False)

class ResellerAuthMiddleware:
    """
    Middleware for reseller authentication compatible with official Cappta API
    """
    
    @staticmethod
    def get_reseller_from_token(
        credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
    ) -> Optional[ResellerAuth]:
        """
        Extract and validate reseller from Bearer token
        Compatible with official Cappta API authentication structure
        """
        if not credentials:
            return None
            
        token = credentials.credentials
        
        try:
            with get_db_session() as db:
                reseller_service = ResellerService(db)
                reseller_auth = reseller_service.validate_reseller_token(token)
                
                if reseller_auth:
                    logger.info("Reseller authentication successful", extra={
                        "reseller_id": reseller_auth.reseller_id,
                        "document": reseller_auth.document
                    })
                    return reseller_auth
                else:
                    logger.warning("Invalid reseller token", extra={
                        "token_prefix": token[:8] + "..." if len(token) > 8 else token
                    })
                    return None
                    
        except Exception as e:
            logger.error(f"Error validating reseller token: {str(e)}")
            return None
    
    @staticmethod
    def require_reseller_auth(
        credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
    ) -> ResellerAuth:
        """
        Require valid reseller authentication
        Raises HTTPException if authentication fails
        """
        reseller = ResellerAuthMiddleware.get_reseller_from_token(credentials)
        
        if not reseller:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or missing reseller authentication token",
                headers={"WWW-Authenticate": "Bearer"}
            )
        
        if reseller.status != "active":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Reseller account is {reseller.status}"
            )
        
        return reseller
    
    @staticmethod
    def get_cappta_auth_context(
        reseller: ResellerAuth = Depends(require_reseller_auth)
    ) -> CapptaAuthContext:
        """
        Create Cappta authentication context compatible with official API
        This provides the same structure as the official API:
        - RESELLER_DOCUMENT
        - CAPPTA_API_URL  
        - CAPPTA_API_TOKEN
        """
        return CapptaAuthContext(
            RESELLER_DOCUMENT=reseller.document,
            CAPPTA_API_URL=settings.CAPPTA_API_URL,
            CAPPTA_API_TOKEN=reseller.api_token
        )

# Dependency shortcuts for common use cases
def get_current_reseller(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> Optional[ResellerAuth]:
    """Get current reseller from token (optional)"""
    return ResellerAuthMiddleware.get_reseller_from_token(credentials)

def require_reseller(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> ResellerAuth:
    """Require reseller authentication"""
    return ResellerAuthMiddleware.require_reseller_auth(credentials)

def get_auth_context(
    reseller: ResellerAuth = Depends(require_reseller)
) -> CapptaAuthContext:
    """Get authentication context (compatible with official API)"""
    return ResellerAuthMiddleware.get_cappta_auth_context(reseller)

# Legacy compatibility - fallback to admin token if no reseller found
async def get_legacy_or_reseller_auth(
    request: Request,
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> dict:
    """
    Dual authentication: try reseller first, fallback to legacy admin token
    This ensures backward compatibility while supporting the new reseller system
    """
    if credentials:
        token = credentials.credentials
        
        # Try reseller authentication first
        reseller = ResellerAuthMiddleware.get_reseller_from_token(credentials)
        if reseller:
            return {
                "type": "reseller",
                "reseller": reseller,
                "context": CapptaAuthContext(
                    RESELLER_DOCUMENT=reseller.document,
                    CAPPTA_API_URL=settings.CAPPTA_API_URL,
                    CAPPTA_API_TOKEN=reseller.api_token
                )
            }
        
        # Fallback to legacy admin token
        if token == settings.API_TOKEN:
            logger.info("Using legacy admin token authentication")
            return {
                "type": "legacy",
                "token": token,
                "context": CapptaAuthContext(
                    RESELLER_DOCUMENT=settings.RESELLER_DOCUMENT,
                    CAPPTA_API_URL=settings.CAPPTA_API_URL,
                    CAPPTA_API_TOKEN=settings.CAPPTA_API_TOKEN
                )
            }
    
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Valid authentication required (Bearer token)",
        headers={"WWW-Authenticate": "Bearer"}
    )