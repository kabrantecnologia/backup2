import httpx
import hashlib
import hmac
import json
import logging
from typing import Dict, Any
from datetime import datetime
from sqlalchemy.orm import Session

from config.settings import settings
from app.database.connection import get_db_session
from app.database.models import WebhookLogDB
from app.models.transaction import TransactionResponse
from app.models.settlement import SettlementResponse

logger = logging.getLogger(__name__)

class WebhookSender:
    """Classe responsável por enviar webhooks para o sistema Tricket"""
    
    def __init__(self):
        self.webhook_url = settings.TRICKET_WEBHOOK_URL
        self.webhook_secret = settings.TRICKET_WEBHOOK_SECRET
        self.timeout = settings.WEBHOOK_TIMEOUT
        self.retry_attempts = settings.WEBHOOK_RETRY_ATTEMPTS
        self.retry_delay = settings.WEBHOOK_RETRY_DELAY
    
    def _generate_signature(self, payload: str) -> str:
        """Gera assinatura HMAC-SHA256 para o webhook"""
        return hmac.new(
            self.webhook_secret.encode('utf-8'),
            payload.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
    
    async def _send_webhook(
        self, 
        event_type: str,
        payload: Dict[str, Any],
        merchant_id: str,
        transaction_id: str = None,
        settlement_id: str = None
    ) -> bool:
        """Envia webhook com retry automático"""
        
        payload_str = json.dumps(payload, default=str, separators=(',', ':'))
        signature = self._generate_signature(payload_str)
        
        headers = {
            "Content-Type": "application/json",
            "X-Cappta-Signature": f"sha256={signature}",
            "X-Cappta-Event": event_type,
            "X-Cappta-Timestamp": str(int(datetime.now().timestamp())),
            "User-Agent": "Cappta-Fake-Simulator/1.0"
        }
        
        success = False
        last_error = None
        response_status = None
        response_body = None
        
        for attempt in range(self.retry_attempts):
            try:
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.post(
                        self.webhook_url,
                        headers=headers,
                        content=payload_str
                    )
                    
                    response_status = response.status_code
                    response_body = response.text[:1000]  # Limita a 1000 caracteres
                    
                    if response.status_code < 400:
                        success = True
                        logger.info(f"Webhook {event_type} sent successfully (attempt {attempt + 1})")
                        break
                    else:
                        last_error = f"HTTP {response.status_code}: {response.text}"
                        logger.warning(f"Webhook {event_type} failed with status {response.status_code} (attempt {attempt + 1})")
                        
            except httpx.RequestError as e:
                last_error = str(e)
                logger.warning(f"Webhook {event_type} request failed (attempt {attempt + 1}): {e}")
            except Exception as e:
                last_error = str(e)
                logger.error(f"Unexpected error sending webhook {event_type} (attempt {attempt + 1}): {e}")
            
            # Aguarda antes da próxima tentativa (exceto na última)
            if attempt < self.retry_attempts - 1:
                await asyncio.sleep(self.retry_delay)
        
        # Log do webhook no banco
        await self._log_webhook(
            event_type=event_type,
            merchant_id=merchant_id,
            transaction_id=transaction_id,
            settlement_id=settlement_id,
            payload=payload_str,
            response_status=response_status,
            response_body=response_body,
            attempt_count=attempt + 1,
            success=success
        )
        
        if not success:
            logger.error(f"Failed to send webhook {event_type} after {self.retry_attempts} attempts. Last error: {last_error}")
        
        return success
    
    async def send_transaction_webhook(self, transaction: TransactionResponse) -> bool:
        """Envia webhook de transação"""
        
        event_type = f"transaction.{transaction.status.value}"
        
        # Prepara dados do webhook
        
        payload = {
            "event": event_type,
            "data": {
                "transaction_id": transaction.transaction_id,
                "merchant_id": transaction.merchant_id,
                "terminal_id": transaction.terminal_id,
                "nsu": transaction.nsu,
                "authorization_code": transaction.authorization_code,
                "payment_method": transaction.payment_method.value,
                "card_brand": transaction.card_brand,
                "gross_amount": transaction.gross_amount,
                "fee_amount": transaction.fee_amount,
                "net_amount": transaction.net_amount,
                "installments": transaction.installments,
                "status": transaction.status.value,
                "captured_at": transaction.captured_at.isoformat(),
                "external_event_id": transaction.external_event_id
            },
            "timestamp": datetime.now().isoformat(),
            "signature": None  # Será calculado em _send_webhook
        }
        
        return await self._send_webhook(
            event_type=event_type,
            payload=payload,
            merchant_id=transaction.merchant_id,
            transaction_id=transaction.transaction_id
        )
    
    async def send_settlement_webhook(self, settlement: SettlementResponse) -> bool:
        """Envia webhook de liquidação"""
        
        event_type = f"settlement.{settlement.status.value}"
        
        payload = {
            "event": event_type,
            "data": {
                "settlement_id": settlement.settlement_id,
                "merchant_id": settlement.merchant_id,
                "gross_amount": settlement.gross_amount,
                "fee_amount": settlement.fee_amount,
                "net_amount": settlement.net_amount,
                "transaction_count": settlement.transaction_count,
                "transaction_refs": settlement.transaction_refs,
                "settlement_date": settlement.settlement_date.isoformat(),
                "status": settlement.status.value,
                "asaas_transfer_id": settlement.asaas_transfer_id,
                "processed_at": settlement.processed_at.isoformat() if settlement.processed_at else None
            },
            "timestamp": datetime.now().isoformat(),
            "signature": None  # Será calculado em _send_webhook
        }
        
        return await self._send_webhook(
            event_type=event_type,
            payload=payload,
            merchant_id=settlement.merchant_id,
            settlement_id=settlement.settlement_id
        )
    
    async def _log_webhook(
        self,
        event_type: str,
        merchant_id: str,
        payload: str,
        response_status: int = None,
        response_body: str = None,
        attempt_count: int = 1,
        success: bool = False,
        transaction_id: str = None,
        settlement_id: str = None
    ):
        """Registra log do webhook no banco"""
        
        try:
            with get_db_session() as db:
                webhook_log = WebhookLogDB(
                    event_type=event_type,
                    merchant_id=merchant_id,
                    transaction_id=transaction_id,
                    settlement_id=settlement_id,
                    payload=payload,
                    response_status=response_status,
                    response_body=response_body,
                    attempt_count=attempt_count,
                    success=success,
                    processed_at=datetime.now() if success else None
                )
                
                db.add(webhook_log)
                db.commit()
                
        except Exception as e:
            logger.error(f"Failed to log webhook: {e}")

# Importa asyncio no final para evitar problemas de importação circular
import asyncio