import os
import sys
from pathlib import Path

# Bootstrap: ensure we re-exec using the local venv's Python if available
SCRIPT_DIR = Path(__file__).resolve().parent
VENV_DIR = SCRIPT_DIR / ".venv" / "bin"
PY_CANDIDATES = [VENV_DIR / "python", VENV_DIR / "python3"]
VENV_PY = next((p for p in PY_CANDIDATES if p.exists()), None)
if VENV_PY is not None and Path(sys.executable).resolve() != VENV_PY.resolve():
    try:
        sys.stderr.write(f"[bootstrap] Switching to venv interpreter: {VENV_PY}\n")
        sys.stderr.flush()
        os.execv(str(VENV_PY), [str(VENV_PY)] + sys.argv)
    except Exception as _e:
        sys.stderr.write(f"[bootstrap] Failed to exec venv python: {_e}\n")
        sys.stderr.flush()

else:
    if VENV_PY is None:
        sys.stderr.write(f"[bootstrap] No venv interpreter found under {VENV_DIR}. Continuing with {sys.executable}.\n")
        sys.stderr.flush()

# Load environment variables from backend .env (after we're in the venv)
try:
    from dotenv import load_dotenv  # type: ignore
    BACKEND_ENV = SCRIPT_DIR.parent / "tricket-backend" / ".env"
    if BACKEND_ENV.exists():
        load_dotenv(dotenv_path=BACKEND_ENV)
    else:
        sys.stderr.write(f"[env] Backend .env not found at {BACKEND_ENV}.\n")
        sys.stderr.flush()
except ModuleNotFoundError:
    sys.stderr.write("[env] python-dotenv not installed in current interpreter. Skipping .env loading.\n")
    sys.stderr.flush()

# Compat: map SERVICE_ROLE_KEY -> SUPABASE_SERVICE_ROLE_KEY if needed
if not os.getenv("SUPABASE_SERVICE_ROLE_KEY") and os.getenv("SERVICE_ROLE_KEY"):
    os.environ["SUPABASE_SERVICE_ROLE_KEY"] = os.environ["SERVICE_ROLE_KEY"]

import typer
import inspect
from rich.console import Console
from rich.prompt import Prompt

from operations.auth import create_user_from_profile, login_user
from operations.supabase_db import supabase_db_push, supabase_db_reset, force_reset_and_signup
from operations.token_manager import manage_tokens, show_token_summary
from operations.bulk_operations import create_all_users_and_profiles
from operations.individual_profile import register_individual_profile_from_config
from operations.profile_approval import get_profiles_for_approval, approve_user_profile_interactive
from operations.marketplace_rpc import marketplace_rpc_menu
from operations.product_distribution import distribute_products_to_suppliers
from operations.automation import automate_users_and_offers
from operations.cart_testing import cart_testing_menu

PROJECT_NAME = "tricket"

app = typer.Typer()
console = Console()

def load_operations() -> dict:
    """Carrega todas as operações disponíveis para o projeto Tricket."""
    operations = {
        "Criar Conta + Perfil Completo": create_user_from_profile,
        "Criar Perfil Individual": register_individual_profile_from_config,
        "Cadastrar TODOS os Usuários": create_all_users_and_profiles,
        "Login de Usuário": login_user,
        "Supabase DB Push (Aplicar Migrações)": supabase_db_push,
        "Supabase DB Reset (Resetar Banco)": supabase_db_reset,
        "DB Reset Forçado + Cadastro Usuário": force_reset_and_signup,
        "Gerenciar Tokens": manage_tokens,
        "Ver Resumo de Tokens": show_token_summary,
        "Ver Profiles para Aprovação (Admin)": get_profiles_for_approval,
        "Aprovar Profile (Admin)": approve_user_profile_interactive,
        "RPCs Marketplace (Admin)": marketplace_rpc_menu,
        "Distribuir Produtos entre Fornecedores (Dry-Run)": distribute_products_to_suppliers,
        "Automatizar: Cadastrar Usuários + Criar Ofertas": automate_users_and_offers,
        "Testar Carrinho (Consumidor)": cart_testing_menu,
    }
    return operations

def main():
    """Inicia o sistema de testes para o projeto Tricket."""
    console.print("[bold cyan]Sistema de Testes - Tricket[/bold cyan]")
    console.print("="*40)

    # Carrega operações disponíveis
    operations = load_operations()
    op_names = list(operations.keys())

    console.print("\n[bold]Operações Disponíveis:[/bold]")
    for i, op_name in enumerate(op_names):
        console.print(f"  {i+1}. {op_name}")

    # Seleção de operação: via env TRICKET_OP, ou prompt interativo
    env_choice = os.getenv("TRICKET_OP")
    if env_choice and env_choice.isdigit() and 1 <= int(env_choice) <= len(op_names):
        op_choice_idx = env_choice
    else:
        try:
            op_choice_idx = Prompt.ask(
                "\nEscolha o número da operação",
                choices=[str(i+1) for i in range(len(op_names))]
            )
        except EOFError:
            console.print("\n[bold yellow]Entrada não-interativa detectada.[/bold yellow]")
            console.print("Defina a variável de ambiente TRICKET_OP com o número da operação, por exemplo: TRICKET_OP=1")
            return
    selected_op_name = op_names[int(op_choice_idx) - 1]
    selected_op_func = operations[selected_op_name]
    
    console.print(f"\n[yellow]Executando:[/] [bold]{selected_op_name}[/bold]...")
    console.print("-"*40)

    # Executa a operação
    try:
        result = selected_op_func(PROJECT_NAME)
        if result is not False:
            console.print("\n[bold green]Operação finalizada.[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Ocorreu um erro inesperado: {e}[/bold red]")

if __name__ == "__main__":
    # Always call main() directly to avoid Typer/Click behavior differences in IDE terminals
    main()
