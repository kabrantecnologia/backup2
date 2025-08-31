from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime
from enum import Enum

class ResellerStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"

class ResellerBase(BaseModel):
    """Base model for Reseller data"""
    document: str = Field(..., min_length=14, max_length=14, description="CNPJ do reseller (14 digits)")
    business_name: str = Field(..., max_length=100, description="Razão social")
    trade_name: Optional[str] = Field(None, max_length=100, description="Nome fantasia")
    email: str = Field(..., description="Email de contato")
    phone: Optional[str] = Field(None, max_length=15, description="Telefone de contato")
    status: ResellerStatus = ResellerStatus.ACTIVE
    daily_limit: int = Field(1000000, description="Limite diário em centavos")
    monthly_limit: int = Field(10000000, description="Limite mensal em centavos")

class ResellerCreate(ResellerBase):
    """Model for creating a new reseller"""
    api_token: str = Field(..., description="Token de acesso da API")
    reseller_metadata: Optional[Dict[str, Any]] = Field(None, description="Metadata adicional")

class ResellerUpdate(BaseModel):
    """Model for updating reseller data"""
    business_name: Optional[str] = Field(None, max_length=100)
    trade_name: Optional[str] = Field(None, max_length=100)
    email: Optional[str] = None
    phone: Optional[str] = Field(None, max_length=15)
    status: Optional[ResellerStatus] = None
    daily_limit: Optional[int] = None
    monthly_limit: Optional[int] = None
    api_token: Optional[str] = None
    reseller_metadata: Optional[Dict[str, Any]] = None

class ResellerResponse(ResellerBase):
    """Model for reseller API responses"""
    reseller_id: str
    api_token: str
    reseller_metadata: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class ResellerAuth(BaseModel):
    """Model for reseller authentication"""
    reseller_id: str
    document: str
    api_token: str
    status: ResellerStatus
    daily_limit: int
    monthly_limit: int
    
    class Config:
        from_attributes = True

# Compatibility models for API oficial structure
class CapptaAuthContext(BaseModel):
    """Context model matching official Cappta API structure"""
    RESELLER_DOCUMENT: str
    CAPPTA_API_URL: str  
    CAPPTA_API_TOKEN: str
    
    @classmethod
    def from_reseller(cls, reseller: ResellerResponse, api_url: str) -> "CapptaAuthContext":
        """Create auth context from reseller data"""
        return cls(
            RESELLER_DOCUMENT=reseller.document,
            CAPPTA_API_URL=api_url,
            CAPPTA_API_TOKEN=reseller.api_token
        )