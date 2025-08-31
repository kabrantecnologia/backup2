from __future__ import annotations
from typing import Dict, Any, List
from pathlib import Path
import json

from rich.console import Console
from rich.table import Table
from rich.panel import Panel

from core.supabase_client import get_supabase_client
from core.session_manager import get_user_token

console = Console()

ASSIGNMENTS_RELATIVE = "testing/product_assignments.json"
RPC_NAME = "rpc_supplier_create_product_offer"
RPC_GET_CONTEXTS = "get_user_contexts"
RPC_SET_ACTIVE = "set_active_profile"


def _get_supplier_client(project_name: str, email: str):
    client = get_supabase_client(project_name)
    token = get_user_token(email)
    if not token or not token.get("access_token"):
        console.print(f"[bold red]Token não encontrado para {email}. Faça login primeiro.[/bold red]")
        return None
    client.auth.set_session(token["access_token"], token.get("refresh_token"))
    return client


def _ensure_active_org_profile(client) -> bool:
    """Seleciona um perfil ORGANIZATION como ativo para o usuário autenticado.
    Usa get_user_contexts() para descobrir os perfis e set_active_profile(profile_id).
    Retorna True em caso de sucesso.
    """
    try:
        res = client.rpc(RPC_GET_CONTEXTS).execute()
        data = getattr(res, "data", None) or {}
        # Estrutura esperada: { active_profile: {...}, available_profiles: [...] }
        active = data.get("active_profile")
        if active and (active.get("profile_type") == "ORGANIZATION"):
            return True
        # Procura um perfil de organização disponível
        for p in data.get("available_profiles", []) or []:
            if p.get("profile_type") == "ORGANIZATION":
                pid = p.get("profile_id")
                if pid:
                    client.rpc(RPC_SET_ACTIVE, {"p_profile_id": pid}).execute()
                    return True
        console.print("[yellow]Nenhum perfil ORGANIZATION disponível para este usuário.[/yellow]")
        return False
    except Exception as e:
        console.print(f"[red]Falha ao definir perfil ativo:[/red] {e}")
        return False


def bulk_create_offers_from_assignments(project_name: str, price_cents: int = 1299, status: str = "ACTIVE") -> bool:
    """
    Lê testing/product_assignments.json e cria ofertas via RPC para cada fornecedor.

    Requisitos:
    - Cada fornecedor deve ter sessão/token salvo (já obtido no cadastro em lote ou login).
    - O usuário fornecedor deve ser membro da organização ativa (validado na RPC).

    Campos usados na RPC:
    - product_id (UUID) [required]
    - price_cents (int) [required]
    - status (ex.: ACTIVE) [opcional]
    - min_order_quantity = 1 (default aqui)
    """
    base_dir = Path(__file__).resolve().parents[1]  # testing-tricket/
    assignments_path = base_dir / ASSIGNMENTS_RELATIVE

    if not assignments_path.exists():
        console.print(f"[bold red]Arquivo de distribuição não encontrado:[/bold red] {assignments_path}")
        console.print("Execute antes: 'Distribuir Produtos entre Fornecedores (Dry-Run)'")
        return False

    assignments: Dict[str, Dict[str, Any]] = json.loads(assignments_path.read_text(encoding="utf-8"))

    console.print(Panel.fit("Criar Ofertas em Massa por Fornecedor", style="bold cyan"))

    summary: List[Dict[str, Any]] = []

    for supplier_key, info in assignments.items():
        email = str(info.get("email") or "")
        product_ids: List[str] = info.get("product_ids", [])

        # Pular entradas sem email válido e o admin
        if not email or email.lower() == "admin@tricket.com.br":
            summary.append({"supplier": supplier_key, "email": email or "(vazio)", "ok": 0, "fail": len(product_ids), "note": "pulado"})
            continue

        client = _get_supplier_client(project_name, email)
        if not client:
            summary.append({"supplier": supplier_key, "email": email, "ok": 0, "fail": len(product_ids), "note": "sem token"})
            continue
        # Garante perfil ORGANIZATION ativo
        if not _ensure_active_org_profile(client):
            summary.append({"supplier": supplier_key, "email": email, "ok": 0, "fail": len(product_ids), "note": "sem perfil ativo"})
            continue

        ok = 0
        ok_existing = 0
        fail = 0
        for pid in product_ids:
            try:
                payload = {
                    "p_data": {
                        "product_id": pid,
                        "price_cents": int(price_cents),
                        "min_order_quantity": 1,
                        "status": status,
                    }
                }
                res = client.rpc(RPC_NAME, payload).execute()
                data = getattr(res, "data", None)
                # A função retorna JSONB; em caso de erro pode vir {'error': ..., 'sqlstate': ...}
                if isinstance(data, dict) and data.get("error"):
                    sqlstate = str(data.get("sqlstate") or "")
                    if sqlstate == "23505" or "unique" in str(data.get("error")).lower():
                        ok_existing += 1
                    else:
                        fail += 1
                else:
                    ok += 1
            except Exception as e:
                fail += 1
        note = ""
        if ok_existing:
            note = f"{ok_existing} existentes"
        summary.append({"supplier": supplier_key, "email": email, "ok": ok + ok_existing, "fail": fail, "note": note})

    # Tabela de resumo
    table = Table(show_header=True, header_style="bold magenta")
    table.add_column("Fornecedor (key)")
    table.add_column("Email")
    table.add_column("OK")
    table.add_column("Falhas")
    table.add_column("Obs")
    total_ok = 0
    total_fail = 0
    for row in summary:
        table.add_row(row["supplier"], row["email"], str(row["ok"]), str(row["fail"]), row.get("note", ""))
        total_ok += row["ok"]
        total_fail += row["fail"]
    console.print(table)
    console.print(f"[green]Total OK:[/green] {total_ok}  •  [red]Falhas:[/red] {total_fail}")

    return total_fail == 0
