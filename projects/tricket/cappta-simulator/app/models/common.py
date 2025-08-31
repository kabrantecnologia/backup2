from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field
from datetime import datetime
import uuid

class TransactionStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved" 
    DECLINED = "declined"
    CANCELLED = "cancelled"
    SETTLED = "settled"

class PaymentMethod(str, Enum):
    CREDIT = "credit"
    DEBIT = "debit"
    PIX = "pix"

class CardBrand(str, Enum):
    VISA = "visa"
    MASTERCARD = "mastercard"
    ELO = "elo"
    AMEX = "amex"
    HIPERCARD = "hipercard"

class SettlementStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

class BaseResponse(BaseModel):
    success: bool
    message: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class ErrorResponse(BaseResponse):
    success: bool = False
    error_code: Optional[str] = None
    details: Optional[dict] = None

class TransactionWebhook(BaseModel):
    event_type: str
    merchant_id: str
    transaction_id: str
    amount: int
    status: TransactionStatus