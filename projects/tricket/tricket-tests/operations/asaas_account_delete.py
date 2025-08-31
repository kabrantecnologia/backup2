#!/usr/bin/env python3
"""
Script para deletar conta Asaas
"""

import sys
import os
import requests
import json

# Adicionar o diretório ao path para importar módulos locais
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

def delete_asaas_account(project_name: str, profile_id: str, remove_reason: str) -> bool:
    """
    Deleta uma conta Asaas usando a edge function
    
    Args:
        project_name: Nome do projeto
        profile_id: ID do profile a ser deletado
        remove_reason: Motivo para remoção
    
    Returns:
        bool: True se sucesso, False se falha
    """
    
    # URL da edge function
    url = "https://api-dev2-tricket.kabran.com.br/functions/v1/asaas_account_delete"
    
    try:
        # Importar funções locais
        from core.session_manager import get_user_token
        
        # Obter token do admin
        token_data = get_user_token("admin@tricket.com.br")
        if not token_data or not token_data.get("access_token"):
            print("❌ Token de admin não encontrado.")
            return False
        
        access_token = token_data["access_token"]
        
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        
        body = {
            "profile_id": profile_id,
            "remove_reason": remove_reason
        }
        
        print(f"🗑️ Deletando conta Asaas para profile {profile_id}...")
        print(f"📋 Motivo: {remove_reason}")
        print(f"🔗 URL: {url}")
        
        response = requests.post(url, headers=headers, json=body)
        
        print(f"📊 Status: {response.status_code}")
        print(f"📤 Request Body: {json.dumps(body, indent=2)}")
        
        if response.status_code == 200:
            try:
                result = response.json()
                print("✅ Conta Asaas deletada com sucesso!")
                print(f"📄 Resposta: {json.dumps(result, indent=2)}")
                return True
            except json.JSONDecodeError:
                print("✅ Conta Asaas deletada com sucesso!")
                print(f"📄 Resposta: {response.text}")
                return True
        else:
            print("❌ Erro ao deletar conta Asaas")
            print(f"📄 Status: {response.status_code}")
            print(f"📄 Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro ao deletar conta Asaas: {e}")
        return False

def test_delete_account():
    """Testa a deleção de uma conta Asaas"""
    
    # Profile ID e motivo para teste
    profile_id = "c1bb0c6a-1f4b-4d87-ab84-853e25471c42"  # fornecedor5@tricket.com.br
    remove_reason = "teste"
    
    success = delete_asaas_account("tricket", profile_id, remove_reason)
    
    if success:
        print("✅ Teste de deleção concluído com sucesso!")
    else:
        print("❌ Teste de deleção falhou")
    
    return success

if __name__ == "__main__":
    test_delete_account()
