from fastapi import Request, HTTPException, status
from typing import Dict, Tuple
import time
from collections import defaultdict, deque
from datetime import datetime, timedelta
from config.settings import settings
from config.logging import get_logger

logger = get_logger(__name__)


class TokenBucket:
    """
    Token bucket implementation for rate limiting
    """
    
    def __init__(self, capacity: int, refill_rate: float):
        self.capacity = capacity
        self.tokens = capacity
        self.refill_rate = refill_rate  # tokens per second
        self.last_refill = time.time()
    
    def consume(self, tokens: int = 1) -> bool:
        """
        Try to consume tokens from the bucket
        
        Args:
            tokens: Number of tokens to consume
            
        Returns:
            True if tokens were consumed, False if not enough tokens
        """
        now = time.time()
        
        # Refill tokens based on elapsed time
        elapsed = now - self.last_refill
        self.tokens = min(self.capacity, self.tokens + elapsed * self.refill_rate)
        self.last_refill = now
        
        if self.tokens >= tokens:
            self.tokens -= tokens
            return True
        
        return False
    
    def time_until_refill(self, tokens: int = 1) -> float:
        """
        Calculate time until enough tokens are available
        
        Args:
            tokens: Number of tokens needed
            
        Returns:
            Time in seconds until tokens are available
        """
        if self.tokens >= tokens:
            return 0.0
        
        needed_tokens = tokens - self.tokens
        return needed_tokens / self.refill_rate


class RateLimiter:
    """
    Rate limiter with multiple strategies
    """
    
    def __init__(self):
        # Token buckets per client
        self.client_buckets: Dict[str, TokenBucket] = {}
        
        # Sliding window counters
        self.request_windows: Dict[str, deque] = defaultdict(deque)
        
        # Global rate limiting
        self.global_bucket = TokenBucket(
            capacity=settings.RATE_LIMIT_BURST * 2,
            refill_rate=settings.RATE_LIMIT_REQUESTS_PER_MINUTE / 60.0
        )
        
        # Per-endpoint limits
        self.endpoint_limits = {
            "/transactions": {"requests": 100, "window": 60},  # 100 req/min
            "/settlements": {"requests": 50, "window": 60},    # 50 req/min
            "/merchants": {"requests": 200, "window": 60},     # 200 req/min
        }
    
    def get_client_bucket(self, client_id: str) -> TokenBucket:
        """
        Get or create token bucket for a client
        
        Args:
            client_id: Client identifier
            
        Returns:
            Token bucket for the client
        """
        if client_id not in self.client_buckets:
            self.client_buckets[client_id] = TokenBucket(
                capacity=settings.RATE_LIMIT_BURST,
                refill_rate=settings.RATE_LIMIT_REQUESTS_PER_MINUTE / 60.0
            )
        return self.client_buckets[client_id]
    
    def check_sliding_window(self, key: str, limit: int, window: int) -> Tuple[bool, Dict]:
        """
        Check sliding window rate limit
        
        Args:
            key: Rate limit key (client_id or endpoint)
            limit: Number of requests allowed
            window: Time window in seconds
            
        Returns:
            Tuple of (allowed, info)
        """
        now = time.time()
        window_start = now - window
        
        # Get request window for this key
        requests = self.request_windows[key]
        
        # Remove old requests outside the window
        while requests and requests[0] < window_start:
            requests.popleft()
        
        current_count = len(requests)
        
        if current_count >= limit:
            # Rate limited
            oldest_request = requests[0] if requests else now
            reset_time = oldest_request + window
            return False, {
                "limit": limit,
                "remaining": 0,
                "reset_time": reset_time,
                "retry_after": int(reset_time - now)
            }
        
        # Add current request
        requests.append(now)
        
        return True, {
            "limit": limit,
            "remaining": limit - current_count - 1,
            "reset_time": now + window,
            "retry_after": 0
        }
    
    def is_allowed(self, request: Request) -> Tuple[bool, Dict]:
        """
        Check if request is allowed based on rate limits
        
        Args:
            request: FastAPI request object
            
        Returns:
            Tuple of (allowed, rate_limit_info)
        """
        if not settings.RATE_LIMIT_ENABLED:
            return True, {}
        
        # Get client info
        client_id = getattr(request.state, "client_id", "anonymous")
        client_ip = request.client.host if request.client else "unknown"
        endpoint = request.url.path
        
        # Check global rate limit
        if not self.global_bucket.consume():
            logger.warning(f"Global rate limit exceeded", extra={
                "client_id": client_id,
                "client_ip": client_ip,
                "endpoint": endpoint
            })
            return False, {
                "error": "global_rate_limit_exceeded",
                "retry_after": int(self.global_bucket.time_until_refill())
            }
        
        # Check per-client rate limit
        client_bucket = self.get_client_bucket(client_id)
        if not client_bucket.consume():
            retry_after = int(client_bucket.time_until_refill())
            logger.warning(f"Client rate limit exceeded", extra={
                "client_id": client_id,
                "client_ip": client_ip,
                "endpoint": endpoint,
                "retry_after": retry_after
            })
            return False, {
                "error": "client_rate_limit_exceeded",
                "retry_after": retry_after
            }
        
        # Check per-endpoint rate limit
        endpoint_config = self.endpoint_limits.get(endpoint)
        if endpoint_config:
            endpoint_key = f"endpoint:{endpoint}:{client_id}"
            allowed, window_info = self.check_sliding_window(
                endpoint_key,
                endpoint_config["requests"],
                endpoint_config["window"]
            )
            
            if not allowed:
                logger.warning(f"Endpoint rate limit exceeded", extra={
                    "client_id": client_id,
                    "client_ip": client_ip,
                    "endpoint": endpoint,
                    "limit": endpoint_config["requests"],
                    "window": endpoint_config["window"]
                })
                return False, {
                    "error": "endpoint_rate_limit_exceeded",
                    "endpoint": endpoint,
                    **window_info
                }
            
            return True, window_info
        
        # Default sliding window for other endpoints
        client_key = f"client:{client_id}"
        return self.check_sliding_window(
            client_key,
            settings.RATE_LIMIT_REQUESTS_PER_MINUTE,
            60
        )
    
    def cleanup_old_data(self):
        """
        Clean up old rate limiting data
        """
        now = time.time()
        cutoff = now - 3600  # Keep last hour of data
        
        # Clean sliding windows
        for key, requests in list(self.request_windows.items()):
            while requests and requests[0] < cutoff:
                requests.popleft()
            
            # Remove empty windows
            if not requests:
                del self.request_windows[key]
        
        logger.debug(f"Cleaned up rate limiter data, active windows: {len(self.request_windows)}")


