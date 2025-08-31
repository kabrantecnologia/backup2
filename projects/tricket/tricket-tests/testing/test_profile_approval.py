#!/usr/bin/env python3
"""
Script para testar a função rpc_get_profiles_for_approval
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from core.supabase_client import get_supabase_client
from core.session_manager import get_user_token
from rich.console import Console
from rich.table import Table

console = Console()

def test_get_profiles_for_approval():
    """Testa a função RPC para obter profiles para aprovação"""
    
    project_name = "tricket"
    
    try:
        client = get_supabase_client(project_name)
        
        # Obter token do admin
        token_data = get_user_token("admin@tricket.com.br")
        if not token_data:
            console.print("[bold red]Admin não encontrado. Execute primeiro: Cadastrar TODOS os Usuários[/bold red]")
            return False
            
        # Autenticar
        client.auth.set_session(token_data["access_token"], token_data["refresh_token"])
        
        console.print("[yellow]Executando rpc_get_profiles_for_approval...[/yellow]")
        
        # Chamar a função RPC
        response = client.rpc("rpc_get_profiles_for_approval").execute()
        
        if response.data:
            console.print(f"[bold green]✅ Encontrados {len(response.data)} profiles para aprovação[/bold green]")
            
            # Criar tabela visual
            table = Table(title="Profiles para Aprovação")
            table.add_column("ID", style="cyan")
            table.add_column("Email", style="yellow")
            table.add_column("Nome", style="white")
            table.add_column("Status", style="green")
            table.add_column("Tipo", style="magenta")
            
            for profile in response.data:
                table.add_row(
                    str(profile.get('id', 'N/A')),
                    str(profile.get('email', 'N/A')),
                    str(profile.get('name', 'N/A')),
                    str(profile.get('status', 'N/A')),
                    str(profile.get('profile_type', 'N/A'))
                )
            
            console.print(table)
            
            # Debug dos dados brutos
            console.print("\n[dim]Dados brutos para debug:[/dim]")
            for i, profile in enumerate(response.data):
                console.print(f"Profile {i+1}: {profile}")
            
            return True
        else:
            console.print("[yellow]Nenhum profile encontrado para aprovação.[/yellow]")
            return True
            
    except Exception as e:
        console.print(f"[bold red]Erro: {e}[/bold red]")
        return False

if __name__ == "__main__":
    test_get_profiles_for_approval()
