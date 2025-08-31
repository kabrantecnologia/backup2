from sqlalchemy import Column, String, Integer, DateTime, Boolean, Date, Text, ForeignKey, Float, Enum as SQLEnum
from sqlalchemy.dialects.sqlite import JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime
from enum import Enum

Base = declarative_base()

# Enums for database constraints
class TransactionStatus(str, Enum):
    PENDING = "pending"
    AUTHORIZED = "authorized"
    CAPTURED = "captured"
    APPROVED = "approved"
    DECLINED = "declined"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"
    SETTLED = "settled"

class SettlementStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

class PaymentMethod(str, Enum):
    CREDIT = "credit"
    DEBIT = "debit"
    PIX = "pix"

class CardBrand(str, Enum):
    VISA = "visa"
    MASTERCARD = "mastercard"
    ELO = "elo"
    AMEX = "amex"

class TerminalStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"
    MAINTENANCE = "maintenance"

class MerchantDB(Base):
    __tablename__ = "merchants"
    
    merchant_id = Column(String, primary_key=True)
    external_merchant_id = Column(String, unique=True)  # ID from Tricket
    asaas_account_id = Column(String, nullable=False, unique=True)
    
    # Business Information
    business_name = Column(String(100), nullable=False)
    trade_name = Column(String(100))  # Nome fantasia
    document = Column(String(14), nullable=False, unique=True)  # CNPJ
    mcc = Column(String(10))  # Merchant Category Code
    
    # Contact Information
    email = Column(String(100), nullable=False)
    phone = Column(String(15), nullable=False)
    
    # Address (JSON for flexibility)
    address = Column(JSON)  # {"street", "number", "city", "state", "zip"}
    
    # Status and Configuration
    is_active = Column(Boolean, default=True)
    plan_id = Column(String, ForeignKey("merchant_plans.plan_id"))
    
    # Metadata
    merchant_metadata = Column(JSON)  # Additional merchant data
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.utcnow)
    
    # Relationships
    transactions = relationship("TransactionDB", back_populates="merchant")
    settlements = relationship("SettlementDB", back_populates="merchant")
    terminals = relationship("TerminalDB", back_populates="merchant")
    plan = relationship("MerchantPlanDB", back_populates="merchants")

class TerminalDB(Base):
    __tablename__ = "terminals"
    
    terminal_id = Column(String, primary_key=True)
    external_terminal_id = Column(String, unique=True)  # ID from Tricket
    merchant_id = Column(String, ForeignKey("merchants.merchant_id"), nullable=False)
    
    # Terminal Configuration
    serial_number = Column(String(50), nullable=False, unique=True)
    brand_acceptance = Column(JSON)  # ["visa", "mastercard", "elo"]
    capture_mode = Column(String(20), default="smartpos")  # smartpos, manual, etc
    
    # Status
    status = Column(SQLEnum(TerminalStatus), default=TerminalStatus.ACTIVE)
    
    # Metadata
    terminal_metadata = Column(JSON)  # Additional terminal configuration
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.utcnow)
    
    # Relationships
    merchant = relationship("MerchantDB", back_populates="terminals")
    transactions = relationship("TransactionDB", back_populates="terminal")
    pos_devices = relationship("POSDeviceDB", back_populates="terminal")

