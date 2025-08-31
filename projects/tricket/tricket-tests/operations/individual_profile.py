from rich.console import Console
from rich.pretty import pprint
from core.supabase_client import get_supabase_client, get_config
from core.session_manager import get_session_data

console = Console()

def register_individual_profile_from_config(project_name: str, profile_name: str = None) -> bool:
    """
    Registra o perfil individual de um usuário usando dados do arquivo de configuração.
    
    Args:
        project_name: Nome do projeto
        profile_name: Nome do perfil no arquivo de configuração (opcional, se None usa interativo)
    
    Returns:
        bool: True se sucesso, False se falha
    """
    try:
        console.print(f"\n[bold cyan]Registrando perfil individual para: {profile_name}[/bold cyan]")
        
        # 1. Verificar sessão ativa
        session_data = get_session_data()
        if not session_data or not session_data.get("access_token"):
            console.print("[bold red]Erro: Nenhum usuário autenticado. Faça login primeiro.[/bold red]")
            return False
            
        # Obter tokens da sessão
        access_token = session_data.get("access_token")
        refresh_token = session_data.get("refresh_token")

        # 2. Obter dados do perfil
        client = get_supabase_client(project_name)
        config = get_config(project_name)
        profiles = config.get("user_profiles", {})
        
        # Se profile_name não for fornecido, perguntar interativamente
        if profile_name is None:
            if not profiles:
                console.print("[bold red]Nenhum perfil de usuário encontrado no arquivo de configuração.[/bold red]")
                return False

            profile_names = list(profiles.keys())
            console.print("\n[bold]Perfis de Usuário Disponíveis:[/bold]")
            for i, name in enumerate(profile_names, 1):
                console.print(f"  {i}. {name.capitalize()}")

            from rich.prompt import Prompt
            choice = Prompt.ask(
                "\nEscolha o número do perfil", 
                choices=[str(i+1) for i in range(len(profile_names))]
            )
            profile_name = profile_names[int(choice) - 1]
        
        if profile_name not in profiles:
            console.print(f"[bold red]Perfil '{profile_name}' não encontrado no arquivo de configuração.[/bold red]")
            return False

        profile_data = profiles[profile_name]
        individual_data = profile_data.get("profile_data", {}).get("individual_data", {})
        address_data = profile_data.get("profile_data", {}).get("address_data", {})

        if not individual_data:
            console.print("[bold red]Dados individuais não encontrados no perfil.[/bold red]")
            return False

        # 3. Preparar dados para a API
        profile_payload = {
            "full_name": individual_data.get("full_name"),
            "birth_date": individual_data.get("birth_date"),
            "income_value_cents": individual_data.get("income_value_cents"),
            "contact_email": individual_data.get("contact_email"),
            "contact_phone": individual_data.get("contact_phone"),
            "cpf": individual_data.get("cpf")
        }

        # 4. Preparar dados de endereço
        address_payload = {
            "address_type": address_data.get("address_type", "MAIN"),
            "is_default": address_data.get("is_default", True),
            "street": address_data.get("street"),
            "number": address_data.get("number"),
            "complement": address_data.get("complement"),
            "neighborhood": address_data.get("neighborhood"),
            "city_id": address_data.get("city_id"),
            "state_id": address_data.get("state_id"),
            "zip_code": address_data.get("zip_code"),
            "country": address_data.get("country"),
            "latitude": address_data.get("latitude"),
            "longitude": address_data.get("longitude"),
            "geolocation": address_data.get("geolocation"),
            "notes": address_data.get("notes")
        }

        # 5. Configurar autenticação no cliente
        if access_token and refresh_token:
            client.auth.set_session(access_token, refresh_token)

        console.print("[yellow]Enviando dados do perfil individual...[/yellow]")
        
        # 6. Chamar a função RPC para registrar perfil individual
        response = client.rpc('register_individual_profile', {
            "profile_data": profile_payload,
            "address_data": address_payload
        }).execute()

        if response.data:
            console.print("[bold green]✅ Perfil individual registrado com sucesso![/bold green]")
            pprint(response.data)
            return True
        else:
            console.print("[bold red]❌ Falha ao registrar perfil individual[/bold red]")
            return False

    except Exception as e:
        console.print(f"[bold red]Erro ao registrar perfil individual: {e}[/bold red]")
        return False
