from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional

from app.models.settlement import (
    SettlementCreate,
    SettlementCreateResponse,
    SettlementListResponse
)
from app.models.common import SettlementStatus, ErrorResponse
from app.services.settlement_processor import SettlementProcessor
from app.api.auth import verify_token_and_ip

router = APIRouter()

@router.post("/", response_model=SettlementCreateResponse)
async def create_settlement(
    settlement_data: SettlementCreate,
    _: str = Depends(verify_token_and_ip)
):
    """Cria uma nova liquidação"""
    
    try:
        processor = SettlementProcessor()
        settlement = await processor.create_settlement(settlement_data)
        
        return SettlementCreateResponse(
            success=True,
            message="Settlement created successfully",
            data=settlement
        )
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create settlement: {str(e)}"
        )

@router.get("/{settlement_id}", response_model=SettlementCreateResponse)
async def get_settlement(
    settlement_id: str,
    _: str = Depends(verify_token_and_ip)
):
    """Consulta uma liquidação por ID"""
    
    try:
        processor = SettlementProcessor()
        settlement = await processor.get_settlement(settlement_id)
        
        if not settlement:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Settlement {settlement_id} not found"
            )
        
        return SettlementCreateResponse(
            success=True,
            message="Settlement found",
            data=settlement
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get settlement: {str(e)}"
        )

@router.get("/", response_model=SettlementListResponse)
async def list_settlements(
    merchant_id: Optional[str] = Query(None),
    status: Optional[SettlementStatus] = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: str = Depends(verify_token_and_ip)
):
    """Lista liquidações com filtros"""
    
    try:
        processor = SettlementProcessor()
        settlements = await processor.list_settlements(
            merchant_id=merchant_id,
            status=status,
            page=page,
            per_page=per_page
        )
        
        return SettlementListResponse(
            success=True,
            message=f"Found {len(settlements)} settlements",
            data=settlements,
            total=len(settlements),
            page=page,
            per_page=per_page
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list settlements: {str(e)}"
        )

@router.post("/auto-settle")
async def trigger_auto_settlement(
    _: str = Depends(verify_token_and_ip)
):
    """Dispara liquidação automática de transações elegíveis"""
    
    try:
        processor = SettlementProcessor()
        await processor.auto_settle_eligible_transactions()
        
        return {
            "success": True,
            "message": "Auto settlement process triggered successfully"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to trigger auto settlement: {str(e)}"
        )

@router.get("/merchant/{merchant_id}/summary")
async def get_merchant_settlement_summary(
    merchant_id: str,
    _: str = Depends(verify_token_and_ip)
):
    """Obtém resumo de liquidações de um comerciante"""
    
    try:
        processor = SettlementProcessor()
        
        # Lista todas as liquidações do comerciante
        settlements = await processor.list_settlements(merchant_id=merchant_id, page=1, per_page=1000)
        
        # Calcula estatísticas
        pending_settlements = [s for s in settlements if s.status == SettlementStatus.PENDING]
        completed_settlements = [s for s in settlements if s.status == SettlementStatus.COMPLETED]
        
        pending_amount = sum(s.net_amount for s in pending_settlements)
        completed_amount = sum(s.net_amount for s in completed_settlements)
        
        last_settlement = max(settlements, key=lambda s: s.settlement_date) if settlements else None
        
        return {
            "success": True,
            "message": "Settlement summary generated",
            "data": {
                "merchant_id": merchant_id,
                "pending_settlements": len(pending_settlements),
                "pending_amount": pending_amount,
                "completed_settlements": len(completed_settlements),
                "completed_amount": completed_amount,
                "total_settlements": len(settlements),
                "last_settlement_date": last_settlement.settlement_date if last_settlement else None
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get settlement summary: {str(e)}"
        )