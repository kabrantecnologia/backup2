from pydantic_settings import BaseSettings
from typing import List, Optional
from enum import Enum
import os

class Environment(str, Enum):
    DEV = "dev"
    STAGING = "staging"
    PROD = "prod"

class Settings(BaseSettings):
    # Environment Configuration
    ENVIRONMENT: Environment = Environment.DEV
    DEBUG: bool = True
    LOG_LEVEL: str = "info"
    
    # API Configuration
    API_TITLE: str = "Cappta Simulator API"
    API_VERSION: str = "2.0.0"
    API_DESCRIPTION: str = "Simulador completo da API Cappta para desenvolvimento Tricket"
    API_PORT: int = 8000
    API_HOST: str = "0.0.0.0"
    BASE_URL: str = "http://localhost:8000"
    
    # Authentication & Security (Compatibilidade com API Oficial)
    API_TOKEN: str
    CAPPTA_API_TOKEN: str = "cappta_fake_token_dev_123"  # Alias para compatibilidade
    CAPPTA_API_URL: str = "http://localhost:8000"  # URL base da API (simulador)
    RESELLER_DOCUMENT: str = "00000000000191"  # CNPJ do reseller padrão
    
    # Legacy authentication (manter para compatibilidade)
    ALLOWED_IPS: List[str] = ["127.0.0.1", "localhost", "::1", "0.0.0.0/0"]
    TOKEN_EXPIRY_HOURS: int = 24
    
    # Rate Limiting
    RATE_LIMIT_REQUESTS_PER_MINUTE: int = 1000
    RATE_LIMIT_BURST: int = 100
    RATE_LIMIT_ENABLED: bool = True
    
    # Asaas Integration (Transferências)
    ASAAS_API_KEY: str = "SUBSTITUIR_PELA_API_KEY_REAL"
    ASAAS_BASE_URL: str = "https://sandbox.asaas.com/api/v3"
    CAPPTA_MASTER_ACCOUNT_ID: str = "SUBSTITUIR_PELO_ACCOUNT_ID_REAL"
    
    # Tricket Integration (Webhooks)
    TRICKET_WEBHOOK_URL: str = "https://dev2.tricket.kabran.com.br/functions/v1/cappta_webhook_receiver"
    TRICKET_WEBHOOK_SECRET: str = "webhook_secret_dev_123"
    TRICKET_API_BASE: str = "https://dev2.tricket.kabran.com.br"
    
    # Webhook System
    WEBHOOK_SIGNATURE_SECRET: str = "signature_secret_dev_xyz"
    WEBHOOK_TIMEOUT: int = 30  # seconds
    WEBHOOK_RETRY_ATTEMPTS: int = 5
    WEBHOOK_RETRY_DELAY: int = 60  # seconds
    
    # Database Configuration
    DATABASE_URL: str = "sqlite:///./cappta_simulator.db"
    DATABASE_POOL_SIZE: int = 10
    DATABASE_ECHO: bool = False
    
    # Business Rules
    DEFAULT_FEE_PERCENTAGE: float = 3.0  # 3%
    DEFAULT_FEE_FIXED: int = 30  # R$ 0,30 in cents
    PIX_FEE_FIXED: int = 10  # R$ 0,10 in cents
    DEBIT_FEE_PERCENTAGE: float = 2.0  # 2%
    DEBIT_FEE_FIXED: int = 20  # R$ 0,20 in cents
    INSTALLMENT_FEE_PERCENTAGE: float = 0.5  # 0.5% por parcela adicional
    
    SETTLEMENT_DELAY_CREDIT: int = 24  # D+1 para crédito
    SETTLEMENT_DELAY_DEBIT: int = 0   # D+0 para débito
    SETTLEMENT_DELAY_PIX: int = 0     # D+0 para PIX
    SETTLEMENT_MIN_AMOUNT: int = 1000 # R$ 10,00 mínimo para liquidação
    
    MAX_TRANSACTION_AMOUNT: int = 1000000  # R$ 10.000,00 in cents
    MIN_TRANSACTION_AMOUNT: int = 100      # R$ 1,00 in cents
    MAX_INSTALLMENTS: int = 12
    
    # Monitoring & Observability
    SENTRY_DSN: Optional[str] = None
    PROMETHEUS_ENABLED: bool = False
    HEALTH_CHECK_INTERVAL: int = 30  # seconds
    
    # Terminal & POS Configuration
    DEFAULT_TERMINAL_BRAND_ACCEPTANCE: List[str] = ["visa", "mastercard", "elo", "amex"]
    DEFAULT_CAPTURE_MODE: str = "smartpos"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True
        
    def is_development(self) -> bool:
        return self.ENVIRONMENT == Environment.DEV
        
    def is_production(self) -> bool:
        return self.ENVIRONMENT == Environment.PROD

# Global settings instance
settings = Settings()