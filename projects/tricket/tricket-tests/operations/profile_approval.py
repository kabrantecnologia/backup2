from rich.console import Console
from rich.table import Table
from rich.pretty import pprint
from core.supabase_client import get_supabase_client
from core.session_manager import get_session_data, get_user_token
from rich.prompt import Prompt

console = Console()

def approve_user_profile(project_name: str, profile_id: str) -> bool:
    """
    Aprova um profile específico usando a função RPC approve_user_profile.
    
    Args:
        project_name: Nome do projeto
        profile_id: ID do profile a ser aprovado
    
    Returns:
        bool: True se sucesso, False se falha
    """
    try:
        return _approve_profile_by_id(project_name, profile_id)
    except Exception as e:
        console.print(f"[bold red]Erro ao aprovar profile: {e}[/bold red]")
        return False

def _approve_profile_by_id(project_name: str, profile_id: str) -> bool:
    """Helper robusto que autentica como admin e tenta múltiplos nomes de RPC."""
    client = get_supabase_client(project_name)

    # Obter dados da sessão do admin
    session_data = get_session_data()
    if not session_data or not session_data.get("email"):
        console.print("[bold red]Erro: Nenhuma sessão ativa encontrada.[/bold red]")
        return False

    # Verificar se é o admin
    if session_data.get("email") != "admin@tricket.com.br":
        console.print("[bold red]Erro: Esta operação requer login como admin@tricket.com.br[/bold red]")
        return False

    # Configurar autenticação
    token_data = get_user_token("admin@tricket.com.br")
    if not token_data or not token_data.get("access_token"):
        console.print("[bold red]Erro: Token de admin não encontrado. Faça login primeiro.[/bold red]")
        return False

    client.auth.set_session(token_data["access_token"], token_data.get("refresh_token"))

    console.print(f"[yellow]Aprovando profile {profile_id}...[/yellow]")

    # Tentar múltiplos nomes de RPC para maior compatibilidade
    rpc_names = [
        "rpc_approve_user_profile",  # usado por approve_specific_profile.py
        "approve_user_profile",      # variação sem prefixo
    ]

    for rpc_name in rpc_names:
        try:
            response = client.rpc(rpc_name, {"p_profile_id": profile_id}).execute()
            # Algumas instalações retornam 200 com data; outras podem retornar erro HTTP com conteúdo
            if getattr(response, "data", None) is not None:
                console.print(f"[bold green]✅ Profile {profile_id} aprovado com sucesso![/bold green]")
                return True
        except Exception as e:
            # Tentar próxima RPC
            continue

    console.print("[bold red]❌ Falha ao aprovar profile (RPCs não disponíveis).[/bold red]")
    return False

def approve_user_profile_interactive(project_name: str) -> bool:
    """Solicita o ID de profile e executa a aprovação como admin."""
    profile_id = Prompt.ask("Informe o ID do profile a aprovar")
    if not profile_id:
        console.print("[red]ID inválido.[/red]")
        return False
    return _approve_profile_by_id(project_name, profile_id)

def get_profiles_for_approval(project_name: str) -> bool:
    """
    Executa a função RPC rpc_get_profiles_for_approval como admin@tricket.com.br
    para obter a lista de usuários com seus IDs para aprovação.
    
    Args:
        project_name: Nome do projeto
    
    Returns:
        bool: True se sucesso, False se falha
    """
    try:
        client = get_supabase_client(project_name)
        
        # Obter dados da sessão do admin
        session_data = get_session_data()
        if not session_data or not session_data.get("email"):
            console.print("[bold red]Erro: Nenhuma sessão ativa encontrada.[/bold red]")
            return False
        
        # Verificar se é o admin
        if session_data.get("email") != "admin@tricket.com.br":
            console.print("[bold red]Erro: Esta operação requer login como admin@tricket.com.br[/bold red]")
            return False
        
        # Configurar autenticação
        token_data = get_user_token("admin@tricket.com.br")
        if not token_data or not token_data.get("access_token"):
            console.print("[bold red]Erro: Token de admin não encontrado. Faça login primeiro.[/bold red]")
            return False
        
        client.auth.set_session(token_data["access_token"], token_data.get("refresh_token"))
        
        console.print("[yellow]Executando rpc_get_profiles_for_approval como admin...[/yellow]")
        
        # Chamar a função RPC
        response = client.rpc("rpc_get_profiles_for_approval").execute()
        
        if response.data:
            console.print("[bold green]✅ Lista de profiles para aprovação obtida com sucesso![/bold green]")
            
            # Criar tabela visual
            table = Table(title="Profiles para Aprovação")
            table.add_column("ID", style="cyan")
            table.add_column("Email", style="yellow")
            table.add_column("Nome", style="white")
            table.add_column("Status", style="green")
            table.add_column("Tipo", style="magenta")
            
            for profile in response.data:
                table.add_row(
                    str(profile.get('id', 'N/A')),
                    str(profile.get('email', 'N/A')),
                    str(profile.get('name', 'N/A')),
                    str(profile.get('status', 'N/A')),
                    str(profile.get('profile_type', 'N/A'))
                )
            
            console.print(table)
            
            # Também mostrar em formato JSON para debug
            console.print("\n[dim]Dados brutos:[/dim]")
            pprint(response.data)
            
            return True
        else:
            console.print("[yellow]Nenhum profile encontrado para aprovação.[/yellow]")
            return True
            
    except Exception as e:
        console.print(f"[bold red]Erro ao obter profiles para aprovação: {e}[/bold red]")
        return False
