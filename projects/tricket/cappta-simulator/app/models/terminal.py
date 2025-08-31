from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

from .common import CardBrand

class TerminalStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"
    MAINTENANCE = "maintenance"

class CaptureMode(str, Enum):
    SMARTPOS = "smartpos"
    MANUAL = "manual"
    AUTOMATIC = "automatic"

class TerminalBase(BaseModel):
    """Base model for Terminal data"""
    serial_number: str = Field(..., min_length=10, max_length=50, description="Serial number do terminal")
    brand_acceptance: List[CardBrand] = Field(..., min_items=1, description="Bandeiras aceitas pelo terminal")
    capture_mode: CaptureMode = CaptureMode.SMARTPOS
    terminal_metadata: Optional[Dict[str, Any]] = Field(None, description="Metadata adicional do terminal")

    @validator('serial_number')
    def validate_serial_number(cls, v):
        if not v.replace('-', '').replace('_', '').isalnum():
            raise ValueError('Serial number deve conter apenas letras, números, hífens e underscores')
        return v.upper().strip()

    @validator('brand_acceptance')
    def validate_brand_acceptance(cls, v):
        if not v:
            raise ValueError('Terminal deve aceitar pelo menos uma bandeira')
        # Remove duplicatas mantendo ordem
        seen = set()
        unique_brands = []
        for brand in v:
            if brand not in seen:
                seen.add(brand)
                unique_brands.append(brand)
        return unique_brands

class TerminalCreate(TerminalBase):
    """Model for creating a new terminal"""
    merchant_id: str = Field(..., description="ID do merchant proprietário")

class TerminalUpdate(BaseModel):
    """Model for updating terminal data"""
    brand_acceptance: Optional[List[CardBrand]] = None
    capture_mode: Optional[CaptureMode] = None
    terminal_metadata: Optional[Dict[str, Any]] = None
    status: Optional[TerminalStatus] = None

    @validator('brand_acceptance')
    def validate_brand_acceptance(cls, v):
        if v is not None and not v:
            raise ValueError('Terminal deve aceitar pelo menos uma bandeira')
        return v

class TerminalResponse(TerminalBase):
    """Model for terminal API responses"""
    terminal_id: str
    merchant_id: str
    external_terminal_id: Optional[str] = None
    status: TerminalStatus
    pos_devices_count: int = 0
    last_transaction_at: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    # Merchant info (quando incluído)
    merchant_business_name: Optional[str] = None
    merchant_document: Optional[str] = None
    
    class Config:
        from_attributes = True

class TerminalListResponse(BaseModel):
    """Model for terminal list responses with pagination"""
    terminals: List[TerminalResponse]
    total: int
    page: int
    per_page: int
    has_next: bool
    has_prev: bool

class TerminalActivationRequest(BaseModel):
    """Model for terminal activation request"""
    force: bool = Field(False, description="Forçar ativação mesmo com validações pendentes")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Metadata da ativação")

class TerminalActivationResponse(BaseModel):
    """Model for terminal activation response"""
    terminal_id: str
    status: TerminalStatus
    activated_at: datetime
    activation_metadata: Optional[Dict[str, Any]] = None
    validation_warnings: List[str] = []

class TerminalStats(BaseModel):
    """Model for terminal statistics"""
    terminal_id: str
    total_transactions: int = 0
    successful_transactions: int = 0
    failed_transactions: int = 0
    total_volume: int = 0  # in cents
    last_transaction_at: Optional[datetime] = None
    pos_devices_count: int = 0
    uptime_percentage: float = 100.0

class TerminalFilter(BaseModel):
    """Model for terminal filtering parameters"""
    merchant_id: Optional[str] = None
    status: Optional[TerminalStatus] = None
    serial_number: Optional[str] = None
    brand: Optional[CardBrand] = None
    created_after: Optional[datetime] = None
    created_before: Optional[datetime] = None
    has_pos_devices: Optional[bool] = None
    
class TerminalSort(str, Enum):
    CREATED_ASC = "created_asc"
    CREATED_DESC = "created_desc"
    UPDATED_ASC = "updated_asc"
    UPDATED_DESC = "updated_desc"
    SERIAL_ASC = "serial_asc"
    SERIAL_DESC = "serial_desc"
    STATUS_ASC = "status_asc"
    STATUS_DESC = "status_desc"

# Validation helpers
class TerminalValidation:
    """Terminal validation utilities"""
    
    @staticmethod
    def can_activate(terminal_data: dict, merchant_data: dict) -> tuple[bool, List[str]]:
        """
        Validate if terminal can be activated
        Returns (can_activate, warnings)
        """
        warnings = []
        
        # Merchant must be active
        if merchant_data.get('is_active') != True:
            return False, ["Merchant deve estar ativo para ativar terminal"]
        
        # Terminal must have POS devices (warning only)
        if terminal_data.get('pos_devices_count', 0) == 0:
            warnings.append("Terminal não possui dispositivos POS associados")
        
        # Terminal must accept at least one brand
        if not terminal_data.get('brand_acceptance'):
            return False, ["Terminal deve aceitar pelo menos uma bandeira"]
        
        return True, warnings
    
    @staticmethod
    def can_deactivate(terminal_data: dict, pending_transactions: int = 0) -> tuple[bool, List[str]]:
        """
        Validate if terminal can be deactivated
        Returns (can_deactivate, reasons)
        """
        reasons = []
        
        if pending_transactions > 0:
            reasons.append(f"Terminal possui {pending_transactions} transações pendentes")
        
        return len(reasons) == 0, reasons

# Business rules
class TerminalBusinessRules:
    """Terminal business rules and constants"""
    
    MAX_TERMINALS_PER_MERCHANT = 50
    MIN_SERIAL_NUMBER_LENGTH = 10
    MAX_SERIAL_NUMBER_LENGTH = 50
    
    REQUIRED_BRANDS_FOR_ACTIVATION = []  # Nenhuma bandeira específica obrigatória
    
    DEFAULT_CAPTURE_MODE = CaptureMode.SMARTPOS
    DEFAULT_BRAND_ACCEPTANCE = [CardBrand.VISA, CardBrand.MASTERCARD]
    
    @classmethod
    def validate_merchant_terminal_limit(cls, current_count: int) -> bool:
        """Check if merchant can create more terminals"""
        return current_count < cls.MAX_TERMINALS_PER_MERCHANT