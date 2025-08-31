from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional
from datetime import datetime

from app.models.transaction import (
    TransactionCreate, 
    TransactionCreateResponse, 
    TransactionListResponse,
    TransactionStatusUpdate
)
from app.models.common import TransactionStatus, ErrorResponse
from app.services.transaction_processor import TransactionProcessor
from app.api.auth import verify_token_and_ip

router = APIRouter()

@router.post("/", response_model=TransactionCreateResponse)
async def create_transaction(
    transaction_data: TransactionCreate,
    _: str = Depends(verify_token_and_ip)
):
    """Cria uma nova transação simulada"""
    
    try:
        processor = TransactionProcessor()
        transaction = await processor.create_transaction(transaction_data)
        
        return TransactionCreateResponse(
            success=True,
            message="Transaction created successfully",
            data=transaction
        )
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create transaction: {str(e)}"
        )

@router.get("/{transaction_id}", response_model=TransactionCreateResponse)
async def get_transaction(
    transaction_id: str,
    _: str = Depends(verify_token_and_ip)
):
    """Consulta uma transação por ID"""
    
    try:
        processor = TransactionProcessor()
        transaction = await processor.get_transaction(transaction_id)
        
        if not transaction:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Transaction {transaction_id} not found"
            )
        
        return TransactionCreateResponse(
            success=True,
            message="Transaction found",
            data=transaction
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get transaction: {str(e)}"
        )

@router.get("/", response_model=TransactionListResponse)
async def list_transactions(
    merchant_id: Optional[str] = Query(None),
    status: Optional[TransactionStatus] = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: str = Depends(verify_token_and_ip)
):
    """Lista transações com filtros"""
    
    try:
        processor = TransactionProcessor()
        transactions = await processor.list_transactions(
            merchant_id=merchant_id,
            status=status,
            page=page,
            per_page=per_page
        )
        
        return TransactionListResponse(
            success=True,
            message=f"Found {len(transactions)} transactions",
            data=transactions,
            total=len(transactions),
            page=page,
            per_page=per_page
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list transactions: {str(e)}"
        )

@router.put("/{transaction_id}/status", response_model=TransactionCreateResponse)
async def update_transaction_status(
    transaction_id: str,
    status_update: TransactionStatusUpdate,
    _: str = Depends(verify_token_and_ip)
):
    """Atualiza status de uma transação"""
    
    try:
        processor = TransactionProcessor()
        transaction = await processor.update_transaction_status(
            transaction_id=transaction_id,
            new_status=status_update.status,
            reason=status_update.reason
        )
        
        if not transaction:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Transaction {transaction_id} not found"
            )
        
        return TransactionCreateResponse(
            success=True,
            message=f"Transaction status updated to {status_update.status.value}",
            data=transaction
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update transaction status: {str(e)}"
        )

@router.post("/simulate-batch")
async def simulate_batch_transactions(
    merchant_id: str,
    count: int = Query(10, ge=1, le=100),
    base_amount: int = Query(10000, ge=100),  # R$ 100,00 in cents
    _: str = Depends(verify_token_and_ip)
):
    """Simula múltiplas transações para testes"""
    
    try:
        processor = TransactionProcessor()
        transactions = []
        
        for i in range(count):
            # Varia o valor em ±20%
            import random
            amount_variation = random.uniform(0.8, 1.2)
            amount = int(base_amount * amount_variation)
            
            transaction_data = TransactionCreate(
                merchant_id=merchant_id,
                terminal_id=f"term_{random.randint(1, 5):03d}",
                gross_amount=amount,
                installments=random.choice([1, 2, 3, 6, 12]),
                captured_at=datetime.now()
            )
            
            transaction = await processor.create_transaction(transaction_data)
            transactions.append(transaction)
        
        return TransactionListResponse(
            success=True,
            message=f"Created {len(transactions)} test transactions",
            data=transactions,
            total=len(transactions),
            page=1,
            per_page=count
        )
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to simulate transactions: {str(e)}"
        )