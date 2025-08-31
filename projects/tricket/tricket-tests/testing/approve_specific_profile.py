#!/usr/bin/env python3
"""
Script completo para login do admin e aprovação de um profile específico
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from rich.console import Console
from rich.prompt import Prompt
from operations.profile_approval import approve_user_profile, approve_user_profile_interactive

console = Console()

def approve_specific_profile():
    """Aprova um profile por ID. Se não for informado via CLI, pergunta interativamente."""
    project_name = "tricket"

    # Permitir ID via argumento de linha de comando
    profile_id = sys.argv[1] if len(sys.argv) > 1 else None

    if profile_id:
        console.print(f"[yellow]Aprovando profile {profile_id} como admin...[/yellow]")
        return approve_user_profile(project_name, profile_id)

    # Fallback: modo interativo
    console.print("[cyan]Nenhum ID informado via CLI. Entrando no modo interativo...[/cyan]")
    return approve_user_profile_interactive(project_name)

if __name__ == "__main__":
    approve_specific_profile()
