#!/usr/bin/env python3
"""
Script para criar conta Asaas após aprovação do profile
"""

import sys
import os
import requests
import json
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from core.session_manager import get_user_token
from rich.console import Console

console = Console()

def create_asaas_account(project_name: str, profile_id: str, profile_type: str) -> bool:
    """
    Solicita a criação da conta Asaas usando a edge function
    
    Args:
        project_name: Nome do projeto
        profile_id: ID do profile aprovado
        profile_type: Tipo do profile (INDIVIDUAL ou ORGANIZATION)
    
    Returns:
        bool: True se sucesso, False se falha
    """
    
    # URL da edge function
    url = "https://api-dev2-tricket.kabran.com.br/functions/v1/asaas_account_create"
    
    try:
        # Obter token do admin
        token_data = get_user_token("admin@tricket.com.br")
        if not token_data or not token_data.get("access_token"):
            console.print("[bold red]Erro: Token de admin não encontrado.[/bold red]")
            return False
        
        headers = {
            "Authorization": f"Bearer {token_data['access_token']}",
            "Content-Type": "application/json"
        }
        
        body = {
            "profile_id": profile_id,
            "profile_type": profile_type
        }
        
        console.print(f"[yellow]Criando conta Asaas para profile {profile_id}...[/yellow]")
        console.print(f"[dim]URL: {url}[/dim]")
        console.print(f"[dim]Profile Type: {profile_type}[/dim]")
        
        response = requests.post(url, headers=headers, json=body)
        
        if response.status_code == 200:
            result = response.json()
            console.print(f"[bold green]✅ Conta Asaas criada com sucesso![/bold green]")
            console.print(f"Resposta: {json.dumps(result, indent=2)}")
            return True
        else:
            console.print(f"[bold red]❌ Erro ao criar conta Asaas[/bold red]")
            console.print(f"Status: {response.status_code}")
            console.print(f"Resposta: {response.text}")
            return False
            
    except Exception as e:
        console.print(f"[bold red]Erro ao criar conta Asaas: {e}[/bold red]")
        return False

def test_create_asaas_account():
    """Testa a criação da conta Asaas com um profile específico"""
    
    # Usando um dos profiles aprovados anteriormente
    profile_id = "c1bb0c6a-1f4b-4d87-ab84-853e25471c42"  # fornecedor5@tricket.com.br
    profile_type = "ORGANIZATION"
    
    success = create_asaas_account("tricket", profile_id, profile_type)
    
    if success:
        console.print("✅ Teste concluído com sucesso!")
    else:
        console.print("❌ Teste falhou")

if __name__ == "__main__":
    test_create_asaas_account()
