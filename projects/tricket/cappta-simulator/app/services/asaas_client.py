import httpx
import logging
from typing import Optional, Dict, Any
from datetime import datetime

from config.settings import settings

logger = logging.getLogger(__name__)

class AsaasClient:
    """Cliente para integração com a API do Asaas"""
    
    def __init__(self):
        self.base_url = settings.ASAAS_BASE_URL
        self.api_key = settings.ASAAS_API_KEY
        self.master_account_id = settings.CAPPTA_MASTER_ACCOUNT_ID
        
        self.headers = {
            "access_token": self.api_key,
            "Content-Type": "application/json",
            "User-Agent": "Cappta-Fake-Simulator/1.0"
        }
    
    async def _make_request(
        self, 
        method: str, 
        endpoint: str, 
        data: Optional[Dict[str, Any]] = None,
        params: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Faz requisição para a API do Asaas"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.request(
                    method=method,
                    url=url,
                    headers=self.headers,
                    json=data,
                    params=params
                )
                
                logger.info(f"Asaas API {method} {endpoint} - Status: {response.status_code}")
                
                if response.status_code >= 400:
                    logger.error(f"Asaas API error: {response.text}")
                    raise httpx.HTTPStatusError(
                        f"Asaas API error: {response.status_code}", 
                        request=response.request, 
                        response=response
                    )
                
                return response.json() if response.content else {}
                
        except httpx.RequestError as e:
            logger.error(f"Request error to Asaas API: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error calling Asaas API: {e}")
            raise
    
    async def get_account_balance(self, account_id: Optional[str] = None) -> Dict[str, Any]:
        """Consulta saldo de uma conta"""
        target_account = account_id or self.master_account_id
        return await self._make_request("GET", f"finance/balance")
    
    async def create_transfer(
        self, 
        destination_account_id: str, 
        amount: float,
        description: str = "Liquidação Cappta"
    ) -> Dict[str, Any]:
        """Cria transferência da conta master para conta do comerciante"""
        
        transfer_data = {
            "walletId": destination_account_id,
            "value": amount / 100,  # Convert cents to reais
            "description": description,
            "scheduleDate": datetime.now().strftime("%Y-%m-%d")
        }
        
        logger.info(f"Creating transfer: {amount/100:.2f} BRL to account {destination_account_id}")
        
        return await self._make_request("POST", "transfers", data=transfer_data)
    
    async def get_transfer_status(self, transfer_id: str) -> Dict[str, Any]:
        """Consulta status de uma transferência"""
        return await self._make_request("GET", f"transfers/{transfer_id}")
    
    async def list_transfers(
        self, 
        account_id: Optional[str] = None,
        limit: int = 20,
        offset: int = 0
    ) -> Dict[str, Any]:
        """Lista transferências"""
        params = {
            "limit": limit,
            "offset": offset
        }
        
        if account_id:
            params["walletId"] = account_id
            
        return await self._make_request("GET", "transfers", params=params)
    
    async def create_webhook(self, webhook_data: Dict[str, Any]) -> Dict[str, Any]:
        """Cria webhook no Asaas"""
        return await self._make_request("POST", "webhooks", data=webhook_data)
    
    async def verify_account_exists(self, account_id: str) -> bool:
        """Verifica se uma conta existe no Asaas"""
        try:
            # Tenta fazer uma consulta simples para verificar se a conta existe
            await self._make_request("GET", f"customers/{account_id}")
            return True
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 404:
                return False
            raise
        except Exception:
            return False
    
    async def simulate_account_funding(self, amount: float) -> Dict[str, Any]:
        """Simula adição de saldo à conta master (apenas para desenvolvimento)"""
        logger.warning(f"SIMULATION: Adding {amount/100:.2f} BRL to master account")
        
        # Em ambiente real, isso seria feito através do painel do Asaas
        # Para o simulador, apenas logamos a operação
        return {
            "success": True,
            "message": f"Simulated funding of {amount/100:.2f} BRL to master account",
            "master_account_id": self.master_account_id,
            "amount": amount,
            "timestamp": datetime.now().isoformat()
        }