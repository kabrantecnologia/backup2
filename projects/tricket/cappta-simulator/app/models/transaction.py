from pydantic import BaseModel, Field, field_validator, model_validator
from typing import Optional
from datetime import datetime
import uuid
from .common import BaseResponse, TransactionStatus, PaymentMethod, CardBrand

class TransactionCreate(BaseModel):
    merchant_id: str = Field(..., description="UUID do comerciante")
    terminal_id: str = Field(..., description="ID do terminal")
    transaction_id: Optional[str] = Field(None, description="ID único da transação")
    nsu: Optional[str] = Field(None, description="NSU (Número Sequencial Único)")
    authorization_code: Optional[str] = Field(None, description="Código de autorização")
    payment_method: PaymentMethod = PaymentMethod.CREDIT
    card_brand: Optional[CardBrand] = None
    gross_amount: int = Field(..., gt=0, description="Valor bruto em centavos")
    installments: int = Field(1, ge=1, le=12, description="Número de parcelas")
    captured_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    external_event_id: Optional[str] = Field(None, description="ID único do evento externo")
    
    @field_validator('merchant_id')
    @classmethod
    def validate_merchant_id(cls, v):
        try:
            uuid.UUID(v)
            return v
        except ValueError:
            raise ValueError('merchant_id must be a valid UUID')
    
    @model_validator(mode='before')
    @classmethod
    def set_defaults(cls, values):
        if isinstance(values, dict):
            # Set transaction_id if not provided
            if not values.get('transaction_id'):
                values['transaction_id'] = f"txn_{uuid.uuid4().hex[:12]}"
            
            # Set NSU if not provided
            if not values.get('nsu'):
                import random
                values['nsu'] = f"{random.randint(100000, 999999):06d}"
            
            # Set authorization_code if not provided
            if not values.get('authorization_code'):
                import random
                import string
                values['authorization_code'] = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            
            # Set external_event_id if not provided
            if not values.get('external_event_id'):
                values['external_event_id'] = f"evt_{uuid.uuid4().hex[:16]}"
                
        return values

class TransactionResponse(BaseModel):
    transaction_id: str
    merchant_id: str
    terminal_id: str
    nsu: str
    authorization_code: str
    payment_method: PaymentMethod
    card_brand: Optional[CardBrand]
    gross_amount: int
    fee_amount: int
    net_amount: int
    installments: int
    status: TransactionStatus
    captured_at: datetime
    external_event_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None

class TransactionCreateResponse(BaseResponse):
    success: bool = True
    data: Optional[TransactionResponse] = None

class TransactionListResponse(BaseResponse):
    success: bool = True
    data: list[TransactionResponse] = []
    total: int = 0
    page: int = 1
    per_page: int = 20

class TransactionStatusUpdate(BaseModel):
    status: TransactionStatus
    reason: Optional[str] = None