class TransactionDB(Base):
    __tablename__ = "transactions"
    
    transaction_id = Column(String, primary_key=True)
    merchant_id = Column(String, ForeignKey("merchants.merchant_id"), nullable=False)
    terminal_id = Column(String, ForeignKey("terminals.terminal_id"), nullable=False)
    
    # Transaction Identifiers
    nsu = Column(String(20), nullable=False, unique=True)
    authorization_code = Column(String(20), nullable=False)
    external_event_id = Column(String(50), nullable=False, unique=True)
    
    # Payment Information
    payment_method = Column(SQLEnum(PaymentMethod), nullable=False)
    card_brand = Column(SQLEnum(CardBrand))
    installments = Column(Integer, default=1)
    installment_type = Column(String(20))  # "merchant" or "issuer"
    
    # Amounts (in cents)
    gross_amount = Column(Integer, nullable=False)
    fee_amount = Column(Integer, nullable=False)
    net_amount = Column(Integer, nullable=False)
    
    # Status and Flow
    status = Column(SQLEnum(TransactionStatus), default=TransactionStatus.PENDING)
    is_captured = Column(Boolean, default=False)
    
    # Important Timestamps
    authorized_at = Column(DateTime)
    captured_at = Column(DateTime)
    cancelled_at = Column(DateTime)
    
    # Settlement Information
    settlement_id = Column(String, ForeignKey("settlements.settlement_id"))
    expected_settlement_date = Column(Date)
    
    # Metadata
    transaction_metadata = Column(JSON)  # Additional transaction data
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.utcnow)
    
    # Relationships
    merchant = relationship("MerchantDB", back_populates="transactions")
    terminal = relationship("TerminalDB", back_populates="transactions")
    settlement = relationship("SettlementDB", back_populates="transactions")
    refunds = relationship("RefundDB", back_populates="transaction")

class SettlementDB(Base):
    __tablename__ = "settlements"
    
    settlement_id = Column(String, primary_key=True)
    merchant_id = Column(String, ForeignKey("merchants.merchant_id"), nullable=False)
    
    # Amounts (in cents)
    gross_amount = Column(Integer, nullable=False)
    fee_amount = Column(Integer, nullable=False)
    net_amount = Column(Integer, nullable=False)
    
    # Settlement Details
    transaction_count = Column(Integer, nullable=False)
    settlement_date = Column(Date, nullable=False)
    settlement_type = Column(String(20), default="automatic")  # automatic, manual, anticipated
    
    # Status
    status = Column(SQLEnum(SettlementStatus), default=SettlementStatus.PENDING)
    
    # External Integration
    asaas_transfer_id = Column(String(100))
    asaas_response = Column(JSON)  # Full Asaas API response
    
    # Anticipation (ARV)
    is_anticipation = Column(Boolean, default=False)
    anticipation_fee = Column(Integer, default=0)
    original_settlement_date = Column(Date)
    
    # Metadata
    settlement_metadata = Column(JSON)  # Additional settlement data
    
    # Important Timestamps
    requested_at = Column(DateTime)
    processed_at = Column(DateTime)
    failed_at = Column(DateTime)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.utcnow)
    
    # Relationships
    merchant = relationship("MerchantDB", back_populates="settlements")
    transactions = relationship("TransactionDB", back_populates="settlement")

# New Tables for Expanded Functionality

class MerchantPlanDB(Base):
    __tablename__ = "merchant_plans"
    
    plan_id = Column(String, primary_key=True)
    plan_name = Column(String(100), nullable=False)
    
    # Fee Structure (JSON for flexibility)
    fee_structure = Column(JSON)  # {"credit": {"percentage": 3.0, "fixed": 30}, "debit": ...}
    
    # Plan Configuration
    is_active = Column(Boolean, default=True)
    is_default = Column(Boolean, default=False)
    
    # Metadata
    description = Column(Text)
    plan_metadata = Column(JSON)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.utcnow)
    
    # Relationships
    merchants = relationship("MerchantDB", back_populates="plan")


class POSDeviceDB(Base):
    __tablename__ = "pos_devices"
    
    device_id = Column(String, primary_key=True)
    terminal_id = Column(String, ForeignKey("terminals.terminal_id"), nullable=False)
    
    # Device Information
    device_type = Column(String(20), default="smartpos")  # smartpos, pinpad, etc
    model = Column(String(50))
    firmware_version = Column(String(20))
    
    # Status
    status = Column(SQLEnum(TerminalStatus), default=TerminalStatus.ACTIVE)
    
    # Configuration
    configuration = Column(JSON)  # Device-specific settings
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.utcnow)
    
    # Relationships
    terminal = relationship("TerminalDB", back_populates="pos_devices")


