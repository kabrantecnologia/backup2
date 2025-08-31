from pydantic import BaseModel, Field, field_validator, model_validator
from typing import List, Optional
from datetime import datetime, date
import uuid
from .common import BaseResponse, SettlementStatus

class SettlementCreate(BaseModel):
    merchant_id: str = Field(..., description="UUID do comerciante")
    settlement_id: Optional[str] = Field(None, description="ID único da liquidação")
    transaction_refs: List[str] = Field(..., description="Lista de external_event_ids das transações")
    settlement_date: Optional[date] = Field(default_factory=date.today)
    force_settlement: bool = Field(False, description="Forçar liquidação mesmo fora do prazo")
    
    @field_validator('merchant_id')
    @classmethod
    def validate_merchant_id(cls, v):
        try:
            uuid.UUID(v)
            return v
        except ValueError:
            raise ValueError('merchant_id must be a valid UUID')
    
    @field_validator('transaction_refs')
    @classmethod
    def validate_transaction_refs(cls, v):
        if not v:
            raise ValueError('At least one transaction reference is required')
        return v
    
    @model_validator(mode='before')
    @classmethod
    def set_defaults(cls, values):
        if isinstance(values, dict):
            # Set settlement_id if not provided
            if not values.get('settlement_id'):
                values['settlement_id'] = f"stl_{uuid.uuid4().hex[:12]}"
        return values

class SettlementResponse(BaseModel):
    settlement_id: str
    merchant_id: str
    gross_amount: int
    fee_amount: int
    net_amount: int
    transaction_count: int
    transaction_refs: List[str]
    settlement_date: date
    status: SettlementStatus
    asaas_transfer_id: Optional[str] = None
    processed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

class SettlementCreateResponse(BaseResponse):
    success: bool = True
    data: Optional[SettlementResponse] = None

class SettlementListResponse(BaseResponse):
    success: bool = True
    data: List[SettlementResponse] = []
    total: int = 0
    page: int = 1
    per_page: int = 20

class SettlementStatusUpdate(BaseModel):
    status: SettlementStatus
    asaas_transfer_id: Optional[str] = None
    processed_at: Optional[datetime] = None
    reason: Optional[str] = None

class SettlementSummary(BaseModel):
    merchant_id: str
    pending_settlements: int
    pending_amount: int
    completed_settlements: int
    completed_amount: int
    last_settlement_date: Optional[date] = None