import logging
from typing import Optional, List
from datetime import datetime
from sqlalchemy.orm import Session

from config.settings import settings
from app.database.connection import get_db_session
from app.database.models import TransactionDB, MerchantDB
from app.models.transaction import TransactionCreate, TransactionResponse
from app.models.common import TransactionStatus, PaymentMethod
from .webhook_sender import WebhookSender

logger = logging.getLogger(__name__)

class TransactionProcessor:
    """Processador de transações do simulador Cappta"""
    
    def __init__(self):
        self.webhook_sender = WebhookSender()
    
    def calculate_fees(self, gross_amount: int, payment_method: PaymentMethod, installments: int = 1) -> int:
        """Calcula taxas baseado no valor e método de pagamento"""
        
        # Taxa percentual baseada no método de pagamento
        if payment_method == PaymentMethod.DEBIT:
            percentage_fee = 2.0  # 2% para débito
        elif payment_method == PaymentMethod.CREDIT:
            if installments == 1:
                percentage_fee = settings.DEFAULT_FEE_PERCENTAGE  # 3% para crédito à vista
            else:
                percentage_fee = settings.DEFAULT_FEE_PERCENTAGE + (installments * 0.5)  # +0.5% por parcela
        elif payment_method == PaymentMethod.PIX:
            percentage_fee = 1.0  # 1% para PIX
        else:
            percentage_fee = settings.DEFAULT_FEE_PERCENTAGE
        
        # Calcula taxa percentual
        percentage_amount = int(gross_amount * (percentage_fee / 100))
        
        # Adiciona taxa fixa
        total_fee = percentage_amount + settings.DEFAULT_FEE_FIXED
        
        # Garante que a taxa não seja maior que o valor da transação
        return min(total_fee, gross_amount - 1)
    
    async def create_transaction(self, transaction_data: TransactionCreate) -> TransactionResponse:
        """Cria uma nova transação"""
        
        with get_db_session() as db:
            # Verifica se o comerciante existe
            merchant = db.query(MerchantDB).filter(
                MerchantDB.merchant_id == transaction_data.merchant_id
            ).first()
            
            if not merchant:
                raise ValueError(f"Merchant {transaction_data.merchant_id} not found")
            
            if not merchant.is_active:
                raise ValueError(f"Merchant {transaction_data.merchant_id} is not active")
            
            # Verifica se já existe transação com mesmo external_event_id (idempotência)
            existing = db.query(TransactionDB).filter(
                TransactionDB.external_event_id == transaction_data.external_event_id
            ).first()
            
            if existing:
                logger.info(f"Transaction {existing.transaction_id} already exists for event {transaction_data.external_event_id}")
                return self._db_to_response(existing)
            
            # Calcula taxas
            fee_amount = self.calculate_fees(
                transaction_data.gross_amount,
                transaction_data.payment_method,
                transaction_data.installments
            )
            net_amount = transaction_data.gross_amount - fee_amount
            
            # Simula aprovação/recusa (95% de aprovação)
            import random
            is_approved = random.random() < 0.95
            status = TransactionStatus.APPROVED if is_approved else TransactionStatus.DECLINED
            
            # Cria transação no banco
            db_transaction = TransactionDB(
                transaction_id=transaction_data.transaction_id,
                merchant_id=transaction_data.merchant_id,
                terminal_id=transaction_data.terminal_id,
                nsu=transaction_data.nsu,
                authorization_code=transaction_data.authorization_code,
                payment_method=transaction_data.payment_method.value,
                card_brand=transaction_data.card_brand.value if transaction_data.card_brand else None,
                gross_amount=transaction_data.gross_amount,
                fee_amount=fee_amount,
                net_amount=net_amount,
                installments=transaction_data.installments,
                status=status.value,
                captured_at=transaction_data.captured_at,
                external_event_id=transaction_data.external_event_id
            )
            
            db.add(db_transaction)
            db.commit()
            db.refresh(db_transaction)
            
            response = self._db_to_response(db_transaction)
            
            # Envia webhook se aprovada
            if is_approved:
                await self._send_transaction_webhook(response)
            
            logger.info(f"Transaction {response.transaction_id} created with status {response.status}")
            
            return response
    
    async def get_transaction(self, transaction_id: str) -> Optional[TransactionResponse]:
        """Busca transação por ID"""
        
        with get_db_session() as db:
            transaction = db.query(TransactionDB).filter(
                TransactionDB.transaction_id == transaction_id
            ).first()
            
            if not transaction:
                return None
            
            return self._db_to_response(transaction)
    
    async def list_transactions(
        self, 
        merchant_id: Optional[str] = None,
        status: Optional[TransactionStatus] = None,
        page: int = 1,
        per_page: int = 20
    ) -> List[TransactionResponse]:
        """Lista transações com filtros"""
        
        with get_db_session() as db:
            query = db.query(TransactionDB)
            
            if merchant_id:
                query = query.filter(TransactionDB.merchant_id == merchant_id)
            
            if status:
                query = query.filter(TransactionDB.status == status.value)
            
            # Paginação
            offset = (page - 1) * per_page
            transactions = query.order_by(TransactionDB.created_at.desc()).offset(offset).limit(per_page).all()
            
            return [self._db_to_response(t) for t in transactions]
    
    async def update_transaction_status(
        self, 
        transaction_id: str, 
        new_status: TransactionStatus,
        reason: Optional[str] = None
    ) -> Optional[TransactionResponse]:
        """Atualiza status de uma transação"""
        
        with get_db_session() as db:
            transaction = db.query(TransactionDB).filter(
                TransactionDB.transaction_id == transaction_id
            ).first()
            
            if not transaction:
                return None
            
            old_status = transaction.status
            transaction.status = new_status.value
            transaction.updated_at = datetime.utcnow()
            
            db.commit()
            db.refresh(transaction)
            
            response = self._db_to_response(transaction)
            
            # Envia webhook para mudanças de status relevantes
            if old_status != new_status.value and new_status in [TransactionStatus.APPROVED, TransactionStatus.DECLINED, TransactionStatus.CANCELLED]:
                await self._send_transaction_webhook(response)
            
            logger.info(f"Transaction {transaction_id} status updated from {old_status} to {new_status}")
            
            return response
    
    def _db_to_response(self, db_transaction: TransactionDB) -> TransactionResponse:
        """Converte modelo do banco para modelo de resposta"""
        return TransactionResponse(
            transaction_id=db_transaction.transaction_id,
            merchant_id=db_transaction.merchant_id,
            terminal_id=db_transaction.terminal_id,
            nsu=db_transaction.nsu,
            authorization_code=db_transaction.authorization_code,
            payment_method=PaymentMethod(db_transaction.payment_method),
            card_brand=db_transaction.card_brand,
            gross_amount=db_transaction.gross_amount,
            fee_amount=db_transaction.fee_amount,
            net_amount=db_transaction.net_amount,
            installments=db_transaction.installments,
            status=TransactionStatus(db_transaction.status),
            captured_at=db_transaction.captured_at,
            external_event_id=db_transaction.external_event_id,
            created_at=db_transaction.created_at,
            updated_at=db_transaction.updated_at
        )
    
    async def _send_transaction_webhook(self, transaction: TransactionResponse):
        """Envia webhook de transação para o Tricket"""
        try:
            await self.webhook_sender.send_transaction_webhook(transaction)
        except Exception as e:
            logger.error(f"Failed to send transaction webhook for {transaction.transaction_id}: {e}")
            # Não falha a transação por causa do webhook