# Global rate limiter instance
rate_limiter = RateLimiter()


async def rate_limit_middleware(request: Request, call_next):
    """
    Middleware to enforce rate limiting
    
    Args:
        request: FastAPI request
        call_next: Next middleware/endpoint
        
    Returns:
        Response with rate limiting headers
    """
    # Check if rate limiting is enabled
    if not settings.RATE_LIMIT_ENABLED:
        response = await call_next(request)
        return response
    
    # Check rate limits
    allowed, rate_info = rate_limiter.is_allowed(request)
    
    if not allowed:
        # Rate limited - return 429
        error_detail = {
            "error": rate_info.get("error", "rate_limit_exceeded"),
            "message": "Rate limit exceeded, please try again later",
            "retry_after": rate_info.get("retry_after", 60)
        }
        
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=error_detail,
            headers={
                "Retry-After": str(rate_info.get("retry_after", 60)),
                "X-RateLimit-Limit": str(rate_info.get("limit", settings.RATE_LIMIT_REQUESTS_PER_MINUTE)),
                "X-RateLimit-Remaining": "0",
                "X-RateLimit-Reset": str(int(rate_info.get("reset_time", time.time() + 60)))
            }
        )
    
    # Process request
    response = await call_next(request)
    
    # Add rate limit headers to response
    if rate_info:
        response.headers["X-RateLimit-Limit"] = str(rate_info.get("limit", settings.RATE_LIMIT_REQUESTS_PER_MINUTE))
        response.headers["X-RateLimit-Remaining"] = str(rate_info.get("remaining", 0))
        response.headers["X-RateLimit-Reset"] = str(int(rate_info.get("reset_time", time.time() + 60)))
    
    return response