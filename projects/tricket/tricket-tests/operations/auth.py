from rich.console import Console
from rich.prompt import Prompt
from getpass import getpass
from core.supabase_client import get_supabase_client, get_config
from core.session_manager import save_session

console = Console()

def sign_up_user(project_name: str, email: str, password: str, silent: bool = False) -> bool:
    """
    Cadastra um usuário com e-mail e senha específicos, garantindo que ele seja confirmado e uma sessão seja criada.
    Retorna True em caso de sucesso e False em caso de falha.
    """
    try:
        client = get_supabase_client(project_name)

        if not silent:
            console.print(f"[yellow]Iniciando processo de cadastro para: {email}...[/yellow]")

        # 1. Detecta existência do usuário. Se já existir, evitamos deleção e tentamos login direto.
        user_exists = False
        try:
            users_response = client.auth.admin.list_users()
            # SDK v2 retorna um objeto com atributo `.users`
            resp_users = getattr(users_response, "users", users_response)
            user_iter = resp_users if isinstance(resp_users, list) else []
            user_found = next((u for u in user_iter if getattr(u, "email", None) == email), None)
            user_exists = user_found is not None
            if user_exists and not silent:
                console.print(f"Usuário já existe (ID: {getattr(user_found, 'id', 'N/A')}). Pulando deleção e tentando login...")
            elif not user_exists and not silent:
                console.print("Nenhum usuário existente com este e-mail foi encontrado. Prosseguindo com criação...")
        except Exception as e:
            if not silent:
                console.print(f"[yellow]Não foi possível verificar existência do usuário: {e}[/yellow]")

        # 2. Cria o usuário como admin somente se não existir
        if not user_exists:
            if not silent:
                console.print("Criando novo usuário via admin...")
            admin_user_attributes = {
                "email": email,
                "password": password,
                "email_confirm": True,
            }
            try:
                create_response = client.auth.admin.create_user(admin_user_attributes)
            except Exception as e:
                msg = str(e)
                # Se já registrado, seguimos para login
                if "already been registered" in msg or "already registered" in msg or "User already registered" in msg:
                    if not silent:
                        console.print("[yellow]Usuário já registrado. Prosseguindo para login...[/yellow]")
                else:
                    if not silent:
                        console.print(f"[red]Exceção ao criar usuário via admin: {e}[/red]")
                    return False

            else:
                if not getattr(create_response, "user", None):
                    if not silent:
                        # Tentar exibir detalhes do response quando disponível
                        try:
                            console.print(f"[red]Falha ao criar usuário via admin. Resposta: {create_response}\nVerifique SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY e permissões do service role.[/red]")
                        except Exception:
                            console.print("[red]Falha ao criar usuário via admin.[/red]")
                    return False
                if not silent:
                    console.print("[green]Usuário criado com sucesso![/green]")

        # 3. Faz login para obter uma sessão válida
        if not silent:
            console.print(f"Realizando login com {email} para obter a sessão...")
        session_response = client.auth.sign_in_with_password({
            "email": email,
            "password": password,
        })

        if session_response.session:
            if not silent:
                console.print("[green]Login bem-sucedido e sessão criada![/green]")
            session_data = session_response.session.model_dump(mode='json')
            session_data["user_id"] = session_response.user.id
            session_data["project"] = project_name
            save_session(session_data)
            if not silent:
                console.print("[cyan]Sessão salva com as informações do novo usuário.[/cyan]")
            return True
        else:
            if not silent:
                console.print("[red]Erro ao fazer login após o cadastro.[/red]")
            return False

    except Exception as e:
        if not silent:
            console.print(f"[bold red]Ocorreu um erro inesperado no processo de cadastro: {e}[/bold red]")
        return False

def create_user_from_profile(project_name: str):
    """Cria um usuário selecionando um perfil do arquivo de configuração."""
    config = get_config(project_name)
    profiles = config.get("user_profiles")

    if not profiles:
        console.print("[bold red]Nenhum perfil de usuário ('user_profiles') encontrado no arquivo de configuração.[/bold red]")
        return False

    profile_names = list(profiles.keys())
    console.print("\n[bold]Perfis de Usuário Disponíveis:[/bold]")
    for i, name in enumerate(profile_names, 1):
        console.print(f"  {i}. {name.capitalize()}")

    choice = Prompt.ask("\nEscolha o número do perfil para criar", choices=[str(i) for i in range(1, len(profile_names) + 1)], default="1")
    selected_profile_name = profile_names[int(choice) - 1]
    selected_profile = profiles[selected_profile_name]

    email = selected_profile.get("email")
    password = selected_profile.get("password")

    if not email or not password:
        console.print(f"[bold red]Perfil '{selected_profile_name}' está mal configurado. 'email' e 'password' são obrigatórios.[/bold red]")
        return False

    console.print(f"\n[bold cyan]Iniciando criação de conta para o perfil: {selected_profile_name.capitalize()}...[/bold cyan]")
    return sign_up_user(project_name, email, password)


def login_user(project_name: str) -> bool:
    """Realiza login usando as credenciais definidas em 'user_profiles' do arquivo de configuração."""
    try:
        client = get_supabase_client(project_name)

        # Carrega perfis do config
        config = get_config(project_name)
        profiles = config.get("user_profiles", {})
        if not profiles:
            console.print("[bold red]Nenhum 'user_profiles' encontrado no arquivo de configuração.[/bold red]")
            return False

        profile_names = list(profiles.keys())
        console.print("\n[bold]Perfis Disponíveis para Login:[/bold]")
        for i, name in enumerate(profile_names, 1):
            console.print(f"  {i}. {name}")

        choice = Prompt.ask("\nEscolha o número do perfil para login", choices=[str(i) for i in range(1, len(profile_names) + 1)], default="1")
        selected_profile = profiles[profile_names[int(choice) - 1]]

        email = selected_profile.get("email")
        password = selected_profile.get("password")
        if not email or not password:
            console.print("[bold red]Perfil selecionado não possui 'email' e 'password' válidos.[/bold red]")
            return False

        console.print(f"\n[yellow]Autenticando usuário: {email}...[/yellow]")
        session_response = client.auth.sign_in_with_password({
            "email": email,
            "password": password,
        })

        if session_response.session:
            console.print("[green]Login bem-sucedido! Sessão ativa.[/green]")
            session_data = session_response.session.model_dump(mode='json')
            session_data["user_id"] = session_response.user.id
            session_data["project"] = project_name
            save_session(session_data)
            console.print("[cyan]Sessão salva localmente para uso nas próximas operações.[/cyan]")
            return True
        else:
            console.print("[red]Falha no login: credenciais inválidas ou usuário inexistente.[/red]")
            return False

    except Exception as e:
        console.print(f"[bold red]Erro durante o login: {e}[/bold red]")
        return False



