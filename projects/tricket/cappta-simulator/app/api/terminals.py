from fastapi import APIRouter, HTTPException, Depends, Query, status
from sqlalchemy.orm import Session
from typing import Optional

from app.database.connection import get_db_session
from app.services.terminal_service import TerminalService
from app.models.terminal import (
    TerminalCreate, TerminalUpdate, TerminalResponse, TerminalListResponse,
    TerminalActivationRequest, TerminalActivationResponse, TerminalStats,
    TerminalFilter, TerminalSort, TerminalStatus
)
from app.models.common import ErrorResponse, CardBrand
from app.middleware.reseller_auth import require_reseller, ResellerAuth
from config.logging import get_logger

logger = get_logger(__name__)

router = APIRouter()

@router.post("/", response_model=TerminalResponse, status_code=status.HTTP_201_CREATED)
async def create_terminal(
    terminal_data: TerminalCreate,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Criar um novo terminal para um merchant
    
    - **merchant_id**: ID do merchant proprietário
    - **serial_number**: Número serial único do terminal
    - **brand_acceptance**: Lista de bandeiras aceitas
    - **capture_mode**: Modo de captura (smartpos, manual, automatic)
    - **terminal_metadata**: Metadata adicional (opcional)
    """
    try:
        terminal_service = TerminalService(db)
        terminal = terminal_service.create_terminal(terminal_data, reseller.reseller_id)
        
        logger.info(f"Terminal created via API", extra={
            "terminal_id": terminal.terminal_id,
            "merchant_id": terminal_data.merchant_id,
            "reseller_id": reseller.reseller_id,
            "serial_number": terminal_data.serial_number
        })
        
        return terminal
        
    except ValueError as e:
        logger.warning(f"Terminal creation validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Terminal creation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while creating terminal"
        )

@router.get("/", response_model=TerminalListResponse)
async def list_terminals(
    # Filtering parameters
    merchant_id: Optional[str] = Query(None, description="Filtrar por merchant ID"),
    status: Optional[TerminalStatus] = Query(None, description="Filtrar por status"),
    serial_number: Optional[str] = Query(None, description="Filtrar por serial number (busca parcial)"),
    brand: Optional[CardBrand] = Query(None, description="Filtrar por bandeira aceita"),
    has_pos_devices: Optional[bool] = Query(None, description="Filtrar terminais com/sem dispositivos POS"),
    
    # Sorting parameters
    sort: TerminalSort = Query(TerminalSort.CREATED_DESC, description="Ordenação dos resultados"),
    
    # Pagination parameters
    page: int = Query(1, ge=1, description="Número da página"),
    per_page: int = Query(20, ge=1, le=100, description="Itens por página"),
    
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Listar terminais do reseller com filtros e paginação
    
    Permite filtrar por:
    - Merchant ID
    - Status do terminal
    - Número serial (busca parcial)
    - Bandeira aceita
    - Presença de dispositivos POS
    
    Suporta ordenação por data de criação, atualização, serial number ou status.
    """
    try:
        terminal_service = TerminalService(db)
        
        filters = TerminalFilter(
            merchant_id=merchant_id,
            status=status,
            serial_number=serial_number,
            brand=brand,
            has_pos_devices=has_pos_devices
        )
        
        terminals = terminal_service.list_terminals(
            reseller_id=reseller.reseller_id,
            filters=filters,
            sort=sort,
            page=page,
            per_page=per_page
        )
        
        logger.info(f"Terminals listed via API", extra={
            "reseller_id": reseller.reseller_id,
            "total_found": terminals.total,
            "page": page,
            "filters": filters.model_dump(exclude_unset=True)
        })
        
        return terminals
        
    except Exception as e:
        logger.error(f"Error listing terminals: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while listing terminals"
        )

@router.get("/{terminal_id}", response_model=TerminalResponse)
async def get_terminal(
    terminal_id: str,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Buscar um terminal específico por ID
    
    Retorna todas as informações do terminal incluindo:
    - Dados básicos do terminal
    - Informações do merchant proprietário
    - Contagem de dispositivos POS associados
    - Data da última transação
    """
    try:
        terminal_service = TerminalService(db)
        terminal = terminal_service.get_terminal_by_id(terminal_id, reseller.reseller_id)
        
        if not terminal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Terminal {terminal_id} not found"
            )
        
        logger.info(f"Terminal retrieved via API", extra={
            "terminal_id": terminal_id,
            "reseller_id": reseller.reseller_id
        })
        
        return terminal
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving terminal {terminal_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while retrieving terminal"
        )

@router.put("/{terminal_id}", response_model=TerminalResponse)
async def update_terminal(
    terminal_id: str,
    update_data: TerminalUpdate,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Atualizar dados de um terminal
    
    Permite atualizar:
    - Bandeiras aceitas
    - Modo de captura
    - Status do terminal
    - Metadata adicional
    
    Nota: Serial number não pode ser alterado após criação
    """
    try:
        terminal_service = TerminalService(db)
        terminal = terminal_service.update_terminal(terminal_id, update_data, reseller.reseller_id)
        
        if not terminal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Terminal {terminal_id} not found"
            )
        
        logger.info(f"Terminal updated via API", extra={
            "terminal_id": terminal_id,
            "reseller_id": reseller.reseller_id,
            "updated_fields": update_data.model_dump(exclude_unset=True).keys()
        })
        
        return terminal
        
    except ValueError as e:
        logger.warning(f"Terminal update validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating terminal {terminal_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while updating terminal"
        )

@router.post("/{terminal_id}/activate", response_model=TerminalActivationResponse)
async def activate_terminal(
    terminal_id: str,
    activation_request: TerminalActivationRequest,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Ativar um terminal
    
    Realiza validações antes da ativação:
    - Merchant deve estar ativo
    - Terminal deve ter bandeiras configuradas
    - Avisa se não há dispositivos POS (mas permite ativação)
    
    Use `force: true` para forçar ativação mesmo com avisos.
    """
    try:
        terminal_service = TerminalService(db)
        activation_response = terminal_service.activate_terminal(
            terminal_id, activation_request, reseller.reseller_id
        )
        
        if not activation_response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Terminal {terminal_id} not found"
            )
        
        logger.info(f"Terminal activated via API", extra={
            "terminal_id": terminal_id,
            "reseller_id": reseller.reseller_id,
            "forced": activation_request.force,
            "warnings_count": len(activation_response.validation_warnings)
        })
        
        return activation_response
        
    except ValueError as e:
        logger.warning(f"Terminal activation validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error activating terminal {terminal_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while activating terminal"
        )

@router.get("/{terminal_id}/stats", response_model=TerminalStats)
async def get_terminal_stats(
    terminal_id: str,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Obter estatísticas de um terminal
    
    Retorna:
    - Total de transações (sucessos/falhas)
    - Volume total processado
    - Data da última transação
    - Contagem de dispositivos POS
    - Porcentagem de uptime
    """
    try:
        terminal_service = TerminalService(db)
        stats = terminal_service.get_terminal_stats(terminal_id, reseller.reseller_id)
        
        if not stats:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Terminal {terminal_id} not found"
            )
        
        logger.info(f"Terminal stats retrieved via API", extra={
            "terminal_id": terminal_id,
            "reseller_id": reseller.reseller_id,
            "total_transactions": stats.total_transactions
        })
        
        return stats
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving terminal stats {terminal_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while retrieving terminal stats"
        )

@router.delete("/{terminal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_terminal(
    terminal_id: str,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Desativar um terminal
    
    Realiza soft delete alterando o status para 'inactive'.
    
    Validações:
    - Terminal não pode ter transações pendentes
    - Dispositivos POS associados são mantidos mas ficam inativos
    """
    try:
        terminal_service = TerminalService(db)
        success = terminal_service.delete_terminal(terminal_id, reseller.reseller_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Terminal {terminal_id} not found"
            )
        
        logger.info(f"Terminal deactivated via API", extra={
            "terminal_id": terminal_id,
            "reseller_id": reseller.reseller_id
        })
        
        # 204 No Content - no response body
        return
        
    except ValueError as e:
        logger.warning(f"Terminal deletion validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting terminal {terminal_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while deleting terminal"
        )