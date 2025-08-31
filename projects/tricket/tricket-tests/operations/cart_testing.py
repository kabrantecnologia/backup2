from __future__ import annotations
from typing import Any, Dict, Optional
from rich.console import Console
from rich.table import Table
from rich.prompt import Prompt
from rich.panel import Panel

from core.supabase_client import get_supabase_client
from core.session_manager import get_user_token

RPC_GET_CONTEXTS = "get_user_contexts"
RPC_SET_ACTIVE = "set_active_profile"

console = Console()


def _get_consumer_client(project_name: str, email: str):
    client = get_supabase_client(project_name)
    token = get_user_token(email)
    if not token or not token.get("access_token"):
        console.print(f"[bold red]Token não encontrado para {email}. Faça login primeiro.[/bold red]")
        return None
    client.auth.set_session(token["access_token"], token.get("refresh_token"))
    return client


def _ensure_active_buyer_profile(client) -> bool:
    """Garante que há um perfil ativo (preferindo INDIVIDUAL) para o usuário autenticado."""
    try:
        res = client.rpc(RPC_GET_CONTEXTS).execute()
        data = getattr(res, "data", None) or {}
        active = data.get("active_profile")
        if active and active.get("active"):
            return True
        # preferir INDIVIDUAL, senão qualquer disponível ativo
        candidate: Optional[str] = None
        for p in (data.get("available_profiles") or []):
            if p.get("active") is not True:
                continue
            if p.get("profile_type") == "INDIVIDUAL" and p.get("profile_id"):
                candidate = p["profile_id"]
                break
            if not candidate and p.get("profile_id"):
                candidate = p["profile_id"]
        if candidate:
            client.rpc(RPC_SET_ACTIVE, {"p_profile_id": candidate}).execute()
            return True
        console.print("[yellow]Nenhum perfil ativo disponível para este usuário.[/yellow]")
        return False
    except Exception as e:
        console.print(f"[red]Falha ao definir perfil ativo:[/red] {e}")
        return False


def _print_offers_grid(items: list[Dict[str, Any]]):
    table = Table(show_header=True, header_style="bold magenta")
    table.add_column("#")
    table.add_column("offer_id")
    table.add_column("product_name")
    table.add_column("brand")
    table.add_column("price_cents", justify="right")
    table.add_column("supplier")
    table.add_column("dist_km", justify="right")
    for idx, it in enumerate(items, 1):
        table.add_row(
            str(idx),
            str(it.get("offer_id", "")),
            str(it.get("product_name", "")),
            str(it.get("brand_name", "")),
            str(it.get("price_cents", "")),
            str(it.get("supplier_name", "")),
            str(it.get("distance_km", "")),
        )
    console.print(table)


def _print_cart_snapshot(s: Dict[str, Any]):
    cart = (s or {}).get("cart") or {}
    items = (s or {}).get("items") or []
    summary = (s or {}).get("summary") or {}
    console.print(Panel.fit(f"Carrinho: {cart.get('id','-')}  status={cart.get('status','-')}", style="bold cyan"))
    table = Table(show_header=True, header_style="bold magenta")
    table.add_column("item_id")
    table.add_column("offer_id")
    table.add_column("qty", justify="right")
    table.add_column("unit_price", justify="right")
    for it in items:
        table.add_row(
            str(it.get("id","")),
            str(it.get("offer_id","")),
            str(it.get("quantity","")),
            str(it.get("unit_price_cents","")),
        )
    console.print(table)
    console.print(f"Total qty: {summary.get('total_quantity',0)}  •  Total cents: {summary.get('total_cents',0)}")


def cart_testing_menu(project_name: str) -> bool:
    console.print("[bold cyan]Teste de RPCs do Carrinho[/bold cyan]")
    email = Prompt.ask("Email do consumidor (deve ter login prévio)")

    client = _get_consumer_client(project_name, email)
    if not client:
        return False
    if not _ensure_active_buyer_profile(client):
        return False

    while True:
        console.print("\n[bold]Ações:[/bold]")
        console.print("  1. Listar ofertas (grid)")
        console.print("  2. Adicionar item ao carrinho")
        console.print("  3. Ver carrinho atual")
        console.print("  4. Atualizar quantidade de item")
        console.print("  5. Remover item")
        console.print("  6. Sair")
        choice = Prompt.ask("Escolha", choices=["1","2","3","4","5","6"])

        try:
            if choice == "1":
                q = Prompt.ask("Busca (q)", default="")
                limit = int(Prompt.ask("limit", default="10"))
                res = client.rpc("rpc_marketplace_offers_grid", {"p_filters": {"q": q, "limit": limit}}).execute()
                data = getattr(res, "data", {}) or {}
                items = data.get("items") or []
                _print_offers_grid(items)
            elif choice == "2":
                offer_id = Prompt.ask("offer_id (UUID)")
                qty = int(Prompt.ask("quantity", default="1"))
                note = Prompt.ask("note (opcional)", default="")
                res = client.rpc("rpc_cart_add_item", {"p_data": {"offer_id": offer_id, "quantity": qty, "note": note or None}}).execute()
                _print_cart_snapshot(getattr(res, "data", {}) or {})
            elif choice == "3":
                res = client.rpc("rpc_cart_get").execute()
                _print_cart_snapshot(getattr(res, "data", {}) or {})
            elif choice == "4":
                item_id = Prompt.ask("item_id (UUID)")
                qty = int(Prompt.ask("new quantity"))
                res = client.rpc("rpc_cart_update_item_quantity", {"p_item_id": item_id, "p_quantity": qty}).execute()
                _print_cart_snapshot(getattr(res, "data", {}) or {})
            elif choice == "5":
                item_id = Prompt.ask("item_id (UUID)")
                res = client.rpc("rpc_cart_remove_item", {"p_item_id": item_id}).execute()
                _print_cart_snapshot(getattr(res, "data", {}) or {})
            else:
                break
        except Exception as e:
            console.print(f"[bold red]Erro:[/bold red] {e}")
    return True
