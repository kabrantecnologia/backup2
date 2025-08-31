from fastapi import Request, Response
import time
import uuid
from typing import Dict, Any
from config.logging import ContextLogger

logger = ContextLogger(__name__)


class AuditMiddleware:
    """
    Middleware for request/response auditing
    """
    
    def __init__(self):
        self.start_times: Dict[str, float] = {}
    
    async def __call__(self, request: Request, call_next) -> Response:
        """
        Process request and response for auditing
        
        Args:
            request: FastAPI request
            call_next: Next middleware/endpoint
            
        Returns:
            Response with audit logging
        """
        # Generate unique request ID
        request_id = str(uuid.uuid4())[:8]
        request.state.request_id = request_id
        
        # Set logging context
        logger.set_context(request_id=request_id)
        
        # Get client info
        client_id = getattr(request.state, "client_id", "anonymous")
        client_ip = request.client.host if request.client else "unknown"
        
        # Record request start
        start_time = time.time()
        self.start_times[request_id] = start_time
        
        # Log request
        request_info = {
            "method": request.method,
            "url": str(request.url),
            "path": request.url.path,
            "query_params": dict(request.query_params),
            "headers": {
                key: value for key, value in request.headers.items()
                if key.lower() not in ["authorization", "x-api-key"]
            },
            "client_ip": client_ip,
            "client_id": client_id,
            "user_agent": request.headers.get("user-agent", "unknown")
        }
        
        logger.info("Request started", extra={
            "event_type": "request_started",
            "client_id": client_id,
            "client_ip": client_ip,
            **request_info
        })
        
        try:
            # Process request
            response = await call_next(request)
            
            # Calculate processing time
            processing_time = time.time() - start_time
            
            # Log successful response
            response_info = {
                "status_code": response.status_code,
                "processing_time_ms": round(processing_time * 1000, 2),
                "response_headers": {
                    key: value for key, value in response.headers.items()
                    if key.lower() not in ["set-cookie"]
                }
            }
            
            log_level = "info" if response.status_code < 400 else "warning"
            getattr(logger, log_level)("Request completed", extra={
                "event_type": "request_completed",
                "client_id": client_id,
                "client_ip": client_ip,
                **request_info,
                **response_info
            })
            
            # Add audit headers to response
            response.headers["X-Request-ID"] = request_id
            response.headers["X-Processing-Time"] = str(response_info["processing_time_ms"])
            
            return response
            
        except Exception as exc:
            # Calculate processing time for failed requests
            processing_time = time.time() - start_time
            
            # Log error
            logger.error("Request failed", extra={
                "event_type": "request_failed",
                "client_id": client_id,
                "client_ip": client_ip,
                "processing_time_ms": round(processing_time * 1000, 2),
                "error": str(exc),
                "error_type": type(exc).__name__,
                **request_info
            })
            
            raise
        
        finally:
            # Clean up
            self.start_times.pop(request_id, None)
            logger.clear_context()


# Global audit middleware instance
audit_middleware = AuditMiddleware()


def log_business_event(
    event_type: str,
    entity_type: str,
    entity_id: str,
    action: str,
    details: Dict[str, Any] = None,
    request: Request = None
):
    """
    Log business events for audit trail
    
    Args:
        event_type: Type of business event (e.g., "transaction_created")
        entity_type: Type of entity (e.g., "transaction", "merchant")
        entity_id: Unique identifier of the entity
        action: Action performed (e.g., "create", "update", "delete")
        details: Additional event details
        request: FastAPI request for context
    """
    if details is None:
        details = {}
    
    # Get context from request
    client_id = "system"
    request_id = None
    client_ip = "unknown"
    
    if request:
        client_id = getattr(request.state, "client_id", "anonymous")
        request_id = getattr(request.state, "request_id", None)
        client_ip = request.client.host if request.client else "unknown"
    
    # Create audit log entry
    audit_entry = {
        "event_type": "business_event",
        "business_event_type": event_type,
        "entity_type": entity_type,
        "entity_id": entity_id,
        "action": action,
        "client_id": client_id,
        "client_ip": client_ip,
        "timestamp": time.time(),
        **details
    }
    
    if request_id:
        audit_entry["request_id"] = request_id
    
    logger.info(f"Business event: {event_type}", extra=audit_entry)


def log_integration_event(
    integration: str,
    event_type: str,
    success: bool,
    details: Dict[str, Any] = None,
    request: Request = None
):
    """
    Log external integration events
    
    Args:
        integration: Name of integration (e.g., "asaas", "tricket")
        event_type: Type of integration event (e.g., "webhook_sent", "api_call")
        success: Whether the integration was successful
        details: Additional event details
        request: FastAPI request for context
    """
    if details is None:
        details = {}
    
    # Get context from request
    client_id = "system"
    request_id = None
    
    if request:
        client_id = getattr(request.state, "client_id", "anonymous")
        request_id = getattr(request.state, "request_id", None)
    
    # Create audit log entry
    audit_entry = {
        "event_type": "integration_event",
        "integration": integration,
        "integration_event_type": event_type,
        "success": success,
        "client_id": client_id,
        "timestamp": time.time(),
        **details
    }
    
    if request_id:
        audit_entry["request_id"] = request_id
    
    log_level = "info" if success else "error"
    getattr(logger, log_level)(f"Integration event: {integration}:{event_type}", extra=audit_entry)