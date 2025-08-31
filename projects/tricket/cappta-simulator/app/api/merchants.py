from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional, List
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import MerchantDB
from app.models.merchant import MerchantCreate, MerchantCreateResponse, MerchantListResponse, MerchantResponse
from app.models.common import ErrorResponse
from app.api.auth import verify_token_and_ip

router = APIRouter()

@router.post("/", response_model=MerchantCreateResponse)
async def create_merchant(
    merchant_data: MerchantCreate,
    _: str = Depends(verify_token_and_ip),
    db: Session = Depends(get_db)
):
    """Cadastra um novo comerciante no simulador"""
    
    try:
        # Verifica se já existe comerciante com mesmo ID
        existing_merchant = db.query(MerchantDB).filter(
            MerchantDB.merchant_id == merchant_data.merchant_id
        ).first()
        
        if existing_merchant:
            return MerchantCreateResponse(
                success=True,
                message="Merchant already exists",
                data=_db_to_response(existing_merchant)
            )
        
        # Verifica se já existe comerciante com mesmo documento
        existing_document = db.query(MerchantDB).filter(
            MerchantDB.document == merchant_data.document
        ).first()
        
        if existing_document:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Merchant with document {merchant_data.document} already exists"
            )
        
        # Verifica se já existe comerciante com mesma conta Asaas
        existing_asaas = db.query(MerchantDB).filter(
            MerchantDB.asaas_account_id == merchant_data.asaas_account_id
        ).first()
        
        if existing_asaas:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Merchant with Asaas account {merchant_data.asaas_account_id} already exists"
            )
        
        # Cria novo comerciante
        db_merchant = MerchantDB(
            merchant_id=merchant_data.merchant_id,
            asaas_account_id=merchant_data.asaas_account_id,
            business_name=merchant_data.business_name,
            document=merchant_data.document,
            email=merchant_data.email,
            phone=merchant_data.phone
        )
        
        db.add(db_merchant)
        db.commit()
        db.refresh(db_merchant)
        
        return MerchantCreateResponse(
            success=True,
            message="Merchant created successfully",
            data=_db_to_response(db_merchant)
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create merchant: {str(e)}"
        )

@router.get("/{merchant_id}", response_model=MerchantCreateResponse)
async def get_merchant(
    merchant_id: str,
    _: str = Depends(verify_token_and_ip),
    db: Session = Depends(get_db)
):
    """Consulta dados de um comerciante"""
    
    merchant = db.query(MerchantDB).filter(
        MerchantDB.merchant_id == merchant_id
    ).first()
    
    if not merchant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Merchant {merchant_id} not found"
        )
    
    return MerchantCreateResponse(
        success=True,
        message="Merchant found",
        data=_db_to_response(merchant)
    )

@router.get("/", response_model=MerchantListResponse)
async def list_merchants(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    is_active: Optional[bool] = Query(None),
    _: str = Depends(verify_token_and_ip),
    db: Session = Depends(get_db)
):
    """Lista comerciantes com paginação"""
    
    query = db.query(MerchantDB)
    
    if is_active is not None:
        query = query.filter(MerchantDB.is_active == is_active)
    
    # Conta total
    total = query.count()
    
    # Paginação
    offset = (page - 1) * per_page
    merchants = query.order_by(MerchantDB.created_at.desc()).offset(offset).limit(per_page).all()
    
    return MerchantListResponse(
        success=True,
        message=f"Found {len(merchants)} merchants",
        data=[_db_to_response(m) for m in merchants],
        total=total
    )

@router.put("/{merchant_id}/status")
async def update_merchant_status(
    merchant_id: str,
    is_active: bool,
    _: str = Depends(verify_token_and_ip),
    db: Session = Depends(get_db)
):
    """Atualiza status ativo/inativo do comerciante"""
    
    merchant = db.query(MerchantDB).filter(
        MerchantDB.merchant_id == merchant_id
    ).first()
    
    if not merchant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Merchant {merchant_id} not found"
        )
    
    merchant.is_active = is_active
    db.commit()
    db.refresh(merchant)
    
    status_text = "activated" if is_active else "deactivated"
    
    return MerchantCreateResponse(
        success=True,
        message=f"Merchant {status_text} successfully",
        data=_db_to_response(merchant)
    )

def _db_to_response(db_merchant: MerchantDB) -> MerchantResponse:
    """Converte modelo do banco para modelo de resposta"""
    return MerchantResponse(
        merchant_id=db_merchant.merchant_id,
        asaas_account_id=db_merchant.asaas_account_id,
        business_name=db_merchant.business_name,
        document=db_merchant.document,
        email=db_merchant.email,
        phone=db_merchant.phone,
        is_active=db_merchant.is_active,
        created_at=db_merchant.created_at,
        updated_at=db_merchant.updated_at
    )