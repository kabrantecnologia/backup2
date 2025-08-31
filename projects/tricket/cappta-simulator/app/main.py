from fastapi import FastAPI, Request, status, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from contextlib import asynccontextmanager
import uvicorn
import asyncio
from datetime import datetime

from app.api import health, merchants, transactions, settlements, auth, terminals, pos_devices, merchant_plans
from app.database.connection import init_db, close_db
from app.database.migrations import init_database
from app.models.common import ErrorResponse
from app.middleware.rate_limit import rate_limit_middleware, rate_limiter
from app.middleware.audit import audit_middleware
from app.middleware.auth import token_manager
from config.settings import settings
from config.logging import setup_logging, get_logger

# Setup structured logging
setup_logging(
    log_level=settings.LOG_LEVEL,
    json_format=not settings.DEBUG  # Use plain format in debug mode
)
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    logger.info("Starting Cappta Simulator...", extra={
        "version": settings.API_VERSION,
        "environment": settings.ENVIRONMENT,
        "debug": settings.DEBUG
    })
    
    try:
        # Initialize database with migrations
        logger.info("Initializing database...")
        if not init_database():
            raise RuntimeError("Database initialization failed")
        
        # Initialize database connection
        await init_db()
        
        # Cleanup expired tokens and rate limit data
        if hasattr(token_manager, 'cleanup_expired_tokens'):
            token_manager.cleanup_expired_tokens()
        
        if hasattr(rate_limiter, 'cleanup_old_data'):
            rate_limiter.cleanup_old_data()
        
        logger.info("Application startup completed")
        
    except Exception as e:
        logger.error(f"Application startup failed: {str(e)}")
        raise
    
    yield
    
    # Cleanup
    logger.info("Shutting down Cappta Simulator...")
    try:
        await close_db()
        logger.info("Application shutdown completed")
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}")


# Create FastAPI application
app = FastAPI(
    title=settings.API_TITLE,
    version=settings.API_VERSION,
    description=settings.API_DESCRIPTION,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    openapi_url="/openapi.json" if settings.DEBUG else None,
    lifespan=lifespan,
    responses={
        422: {"model": ErrorResponse},
        500: {"model": ErrorResponse},
        429: {
            "description": "Rate limit exceeded",
            "headers": {
                "Retry-After": {"description": "Seconds to wait before retrying"},
                "X-RateLimit-Limit": {"description": "Request limit per window"},
                "X-RateLimit-Remaining": {"description": "Remaining requests in window"},
                "X-RateLimit-Reset": {"description": "Window reset time (Unix timestamp)"}
            }
        }
    }
)

# Add middlewares in correct order (last added = first executed)

# CORS middleware (last - first to execute)
allowed_origins = ["*"] if settings.DEBUG else [
    "https://dev2.tricket.kabran.com.br",
    "https://simulador-cappta.kabran.com.br",
    "http://localhost:3000"  # For development
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
    allow_headers=["*"],
    expose_headers=[
        "X-Request-ID", 
        "X-Processing-Time",
        "X-RateLimit-Limit",
        "X-RateLimit-Remaining", 
        "X-RateLimit-Reset"
    ]
)

# Rate limiting middleware
if settings.RATE_LIMIT_ENABLED:
    app.middleware("http")(rate_limit_middleware)

# Audit middleware (logs requests/responses)
app.middleware("http")(audit_middleware)


