#!/usr/bin/env python3
"""
Smoke test para RPCs do marketplace (admin-only):
- Cria Department -> Category -> SubCategory -> Brand -> Product
- Executa updates simples em cada um
- Executa soft-delete em cada um

Pré-requisito: estar logado como admin (token salvo) e sessão ativa com email admin.
"""

import os
import sys
import time
import random
from rich.console import Console
from rich.pretty import pprint

# Permitir imports relativos ao projeto
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.abspath(os.path.join(CURRENT_DIR, ".."))
sys.path.append(ROOT_DIR)

from core.supabase_client import get_supabase_client
from core.session_manager import get_session_data, get_user_token

console = Console()
PROJECT_NAME = "tricket"


def _get_admin_client():
    client = get_supabase_client(PROJECT_NAME)

    # 1) Tentar usar sessão/token existente do admin
    session_data = get_session_data()
    token_data = get_user_token("admin@tricket.com.br")
    if session_data and session_data.get("email") == "admin@tricket.com.br" and token_data and token_data.get("access_token"):
        client.auth.set_session(token_data["access_token"], token_data.get("refresh_token"))
        return client

    # 2) Fallback: fazer login programático usando config/tricket.json
    import json
    config_path = os.path.join(ROOT_DIR, "config", "tricket.json")
    with open(config_path, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    admin_cfg = cfg.get("user_profiles", {}).get("admin", {})
    email = admin_cfg.get("email")
    password = admin_cfg.get("password")
    if not email or not password:
        raise RuntimeError("Credenciais do admin não encontradas em config/tricket.json")

    # Login via Supabase
    client.auth.sign_in_with_password({"email": email, "password": password})
    return client


def main():
    client = _get_admin_client()

    ts = int(time.time())
    rand = random.randint(1000, 9999)

    # 1) Department
    dept_data = {
        "name": f"Dept Test {ts}",
        "slug": None,
        "description": "Smoke test department",
        "icon_url": None,
        "sort_order": 0,
    }
    res = client.rpc("rpc_create_marketplace_department", {"p_data": dept_data}).execute()
    dept = getattr(res, "data", None)
    assert dept and dept.get("id"), f"Falha criar department: {res}"
    dept_id = dept["id"]
    console.print("[green]Departamento criado:[/green]")
    pprint(dept)

    # 2) Category
    cat_data = {
        "department_id": dept_id,
        "name": f"Cat Test {ts}",
        "slug": None,
        "description": "Smoke test category",
        "icon_url": None,
        "sort_order": 0,
    }
    res = client.rpc("rpc_create_marketplace_category", {"p_data": cat_data}).execute()
    cat = getattr(res, "data", None)
    assert cat and cat.get("id"), f"Falha criar category: {res}"
    cat_id = cat["id"]
    console.print("[green]Categoria criada:[/green]")
    pprint(cat)

    # 3) SubCategory
    subcat_data = {
        "category_id": cat_id,
        "name": f"SubCat Test {ts}",
        "slug": None,
        "description": "Smoke test subcategory",
        "icon_url": None,
        "sort_order": 0,
    }
    res = client.rpc("rpc_create_marketplace_sub_category", {"p_data": subcat_data}).execute()
    subcat = getattr(res, "data", None)
    assert subcat and subcat.get("id"), f"Falha criar subcategory: {res}"
    subcat_id = subcat["id"]
    console.print("[green]Subcategoria criada:[/green]")
    pprint(subcat)

    # 4) Brand
    brand_data = {
        "name": f"Brand Test {ts}",
        "slug": None,
        "description": "Smoke test brand",
        "logo_url": None,
        "official_website": None,
        "country_of_origin_code": "BR",
        "gs1_company_prefix": None,
        "gln_brand_owner": None,
        "status": "PENDING_APPROVAL",
    }
    res = client.rpc("rpc_create_marketplace_brand", {"p_data": brand_data}).execute()
    brand = getattr(res, "data", None)
    assert brand and brand.get("id"), f"Falha criar brand: {res}"
    brand_id = brand["id"]
    console.print("[green]Marca criada:[/green]")
    pprint(brand)

    # 5) Product (usa sub_category_id e brand_id)
    gtin = f"789{ts % 1000000000:09d}{rand % 10}"
    prod_data = {
        "sub_category_id": subcat_id,
        "brand_id": brand_id,
        "name": f"Product Test {ts}",
        "description": "Smoke test product",
        "sku_base": f"SKU-{ts}",
        "gtin": gtin,
    }
    res = client.rpc("rpc_create_marketplace_product", {"p_data": prod_data}).execute()
    product = getattr(res, "data", None)
    assert product and product.get("id"), f"Falha criar product: {res}"
    product_id = product["id"]
    console.print("[green]Produto criado:[/green]")
    pprint(product)

    # Updates simples
    client.rpc("rpc_update_marketplace_department", {"p_id": dept_id, "p_data": {"name": f"Dept Test {ts}-UPD"}}).execute()
    client.rpc("rpc_update_marketplace_category", {"p_id": cat_id, "p_data": {"name": f"Cat Test {ts}-UPD"}}).execute()
    client.rpc("rpc_update_marketplace_sub_category", {"p_id": subcat_id, "p_data": {"name": f"SubCat Test {ts}-UPD"}}).execute()
    client.rpc("rpc_update_marketplace_brand", {"p_id": brand_id, "p_data": {"status": "ACTIVE"}}).execute()
    client.rpc("rpc_update_marketplace_product", {"p_id": product_id, "p_data": {"name": f"Product Test {ts}-UPD"}}).execute()
    console.print("[cyan]Updates executados.[/cyan]")

    # Deletes (soft)
    client.rpc("rpc_delete_marketplace_product", {"p_id": product_id}).execute()
    client.rpc("rpc_delete_marketplace_brand", {"p_id": brand_id}).execute()
    client.rpc("rpc_delete_marketplace_sub_category", {"p_id": subcat_id}).execute()
    client.rpc("rpc_delete_marketplace_category", {"p_id": cat_id}).execute()
    client.rpc("rpc_delete_marketplace_department", {"p_id": dept_id}).execute()
    console.print("[cyan]Deletes (soft) executados.[/cyan]")

    console.print("\n[bold green]Smoke test concluído com sucesso.[/bold green]")
    console.print({
        "department_id": dept_id,
        "category_id": cat_id,
        "sub_category_id": subcat_id,
        "brand_id": brand_id,
        "product_id": product_id,
    })


if __name__ == "__main__":
    main()
