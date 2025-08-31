#!/usr/bin/env python3
"""
Automation Runner - Tricket Testing

Executes a sequence of testing operations to speed up end-to-end checks
without changing the current interactive main.

Flow (v1):
1) Login de Usuário (irá perguntar email/senha como no fluxo atual)
2) Criar Ofertas COCA-COLA (bulk, preço 1299, status ACTIVE)

You can extend this script to add more steps.
"""
from __future__ import annotations

import sys
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from pathlib import Path
import os
import sys as _sys

# Adjust sys.path so we can import from ../operations when executed directly
_BASE_DIR = Path(__file__).resolve().parents[1]  # testing-tricket/
if str(_BASE_DIR) not in _sys.path:
    _sys.path.insert(0, str(_BASE_DIR))

# Import existing operations
try:
    from operations.auth import login_user
    from operations.supplier_offers import supplier_bulk_create_offers_coca, PROJECT_NAME_DEFAULT
except Exception as e:
    print("Falha ao importar operações. Verifique o PYTHONPATH e a estrutura do projeto.")
    raise

console = Console()


def step_login(project_name: str) -> bool:
    console.rule("Login (Automation)")
    try:
        ok = login_user(project_name)
        if not ok:
            console.print("[bold red]Falha no login. Abortando.[/bold red]")
            return False
        return True
    except Exception as e:
        console.print(f"[bold red]Erro inesperado no login:[/bold red] {e}")
        return False


def step_bulk_coca(project_name: str) -> bool:
    console.rule("Bulk Offers COCA-COLA (Automation)")
    try:
        ok = supplier_bulk_create_offers_coca(project_name)
        if not ok:
            console.print("[bold red]Bulk COCA-COLA retornou falso.[/bold red]")
            return False
        return True
    except Exception as e:
        console.print(f"[bold red]Erro inesperado no bulk COCA-COLA:[/bold red] {e}")
        return False


def main():
    console.print(Panel.fit("Automation Runner - Tricket Testing", style="bold cyan"))
    project_name = PROJECT_NAME_DEFAULT

    # Steps
    if not step_login(project_name):
        sys.exit(1)

    if not step_bulk_coca(project_name):
        sys.exit(2)

    console.rule("Resumo")
    table = Table(show_header=True, header_style="bold magenta")
    table.add_column("Step")
    table.add_column("Status")
    table.add_row("Login", "OK")
    table.add_row("Bulk COCA-COLA", "OK")
    console.print(table)

    console.print("[bold green]Automation concluída com sucesso![/bold green]")


if __name__ == "__main__":
    main()
