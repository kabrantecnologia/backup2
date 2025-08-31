#!/usr/bin/env python3
"""
Script de Teste - Asaas Master Webhook
João Henrique Andrade - Tricket
"""

import requests
import json
import os
from datetime import datetime

def test_webhook():
    """Testa o webhook com payloads reais"""
    
    # Configurações
    base_url = "https://api-dev2-tricket.kabran.com.br"
    webhook_url = f"{base_url}/functions/v1/asaas_master_webhook"
    
    # Obter token do ambiente
    token = input("Digite o SUPABASE_ANON_KEY: ").strip()
    
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
        'asaas-signature': 'test-signature-dev'
    }
    
    # Teste 1: Pagamento Recebido
    print("🧪 Testando PAYMENT_RECEIVED...")
    payment_payload = {
        "event": "PAYMENT_RECEIVED",
        "payment": {
            "id": f"pay_test_{datetime.now().strftime('%Y%m%d%H%M%S')}",
            "customer": "cus_test_customer",
            "value": 1500.00,
            "netValue": 1455.00,
            "status": "RECEIVED",
            "billingType": "CREDIT_CARD",
            "dueDate": "2024-08-15",
            "paymentDate": datetime.now().isoformat(),
            "externalReference": f"ref_test_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        }
    }
    
    try:
        response = requests.post(webhook_url, headers=headers, json=payment_payload, timeout=10)
        print(f"✅ Status: {response.status_code}")
        print(f"📦 Response: {response.text}")
    except Exception as e:
        print(f"❌ Erro: {e}")
    
    # Teste 2: Transferência Concluída
    print("\n🧪 Testando TRANSFER_COMPLETED...")
    transfer_payload = {
        "event": "TRANSFER_COMPLETED",
        "transfer": {
            "id": f"tra_test_{datetime.now().strftime('%Y%m%d%H%M%S')}",
            "value": 500.00,
            "netValue": 495.00,
            "status": "DONE",
            "transferType": "PIX",
            "scheduledDate": "2024-08-09",
            "effectiveDate": "2024-08-09"
        }
    }
    
    try:
        response = requests.post(webhook_url, headers=headers, json=transfer_payload, timeout=10)
        print(f"✅ Status: {response.status_code}")
        print(f"📦 Response: {response.text}")
    except Exception as e:
        print(f"❌ Erro: {e}")

if __name__ == "__main__":
    print("🚀 Testando Webhook Asaas Master")
    print("=" * 50)
    test_webhook()
    print("\n✅ Testes concluídos!")
