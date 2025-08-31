from sqlalchemy import Column, String, Integer, DateTime, Boolean, Date, Text, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()

class MerchantDB(Base):
    __tablename__ = "merchants"
    
    merchant_id = Column(String, primary_key=True)
    asaas_account_id = Column(String, nullable=False, unique=True)
    business_name = Column(String(100), nullable=False)
    document = Column(String(14), nullable=False, unique=True)
    email = Column(String(100), nullable=False)
    phone = Column(String(15), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.utcnow)
    
    # Relationships
    transactions = relationship("TransactionDB", back_populates="merchant")
    settlements = relationship("SettlementDB", back_populates="merchant")

class TerminalDB(Base):
    __tablename__ = "terminals"
    
    terminal_id = Column(String, primary_key=True)
    merchant_id = Column(String, ForeignKey("merchants.merchant_id"), nullable=False)
    serial_number = Column(String(50), nullable=False, unique=True)
    model = Column(String(50), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    transactions = relationship("TransactionDB", back_populates="terminal")

class TransactionDB(Base):
    __tablename__ = "transactions"
    
    transaction_id = Column(String, primary_key=True)
    merchant_id = Column(String, ForeignKey("merchants.merchant_id"), nullable=False)
    terminal_id = Column(String, ForeignKey("terminals.terminal_id"), nullable=False)
    nsu = Column(String(20), nullable=False)
    authorization_code = Column(String(20), nullable=False)
    payment_method = Column(String(10), nullable=False)
    card_brand = Column(String(20))
    gross_amount = Column(Integer, nullable=False)
    fee_amount = Column(Integer, nullable=False)
    net_amount = Column(Integer, nullable=False)
    installments = Column(Integer, default=1)
    status = Column(String(20), nullable=False, default="pending")
    captured_at = Column(DateTime, nullable=False)
    external_event_id = Column(String(50), nullable=False, unique=True)
    settlement_id = Column(String, ForeignKey("settlements.settlement_id"))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.utcnow)
    
    # Relationships
    merchant = relationship("MerchantDB", back_populates="transactions")
    terminal = relationship("TerminalDB", back_populates="transactions")
    settlement = relationship("SettlementDB", back_populates="transactions")

class SettlementDB(Base):
    __tablename__ = "settlements"
    
    settlement_id = Column(String, primary_key=True)
    merchant_id = Column(String, ForeignKey("merchants.merchant_id"), nullable=False)
    gross_amount = Column(Integer, nullable=False)
    fee_amount = Column(Integer, nullable=False)
    net_amount = Column(Integer, nullable=False)
    transaction_count = Column(Integer, nullable=False)
    settlement_date = Column(Date, nullable=False)
    status = Column(String(20), nullable=False, default="pending")
    asaas_transfer_id = Column(String(100))
    processed_at = Column(DateTime)
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