

from rich.console import Console
from rich.pretty import pprint
from core.supabase_client import get_supabase_client
from core.session_manager import get_session_data
from operations.auth import sign_up_user

console = Console()

def register_supplier(project_name: str):
    """Cadastra um usuário fornecedor e seu perfil para o projeto Tricket."""
    email = "fornecedor@tricket.com.br"
    console.print(f"[bold cyan]Iniciando cadastro de Fornecedor ({email})...[/bold cyan]")

    # 1. Criar o usuário e a sessão
    if not sign_up_user(project_name, email, silent=True):
        console.print("[bold red]Falha ao criar o usuário base. Abortando.[/bold red]")
        return

    # 2. Chamar a RPC para cadastrar o perfil do fornecedor
    try:
        session = get_session_data()
        client = get_supabase_client(project_name)
        client.auth.set_session(session["access_token"], session.get("refresh_token"))

        console.print("[yellow]Preparando dados para o cadastro de perfil de fornecedor...[/yellow]")
        params = {
            "profile_data": {
                "full_name": "Fornecedor Padrão",
                "cnpj": "12345678000199",
                "contact_phone": "+5531999999999",
                "profile_role": "SUPPLIER"
            }
        }

        console.print("\n[cyan]Enviando para a função RPC 'register_supplier_profile':[/cyan]")
        pprint(params)

        response = client.rpc('register_supplier_profile', params).execute()

        console.print("\n[green]Resposta da API:[/green]")
        pprint(response.data)

    except Exception as e:
        console.print(f"[bold red]Ocorreu um erro inesperado no cadastro do perfil: {e}[/bold red]")

def register_merchant(project_name: str):
    """Cadastra um usuário comerciante e seu perfil para o projeto Tricket."""
    email = "comerciante@tricket.com.br"
    console.print(f"[bold cyan]Iniciando cadastro de Comerciante ({email})...[/bold cyan]")

    # 1. Criar o usuário e a sessão
    if not sign_up_user(project_name, email, silent=True):
        console.print("[bold red]Falha ao criar o usuário base. Abortando.[/bold red]")
        return

    # 2. Chamar a RPC para cadastrar o perfil do comerciante
    try:
        session = get_session_data()
        client = get_supabase_client(project_name)
        client.auth.set_session(session["access_token"], session.get("refresh_token"))

        console.print("[yellow]Preparando dados para o cadastro de perfil de comerciante...[/yellow]")
        params = {
            "profile_data": {
                "full_name": "Comerciante Padrão",
                "cnpj": "98765432000199",
                "contact_phone": "+5531988888888",
                "profile_role": "MERCHANT"
            }
        }

        console.print("\n[cyan]Enviando para a função RPC 'register_merchant_profile':[/cyan]")
        pprint(params)

        response = client.rpc('register_merchant_profile', params).execute()

        console.print("\n[green]Resposta da API:[/green]")
        pprint(response.data)

    except Exception as e:
        console.print(f"[bold red]Ocorreu um erro inesperado no cadastro do perfil: {e}[/bold red]")

