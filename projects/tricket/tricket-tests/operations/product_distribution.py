import re
import json
from pathlib import Path
from typing import Dict, List
from rich.console import Console
from rich.table import Table
from rich.panel import Panel

from core.supabase_client import get_config

console = Console()
UUID_RE = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")


def _load_product_ids(repo_root: Path) -> List[str]:
    products_file = repo_root / "products.md"
    if not products_file.exists():
        console.print(f"[bold red]Arquivo não encontrado:[/bold red] {products_file}")
        return []
    ids: List[str] = []
    for line in products_file.read_text(encoding="utf-8").splitlines():
        line = line.strip().rstrip(".")  # tolera ponto final acidental
        if UUID_RE.match(line):
            ids.append(line)
    return ids


def _get_suppliers_from_config(project_name: str, repo_root: Path) -> List[Dict[str, str]]:
    config = get_config(project_name)
    profiles = config.get("user_profiles", {})
    suppliers: List[Dict[str, str]] = []
    for key, data in profiles.items():
        org = data.get("profile_data", {}).get("organization_data", {})
        role = (org.get("platform_role") or "").upper()
        if role == "FORNECEDOR" and key != "admin":
            suppliers.append({
                "key": key,
                "email": data.get("email", "")
            })
    return suppliers


def distribute_products_to_suppliers(project_name: str) -> bool:
    """
    Lê os product IDs de products.md e distribui entre todos os fornecedores do config
    (round-robin). Salva o resultado em testing-tricket/testing/product_assignments.json
    e exibe um resumo em tabela (dry-run, sem criar ofertas/produtos via RPC).
    """
    # repo_root = testing-tricket/..
    # Este módulo roda dentro de testing-tricket/, então repo_root é dois níveis acima de operations
    repo_root = Path(__file__).resolve().parents[2]
    testing_dir = Path(__file__).resolve().parents[1]  # testing-tricket/
    out_dir = testing_dir / "testing"
    out_dir.mkdir(parents=True, exist_ok=True)

    # Carrega dados
    product_ids = _load_product_ids(repo_root)
    suppliers = _get_suppliers_from_config(project_name, repo_root)

    if not product_ids:
        console.print("[bold yellow]Nenhum product ID válido encontrado em products.md[/bold yellow]")
        return False
    if not suppliers:
        console.print("[bold yellow]Nenhum fornecedor encontrado em config/tricket.json[/bold yellow]")
        return False

    # Distribuição round-robin
    assignments: Dict[str, Dict[str, object]] = {}
    for s in suppliers:
        assignments[s["key"]] = {"email": s["email"], "product_ids": []}

    idx = 0
    sup_keys = [s["key"] for s in suppliers]
    for pid in product_ids:
        target_key = sup_keys[idx % len(suppliers)]
        assignments[target_key]["product_ids"].append(pid)
        idx += 1

    # Salva arquivo
    out_file = out_dir / "product_assignments.json"
    out_file.write_text(json.dumps(assignments, ensure_ascii=False, indent=2), encoding="utf-8")

    # Exibe resumo
    console.print(Panel.fit("Distribuição de Produtos entre Fornecedores (Dry-Run)", style="bold cyan"))
    table = Table(show_header=True, header_style="bold magenta")
    table.add_column("Fornecedor (key)")
    table.add_column("Email")
    table.add_column("Qtd Produtos")
    for key in sup_keys:
        info = assignments[key]
        table.add_row(key, str(info.get("email", "")), str(len(info.get("product_ids", []))))
    console.print(table)
    console.print(f"[green]Arquivo gerado:[/green] {out_file}")
    console.print("[dim]Observação: este passo não cria ofertas/produtos. Serve para planejar o bulk por fornecedor.[/dim]")
    return True
