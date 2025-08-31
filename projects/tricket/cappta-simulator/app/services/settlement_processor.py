import logging
from typing import List, Optional
from datetime import datetime, date, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import and_

from config.settings import settings
from app.database.connection import get_db_session
from app.database.models import SettlementDB, TransactionDB, MerchantDB
from app.models.settlement import SettlementCreate, SettlementResponse
from app.models.common import SettlementStatus, TransactionStatus
from .asaas_client import AsaasClient
from .webhook_sender import WebhookSender

logger = logging.getLogger(__name__)

class SettlementProcessor:
    """Processador de liquidações do simulador Cappta"""
    
    def __init__(self):
        self.asaas_client = AsaasClient()
        self.webhook_sender = WebhookSender()
    
    async def create_settlement(self, settlement_data: SettlementCreate) -> SettlementResponse:
        """Cria uma nova liquidação"""
        
        with get_db_session() as db:
            # Verifica se o comerciante existe
            merchant = db.query(MerchantDB).filter(
                MerchantDB.merchant_id == settlement_data.merchant_id
            ).first()
            
            if not merchant:
                raise ValueError(f"Merchant {settlement_data.merchant_id} not found")
            
            # Busca transações pendentes de liquidação
            transactions = db.query(TransactionDB).filter(
                and_(
                    TransactionDB.external_event_id.in_(settlement_data.transaction_refs),
                    TransactionDB.merchant_id == settlement_data.merchant_id,
                    TransactionDB.status == TransactionStatus.APPROVED.value,
                    TransactionDB.settlement_id.is_(None)
                )
            ).all()
            
            if not transactions:
                raise ValueError("No eligible transactions found for settlement")
            
            # Verifica se as transações estão dentro do prazo para liquidação
            if not settlement_data.force_settlement:
                cutoff_date = datetime.now() - timedelta(hours=settings.SETTLEMENT_DELAY_HOURS)
                recent_transactions = [t for t in transactions if t.captured_at > cutoff_date]
                if recent_transactions:
                    recent_ids = [t.transaction_id for t in recent_transactions]
                    raise ValueError(f"Transactions {recent_ids} are not yet eligible for settlement")
            
            # Calcula totais
            gross_amount = sum(t.gross_amount for t in transactions)
            fee_amount = sum(t.fee_amount for t in transactions)
            net_amount = sum(t.net_amount for t in transactions)
            
            # Cria liquidação no banco
            db_settlement = SettlementDB(
                settlement_id=settlement_data.settlement_id,
                merchant_id=settlement_data.merchant_id,
                gross_amount=gross_amount,
                fee_amount=fee_amount,
                net_amount=net_amount,
                transaction_count=len(transactions),
                settlement_date=settlement_data.settlement_date,
                status=SettlementStatus.PENDING.value
            )
            
            db.add(db_settlement)
            db.flush()  # Para obter o ID antes do commit
            
            # Associa transações à liquidação
            for transaction in transactions:
                transaction.settlement_id = db_settlement.settlement_id
                transaction.status = TransactionStatus.SETTLED.value
                transaction.updated_at = datetime.utcnow()
            
            db.commit()
            db.refresh(db_settlement)
            
            response = self._db_to_response(db_settlement)
            
            # Processa liquidação assincronamente
            await self._process_settlement(response)
            
            logger.info(f"Settlement {response.settlement_id} created for merchant {response.merchant_id}")
            
            return response
    
    async def _process_settlement(self, settlement: SettlementResponse):
        """Processa a liquidação fazendo transferência via Asaas"""
        
        try:
            with get_db_session() as db:
                # Atualiza status para processando
                db_settlement = db.query(SettlementDB).filter(
                    SettlementDB.settlement_id == settlement.settlement_id
                ).first()
                
                if not db_settlement:
                    raise ValueError("Settlement not found")
                
                db_settlement.status = SettlementStatus.PROCESSING.value
                db.commit()
                
                # Busca dados do comerciante
                merchant = db.query(MerchantDB).filter(
                    MerchantDB.merchant_id == settlement.merchant_id
                ).first()
                
                if not merchant:
                    raise ValueError("Merchant not found")
                
                # Cria transferência no Asaas
                transfer_response = await self.asaas_client.create_transfer(
                    destination_account_id=merchant.asaas_account_id,
                    amount=settlement.net_amount,
                    description=f"Liquidação Cappta - {settlement.settlement_id}"
                )
                
                # Atualiza liquidação com dados da transferência
                db_settlement.asaas_transfer_id = transfer_response.get("id")
                db_settlement.status = SettlementStatus.COMPLETED.value
                db_settlement.processed_at = datetime.utcnow()
                db.commit()
                
                updated_settlement = self._db_to_response(db_settlement)
                
                # Envia webhook de liquidação
                await self.webhook_sender.send_settlement_webhook(updated_settlement)
                
                logger.info(f"Settlement {settlement.settlement_id} processed successfully via Asaas transfer {transfer_response.get('id')}")
                
        except Exception as e:
            logger.error(f"Failed to process settlement {settlement.settlement_id}: {e}")
            
            # Marca liquidação como falha
            with get_db_session() as db:
                db_settlement = db.query(SettlementDB).filter(
                    SettlementDB.settlement_id == settlement.settlement_id
                ).first()
                
                if db_settlement:
                    db_settlement.status = SettlementStatus.FAILED.value
                    db_settlement.processed_at = datetime.utcnow()
                    db.commit()
    
    async def get_settlement(self, settlement_id: str) -> Optional[SettlementResponse]:
        """Busca liquidação por ID"""
        
        with get_db_session() as db:
            settlement = db.query(SettlementDB).filter(
                SettlementDB.settlement_id == settlement_id
            ).first()
            
            if not settlement:
                return None
            
            return self._db_to_response(settlement)
    
    async def list_settlements(
        self,
        merchant_id: Optional[str] = None,
        status: Optional[SettlementStatus] = None,
        page: int = 1,
        per_page: int = 20
    ) -> List[SettlementResponse]:
        """Lista liquidações com filtros"""
        
        with get_db_session() as db:
            query = db.query(SettlementDB)
            
            if merchant_id:
                query = query.filter(SettlementDB.merchant_id == merchant_id)
            
            if status:
                query = query.filter(SettlementDB.status == status.value)
            
            # Paginação
            offset = (page - 1) * per_page
            settlements = query.order_by(SettlementDB.created_at.desc()).offset(offset).limit(per_page).all()
            
            return [self._db_to_response(s) for s in settlements]
    
    async def auto_settle_eligible_transactions(self):
        """Processa automaticamente transações elegíveis para liquidação"""
        
        with get_db_session() as db:
            # Busca transações aprovadas há mais tempo que o prazo de liquidação
            cutoff_date = datetime.now() - timedelta(hours=settings.SETTLEMENT_DELAY_HOURS)
            
            eligible_transactions = db.query(TransactionDB).filter(
                and_(
                    TransactionDB.status == TransactionStatus.APPROVED.value,
                    TransactionDB.settlement_id.is_(None),
                    TransactionDB.captured_at <= cutoff_date
                )
            ).all()
            
            if not eligible_transactions:
                logger.info("No eligible transactions found for auto settlement")
                return
            
            # Agrupa por comerciante
            transactions_by_merchant = {}
            for transaction in eligible_transactions:
                if transaction.merchant_id not in transactions_by_merchant:
                    transactions_by_merchant[transaction.merchant_id] = []
                transactions_by_merchant[transaction.merchant_id].append(transaction)
            
            # Cria liquidações para cada comerciante
            for merchant_id, transactions in transactions_by_merchant.items():
                try:
                    settlement_data = SettlementCreate(
                        merchant_id=merchant_id,
                        transaction_refs=[t.external_event_id for t in transactions],
                        settlement_date=date.today(),
                        force_settlement=True
                    )
                    
                    await self.create_settlement(settlement_data)
                    logger.info(f"Auto settlement created for merchant {merchant_id} with {len(transactions)} transactions")
                    
                except Exception as e:
                    logger.error(f"Failed to create auto settlement for merchant {merchant_id}: {e}")
    
    def _db_to_response(self, db_settlement: SettlementDB) -> SettlementResponse:
        """Converte modelo do banco para modelo de resposta"""
        
        with get_db_session() as db:
            # Busca referências das transações
            transaction_refs = db.query(TransactionDB.external_event_id).filter(
                TransactionDB.settlement_id == db_settlement.settlement_id
            ).all()
            
            return SettlementResponse(
                settlement_id=db_settlement.settlement_id,
                merchant_id=db_settlement.merchant_id,
                gross_amount=db_settlement.gross_amount,
                fee_amount=db_settlement.fee_amount,
                net_amount=db_settlement.net_amount,
                transaction_count=db_settlement.transaction_count,
                transaction_refs=[ref[0] for ref in transaction_refs],
                settlement_date=db_settlement.settlement_date,
                status=SettlementStatus(db_settlement.status),
                asaas_transfer_id=db_settlement.asaas_transfer_id,
                processed_at=db_settlement.processed_at,
                created_at=db_settlement.created_at,
                updated_at=db_settlement.updated_at
            )