from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import datetime
import uuid
from .common import BaseResponse

class MerchantCreate(BaseModel):
    merchant_id: str = Field(..., description="UUID do comerciante no sistema Tricket")
    asaas_account_id: str = Field(..., description="ID da conta Asaas do comerciante")
    business_name: str = Field(..., min_length=1, max_length=100)
    document: str = Field(..., min_length=11, max_length=14, description="CPF ou CNPJ")
    email: str = Field(..., pattern=r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
    phone: str = Field(..., min_length=10, max_length=15)
    
    @field_validator('merchant_id')
    @classmethod
    def validate_merchant_id(cls, v):
        try:
            uuid.UUID(v)
            return v
        except ValueError:
            raise ValueError('merchant_id must be a valid UUID')
    
    @field_validator('document')
    @classmethod
    def validate_document(cls, v):
        # Remove formatting
        clean_doc = ''.join(filter(str.isdigit, v))
        if len(clean_doc) not in [11, 14]:
            raise ValueError('Document must be CPF (11 digits) or CNPJ (14 digits)')
        return clean_doc

class MerchantResponse(BaseModel):
    merchant_id: str
    asaas_account_id: str
    business_name: str
    document: str
    email: str
    phone: str
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

class MerchantCreateResponse(BaseResponse):
    success: bool = True
    data: Optional[MerchantResponse] = None

class MerchantListResponse(BaseResponse):
    success: bool = True
    data: list[MerchantResponse] = []
    total: int = 0

class Terminal(BaseModel):
    terminal_id: str = Field(..., description="ID único do terminal")
    merchant_id: str = Field(..., description="UUID do comerciante")
    serial_number: str = Field(..., description="Número de série do terminal")
    model: str = Field(..., description="Modelo do terminal")
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)