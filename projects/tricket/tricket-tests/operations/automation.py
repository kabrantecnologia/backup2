from __future__ import annotations
from rich.console import Console
from rich.panel import Panel

from operations.bulk_operations import create_all_users_and_profiles
from operations.product_distribution import distribute_products_to_suppliers
from operations.supplier_offers_bulk import bulk_create_offers_from_assignments

console = Console()


def automate_users_and_offers(project_name: str) -> bool:
    """
    Passo-a-passo automatizado:
    1) Cadastrar TODOS os usuários e perfis (tokens salvos).
    2) Distribuir products.md entre fornecedores (gera testing/product_assignments.json).
    3) Criar ofertas em massa por fornecedor usando as distribuições.
    Retorna True se todas as etapas concluírem sem falhas críticas.
    """
    console.print(Panel.fit("Automação: Cadastrar usuários + Criar ofertas", style="bold cyan"))

    # 1) Cadastrar usuários/perfis
    console.print("[bold]1) Cadastrando todos os usuários e perfis...[/bold]")
    if create_all_users_and_profiles(project_name) is False:
        console.print("[red]Falha no cadastro de usuários/perfis.[/red]")
        return False

    # 2) Distribuir produtos entre fornecedores (dry-run -> assignments.json)
    console.print("[bold]2) Gerando distribuição de produtos para fornecedores...[/bold]")
    if distribute_products_to_suppliers(project_name) is False:
        console.print("[red]Falha na distribuição de produtos.[/red]")
        return False

    # 3) Criar ofertas em massa (usa tokens salvos e garante perfil ORG ativo)
    console.print("[bold]3) Criando ofertas em massa por fornecedor...[/bold]")
    ok = bulk_create_offers_from_assignments(project_name, price_cents=1299, status="ACTIVE")
    if ok is False:
        console.print("[yellow]Concluído com falhas em algumas ofertas.[/yellow]")
    else:
        console.print("[green]Ofertas criadas com sucesso para todos os fornecedores.[/green]")

    return True
