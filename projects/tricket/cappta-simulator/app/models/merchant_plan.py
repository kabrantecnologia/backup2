from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any, Union
from datetime import datetime
from enum import Enum

from .common import CardBrand, PaymentMethod

class PlanStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    DRAFT = "draft"

class FeeType(str, Enum):
    PERCENTAGE = "percentage"
    FIXED = "fixed"
    MIXED = "mixed"  # percentage + fixed

class FeeStructure(BaseModel):
    """Fee structure for different payment methods"""
    percentage: float = Field(0.0, ge=0.0, le=100.0, description="Taxa percentual (0-100%)")
    fixed: int = Field(0, ge=0, description="Taxa fixa em centavos")
    
    @validator('percentage')
    def validate_percentage(cls, v):
        if v < 0 or v > 100:
            raise ValueError('Percentage must be between 0 and 100')
        return round(v, 2)  # Round to 2 decimal places
    
    @validator('fixed')
    def validate_fixed(cls, v):
        if v < 0:
            raise ValueError('Fixed fee cannot be negative')
        return v

class InstallmentFee(BaseModel):
    """Fee structure for installments"""
    min_installments: int = Field(2, ge=2, le=12, description="Mínimo de parcelas para cobrança")
    max_installments: int = Field(12, ge=2, le=24, description="Máximo de parcelas permitidas")
    percentage_per_installment: float = Field(0.5, ge=0.0, le=5.0, description="Taxa adicional por parcela (%)")
    
    @validator('max_installments')
    def validate_max_installments(cls, v, values):
        min_installments = values.get('min_installments', 2)
        if v < min_installments:
            raise ValueError('Max installments must be greater than or equal to min installments')
        return v

class PaymentMethodFees(BaseModel):
    """Complete fee structure for all payment methods"""
    credit: FeeStructure = Field(..., description="Taxas para cartão de crédito")
    debit: FeeStructure = Field(..., description="Taxas para cartão de débito") 
    pix: FeeStructure = Field(..., description="Taxas para PIX")
    installments: InstallmentFee = Field(..., description="Configuração de parcelamento")

    @validator('pix')
    def validate_pix_fees(cls, v):
        # PIX typically has only fixed fees, no percentage
        if v.percentage > 0:
            # Allow but warn that PIX usually doesn't have percentage fees
            pass
        return v

class MerchantPlanBase(BaseModel):
    """Base model for Merchant Plan data"""
    plan_name: str = Field(..., min_length=3, max_length=100, description="Nome do plano")
    description: Optional[str] = Field(None, max_length=500, description="Descrição do plano")
    is_active: bool = Field(True, description="Se o plano está ativo")
    is_default: bool = Field(False, description="Se é o plano padrão")
    fee_structure: PaymentMethodFees = Field(..., description="Estrutura de taxas")

    @validator('plan_name')
    def validate_plan_name(cls, v):
        return v.strip().title()

class MerchantPlanCreate(MerchantPlanBase):
    """Model for creating a new merchant plan"""
    pass

