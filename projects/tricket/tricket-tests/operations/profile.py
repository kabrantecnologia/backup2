from rich.console import Console
from rich.pretty import pprint
from rich.prompt import Prompt
from core.supabase_client import get_supabase_client, get_config, set_session
from core.session_manager import get_session_data

console = Console()

def register_individual_profile(project_name: str) -> bool:
    """Chama a função 'register_individual_profile' no Supabase. Retorna True em sucesso, False em falha."""
    try:
        session = get_session_data()
        if not session or not session.get("access_token"):
            raise ValueError("Falha na operação: Nenhum usuário autenticado. Execute uma operação de criação de conta primeiro.")

        client = get_supabase_client(project_name)
        set_session(client, session)

        console.print("[yellow]Preparando dados para o cadastro de perfil individual...[/yellow]")
        
        params = {
            "profile_data": {
                "full_name": "João Henrique",
                "cpf": "11762341610",
                "birth_date": "1993-02-03",
                "contact_phone": "+5531988039650",
                "income_value_cents": None,
                "contact_email": None,
                "profile_role": "CONSUMER"
            },
            "address_data": {
                "address_type": "MAIN",
                "is_default": True,
                "street": "Rua Augusto Ferreira dos Santos",
                "number": "185",
                "complement": "166",
                "neighborhood": "Serra Verde (Venda Nova)",
                "city_id": 2308,
                "state_id": 11,
                "zip_code": "31630120",
                "country": "Brasil",
                "latitude": -19.8023136,
                "longitude": -43.9527723,
                "geolocation": "0101000020E610000071845671F4F945C0D322916C64CD33C0",
                "notes": None
            }
        }

        console.print("\n[cyan]Enviando para a função RPC 'register_individual_profile':[/cyan]")
        pprint(params)

        response = client.rpc('register_individual_profile', params).execute()

        console.print("\n[green]Resposta da API:[/green]")
        pprint(response.data)
        return True

    except (Exception, ValueError) as e:
        # Se a exceção for a que criamos, exibe a mensagem amigável.
        # Se for 'Auth session missing!', também é o mesmo problema.
        # Outras exceções são exibidas como erro inesperado.
        if "Falha na operação" in str(e) or "Auth session missing!" in str(e):
            console.print(f"[bold red]{e}[/bold red]")
        else:
            console.print(f"[bold red]Ocorreu um erro inesperado durante o cadastro de perfil: {e}[/bold red]")
        return False

def register_organization_profile_from_config(project_name: str, profile_name: str = None):
    """
    Registra o perfil de uma organização selecionando um perfil com dados detalhados
    do arquivo de configuração e usando a sessão de usuário ativa.
    """
    console.print(f"\n[bold cyan]Iniciando cadastro de perfil de organização para o projeto: {project_name}...[/bold cyan]")
    
    try:
        # 1. Obter cliente e carregar sessão
        client = get_supabase_client(project_name)
        session_data = get_session_data()

        if not session_data or not session_data.get("access_token"):
            raise ValueError("Nenhuma sessão de usuário ativa. Por favor, crie uma conta primeiro.")

        client.auth.set_session(session_data["access_token"], session_data.get("refresh_token"))
        console.print("[green]Sessão de usuário carregada com sucesso.[/green]")

        # 2. Carregar e selecionar o perfil de organização
        config = get_config(project_name)
        all_profiles = config.get("user_profiles", {})
        org_profiles = {name: data for name, data in all_profiles.items() if "profile_data" in data}

        if not org_profiles:
            console.print("[bold red]Nenhum perfil com 'profile_data' encontrado no arquivo de configuração.[/bold red]")
            return False

        # Se profile_name for fornecido, usar diretamente
        if profile_name and profile_name in org_profiles:
            selected_profile_name = profile_name
            selected_profile = org_profiles[profile_name]
        else:
            # Modo interativo
            profile_names = list(org_profiles.keys())
            console.print("\n[bold]Perfis de Organização Disponíveis:[/bold]")
            for i, name in enumerate(profile_names, 1):
                console.print(f"  {i}. {name.capitalize()}")

            choice = Prompt.ask("\nEscolha o número do perfil para registrar", choices=[str(i) for i in range(1, len(profile_names) + 1)], default="1")
            selected_profile_name = profile_names[int(choice) - 1]
            selected_profile = org_profiles[selected_profile_name]

        profile_data = selected_profile["profile_data"]
        individual_details = profile_data.get("individual_data") # Corrigido para corresponder ao novo JSON
        organization_details = profile_data.get("organization_data") # Corrigido para corresponder ao novo JSON
        address_data = profile_data.get("address_data")

        if not all([individual_details, organization_details, address_data]):
            console.print(f"[bold red]Estrutura de 'profile_data' para '{selected_profile_name}' está incompleta.[/bold red]")
            return False
            
        console.print(f"Dados de perfil para '{selected_profile_name.capitalize()}' carregados do arquivo de configuração.")

        # 3. Chamar a função RPC
        console.print("Enviando dados para a função RPC 'register_organization_profile'...")
        response = client.rpc(
            "register_organization_profile",
            {
                "individual_data": individual_details,
                "organization_data": organization_details,
                "address_data": address_data,
            },
        ).execute()

        # A verificação de sucesso/erro pode precisar de ajuste dependendo da resposta da RPC
        if response.data and isinstance(response.data, list) and len(response.data) > 0:
            result = response.data[0]
            if result.get('status') == 'error':
                console.print(f"[bold red]Erro retornado pela RPC: {result.get('message')}[/bold red]")
                return False

        console.print(f"Resposta da RPC: {response.data}")
        console.print("[bold green]Perfil da organização registrado com sucesso![/bold green]")
        return True

    except ValueError as e:
        console.print(f"[bold red]{e}[/bold red]")
        return False
    except Exception as e:
        error_message = str(e)
        if "Auth session missing!" in error_message:
            console.print("[bold red]Erro de autenticação: A sessão é inválida ou expirou. Por favor, crie a conta novamente.[/bold red]")
        else:
            console.print(f"[bold red]Ocorreu um erro inesperado: {error_message}[/bold red]")
        return False