class RefundDB(Base):
    __tablename__ = "refunds"
    
    refund_id = Column(String, primary_key=True)
    transaction_id = Column(String, ForeignKey("transactions.transaction_id"), nullable=False)
    
    # Refund Information
    refund_amount = Column(Integer, nullable=False)  # Amount refunded (in cents)
    refund_reason = Column(String(100))
    refund_type = Column(String(20), default="partial")  # partial, total
    
    # Status
    status = Column(String(20), default="pending")  # pending, completed, failed
    
    # External Integration
    asaas_refund_id = Column(String(100))
    external_refund_id = Column(String(50))
    
    # Timestamps
    requested_at = Column(DateTime, default=datetime.utcnow)
    processed_at = Column(DateTime)
    
    # Relationships
    transaction = relationship("TransactionDB", back_populates="refunds")


class WebhookLogDB(Base):
    __tablename__ = "webhook_logs"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    
    # Event Information
    event_type = Column(String(50), nullable=False)
    event_id = Column(String, unique=True)  # Unique event identifier
    
    # Related Entities
    merchant_id = Column(String)
    transaction_id = Column(String)
    settlement_id = Column(String)
    refund_id = Column(String)
    
    # Webhook Details
    webhook_url = Column(String(500), nullable=False)
    payload = Column(Text, nullable=False)
    signature = Column(String(100))  # HMAC signature
    
    # Response Information
    response_status = Column(Integer)
    response_body = Column(Text)
    response_time_ms = Column(Integer)  # Response time in milliseconds
    
    # Retry Logic
    attempt_count = Column(Integer, default=1)
    max_attempts = Column(Integer, default=5)
    next_retry_at = Column(DateTime)
    
    # Status
    success = Column(Boolean, default=False)
    is_final = Column(Boolean, default=False)  # No more retries
    
    # Error Information
    error_message = Column(Text)
    error_type = Column(String(50))
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    processed_at = Column(DateTime)
    last_attempt_at = Column(DateTime)


class AuditLogDB(Base):
    __tablename__ = "audit_logs"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    
    # Event Information
    event_type = Column(String(50), nullable=False)
    entity_type = Column(String(50), nullable=False)  # merchant, transaction, etc
    entity_id = Column(String, nullable=False)
    
    # Action Details
    action = Column(String(20), nullable=False)  # create, update, delete
    client_id = Column(String(50))
    request_id = Column(String(50))
    
    # Request Context
    client_ip = Column(String(45))  # IPv4 or IPv6
    user_agent = Column(String(500))
    
    # Change Information
    old_values = Column(JSON)  # Previous values (for updates)
    new_values = Column(JSON)  # New values
    
    # Metadata
    audit_metadata = Column(JSON)  # Additional context
    
    # Timestamp
    created_at = Column(DateTime, default=datetime.utcnow)


# Create all indexes and constraints
def create_indexes(engine):
    """Create database indexes for better performance"""
    from sqlalchemy import Index
    
    # Transaction indexes
    Index('idx_transactions_merchant_status', TransactionDB.merchant_id, TransactionDB.status)
    Index('idx_transactions_created_at', TransactionDB.created_at)
    Index('idx_transactions_settlement', TransactionDB.settlement_id)
    Index('idx_transactions_nsu', TransactionDB.nsu)
    
    # Settlement indexes
    Index('idx_settlements_merchant_date', SettlementDB.merchant_id, SettlementDB.settlement_date)
    Index('idx_settlements_status', SettlementDB.status)
    
    # Webhook indexes
    Index('idx_webhooks_event_type', WebhookLogDB.event_type)
    Index('idx_webhooks_merchant', WebhookLogDB.merchant_id)
    Index('idx_webhooks_retry', WebhookLogDB.success, WebhookLogDB.is_final)
    
    # Audit indexes
    Index('idx_audit_entity', AuditLogDB.entity_type, AuditLogDB.entity_id)
    Index('idx_audit_client', AuditLogDB.client_id)
    Index('idx_audit_created', AuditLogDB.created_at)