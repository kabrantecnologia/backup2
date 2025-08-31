from sqlalchemy.orm import Session
from sqlalchemy import and_, func, desc, asc
from typing import Optional, List, Tuple
import uuid
from datetime import datetime

from app.database.models import TerminalDB, MerchantDB, TransactionDB, POSDeviceDB
from app.models.terminal import (
    TerminalCreate, TerminalUpdate, TerminalResponse, TerminalListResponse,
    TerminalActivationRequest, TerminalActivationResponse, TerminalStats,
    TerminalFilter, TerminalSort, TerminalValidation, TerminalBusinessRules,
    TerminalStatus
)
from config.logging import get_logger

logger = get_logger(__name__)

class TerminalService:
    """Service for managing terminals"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def create_terminal(self, terminal_data: TerminalCreate, reseller_id: str) -> TerminalResponse:
        """Create a new terminal"""
        try:
            # Validate merchant exists and belongs to reseller
            merchant = self._get_merchant_by_id(terminal_data.merchant_id, reseller_id)
            if not merchant:
                raise ValueError(f"Merchant {terminal_data.merchant_id} not found or doesn't belong to reseller")
            
            # Check merchant terminal limit
            current_terminal_count = self.db.query(TerminalDB).filter(
                TerminalDB.merchant_id == terminal_data.merchant_id
            ).count()
            
            if not TerminalBusinessRules.validate_merchant_terminal_limit(current_terminal_count):
                raise ValueError(f"Merchant exceeded maximum terminals limit ({TerminalBusinessRules.MAX_TERMINALS_PER_MERCHANT})")
            
            # Check serial number uniqueness
            existing_terminal = self.db.query(TerminalDB).filter(
                TerminalDB.serial_number == terminal_data.serial_number
            ).first()
            
            if existing_terminal:
                raise ValueError(f"Terminal with serial number {terminal_data.serial_number} already exists")
            
            # Create terminal
            db_terminal = TerminalDB(
                terminal_id=str(uuid.uuid4()),
                merchant_id=terminal_data.merchant_id,
                serial_number=terminal_data.serial_number,
                brand_acceptance=[brand.value for brand in terminal_data.brand_acceptance],
                capture_mode=terminal_data.capture_mode.value,
                status="inactive",  # New terminals start inactive
                terminal_metadata=terminal_data.terminal_metadata or {}
            )
            
            self.db.add(db_terminal)
            self.db.commit()
            self.db.refresh(db_terminal)
            
            logger.info(f"Created terminal: {db_terminal.terminal_id}", extra={
                "terminal_id": db_terminal.terminal_id,
                "merchant_id": terminal_data.merchant_id,
                "serial_number": terminal_data.serial_number,
                "reseller_id": reseller_id
            })
            
            return self._to_response(db_terminal, include_merchant_info=True)
            
        except Exception as e:
            logger.error(f"Error creating terminal: {str(e)}")
            self.db.rollback()
            raise
    
    def get_terminal_by_id(self, terminal_id: str, reseller_id: str) -> Optional[TerminalResponse]:
        """Get terminal by ID"""
        terminal = self._get_terminal_by_id(terminal_id, reseller_id)
        return self._to_response(terminal, include_merchant_info=True) if terminal else None
    
    def list_terminals(
        self,
        reseller_id: str,
        filters: TerminalFilter,
        sort: TerminalSort = TerminalSort.CREATED_DESC,
        page: int = 1,
        per_page: int = 20
    ) -> TerminalListResponse:
        """List terminals with filtering and pagination"""
        
        # Base query - only terminals belonging to reseller's merchants
        query = self.db.query(TerminalDB).join(MerchantDB).filter(
            MerchantDB.reseller_id == reseller_id
        )
        
        # Apply filters
        if filters.merchant_id:
            query = query.filter(TerminalDB.merchant_id == filters.merchant_id)
        
        if filters.status:
            query = query.filter(TerminalDB.status == filters.status.value)
        
        if filters.serial_number:
            query = query.filter(TerminalDB.serial_number.ilike(f"%{filters.serial_number}%"))
        
        if filters.brand:
            # JSON contains search for SQLite
            query = query.filter(TerminalDB.brand_acceptance.contains(filters.brand.value))
        
        if filters.created_after:
            query = query.filter(TerminalDB.created_at >= filters.created_after)
        
        if filters.created_before:
            query = query.filter(TerminalDB.created_at <= filters.created_before)
        
        if filters.has_pos_devices is not None:
            pos_devices_subquery = self.db.query(POSDeviceDB.terminal_id).distinct()
            if filters.has_pos_devices:
                query = query.filter(TerminalDB.terminal_id.in_(pos_devices_subquery))
            else:
                query = query.filter(~TerminalDB.terminal_id.in_(pos_devices_subquery))
        
        # Apply sorting
        if sort == TerminalSort.CREATED_ASC:
            query = query.order_by(asc(TerminalDB.created_at))
        elif sort == TerminalSort.CREATED_DESC:
            query = query.order_by(desc(TerminalDB.created_at))
        elif sort == TerminalSort.UPDATED_ASC:
            query = query.order_by(asc(TerminalDB.updated_at))
        elif sort == TerminalSort.UPDATED_DESC:
            query = query.order_by(desc(TerminalDB.updated_at))
        elif sort == TerminalSort.SERIAL_ASC:
            query = query.order_by(asc(TerminalDB.serial_number))
        elif sort == TerminalSort.SERIAL_DESC:
            query = query.order_by(desc(TerminalDB.serial_number))
        elif sort == TerminalSort.STATUS_ASC:
            query = query.order_by(asc(TerminalDB.status))
        elif sort == TerminalSort.STATUS_DESC:
            query = query.order_by(desc(TerminalDB.status))
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        offset = (page - 1) * per_page
        terminals = query.offset(offset).limit(per_page).all()
        
        # Convert to responses
        terminal_responses = [
            self._to_response(terminal, include_merchant_info=True) 
            for terminal in terminals
        ]
        
        return TerminalListResponse(
            terminals=terminal_responses,
            total=total,
            page=page,
            per_page=per_page,
            has_next=offset + per_page < total,
            has_prev=page > 1
        )
    
    def update_terminal(self, terminal_id: str, update_data: TerminalUpdate, reseller_id: str) -> Optional[TerminalResponse]:
        """Update terminal data"""
        try:
            terminal = self._get_terminal_by_id(terminal_id, reseller_id)
            if not terminal:
                return None
            
            # Update only provided fields
            update_dict = update_data.model_dump(exclude_unset=True)
            
            for field, value in update_dict.items():
                if field == 'brand_acceptance' and value:
                    # Convert enum list to string list
                    setattr(terminal, field, [brand.value if hasattr(brand, 'value') else brand for brand in value])
                elif field == 'capture_mode' and value:
                    setattr(terminal, field, value.value if hasattr(value, 'value') else value)
                elif field == 'status' and value:
                    # Status changes need validation
                    if not self._can_change_status(terminal, value):
                        raise ValueError(f"Cannot change terminal status to {value}")
                    setattr(terminal, field, value.value if hasattr(value, 'value') else value)
                else:
                    setattr(terminal, field, value)
            
            terminal.updated_at = datetime.utcnow()
            
            self.db.commit()
            self.db.refresh(terminal)
            
            logger.info(f"Updated terminal: {terminal_id}", extra={
                "terminal_id": terminal_id,
                "updated_fields": list(update_dict.keys()),
                "reseller_id": reseller_id
            })
            
            return self._to_response(terminal, include_merchant_info=True)
            
        except Exception as e:
            logger.error(f"Error updating terminal {terminal_id}: {str(e)}")
            self.db.rollback()
            raise
    
    def activate_terminal(
        self,
        terminal_id: str,
        activation_request: TerminalActivationRequest,
        reseller_id: str
    ) -> Optional[TerminalActivationResponse]:
        """Activate terminal with validations"""
        try:
            terminal = self._get_terminal_by_id(terminal_id, reseller_id)
            if not terminal:
                return None
            
            merchant = terminal.merchant
            
            # Validate activation
            terminal_data = {
                "brand_acceptance": terminal.brand_acceptance,
                "pos_devices_count": len(terminal.pos_devices) if terminal.pos_devices else 0
            }
            merchant_data = {
                "is_active": merchant.is_active
            }
            
            can_activate, warnings = TerminalValidation.can_activate(terminal_data, merchant_data)
            
            if not can_activate and not activation_request.force:
                raise ValueError(f"Cannot activate terminal: {'; '.join(warnings)}")
            
            # Activate terminal
            terminal.status = "active"
            terminal.updated_at = datetime.utcnow()
            
            # Store activation metadata
            activation_metadata = activation_request.metadata or {}
            activation_metadata.update({
                "activated_by": reseller_id,
                "activation_time": datetime.utcnow().isoformat(),
                "forced": activation_request.force,
                "warnings": warnings
            })
            
            if terminal.terminal_metadata:
                terminal.terminal_metadata.update({"last_activation": activation_metadata})
            else:
                terminal.terminal_metadata = {"last_activation": activation_metadata}
            
            self.db.commit()
            self.db.refresh(terminal)
            
            logger.info(f"Activated terminal: {terminal_id}", extra={
                "terminal_id": terminal_id,
                "reseller_id": reseller_id,
                "forced": activation_request.force,
                "warnings_count": len(warnings)
            })
            
            return TerminalActivationResponse(
                terminal_id=terminal_id,
                status=TerminalStatus.ACTIVE,
                activated_at=datetime.utcnow(),
                activation_metadata=activation_metadata,
                validation_warnings=warnings
            )
            
        except Exception as e:
            logger.error(f"Error activating terminal {terminal_id}: {str(e)}")
            self.db.rollback()
            raise
    
    def get_terminal_stats(self, terminal_id: str, reseller_id: str) -> Optional[TerminalStats]:
        """Get terminal statistics"""
        terminal = self._get_terminal_by_id(terminal_id, reseller_id)
        if not terminal:
            return None
        
        # Get transaction stats
        transaction_stats = self.db.query(
            func.count(TransactionDB.transaction_id).label('total'),
            func.count(TransactionDB.transaction_id).filter(
                TransactionDB.status.in_(['approved', 'captured', 'settled'])
            ).label('successful'),
            func.sum(TransactionDB.gross_amount).label('total_volume'),
            func.max(TransactionDB.created_at).label('last_transaction')
        ).filter(
            TransactionDB.terminal_id == terminal_id
        ).first()
        
        total_transactions = transaction_stats.total or 0
        successful_transactions = transaction_stats.successful or 0
        failed_transactions = total_transactions - successful_transactions
        total_volume = transaction_stats.total_volume or 0
        last_transaction_at = transaction_stats.last_transaction
        
        # Get POS devices count
        pos_devices_count = self.db.query(POSDeviceDB).filter(
            POSDeviceDB.terminal_id == terminal_id
        ).count()
        
        return TerminalStats(
            terminal_id=terminal_id,
            total_transactions=total_transactions,
            successful_transactions=successful_transactions,
            failed_transactions=failed_transactions,
            total_volume=total_volume,
            last_transaction_at=last_transaction_at,
            pos_devices_count=pos_devices_count,
            uptime_percentage=100.0  # TODO: Calculate actual uptime
        )
    
    def delete_terminal(self, terminal_id: str, reseller_id: str) -> bool:
        """Delete/deactivate terminal"""
        try:
            terminal = self._get_terminal_by_id(terminal_id, reseller_id)
            if not terminal:
                return False
            
            # Check if can be deactivated
            pending_transactions = self.db.query(TransactionDB).filter(
                and_(
                    TransactionDB.terminal_id == terminal_id,
                    TransactionDB.status.in_(['pending', 'authorized'])
                )
            ).count()
            
            can_deactivate, reasons = TerminalValidation.can_deactivate(
                {"terminal_id": terminal_id},
                pending_transactions
            )
            
            if not can_deactivate:
                raise ValueError(f"Cannot deactivate terminal: {'; '.join(reasons)}")
            
            # Soft delete - change status to inactive
            terminal.status = "inactive"
            terminal.updated_at = datetime.utcnow()
            
            self.db.commit()
            
            logger.info(f"Deactivated terminal: {terminal_id}", extra={
                "terminal_id": terminal_id,
                "reseller_id": reseller_id
            })
            
            return True
            
        except Exception as e:
            logger.error(f"Error deleting terminal {terminal_id}: {str(e)}")
            self.db.rollback()
            raise
    
    # Private helper methods
    
    def _get_terminal_by_id(self, terminal_id: str, reseller_id: str) -> Optional[TerminalDB]:
        """Get terminal by ID ensuring it belongs to the reseller"""
        return self.db.query(TerminalDB).join(MerchantDB).filter(
            and_(
                TerminalDB.terminal_id == terminal_id,
                MerchantDB.reseller_id == reseller_id
            )
        ).first()
    
    def _get_merchant_by_id(self, merchant_id: str, reseller_id: str) -> Optional[MerchantDB]:
        """Get merchant by ID ensuring it belongs to the reseller"""
        return self.db.query(MerchantDB).filter(
            and_(
                MerchantDB.merchant_id == merchant_id,
                MerchantDB.reseller_id == reseller_id
            )
        ).first()
    
    def _to_response(self, terminal: TerminalDB, include_merchant_info: bool = False) -> TerminalResponse:
        """Convert TerminalDB to TerminalResponse"""
        
        # Get POS devices count
        pos_devices_count = len(terminal.pos_devices) if terminal.pos_devices else 0
        
        # Get last transaction time
        last_transaction = self.db.query(TransactionDB).filter(
            TransactionDB.terminal_id == terminal.terminal_id
        ).order_by(desc(TransactionDB.created_at)).first()
        
        response_data = {
            "terminal_id": terminal.terminal_id,
            "merchant_id": terminal.merchant_id,
            "external_terminal_id": terminal.external_terminal_id,
            "serial_number": terminal.serial_number,
            "brand_acceptance": terminal.brand_acceptance,
            "capture_mode": terminal.capture_mode,
            "status": terminal.status,
            "pos_devices_count": pos_devices_count,
            "last_transaction_at": last_transaction.created_at if last_transaction else None,
            "terminal_metadata": terminal.terminal_metadata,
            "created_at": terminal.created_at,
            "updated_at": terminal.updated_at
        }
        
        if include_merchant_info and terminal.merchant:
            response_data.update({
                "merchant_business_name": terminal.merchant.business_name,
                "merchant_document": terminal.merchant.document
            })
        
        return TerminalResponse(**response_data)
    
    def _can_change_status(self, terminal: TerminalDB, new_status: TerminalStatus) -> bool:
        """Check if status change is allowed"""
        current_status = terminal.status
        
        # Define allowed transitions
        allowed_transitions = {
            "inactive": ["active", "maintenance", "suspended"],
            "active": ["inactive", "maintenance", "suspended"],
            "maintenance": ["active", "inactive"],
            "suspended": ["active", "inactive"]
        }
        
        return new_status.value in allowed_transitions.get(current_status, [])