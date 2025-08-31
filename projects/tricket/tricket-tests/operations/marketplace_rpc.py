from typing import Optional, Dict, Any
from rich.console import Console
from rich.prompt import Prompt
from rich.pretty import pprint
from rich.table import Table

from core.supabase_client import get_supabase_client
from core.session_manager import get_session_data, get_user_token, get_current_user

console = Console()

PROJECT_NAME_DEFAULT = "tricket"


def _get_admin_client(project_name: str):
    client = get_supabase_client(project_name)
    current_email = get_current_user()
    if current_email != "admin@tricket.com.br":
        console.print("[bold red]Esta operação requer login como admin@tricket.com.br[/bold red]")
        return None

    token_data = get_user_token("admin@tricket.com.br")
    if not token_data or not token_data.get("access_token"):
        console.print("[bold red]Token do admin não encontrado. Faça login primeiro.[/bold red]")
        return None

    client.auth.set_session(token_data["access_token"], token_data.get("refresh_token"))
    return client


def _print_result(title: str, data: Any):
    console.print(f"[bold green]✅ {title}[/bold green]")
    pprint(data)


def _print_error(title: str, error: Exception):
    console.print(f"[bold red]❌ {title}: {error}[/bold red]")


# ---------------------------
# INSERT RPCs
# ---------------------------

