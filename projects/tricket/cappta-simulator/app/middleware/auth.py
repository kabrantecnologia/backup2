from fastapi import HTTPException, Request, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Dict, List, Optional, Set
import time
import hashlib
from datetime import datetime, timedelta
from config.settings import settings
from config.logging import get_logger

logger = get_logger(__name__)

class TokenManager:
    """
    Manages authentication tokens with expiry and client tracking
    """
    
    def __init__(self):
        self.tokens: Dict[str, Dict] = {}
        self.client_tokens: Dict[str, Set[str]] = {}
        
        # Add default admin token
        self._add_default_tokens()
    
    def _add_default_tokens(self):
        """Add default tokens for development"""
        admin_token = settings.API_TOKEN
        self.tokens[admin_token] = {
            "client_id": "admin",
            "created_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + timedelta(hours=settings.TOKEN_EXPIRY_HOURS),
            "permissions": ["all"],
            "last_used": datetime.utcnow(),
            "usage_count": 0
        }
        
        if "admin" not in self.client_tokens:
            self.client_tokens["admin"] = set()
        self.client_tokens["admin"].add(admin_token)
    
    def create_token(self, client_id: str, permissions: List[str] = None) -> str:
        """
        Create a new token for a client
        
        Args:
            client_id: Unique client identifier
            permissions: List of permissions for this token
            
        Returns:
            Generated token string
        """
        if permissions is None:
            permissions = ["read", "write"]
        
        # Generate token based on client_id and timestamp
        timestamp = str(time.time())
        token_data = f"{client_id}:{timestamp}:{settings.WEBHOOK_SIGNATURE_SECRET}"
        token = hashlib.sha256(token_data.encode()).hexdigest()[:32]
        
        # Store token info
        self.tokens[token] = {
            "client_id": client_id,
            "created_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + timedelta(hours=settings.TOKEN_EXPIRY_HOURS),
            "permissions": permissions,
            "last_used": datetime.utcnow(),
            "usage_count": 0
        }
        
        # Track client tokens
        if client_id not in self.client_tokens:
            self.client_tokens[client_id] = set()
        self.client_tokens[client_id].add(token)
        
        logger.info(f"Created new token for client: {client_id}", extra={"client_id": client_id})
        return token
    
    def validate_token(self, token: str) -> Optional[Dict]:
        """
        Validate a token and return client info
        
        Args:
            token: Token to validate
            
        Returns:
            Client info if valid, None if invalid
        """
        if token not in self.tokens:
            logger.warning(f"Invalid token used: {token[:8]}...", extra={"token_prefix": token[:8]})
            return None
        
        token_info = self.tokens[token]
        
        # Check if token expired
        if datetime.utcnow() > token_info["expires_at"]:
            logger.warning(f"Expired token used: {token[:8]}...", extra={
                "token_prefix": token[:8],
                "client_id": token_info["client_id"]
            })
            self.revoke_token(token)
            return None
        
        # Update usage
        token_info["last_used"] = datetime.utcnow()
        token_info["usage_count"] += 1
        
        return token_info
    
    def revoke_token(self, token: str) -> bool:
        """
        Revoke a specific token
        
        Args:
            token: Token to revoke
            
        Returns:
            True if revoked, False if not found
        """
        if token not in self.tokens:
            return False
        
        token_info = self.tokens[token]
        client_id = token_info["client_id"]
        
        # Remove from tokens
        del self.tokens[token]
        
        # Remove from client tracking
        if client_id in self.client_tokens:
            self.client_tokens[client_id].discard(token)
            if not self.client_tokens[client_id]:
                del self.client_tokens[client_id]
        
        logger.info(f"Token revoked for client: {client_id}", extra={"client_id": client_id})
        return True
    
    def revoke_client_tokens(self, client_id: str) -> int:
        """
        Revoke all tokens for a specific client
        
        Args:
            client_id: Client whose tokens to revoke
            
        Returns:
            Number of tokens revoked
        """
        if client_id not in self.client_tokens:
            return 0
        
        tokens_to_revoke = list(self.client_tokens[client_id])
        revoked_count = 0
        
        for token in tokens_to_revoke:
            if self.revoke_token(token):
                revoked_count += 1
        
        logger.info(f"Revoked {revoked_count} tokens for client: {client_id}", extra={
            "client_id": client_id,
            "revoked_count": revoked_count
        })
        return revoked_count
    
    def cleanup_expired_tokens(self) -> int:
        """
        Clean up all expired tokens
        
        Returns:
            Number of tokens cleaned up
        """
        now = datetime.utcnow()
        expired_tokens = [
            token for token, info in self.tokens.items()
            if now > info["expires_at"]
        ]
        
        for token in expired_tokens:
            self.revoke_token(token)
        
        if expired_tokens:
            logger.info(f"Cleaned up {len(expired_tokens)} expired tokens")
        
        return len(expired_tokens)
    
    def get_client_info(self, client_id: str) -> Optional[Dict]:
        """
        Get information about a client's tokens
        
        Args:
            client_id: Client ID to lookup
            
        Returns:
            Client token information
        """
        if client_id not in self.client_tokens:
            return None
        
        client_tokens = self.client_tokens[client_id]
        active_tokens = []
        
        for token in client_tokens:
            if token in self.tokens:
                token_info = self.tokens[token]
                active_tokens.append({
                    "token": token[:8] + "...",
                    "created_at": token_info["created_at"].isoformat(),
                    "expires_at": token_info["expires_at"].isoformat(),
                    "last_used": token_info["last_used"].isoformat(),
                    "usage_count": token_info["usage_count"],
                    "permissions": token_info["permissions"]
                })
        
        return {
            "client_id": client_id,
            "active_tokens": len(active_tokens),
            "tokens": active_tokens
        }


# Global token manager instance
token_manager = TokenManager()


class AuthBearer(HTTPBearer):
    """
    Custom HTTP Bearer authentication
    """
    
    def __init__(self, auto_error: bool = True):
        super().__init__(auto_error=auto_error)
    
    async def __call__(self, request: Request) -> Optional[str]:
        credentials: HTTPAuthorizationCredentials = await super().__call__(request)
        
        if not credentials:
            if self.auto_error:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Authorization header required"
                )
            return None
        
        if credentials.scheme.lower() != "bearer":
            if self.auto_error:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid authentication scheme"
                )
            return None
        
        token_info = token_manager.validate_token(credentials.credentials)
        if not token_info:
            if self.auto_error:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired token"
                )
            return None
        
        # Add client info to request state
        request.state.client_id = token_info["client_id"]
        request.state.permissions = token_info["permissions"]
        request.state.token_info = token_info
        
        return credentials.credentials


def check_permission(required_permission: str):
    """
    Decorator to check if client has required permission
    
    Args:
        required_permission: Permission required to access endpoint
    """
    def decorator(func):
        async def wrapper(request: Request, *args, **kwargs):
            if not hasattr(request.state, "permissions"):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Authentication required"
                )
            
            permissions = request.state.permissions
            if "all" not in permissions and required_permission not in permissions:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Permission '{required_permission}' required"
                )
            
            return await func(request, *args, **kwargs)
        return wrapper
    return decorator


# Dependency for authentication
auth_bearer = AuthBearer()