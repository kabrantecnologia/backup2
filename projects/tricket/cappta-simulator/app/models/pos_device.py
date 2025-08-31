from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

class DeviceType(str, Enum):
    SMARTPOS = "smartpos"
    PINPAD = "pinpad"
    MOBILE = "mobile"
    TERMINAL = "terminal"

class DeviceStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    MAINTENANCE = "maintenance"
    ERROR = "error"

class POSDeviceBase(BaseModel):
    """Base model for POS Device data"""
    device_type: DeviceType = DeviceType.SMARTPOS
    model: str = Field(..., min_length=1, max_length=50, description="Modelo do dispositivo")
    firmware_version: Optional[str] = Field(None, max_length=20, description="Versão do firmware")
    configuration: Dict[str, Any] = Field(default_factory=dict, description="Configurações do dispositivo")

    @validator('model')
    def validate_model(cls, v):
        return v.strip().upper()

    @validator('firmware_version')
    def validate_firmware_version(cls, v):
        if v:
            return v.strip()
        return v

class POSDeviceCreate(POSDeviceBase):
    """Model for creating a new POS device"""
    pass

class POSDeviceUpdate(BaseModel):
    """Model for updating POS device data"""
    device_type: Optional[DeviceType] = None
    model: Optional[str] = Field(None, min_length=1, max_length=50)
    firmware_version: Optional[str] = Field(None, max_length=20)
    configuration: Optional[Dict[str, Any]] = None
    status: Optional[DeviceStatus] = None

    @validator('model')
    def validate_model(cls, v):
        if v:
            return v.strip().upper()
        return v

class POSDeviceResponse(POSDeviceBase):
    """Model for POS device API responses"""
    device_id: str
    terminal_id: str
    status: DeviceStatus
    last_activity: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    # Terminal info (quando incluído)
    terminal_serial_number: Optional[str] = None
    terminal_status: Optional[str] = None
    
    class Config:
        from_attributes = True

class POSDeviceListResponse(BaseModel):
    """Model for POS device list responses"""
    pos_devices: List[POSDeviceResponse]
    terminal_id: str
    total: int

class POSDeviceConfigurationUpdate(BaseModel):
    """Model for updating device configuration"""
    configuration: Dict[str, Any] = Field(..., description="Nova configuração do dispositivo")
    restart_required: bool = Field(False, description="Se o dispositivo precisa ser reiniciado")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Metadata da configuração")

class POSDeviceConfigurationResponse(BaseModel):
    """Model for device configuration update response"""
    device_id: str
    configuration: Dict[str, Any]
    restart_required: bool
    updated_at: datetime
    configuration_version: int = 1

class POSDeviceActivity(BaseModel):
    """Model for device activity tracking"""
    device_id: str
    activity_type: str  # "heartbeat", "transaction", "config_update", "error"
    activity_data: Dict[str, Any] = Field(default_factory=dict)
    timestamp: datetime

class POSDeviceStats(BaseModel):
    """Model for POS device statistics"""
    device_id: str
    terminal_id: str
    status: DeviceStatus
    uptime_percentage: float = 100.0
    total_transactions: int = 0
    last_transaction_at: Optional[datetime] = None
    last_heartbeat_at: Optional[datetime] = None
    error_count: int = 0
    last_error_at: Optional[datetime] = None
    configuration_version: int = 1

# Configuration templates for different device types
class POSDeviceDefaults:
    """Default configurations for different device types"""
    
    SMARTPOS_CONFIG = {
        "display": {
            "brightness": 80,
            "timeout": 30,
            "language": "pt-BR"
        },
        "connectivity": {
            "wifi_enabled": True,
            "bluetooth_enabled": False,
            "ethernet_enabled": True
        },
        "payment": {
            "contactless_enabled": True,
            "chip_enabled": True,
            "magnetic_enabled": True
        },
        "security": {
            "pin_required": True,
            "timeout_seconds": 60,
            "max_attempts": 3
        },
        "printing": {
            "auto_print": True,
            "paper_size": "80mm",
            "logo_enabled": True
        }
    }
    
    PINPAD_CONFIG = {
        "display": {
            "brightness": 70,
            "timeout": 15
        },
        "connectivity": {
            "wifi_enabled": False,
            "bluetooth_enabled": True,
            "ethernet_enabled": False
        },
        "payment": {
            "contactless_enabled": True,
            "chip_enabled": True,
            "magnetic_enabled": False
        },
        "security": {
            "pin_required": True,
            "timeout_seconds": 30,
            "max_attempts": 3
        }
    }
    
    MOBILE_CONFIG = {
        "app": {
            "auto_update": True,
            "offline_mode": True,
            "sync_interval": 300
        },
        "payment": {
            "contactless_enabled": True,
            "chip_enabled": False,
            "magnetic_enabled": False
        },
        "security": {
            "pin_required": False,
            "biometric_enabled": True,
            "session_timeout": 900
        }
    }

    @classmethod
    def get_default_config(cls, device_type: DeviceType) -> Dict[str, Any]:
        """Get default configuration for device type"""
        config_map = {
            DeviceType.SMARTPOS: cls.SMARTPOS_CONFIG,
            DeviceType.PINPAD: cls.PINPAD_CONFIG,
            DeviceType.MOBILE: cls.MOBILE_CONFIG,
            DeviceType.TERMINAL: cls.SMARTPOS_CONFIG  # Terminal uses SmartPOS config
        }
        return config_map.get(device_type, cls.SMARTPOS_CONFIG).copy()

# Business rules
class POSDeviceBusinessRules:
    """POS Device business rules and constants"""
    
    MAX_DEVICES_PER_TERMINAL = 10
    MIN_FIRMWARE_VERSION = "1.0.0"
    
    REQUIRED_CONFIG_KEYS = ["security", "payment"]
    
    # Device type compatibility with terminal capture modes
    COMPATIBLE_DEVICES = {
        "smartpos": ["smartpos", "pinpad", "mobile"],
        "manual": ["smartpos", "pinpad", "terminal"],
        "automatic": ["smartpos", "terminal"]
    }
    
    @classmethod
    def is_compatible_with_terminal(cls, device_type: DeviceType, capture_mode: str) -> bool:
        """Check if device type is compatible with terminal capture mode"""
        return device_type.value in cls.COMPATIBLE_DEVICES.get(capture_mode, [])
    
    @classmethod
    def validate_configuration(cls, config: Dict[str, Any], device_type: DeviceType) -> tuple[bool, List[str]]:
        """Validate device configuration"""
        errors = []
        
        # Check required keys
        for key in cls.REQUIRED_CONFIG_KEYS:
            if key not in config:
                errors.append(f"Configuration missing required key: {key}")
        
        # Validate security settings
        if "security" in config:
            security = config["security"]
            if device_type in [DeviceType.SMARTPOS, DeviceType.PINPAD]:
                if not security.get("pin_required", False):
                    errors.append("PIN is required for this device type")
        
        # Validate payment settings
        if "payment" in config:
            payment = config["payment"]
            enabled_methods = [k for k, v in payment.items() if v and k.endswith("_enabled")]
            if not enabled_methods:
                errors.append("At least one payment method must be enabled")
        
        return len(errors) == 0, errors