def create_department(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False

    name = Prompt.ask("Nome do departamento")
    slug = Prompt.ask("Slug (opcional, deixe vazio para auto)", default="")
    description = Prompt.ask("Descrição (opcional)", default="")
    icon_url = Prompt.ask("Icon URL (opcional)", default="")
    sort_order = Prompt.ask("Ordem (int, opcional)", default="0")

    p_data = {
        "name": name,
        "slug": slug or None,
        "description": description or None,
        "icon_url": icon_url or None,
        "sort_order": int(sort_order or 0),
    }
    try:
        res = client.rpc("rpc_create_marketplace_department", {"p_data": p_data}).execute()
        _print_result("Departamento criado", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao criar departamento", e)
        return False


def create_category(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False

    department_id = Prompt.ask("ID do departamento (UUID)")
    name = Prompt.ask("Nome da categoria")
    slug = Prompt.ask("Slug (opcional, deixe vazio para auto)", default="")
    description = Prompt.ask("Descrição (opcional)", default="")
    icon_url = Prompt.ask("Icon URL (opcional)", default="")
    sort_order = Prompt.ask("Ordem (int, opcional)", default="0")

    p_data = {
        "department_id": department_id,
        "name": name,
        "slug": slug or None,
        "description": description or None,
        "icon_url": icon_url or None,
        "sort_order": int(sort_order or 0),
    }
    try:
        res = client.rpc("rpc_create_marketplace_category", {"p_data": p_data}).execute()
        _print_result("Categoria criada", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao criar categoria", e)
        return False


def create_sub_category(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False

    category_id = Prompt.ask("ID da categoria (UUID)")
    name = Prompt.ask("Nome da subcategoria")
    slug = Prompt.ask("Slug (opcional, deixe vazio para auto)", default="")
    description = Prompt.ask("Descrição (opcional)", default="")
    icon_url = Prompt.ask("Icon URL (opcional)", default="")
    sort_order = Prompt.ask("Ordem (int, opcional)", default="0")

    p_data = {
        "category_id": category_id,
        "name": name,
        "slug": slug or None,
        "description": description or None,
        "icon_url": icon_url or None,
        "sort_order": int(sort_order or 0),
    }
    try:
        res = client.rpc("rpc_create_marketplace_sub_category", {"p_data": p_data}).execute()
        _print_result("Subcategoria criada", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao criar subcategoria", e)
        return False


def create_brand(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False

    name = Prompt.ask("Nome da marca")
    slug = Prompt.ask("Slug (opcional, deixe vazio para auto)", default="")
    description = Prompt.ask("Descrição (opcional)", default="")
    logo_url = Prompt.ask("Logo URL (opcional)", default="")
    official_website = Prompt.ask("Site oficial (opcional)", default="")
    country_code = Prompt.ask("País de origem (ISO, opcional)", default="")
    gs1_prefix = Prompt.ask("GS1 company prefix (opcional)", default="")
    gln_owner = Prompt.ask("GLN brand owner (opcional)", default="")
    status = Prompt.ask("Status (PENDING_APPROVAL/ACTIVE/INACTIVE) [default=PENDING_APPROVAL]", default="")

    p_data = {
        "name": name,
        "slug": slug or None,
        "description": description or None,
        "logo_url": logo_url or None,
        "official_website": official_website or None,
        "country_of_origin_code": country_code or None,
        "gs1_company_prefix": gs1_prefix or None,
        "gln_brand_owner": gln_owner or None,
        "status": status or None,
    }
    try:
        res = client.rpc("rpc_create_marketplace_brand", {"p_data": p_data}).execute()
        _print_result("Marca criada", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao criar marca", e)
        return False


def create_product(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False

    sub_category_id = Prompt.ask("ID da subcategoria (UUID)")
    brand_id = Prompt.ask("ID da marca (UUID)")
    name = Prompt.ask("Nome do produto")
    description = Prompt.ask("Descrição (opcional)", default="")
    sku_base = Prompt.ask("SKU base (opcional)", default="")
    gtin = Prompt.ask("GTIN (obrigatório)")

    p_data: Dict[str, Any] = {
        "sub_category_id": sub_category_id,
        "brand_id": brand_id,
        "name": name,
        "description": description or None,
        "sku_base": sku_base or None,
        "gtin": gtin,
        # Campos opcionais adicionais podem ser coletados futuramente
    }
    try:
        res = client.rpc("rpc_create_marketplace_product", {"p_data": p_data}).execute()
        _print_result("Produto criado", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao criar produto", e)
        return False


# ---------------------------
# UPDATE/DELETE RPCs
# ---------------------------

def update_department(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False
    p_id = Prompt.ask("ID do departamento (UUID)")
    # Campos opcionais
    name = Prompt.ask("Novo nome (opcional)", default="")
    slug = Prompt.ask("Novo slug (opcional)", default="")
    description = Prompt.ask("Nova descrição (opcional)", default="")
    icon_url = Prompt.ask("Novo icon_url (opcional)", default="")
    is_active = Prompt.ask("Ativo? (true/false, opcional)", default="")
    sort_order = Prompt.ask("Ordem (int, opcional)", default="")

    p_data: Dict[str, Any] = {}
    if name: p_data["name"] = name
    if slug: p_data["slug"] = slug
    if description: p_data["description"] = description
    if icon_url: p_data["icon_url"] = icon_url
    if is_active: p_data["is_active"] = True if is_active.lower() == "true" else False
    if sort_order: p_data["sort_order"] = int(sort_order)

    try:
        res = client.rpc("rpc_update_marketplace_department", {"p_id": p_id, "p_data": p_data}).execute()
        _print_result("Departamento atualizado", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao atualizar departamento", e)
        return False


def delete_department(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False
    p_id = Prompt.ask("ID do departamento (UUID)")
    try:
        res = client.rpc("rpc_delete_marketplace_department", {"p_id": p_id}).execute()
        _print_result("Departamento soft-deleted", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao deletar departamento", e)
        return False


def update_category(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False
    p_id = Prompt.ask("ID da categoria (UUID)")
    department_id = Prompt.ask("Novo department_id (UUID, opcional)", default="")
    name = Prompt.ask("Novo nome (opcional)", default="")
    slug = Prompt.ask("Novo slug (opcional)", default="")
    description = Prompt.ask("Nova descrição (opcional)", default="")
    icon_url = Prompt.ask("Novo icon_url (opcional)", default="")
    is_active = Prompt.ask("Ativo? (true/false, opcional)", default="")
    sort_order = Prompt.ask("Ordem (int, opcional)", default="")

    p_data: Dict[str, Any] = {}
    if department_id: p_data["department_id"] = department_id
    if name: p_data["name"] = name
    if slug: p_data["slug"] = slug
    if description: p_data["description"] = description
    if icon_url: p_data["icon_url"] = icon_url
    if is_active: p_data["is_active"] = True if is_active.lower() == "true" else False
    if sort_order: p_data["sort_order"] = int(sort_order)

    try:
        res = client.rpc("rpc_update_marketplace_category", {"p_id": p_id, "p_data": p_data}).execute()
        _print_result("Categoria atualizada", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao atualizar categoria", e)
        return False


def delete_category(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False
    p_id = Prompt.ask("ID da categoria (UUID)")
    try:
        res = client.rpc("rpc_delete_marketplace_category", {"p_id": p_id}).execute()
        _print_result("Categoria soft-deleted", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao deletar categoria", e)
        return False


def update_sub_category(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False
    p_id = Prompt.ask("ID da subcategoria (UUID)")
    category_id = Prompt.ask("Novo category_id (UUID, opcional)", default="")
    name = Prompt.ask("Novo nome (opcional)", default="")
    slug = Prompt.ask("Novo slug (opcional)", default="")
    description = Prompt.ask("Nova descrição (opcional)", default="")
    icon_url = Prompt.ask("Novo icon_url (opcional)", default="")
    is_active = Prompt.ask("Ativo? (true/false, opcional)", default="")
    sort_order = Prompt.ask("Ordem (int, opcional)", default="")

    p_data: Dict[str, Any] = {}
    if category_id: p_data["category_id"] = category_id
    if name: p_data["name"] = name
    if slug: p_data["slug"] = slug
    if description: p_data["description"] = description
    if icon_url: p_data["icon_url"] = icon_url
    if is_active: p_data["is_active"] = True if is_active.lower() == "true" else False
    if sort_order: p_data["sort_order"] = int(sort_order)

    try:
        res = client.rpc("rpc_update_marketplace_sub_category", {"p_id": p_id, "p_data": p_data}).execute()
        _print_result("Subcategoria atualizada", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao atualizar subcategoria", e)
        return False


def delete_sub_category(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False
    p_id = Prompt.ask("ID da subcategoria (UUID)")
    try:
        res = client.rpc("rpc_delete_marketplace_sub_category", {"p_id": p_id}).execute()
        _print_result("Subcategoria soft-deleted", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao deletar subcategoria", e)
        return False


def update_brand(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False
    p_id = Prompt.ask("ID da marca (UUID)")
    name = Prompt.ask("Novo nome (opcional)", default="")
    slug = Prompt.ask("Novo slug (opcional)", default="")
    description = Prompt.ask("Nova descrição (opcional)", default="")
    logo_url = Prompt.ask("Novo logo_url (opcional)", default="")
    official_website = Prompt.ask("Novo site oficial (opcional)", default="")
    country_code = Prompt.ask("Novo país de origem (ISO, opcional)", default="")
    gs1_prefix = Prompt.ask("Novo GS1 company prefix (opcional)", default="")
    gln_owner = Prompt.ask("Novo GLN brand owner (opcional)", default="")
    status = Prompt.ask("Novo status (PENDING_APPROVAL/ACTIVE/INACTIVE, opcional)", default="")

    p_data: Dict[str, Any] = {}
    if name: p_data["name"] = name
    if slug: p_data["slug"] = slug
    if description: p_data["description"] = description
    if logo_url: p_data["logo_url"] = logo_url
    if official_website: p_data["official_website"] = official_website
    if country_code: p_data["country_of_origin_code"] = country_code
    if gs1_prefix: p_data["gs1_company_prefix"] = gs1_prefix
    if gln_owner: p_data["gln_brand_owner"] = gln_owner
    if status: p_data["status"] = status

    try:
        res = client.rpc("rpc_update_marketplace_brand", {"p_id": p_id, "p_data": p_data}).execute()
        _print_result("Marca atualizada", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao atualizar marca", e)
        return False


def delete_brand(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False
    p_id = Prompt.ask("ID da marca (UUID)")
    try:
        res = client.rpc("rpc_delete_marketplace_brand", {"p_id": p_id}).execute()
        _print_result("Marca soft-deleted (status=INACTIVE)", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao deletar marca", e)
        return False


def update_product(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False
    p_id = Prompt.ask("ID do produto (UUID)")
    # Campos opcionais comuns
    name = Prompt.ask("Novo nome (opcional)", default="")
    description = Prompt.ask("Nova descrição (opcional)", default="")
    sku_base = Prompt.ask("Novo SKU base (opcional)", default="")
    gtin = Prompt.ask("Novo GTIN (opcional)", default="")

    p_data: Dict[str, Any] = {}
    if name: p_data["name"] = name
    if description: p_data["description"] = description
    if sku_base: p_data["sku_base"] = sku_base
    if gtin: p_data["gtin"] = gtin

    try:
        res = client.rpc("rpc_update_marketplace_product", {"p_id": p_id, "p_data": p_data}).execute()
        _print_result("Produto atualizado", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao atualizar produto", e)
        return False


def delete_product(project_name: str) -> bool:
    client = _get_admin_client(project_name)
    if not client:
        return False
    p_id = Prompt.ask("ID do produto (UUID)")
    try:
        res = client.rpc("rpc_delete_marketplace_product", {"p_id": p_id}).execute()
        _print_result("Produto soft-deleted (status=INACTIVE)", getattr(res, "data", None))
        return True
    except Exception as e:
        _print_error("Falha ao deletar produto", e)
        return False


# ---------------------------
# MENU
# ---------------------------

def marketplace_rpc_menu(project_name: str) -> bool:
    """Menu interativo para testar RPCs do marketplace (admin-only)."""
    ops = {
        "Criar Department": create_department,
        "Atualizar Department": update_department,
        "Deletar Department (soft)": delete_department,
        "Criar Category": create_category,
        "Atualizar Category": update_category,
        "Deletar Category (soft)": delete_category,
        "Criar SubCategory": create_sub_category,
        "Atualizar SubCategory": update_sub_category,
        "Deletar SubCategory (soft)": delete_sub_category,
        "Criar Brand": create_brand,
        "Atualizar Brand": update_brand,
        "Deletar Brand (soft)": delete_brand,
        "Criar Product": create_product,
        "Atualizar Product": update_product,
        "Deletar Product (soft)": delete_product,
    }

    console.print("[bold magenta]\nRPCs do Marketplace (ADMIN)[/bold magenta]")
    for idx, name in enumerate(ops.keys(), start=1):
        console.print(f"  {idx}. {name}")
    choice = Prompt.ask("Escolha o número da operação", choices=[str(i) for i in range(1, len(ops)+1)])
    sel_name = list(ops.keys())[int(choice)-1]
    console.print(f"\n[yellow]Executando:[/] [bold]{sel_name}[/bold]\n")
    func = ops[sel_name]
    return func(project_name)
