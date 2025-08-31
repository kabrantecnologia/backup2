from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import Optional, List
import uuid
from datetime import datetime

from app.database.models import ResellerDB
from app.models.reseller import ResellerCreate, ResellerUpdate, ResellerResponse, ResellerAuth
from config.logging import get_logger

logger = get_logger(__name__)

class ResellerService:
    """Service for managing resellers and compatibility with official API"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def create_reseller(self, reseller_data: ResellerCreate) -> ResellerResponse:
        """Create a new reseller"""
        try:
            # Check if document already exists
            existing = self.get_reseller_by_document(reseller_data.document)
            if existing:
                raise ValueError(f"Reseller with document {reseller_data.document} already exists")
            
            db_reseller = ResellerDB(
                reseller_id=str(uuid.uuid4()),
                document=reseller_data.document,
                business_name=reseller_data.business_name,
                trade_name=reseller_data.trade_name,
                email=reseller_data.email,
                phone=reseller_data.phone,
                status=reseller_data.status,
                api_token=reseller_data.api_token,
                daily_limit=reseller_data.daily_limit,
                monthly_limit=reseller_data.monthly_limit,
                reseller_metadata=reseller_data.reseller_metadata or {}
            )
            
            self.db.add(db_reseller)
            self.db.commit()
            self.db.refresh(db_reseller)
            
            logger.info(f"Created reseller: {db_reseller.reseller_id}", extra={
                "reseller_id": db_reseller.reseller_id,
                "document": db_reseller.document
            })
            
            return ResellerResponse.model_validate(db_reseller)
            
        except Exception as e:
            logger.error(f"Error creating reseller: {str(e)}")
            self.db.rollback()
            raise
    
    def get_reseller_by_id(self, reseller_id: str) -> Optional[ResellerResponse]:
        """Get reseller by ID"""
        reseller = self.db.query(ResellerDB).filter(
            ResellerDB.reseller_id == reseller_id
        ).first()
        
        return ResellerResponse.model_validate(reseller) if reseller else None
    
    def get_reseller_by_document(self, document: str) -> Optional[ResellerResponse]:
        """Get reseller by document (CNPJ)"""
        reseller = self.db.query(ResellerDB).filter(
            ResellerDB.document == document
        ).first()
        
        return ResellerResponse.model_validate(reseller) if reseller else None
    
    def get_reseller_by_token(self, api_token: str) -> Optional[ResellerAuth]:
        """Get reseller authentication info by API token"""
        reseller = self.db.query(ResellerDB).filter(
            ResellerDB.api_token == api_token
        ).first()
        
        return ResellerAuth.model_validate(reseller) if reseller else None
    
    def update_reseller(self, reseller_id: str, update_data: ResellerUpdate) -> Optional[ResellerResponse]:
        """Update reseller data"""
        try:
            reseller = self.db.query(ResellerDB).filter(
                ResellerDB.reseller_id == reseller_id
            ).first()
            
            if not reseller:
                return None
            
            # Update only provided fields
            update_dict = update_data.model_dump(exclude_unset=True)
            for field, value in update_dict.items():
                setattr(reseller, field, value)
            
            reseller.updated_at = datetime.utcnow()
            
            self.db.commit()
            self.db.refresh(reseller)
            
            logger.info(f"Updated reseller: {reseller_id}", extra={
                "reseller_id": reseller_id,
                "updated_fields": list(update_dict.keys())
            })
            
            return ResellerResponse.model_validate(reseller)
            
        except Exception as e:
            logger.error(f"Error updating reseller {reseller_id}: {str(e)}")
            self.db.rollback()
            raise
    
    def list_resellers(self, skip: int = 0, limit: int = 100) -> List[ResellerResponse]:
        """List all resellers with pagination"""
        resellers = self.db.query(ResellerDB).offset(skip).limit(limit).all()
        return [ResellerResponse.model_validate(r) for r in resellers]
    
    def delete_reseller(self, reseller_id: str) -> bool:
        """Delete a reseller (soft delete by setting status to inactive)"""
        try:
            reseller = self.db.query(ResellerDB).filter(
                ResellerDB.reseller_id == reseller_id
            ).first()
            
            if not reseller:
                return False
            
            # Check if reseller has active merchants
            merchant_count = self.db.execute(
                text("SELECT COUNT(*) FROM merchants WHERE reseller_id = :reseller_id"),
                {"reseller_id": reseller_id}
            ).scalar()
            
            if merchant_count > 0:
                # Soft delete - just deactivate
                reseller.status = "inactive"
                reseller.updated_at = datetime.utcnow()
                self.db.commit()
                
                logger.info(f"Soft deleted reseller with active merchants: {reseller_id}", extra={
                    "reseller_id": reseller_id,
                    "merchant_count": merchant_count
                })
            else:
                # Hard delete - no merchants associated
                self.db.delete(reseller)
                self.db.commit()
                
                logger.info(f"Hard deleted reseller: {reseller_id}", extra={
                    "reseller_id": reseller_id
                })
            
            return True
            
        except Exception as e:
            logger.error(f"Error deleting reseller {reseller_id}: {str(e)}")
            self.db.rollback()
            raise
    
    def validate_reseller_token(self, token: str, document: Optional[str] = None) -> Optional[ResellerAuth]:
        """Validate reseller token (compatible with official API structure)"""
        query = self.db.query(ResellerDB).filter(
            ResellerDB.api_token == token,
            ResellerDB.status == "active"
        )
        
        # If document provided, also validate it
        if document:
            query = query.filter(ResellerDB.document == document)
        
        reseller = query.first()
        
        if reseller:
            logger.info(f"Token validation successful", extra={
                "reseller_id": reseller.reseller_id,
                "document": reseller.document
            })
            return ResellerAuth.model_validate(reseller)
        else:
            logger.warning(f"Token validation failed", extra={
                "token": token[:8] + "..." if len(token) > 8 else token,
                "document": document
            })
            return None
    
    def create_default_reseller(self, api_token: str, document: str) -> ResellerResponse:
        """Create default reseller for compatibility (used in migrations)"""
        default_data = ResellerCreate(
            document=document,
            business_name="Tricket Reseller Padrão",
            trade_name="Tricket",
            email="reseller@tricket.com.br",
            phone="11999999999",
            api_token=api_token,
            reseller_metadata={
                "is_default": True,
                "created_for": "compatibility"
            }
        )
        
        return self.create_reseller(default_data)