# Global exception handlers
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle validation errors"""
    request_id = getattr(request.state, "request_id", "unknown")
    client_id = getattr(request.state, "client_id", "anonymous")
    
    logger.warning("Request validation failed", extra={
        "request_id": request_id,
        "client_id": client_id,
        "url": str(request.url),
        "method": request.method,
        "validation_errors": exc.errors()
    })
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=ErrorResponse(
            message="Invalid request data",
            error_code="VALIDATION_ERROR",
            details={"errors": exc.errors()}
        ).dict(),
        headers={
            "X-Request-ID": request_id
        }
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Handle HTTP exceptions with proper logging"""
    request_id = getattr(request.state, "request_id", "unknown")
    client_id = getattr(request.state, "client_id", "anonymous")
    
    # Log based on status code severity
    if exc.status_code >= 500:
        log_method = logger.error
    elif exc.status_code >= 400:
        log_method = logger.warning
    else:
        log_method = logger.info
    
    log_method(f"HTTP {exc.status_code}: {exc.detail}", extra={
        "request_id": request_id,
        "client_id": client_id,
        "url": str(request.url),
        "method": request.method,
        "status_code": exc.status_code
    })
    
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "message": exc.detail,
            "error_code": f"HTTP_{exc.status_code}",
            "status_code": exc.status_code
        },
        headers=getattr(exc, "headers", None) or {"X-Request-ID": request_id}
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle general exceptions"""
    request_id = getattr(request.state, "request_id", "unknown")
    client_id = getattr(request.state, "client_id", "anonymous")
    
    logger.error("Unhandled exception occurred", extra={
        "request_id": request_id,
        "client_id": client_id,
        "url": str(request.url),
        "method": request.method,
        "exception_type": type(exc).__name__,
        "exception_message": str(exc)
    }, exc_info=True)
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=ErrorResponse(
            message="Internal server error",
            error_code="INTERNAL_ERROR",
            details={"request_id": request_id} if settings.DEBUG else None
        ).dict(),
        headers={
            "X-Request-ID": request_id
        }
    )


# Health check for monitoring
@app.get("/health/live", include_in_schema=False)
async def liveness_check():
    """Kubernetes liveness probe"""
    return {"status": "alive", "timestamp": datetime.utcnow().isoformat()}


@app.get("/health/ready", include_in_schema=False) 
async def readiness_check():
    """Kubernetes readiness probe"""
    try:
        # Test database connection
        from app.database.connection import get_db_session
        from sqlalchemy import text
        with get_db_session() as session:
            session.execute(text("SELECT 1"))
        
        return {
            "status": "ready",
            "timestamp": datetime.utcnow().isoformat(),
            "version": settings.API_VERSION,
            "environment": settings.ENVIRONMENT
        }
    except Exception as e:
        logger.error(f"Readiness check failed: {str(e)}")
        return JSONResponse(
            status_code=503,
            content={
                "status": "not_ready", 
                "error": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }
        )


# Include routers
app.include_router(health.router, tags=["Health"])
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(merchants.router, prefix="/merchants", tags=["Merchants"])
app.include_router(terminals.router, prefix="/terminals", tags=["Terminals"])
app.include_router(pos_devices.router, tags=["POS Devices"])
app.include_router(merchant_plans.router, prefix="/plans", tags=["Merchant Plans"])
app.include_router(transactions.router, prefix="/transactions", tags=["Transactions"])
app.include_router(settlements.router, prefix="/settlements", tags=["Settlements"])


@app.get("/", include_in_schema=False)
async def root():
    """Root endpoint - API information"""
    return {
        "service": settings.API_TITLE,
        "description": settings.API_DESCRIPTION,
        "version": settings.API_VERSION,
        "environment": settings.ENVIRONMENT.value,
        "status": "operational",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "endpoints": {
            "health": "/health",
            "docs": "/docs" if settings.DEBUG else None,
            "openapi": "/openapi.json" if settings.DEBUG else None
        },
        "features": {
            "rate_limiting": settings.RATE_LIMIT_ENABLED,
            "authentication": True,
            "audit_logging": True,
            "webhooks": True,
            "asaas_integration": bool(settings.ASAAS_API_KEY and settings.ASAAS_API_KEY != "SUBSTITUIR_PELA_API_KEY_REAL")
        }
    }


# Periodic cleanup task
async def cleanup_task():
    """Periodic cleanup of expired data"""
    while True:
        try:
            # Wait 1 hour between cleanups
            await asyncio.sleep(3600)
            
            # Cleanup expired tokens
            if hasattr(token_manager, 'cleanup_expired_tokens'):
                token_manager.cleanup_expired_tokens()
            
            # Cleanup old rate limit data
            if hasattr(rate_limiter, 'cleanup_old_data'):
                rate_limiter.cleanup_old_data()
                
            logger.info("Periodic cleanup completed")
            
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"Cleanup task error: {str(e)}")


# Start cleanup task on application startup
@app.on_event("startup")
async def start_cleanup_task():
    asyncio.create_task(cleanup_task())


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=settings.API_HOST,
        port=settings.API_PORT,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower(),
        access_log=settings.DEBUG,
        server_header=False,  # Security - hide server header
        date_header=False     # Security - hide date header
    )