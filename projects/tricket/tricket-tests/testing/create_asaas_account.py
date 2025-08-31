#!/usr/bin/env python3
"""
Script para criar conta Asaas após aprovação do profile
"""

import sys
import os
import requests
import json

# Adicionar o diretório ao path para importar módulos locais
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

def create_asaas_account_with_token():
    """Cria conta Asaas usando o token do admin"""
    
    # URL da edge function
    url = "https://api-dev2-tricket.kabran.com.br/functions/v1/asaas_account_create"
    
    # Profile ID e tipo para teste - usando fornecedor aprovado
    profile_id = "9d3ff895-7894-47dd-8d26-7af78848bfc8"  # fornecedor5@tricket.com.br
    profile_type = "ORGANIZATION"
    
    try:
        # Importar funções locais
        from core.session_manager import get_user_token
        
        # Obter token do admin
        token_data = get_user_token("admin@tricket.com.br")
        if not token_data or not token_data.get("access_token"):
            print("❌ Token de admin não encontrado. Execute primeiro:")
            print("   1. Cadastrar TODOS os Usuários")
            print("   2. Aprovar o profile")
            return False
        
        access_token = token_data["access_token"]
        
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        
        body = {
            "profile_id": profile_id,
            "profile_type": profile_type
        }
        
        print("🔄 Criando conta Asaas...")
        print(f"📋 Profile ID: {profile_id}")
        print(f"📋 Profile Type: {profile_type}")
        print(f"🔑 Token: {access_token[:20]}...")
        
        response = requests.post(url, headers=headers, json=body)
        
        print(f"📊 Status: {response.status_code}")
        
        if response.status_code == 200:
            try:
                result = response.json()
                print("✅ Conta Asaas criada com sucesso!")
                print(f"📄 Resposta: {json.dumps(result, indent=2)}")
                return True
            except json.JSONDecodeError:
                print("✅ Conta Asaas criada com sucesso!")
                print(f"📄 Resposta: {response.text}")
                return True
        else:
            print("❌ Erro ao criar conta Asaas")
            print(f"📄 Status: {response.status_code}")
            print(f"📄 Resposta: {response.text}")
            return False
            
    except ImportError as e:
        print(f"❌ Erro de importação: {e}")
        print("📝 Para testar manualmente, use:")
        print(f"curl -X POST {url} \\")
        print(f"  -H 'Authorization: Bearer SEU_TOKEN_AQUI' \\")
        print(f"  -H 'Content-Type: application/json' \\")
        print(f"  -d '{{\"profile_id\": \"{profile_id}\", \"profile_type\": \"{profile_type}\"}}'")
        return False
    except Exception as e:
        print(f"❌ Erro: {e}")
        return False

if __name__ == "__main__":
    create_asaas_account_with_token()
