from rich.console import Console
from rich.pretty import pprint
from core.supabase_client import get_supabase_client, get_config
from core.session_manager import get_session_data

console = Console()

def register_organization_profile_batch(project_name: str, profile_name: str) -> bool:
    """
    Versão silenciosa para cadastro em lote de perfis organizacionais.
    
    Args:
        project_name: Nome do projeto
        profile_name: Nome do perfil no arquivo de configuração
    
    Returns:
        bool: True se sucesso, False se falha
    """
    try:
        # 1. Obter cliente e carregar sessão
        client = get_supabase_client(project_name)
        session_data = get_session_data()

        if not session_data or not session_data.get("access_token"):
            console.print("[bold red]Erro: Nenhuma sessão de usuário ativa.[/bold red]")
            return False

        client.auth.set_session(session_data["access_token"], session_data.get("refresh_token"))

        # 2. Carregar perfil específico
        config = get_config(project_name)
        all_profiles = config.get("user_profiles", {})
        
        if profile_name not in all_profiles:
            console.print(f"[bold red]Perfil '{profile_name}' não encontrado.[/bold red]")
            return False

        selected_profile = all_profiles[profile_name]
        profile_data = selected_profile.get("profile_data", {})
        
        individual_details = profile_data.get("individual_data")
        organization_details = profile_data.get("organization_data")
        address_data = profile_data.get("address_data")

        if not all([individual_details, organization_details, address_data]):
            console.print(f"[bold red]Dados incompletos para '{profile_name}'.[/bold red]")
            return False

        # 3. Chamar a função RPC
        response = client.rpc(
            "register_organization_profile",
            {
                "individual_data": individual_details,
                "organization_data": organization_details,
                "address_data": address_data,
            },
        ).execute()

        if response.data and isinstance(response.data, list) and len(response.data) > 0:
            result = response.data[0]
            if result.get('status') == 'error':
                return False

        return True

    except Exception as e:
        return False
