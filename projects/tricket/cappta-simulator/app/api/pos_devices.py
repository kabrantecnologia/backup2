from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.orm import Session

from app.database.connection import get_db_session
from app.services.pos_device_service import POSDeviceService
from app.models.pos_device import (
    POSDeviceCreate, POSDeviceUpdate, POSDeviceResponse, POSDeviceListResponse,
    POSDeviceConfigurationUpdate, POSDeviceConfigurationResponse, POSDeviceStats
)
from app.middleware.reseller_auth import require_reseller, ResellerAuth
from config.logging import get_logger

logger = get_logger(__name__)

router = APIRouter()

@router.post("/terminals/{terminal_id}/pos-devices", response_model=POSDeviceResponse, status_code=status.HTTP_201_CREATED)
async def create_pos_device(
    terminal_id: str,
    device_data: POSDeviceCreate,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Criar um novo dispositivo POS para um terminal
    
    - **terminal_id**: ID do terminal que receberá o dispositivo
    - **device_type**: Tipo do dispositivo (smartpos, pinpad, mobile, terminal)
    - **model**: Modelo do dispositivo
    - **firmware_version**: Versão do firmware (opcional)
    - **configuration**: Configurações específicas do dispositivo (opcional - usa padrões)
    
    O dispositivo será criado com configurações padrão baseadas no tipo,
    se nenhuma configuração for fornecida.
    """
    try:
        pos_device_service = POSDeviceService(db)
        device = pos_device_service.create_pos_device(terminal_id, device_data, reseller.reseller_id)
        
        logger.info(f"POS device created via API", extra={
            "device_id": device.device_id,
            "terminal_id": terminal_id,
            "device_type": device_data.device_type,
            "reseller_id": reseller.reseller_id
        })
        
        return device
        
    except ValueError as e:
        logger.warning(f"POS device creation validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"POS device creation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while creating POS device"
        )

@router.get("/terminals/{terminal_id}/pos-devices", response_model=POSDeviceListResponse)
async def list_pos_devices(
    terminal_id: str,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Listar todos os dispositivos POS de um terminal
    
    Retorna informações completas de todos os dispositivos associados
    ao terminal, incluindo status, configurações e dados do terminal.
    """
    try:
        pos_device_service = POSDeviceService(db)
        devices = pos_device_service.list_pos_devices_by_terminal(terminal_id, reseller.reseller_id)
        
        logger.info(f"POS devices listed via API", extra={
            "terminal_id": terminal_id,
            "device_count": devices.total,
            "reseller_id": reseller.reseller_id
        })
        
        return devices
        
    except ValueError as e:
        logger.warning(f"POS device listing validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error listing POS devices for terminal {terminal_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while listing POS devices"
        )

@router.get("/pos-devices/{device_id}", response_model=POSDeviceResponse)
async def get_pos_device(
    device_id: str,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Buscar um dispositivo POS específico por ID
    
    Retorna informações completas do dispositivo incluindo:
    - Configurações atuais
    - Status operacional
    - Dados do terminal associado
    - Histórico de atividade
    """
    try:
        pos_device_service = POSDeviceService(db)
        device = pos_device_service.get_pos_device_by_id(device_id, reseller.reseller_id)
        
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"POS device {device_id} not found"
            )
        
        logger.info(f"POS device retrieved via API", extra={
            "device_id": device_id,
            "terminal_id": device.terminal_id,
            "reseller_id": reseller.reseller_id
        })
        
        return device
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving POS device {device_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while retrieving POS device"
        )

@router.put("/pos-devices/{device_id}", response_model=POSDeviceResponse)
async def update_pos_device(
    device_id: str,
    update_data: POSDeviceUpdate,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Atualizar dados de um dispositivo POS
    
    Permite atualizar:
    - Tipo do dispositivo
    - Modelo
    - Versão do firmware
    - Status operacional
    - Configurações básicas
    
    Para atualizações de configuração avançada, use o endpoint específico.
    """
    try:
        pos_device_service = POSDeviceService(db)
        device = pos_device_service.update_pos_device(device_id, update_data, reseller.reseller_id)
        
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"POS device {device_id} not found"
            )
        
        logger.info(f"POS device updated via API", extra={
            "device_id": device_id,
            "terminal_id": device.terminal_id,
            "updated_fields": update_data.model_dump(exclude_unset=True).keys(),
            "reseller_id": reseller.reseller_id
        })
        
        return device
        
    except ValueError as e:
        logger.warning(f"POS device update validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating POS device {device_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while updating POS device"
        )

@router.put("/pos-devices/{device_id}/config", response_model=POSDeviceConfigurationResponse)
async def update_device_configuration(
    device_id: str,
    config_update: POSDeviceConfigurationUpdate,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Atualizar configuração avançada de um dispositivo POS
    
    Permite configurar:
    - Parâmetros de display e interface
    - Configurações de conectividade
    - Configurações de pagamento
    - Configurações de segurança
    - Configurações de impressão
    
    **restart_required**: Se true, o dispositivo precisa ser reiniciado para aplicar as configurações.
    
    A configuração é validada antes da aplicação e incrementa a versão da configuração.
    """
    try:
        pos_device_service = POSDeviceService(db)
        config_response = pos_device_service.update_device_configuration(
            device_id, config_update, reseller.reseller_id
        )
        
        if not config_response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"POS device {device_id} not found"
            )
        
        logger.info(f"POS device configuration updated via API", extra={
            "device_id": device_id,
            "configuration_version": config_response.configuration_version,
            "restart_required": config_update.restart_required,
            "reseller_id": reseller.reseller_id
        })
        
        return config_response
        
    except ValueError as e:
        logger.warning(f"POS device configuration validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating POS device configuration {device_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while updating POS device configuration"
        )

@router.post("/pos-devices/{device_id}/activate", response_model=POSDeviceResponse)
async def activate_pos_device(
    device_id: str,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Ativar um dispositivo POS
    
    Validações antes da ativação:
    - Terminal deve estar ativo
    - Configuração deve ser válida
    - Dispositivo deve estar em condições operacionais
    
    Após ativação, o dispositivo estará pronto para processar transações.
    """
    try:
        pos_device_service = POSDeviceService(db)
        device = pos_device_service.activate_pos_device(device_id, reseller.reseller_id)
        
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"POS device {device_id} not found"
            )
        
        logger.info(f"POS device activated via API", extra={
            "device_id": device_id,
            "terminal_id": device.terminal_id,
            "reseller_id": reseller.reseller_id
        })
        
        return device
        
    except ValueError as e:
        logger.warning(f"POS device activation validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error activating POS device {device_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while activating POS device"
        )

@router.get("/pos-devices/{device_id}/stats", response_model=POSDeviceStats)
async def get_pos_device_stats(
    device_id: str,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Obter estatísticas de um dispositivo POS
    
    Retorna:
    - Status operacional e uptime
    - Estatísticas de transações
    - Histórico de atividade
    - Versão da configuração atual
    - Contadores de erro e eventos
    """
    try:
        pos_device_service = POSDeviceService(db)
        stats = pos_device_service.get_pos_device_stats(device_id, reseller.reseller_id)
        
        if not stats:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"POS device {device_id} not found"
            )
        
        logger.info(f"POS device stats retrieved via API", extra={
            "device_id": device_id,
            "terminal_id": stats.terminal_id,
            "total_transactions": stats.total_transactions,
            "reseller_id": reseller.reseller_id
        })
        
        return stats
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving POS device stats {device_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while retrieving POS device stats"
        )

@router.delete("/pos-devices/{device_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_pos_device(
    device_id: str,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Desativar um dispositivo POS
    
    Realiza soft delete alterando o status para 'inactive'.
    
    O dispositivo permanece no banco de dados para fins de auditoria,
    mas não será mais utilizado para processar transações.
    """
    try:
        pos_device_service = POSDeviceService(db)
        success = pos_device_service.delete_pos_device(device_id, reseller.reseller_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"POS device {device_id} not found"
            )
        
        logger.info(f"POS device deactivated via API", extra={
            "device_id": device_id,
            "reseller_id": reseller.reseller_id
        })
        
        # 204 No Content - no response body
        return
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting POS device {device_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while deleting POS device"
        )