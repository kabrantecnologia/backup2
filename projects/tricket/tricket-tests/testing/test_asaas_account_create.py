#!/usr/bin/env python3
"""
Script para testar criação de conta Asaas após aprovação
"""

import sys
import os
import requests
import json

# Adicionar o diretório atual ao path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def create_asaas_account(profile_id: str, profile_type: str, access_token: str) -> bool:
    """
    Solicita a criação da conta Asaas usando a edge function
    
    Args:
        profile_id: ID do profile aprovado
        profile_type: Tipo do profile (INDIVIDUAL ou ORGANIZATION)
        access_token: Token de acesso do admin
    
    Returns:
        bool: True se sucesso, False se falha
    """
    
    # URL da edge function
    url = "https://api-dev2-tricket.kabran.com.br/functions/v1/asaas_account_create"
    
    try:
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        
        body = {
            "profile_id": profile_id,
            "profile_type": profile_type
        }
        
        print(f"🔄 Criando conta Asaas para profile {profile_id}...")
        print(f"📋 Profile Type: {profile_type}")
        print(f"🔗 URL: {url}")
        
        response = requests.post(url, headers=headers, json=body)
        
        print(f"📊 Status: {response.status_code}")
        print(f"📤 Request Body: {json.dumps(body, indent=2)}")
        
        if response.status_code == 200:
            try:
                result = response.json()
                print("✅ Conta Asaas criada com sucesso!")
                print(f"📄 Resposta: {json.dumps(result, indent=2)}")
                return True
            except json.JSONDecodeError:
                print("✅ Conta Asaas criada com sucesso!")
                print(f"📄 Resposta (texto): {response.text}")
                return True
        else:
            print("❌ Erro ao criar conta Asaas")
            print(f"📄 Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro ao criar conta Asaas: {e}")
        return False

def test_with_admin_token():
    """Testa com o token do admin"""
    
    # Profile ID e tipo
    profile_id = "c1bb0c6a-1f4b-4d87-ab84-853e25471c42"  # fornecedor5@tricket.com.br
    profile_type = "ORGANIZATION"
    
    # Token do admin (precisa ser obtido do arquivo de tokens)
    try:
        import os
        import json
        
        # Tentar carregar token do arquivo
        token_file = os.path.join(os.path.dirname(__file__), 'tokens.json')
        if os.path.exists(token_file):
            with open(token_file, 'r') as f:
                tokens = json.load(f)
                admin_token = tokens.get('admin@tricket.com.br', {})
                access_token = admin_token.get('access_token')
                
                if access_token:
                    print("🔑 Usando token do admin encontrado")
                    return create_asaas_account(profile_id, profile_type, access_token)
                else:
                    print("❌ Token de admin não encontrado")
        else:
            print("❌ Arquivo de tokens não encontrado")
            
    except Exception as e:
        print(f"❌ Erro ao carregar token: {e}")
    
    # Fallback - pedir token manualmente
    print("\n📝 Para testar manualmente, use:")
    print(f"curl -X POST https://api-dev2-tricket.kabran.com.br/functions/v1/asaas_account_create \\")
    print(f"  -H 'Authorization: Bearer SEU_TOKEN_AQUI' \\")
    print(f"  -H 'Content-Type: application/json' \\")
    print(f"  -d '{{\"profile_id\": \"{profile_id}\", \"profile_type\": \"{profile_type}\"}}'")
    
    return False

if __name__ == "__main__":
    test_with_admin_token()
