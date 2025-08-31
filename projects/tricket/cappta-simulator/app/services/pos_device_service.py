from sqlalchemy.orm import Session
from sqlalchemy import and_, func, desc
from typing import Optional, List
import uuid
from datetime import datetime

from app.database.models import POSDeviceDB, TerminalDB, MerchantDB
from app.models.pos_device import (
    POSDeviceCreate, POSDeviceUpdate, POSDeviceResponse, POSDeviceListResponse,
    POSDeviceConfigurationUpdate, POSDeviceConfigurationResponse, POSDeviceStats,
    POSDeviceDefaults, POSDeviceBusinessRules, DeviceStatus, DeviceType
)
from config.logging import get_logger

logger = get_logger(__name__)

class POSDeviceService:
    """Service for managing POS devices"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def create_pos_device(
        self,
        terminal_id: str,
        device_data: POSDeviceCreate,
        reseller_id: str
    ) -> POSDeviceResponse:
        """Create a new POS device for a terminal"""
        try:
            # Validate terminal exists and belongs to reseller
            terminal = self._get_terminal_by_id(terminal_id, reseller_id)
            if not terminal:
                raise ValueError(f"Terminal {terminal_id} not found or doesn't belong to reseller")
            
            # Check device limit per terminal
            current_device_count = self.db.query(POSDeviceDB).filter(
                POSDeviceDB.terminal_id == terminal_id
            ).count()
            
            if current_device_count >= POSDeviceBusinessRules.MAX_DEVICES_PER_TERMINAL:
                raise ValueError(f"Terminal exceeded maximum POS devices limit ({POSDeviceBusinessRules.MAX_DEVICES_PER_TERMINAL})")
            
            # Check device compatibility with terminal capture mode
            if not POSDeviceBusinessRules.is_compatible_with_terminal(device_data.device_type, terminal.capture_mode):
                raise ValueError(f"Device type {device_data.device_type} is not compatible with terminal capture mode {terminal.capture_mode}")
            
            # Get default configuration if not provided
            if not device_data.configuration:
                device_data.configuration = POSDeviceDefaults.get_default_config(device_data.device_type)
            
            # Validate configuration
            is_valid, errors = POSDeviceBusinessRules.validate_configuration(
                device_data.configuration, 
                device_data.device_type
            )
            if not is_valid:
                raise ValueError(f"Invalid device configuration: {'; '.join(errors)}")
            
            # Create POS device
            db_device = POSDeviceDB(
                device_id=str(uuid.uuid4()),
                terminal_id=terminal_id,
                device_type=device_data.device_type.value,
                model=device_data.model,
                firmware_version=device_data.firmware_version,
                status="inactive",  # New devices start inactive
                configuration=device_data.configuration
            )
            
            self.db.add(db_device)
            self.db.commit()
            self.db.refresh(db_device)
            
            logger.info(f"Created POS device: {db_device.device_id}", extra={
                "device_id": db_device.device_id,
                "terminal_id": terminal_id,
                "device_type": device_data.device_type,
                "model": device_data.model,
                "reseller_id": reseller_id
            })
            
            return self._to_response(db_device, include_terminal_info=True)
            
        except Exception as e:
            logger.error(f"Error creating POS device: {str(e)}")
            self.db.rollback()
            raise
    
    def list_pos_devices_by_terminal(self, terminal_id: str, reseller_id: str) -> POSDeviceListResponse:
        """List all POS devices for a terminal"""
        try:
            # Validate terminal exists and belongs to reseller
            terminal = self._get_terminal_by_id(terminal_id, reseller_id)
            if not terminal:
                raise ValueError(f"Terminal {terminal_id} not found or doesn't belong to reseller")
            
            devices = self.db.query(POSDeviceDB).filter(
                POSDeviceDB.terminal_id == terminal_id
            ).order_by(desc(POSDeviceDB.created_at)).all()
            
            device_responses = [
                self._to_response(device, include_terminal_info=True)
                for device in devices
            ]
            
            logger.info(f"Listed POS devices for terminal", extra={
                "terminal_id": terminal_id,
                "device_count": len(device_responses),
                "reseller_id": reseller_id
            })
            
            return POSDeviceListResponse(
                pos_devices=device_responses,
                terminal_id=terminal_id,
                total=len(device_responses)
            )
            
        except Exception as e:
            logger.error(f"Error listing POS devices for terminal {terminal_id}: {str(e)}")
            raise
    
    def get_pos_device_by_id(self, device_id: str, reseller_id: str) -> Optional[POSDeviceResponse]:
        """Get POS device by ID"""
        device = self._get_pos_device_by_id(device_id, reseller_id)
        return self._to_response(device, include_terminal_info=True) if device else None
    
    def update_pos_device(
        self,
        device_id: str,
        update_data: POSDeviceUpdate,
        reseller_id: str
    ) -> Optional[POSDeviceResponse]:
        """Update POS device data"""
        try:
            device = self._get_pos_device_by_id(device_id, reseller_id)
            if not device:
                return None
            
            # Update only provided fields
            update_dict = update_data.model_dump(exclude_unset=True)
            
            # Validate configuration if being updated
            if 'configuration' in update_dict and update_dict['configuration']:
                device_type = DeviceType(device.device_type)
                is_valid, errors = POSDeviceBusinessRules.validate_configuration(
                    update_dict['configuration'], 
                    device_type
                )
                if not is_valid:
                    raise ValueError(f"Invalid device configuration: {'; '.join(errors)}")
            
            for field, value in update_dict.items():
                if field in ['device_type', 'status'] and value:
                    # Handle enums
                    setattr(device, field, value.value if hasattr(value, 'value') else value)
                else:
                    setattr(device, field, value)
            
            device.updated_at = datetime.utcnow()
            
            self.db.commit()
            self.db.refresh(device)
            
            logger.info(f"Updated POS device: {device_id}", extra={
                "device_id": device_id,
                "updated_fields": list(update_dict.keys()),
                "reseller_id": reseller_id
            })
            
            return self._to_response(device, include_terminal_info=True)
            
        except Exception as e:
            logger.error(f"Error updating POS device {device_id}: {str(e)}")
            self.db.rollback()
            raise
    
    def update_device_configuration(
        self,
        device_id: str,
        config_update: POSDeviceConfigurationUpdate,
        reseller_id: str
    ) -> Optional[POSDeviceConfigurationResponse]:
        """Update device configuration"""
        try:
            device = self._get_pos_device_by_id(device_id, reseller_id)
            if not device:
                return None
            
            # Validate configuration
            device_type = DeviceType(device.device_type)
            is_valid, errors = POSDeviceBusinessRules.validate_configuration(
                config_update.configuration,
                device_type
            )
            if not is_valid:
                raise ValueError(f"Invalid device configuration: {'; '.join(errors)}")
            
            # Update configuration
            device.configuration = config_update.configuration
            device.updated_at = datetime.utcnow()
            
            # Increment configuration version (stored in metadata)
            current_version = 1
            if device.configuration and isinstance(device.configuration, dict):
                current_version = device.configuration.get('_version', 1) + 1
                device.configuration['_version'] = current_version
            
            self.db.commit()
            self.db.refresh(device)
            
            logger.info(f"Updated POS device configuration: {device_id}", extra={
                "device_id": device_id,
                "configuration_version": current_version,
                "restart_required": config_update.restart_required,
                "reseller_id": reseller_id
            })
            
            return POSDeviceConfigurationResponse(
                device_id=device_id,
                configuration=device.configuration,
                restart_required=config_update.restart_required,
                updated_at=datetime.utcnow(),
                configuration_version=current_version
            )
            
        except Exception as e:
            logger.error(f"Error updating POS device configuration {device_id}: {str(e)}")
            self.db.rollback()
            raise
    
    def get_pos_device_stats(self, device_id: str, reseller_id: str) -> Optional[POSDeviceStats]:
        """Get POS device statistics"""
        device = self._get_pos_device_by_id(device_id, reseller_id)
        if not device:
            return None
        
        # TODO: Implement actual transaction counting and activity tracking
        # For now, return basic stats
        
        config_version = 1
        if device.configuration and isinstance(device.configuration, dict):
            config_version = device.configuration.get('_version', 1)
        
        return POSDeviceStats(
            device_id=device_id,
            terminal_id=device.terminal_id,
            status=DeviceStatus(device.status),
            uptime_percentage=100.0,  # TODO: Calculate actual uptime
            total_transactions=0,     # TODO: Count actual transactions
            last_transaction_at=None, # TODO: Get actual last transaction
            last_heartbeat_at=None,   # TODO: Track device heartbeats
            error_count=0,            # TODO: Track device errors
            last_error_at=None,       # TODO: Track last error
            configuration_version=config_version
        )
    
    def activate_pos_device(self, device_id: str, reseller_id: str) -> Optional[POSDeviceResponse]:
        """Activate a POS device"""
        try:
            device = self._get_pos_device_by_id(device_id, reseller_id)
            if not device:
                return None
            
            # Check if terminal is active
            terminal = device.terminal
            if terminal.status != "active":
                raise ValueError("Cannot activate POS device: terminal is not active")
            
            device.status = "active"
            device.updated_at = datetime.utcnow()
            
            self.db.commit()
            self.db.refresh(device)
            
            logger.info(f"Activated POS device: {device_id}", extra={
                "device_id": device_id,
                "terminal_id": device.terminal_id,
                "reseller_id": reseller_id
            })
            
            return self._to_response(device, include_terminal_info=True)
            
        except Exception as e:
            logger.error(f"Error activating POS device {device_id}: {str(e)}")
            self.db.rollback()
            raise
    
    def delete_pos_device(self, device_id: str, reseller_id: str) -> bool:
        """Delete/deactivate POS device"""
        try:
            device = self._get_pos_device_by_id(device_id, reseller_id)
            if not device:
                return False
            
            # TODO: Check if device has pending operations
            
            # Soft delete - change status to inactive
            device.status = "inactive"
            device.updated_at = datetime.utcnow()
            
            self.db.commit()
            
            logger.info(f"Deactivated POS device: {device_id}", extra={
                "device_id": device_id,
                "terminal_id": device.terminal_id,
                "reseller_id": reseller_id
            })
            
            return True
            
        except Exception as e:
            logger.error(f"Error deleting POS device {device_id}: {str(e)}")
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
    
    def _get_pos_device_by_id(self, device_id: str, reseller_id: str) -> Optional[POSDeviceDB]:
        """Get POS device by ID ensuring it belongs to the reseller"""
        return self.db.query(POSDeviceDB).join(TerminalDB).join(MerchantDB).filter(
            and_(
                POSDeviceDB.device_id == device_id,
                MerchantDB.reseller_id == reseller_id
            )
        ).first()
    
    def _to_response(self, device: POSDeviceDB, include_terminal_info: bool = False) -> POSDeviceResponse:
        """Convert POSDeviceDB to POSDeviceResponse"""
        
        response_data = {
            "device_id": device.device_id,
            "terminal_id": device.terminal_id,
            "device_type": device.device_type,
            "model": device.model,
            "firmware_version": device.firmware_version,
            "status": device.status,
            "configuration": device.configuration or {},
            "last_activity": None,  # TODO: Track actual activity
            "created_at": device.created_at,
            "updated_at": device.updated_at
        }
        
        if include_terminal_info and device.terminal:
            response_data.update({
                "terminal_serial_number": device.terminal.serial_number,
                "terminal_status": device.terminal.status
            })
        
        return POSDeviceResponse(**response_data)