class MerchantPlanUpdate(BaseModel):
    """Model for updating merchant plan data"""
    plan_name: Optional[str] = Field(None, min_length=3, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    is_active: Optional[bool] = None
    is_default: Optional[bool] = None
    fee_structure: Optional[PaymentMethodFees] = None

    @validator('plan_name')
    def validate_plan_name(cls, v):
        if v:
            return v.strip().title()
        return v

class MerchantPlanResponse(MerchantPlanBase):
    """Model for merchant plan API responses"""
    plan_id: str
    merchants_count: int = 0
    total_transactions: int = 0
    total_volume: int = 0  # in cents
    created_at: datetime
    updated_at: Optional[datetime] = None
    created_by_reseller_id: str
    
    class Config:
        from_attributes = True

class MerchantPlanListResponse(BaseModel):
    """Model for merchant plan list responses"""
    plans: List[MerchantPlanResponse]
    total: int
    page: int
    per_page: int
    has_next: bool
    has_prev: bool

class MerchantPlanAssociation(BaseModel):
    """Model for associating plan to merchant"""
    plan_id: str = Field(..., description="ID do plano a ser associado")
    effective_date: Optional[datetime] = Field(None, description="Data de início da vigência")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Metadata da associação")

class MerchantPlanAssociationResponse(BaseModel):
    """Model for plan association response"""
    merchant_id: str
    plan_id: str
    plan_name: str
    previous_plan_id: Optional[str] = None
    effective_date: datetime
    association_metadata: Optional[Dict[str, Any]] = None
    associated_at: datetime

class PlanCalculation(BaseModel):
    """Model for fee calculation preview"""
    plan_id: str
    transaction_amount: int  # in cents
    payment_method: PaymentMethod
    installments: int = 1
    
    # Calculation results
    gross_amount: int
    percentage_fee: int = 0
    fixed_fee: int = 0
    installment_fee: int = 0
    total_fee: int = 0
    net_amount: int
    
    # Fee breakdown
    fee_breakdown: Dict[str, Any] = Field(default_factory=dict)

class PlanFilter(BaseModel):
    """Model for plan filtering parameters"""
    status: Optional[PlanStatus] = None
    is_default: Optional[bool] = None
    created_after: Optional[datetime] = None
    created_before: Optional[datetime] = None
    has_merchants: Optional[bool] = None

class PlanSort(str, Enum):
    NAME_ASC = "name_asc"
    NAME_DESC = "name_desc"
    CREATED_ASC = "created_asc"
    CREATED_DESC = "created_desc"
    MERCHANTS_ASC = "merchants_asc"
    MERCHANTS_DESC = "merchants_desc"

# Default plan templates
class DefaultPlanTemplates:
    """Default merchant plan templates"""
    
    STARTER_PLAN = {
        "plan_name": "Plano Iniciante",
        "description": "Plano básico para novos merchants com taxas competitivas",
        "is_active": True,
        "is_default": True,
        "fee_structure": {
            "credit": {"percentage": 3.5, "fixed": 30},  # 3.5% + R$0.30
            "debit": {"percentage": 2.0, "fixed": 20},   # 2.0% + R$0.20
            "pix": {"percentage": 0.0, "fixed": 10},     # R$0.10 flat
            "installments": {
                "min_installments": 2,
                "max_installments": 12,
                "percentage_per_installment": 0.5
            }
        }
    }
    
    PROFESSIONAL_PLAN = {
        "plan_name": "Plano Profissional", 
        "description": "Plano para merchants com alto volume de transações",
        "is_active": True,
        "is_default": False,
        "fee_structure": {
            "credit": {"percentage": 2.8, "fixed": 25},  # 2.8% + R$0.25
            "debit": {"percentage": 1.5, "fixed": 15},   # 1.5% + R$0.15
            "pix": {"percentage": 0.0, "fixed": 5},      # R$0.05 flat
            "installments": {
                "min_installments": 2,
                "max_installments": 18,
                "percentage_per_installment": 0.3
            }
        }
    }
    
    ENTERPRISE_PLAN = {
        "plan_name": "Plano Empresarial",
        "description": "Plano premium para grandes merchants com taxas negociadas",
        "is_active": True,
        "is_default": False,
        "fee_structure": {
            "credit": {"percentage": 2.2, "fixed": 20},  # 2.2% + R$0.20
            "debit": {"percentage": 1.0, "fixed": 10},   # 1.0% + R$0.10
            "pix": {"percentage": 0.0, "fixed": 0},      # Free PIX
            "installments": {
                "min_installments": 2,
                "max_installments": 24,
                "percentage_per_installment": 0.2
            }
        }
    }

    @classmethod
    def get_all_templates(cls) -> List[Dict[str, Any]]:
        """Get all default plan templates"""
        return [
            cls.STARTER_PLAN,
            cls.PROFESSIONAL_PLAN,
            cls.ENTERPRISE_PLAN
        ]

# Business rules and validation
class PlanBusinessRules:
    """Merchant plan business rules and constants"""
    
    MAX_PLANS_PER_RESELLER = 20
    MIN_CREDIT_FEE_PERCENTAGE = 1.0  # Minimum 1% for credit
    MAX_CREDIT_FEE_PERCENTAGE = 10.0  # Maximum 10% for credit
    MIN_DEBIT_FEE_PERCENTAGE = 0.5   # Minimum 0.5% for debit
    MAX_DEBIT_FEE_PERCENTAGE = 5.0   # Maximum 5% for debit
    
    MAX_FIXED_FEE = 500  # Maximum R$5.00 fixed fee
    MAX_INSTALLMENTS = 24
    
    @classmethod
    def validate_fee_limits(cls, fee_structure: PaymentMethodFees) -> tuple[bool, List[str]]:
        """Validate if fee structure is within business limits"""
        errors = []
        
        # Credit card limits
        if fee_structure.credit.percentage < cls.MIN_CREDIT_FEE_PERCENTAGE:
            errors.append(f"Credit percentage fee must be at least {cls.MIN_CREDIT_FEE_PERCENTAGE}%")
        if fee_structure.credit.percentage > cls.MAX_CREDIT_FEE_PERCENTAGE:
            errors.append(f"Credit percentage fee cannot exceed {cls.MAX_CREDIT_FEE_PERCENTAGE}%")
        if fee_structure.credit.fixed > cls.MAX_FIXED_FEE:
            errors.append(f"Credit fixed fee cannot exceed R${cls.MAX_FIXED_FEE/100:.2f}")
        
        # Debit card limits
        if fee_structure.debit.percentage < cls.MIN_DEBIT_FEE_PERCENTAGE:
            errors.append(f"Debit percentage fee must be at least {cls.MIN_DEBIT_FEE_PERCENTAGE}%")
        if fee_structure.debit.percentage > cls.MAX_DEBIT_FEE_PERCENTAGE:
            errors.append(f"Debit percentage fee cannot exceed {cls.MAX_DEBIT_FEE_PERCENTAGE}%")
        if fee_structure.debit.fixed > cls.MAX_FIXED_FEE:
            errors.append(f"Debit fixed fee cannot exceed R${cls.MAX_FIXED_FEE/100:.2f}")
        
        # PIX limits (usually only fixed fees)
        if fee_structure.pix.fixed > cls.MAX_FIXED_FEE:
            errors.append(f"PIX fixed fee cannot exceed R${cls.MAX_FIXED_FEE/100:.2f}")
        
        # Installment limits
        if fee_structure.installments.max_installments > cls.MAX_INSTALLMENTS:
            errors.append(f"Maximum installments cannot exceed {cls.MAX_INSTALLMENTS}")
        
        return len(errors) == 0, errors
    
    @classmethod
    def calculate_fees(
        cls,
        fee_structure: PaymentMethodFees,
        amount: int,
        payment_method: PaymentMethod,
        installments: int = 1
    ) -> Dict[str, int]:
        """Calculate fees for a transaction"""
        
        if payment_method == PaymentMethod.CREDIT:
            fees = fee_structure.credit
        elif payment_method == PaymentMethod.DEBIT:
            fees = fee_structure.debit
        elif payment_method == PaymentMethod.PIX:
            fees = fee_structure.pix
        else:
            fees = fee_structure.credit  # Default fallback
        
        # Base fees
        percentage_fee = int(amount * fees.percentage / 100)
        fixed_fee = fees.fixed
        
        # Installment fees (only for credit cards with installments > 1)
        installment_fee = 0
        if payment_method == PaymentMethod.CREDIT and installments > 1:
            additional_installments = installments - 1
            installment_fee = int(amount * fee_structure.installments.percentage_per_installment * additional_installments / 100)
        
        total_fee = percentage_fee + fixed_fee + installment_fee
        net_amount = amount - total_fee
        
        return {
            "gross_amount": amount,
            "percentage_fee": percentage_fee,
            "fixed_fee": fixed_fee,
            "installment_fee": installment_fee,
            "total_fee": total_fee,
            "net_amount": max(0, net_amount)  # Never negative
        }