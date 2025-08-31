from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
from rich.panel import Panel
from rich.table import Table
from typing import Dict, Any, List
import time

from operations.auth import sign_up_user
from operations.individual_profile import register_individual_profile_from_config
from operations.profile_batch import register_organization_profile_batch
from core.supabase_client import get_supabase_client, get_config
from core.session_manager import save_user_token, save_session

console = Console()

def create_all_users_and_profiles(project_name: str) -> bool:
    """
    Cadastra e cria perfis completos para TODOS os usuários do arquivo de configuração.
    Processo automatizado em lote com progresso visual.
    """
    try:
        client = get_supabase_client(project_name)
        config = get_config(project_name)
        profiles = config.get("user_profiles", {})
        
        if not profiles:
            console.print("[bold red]Nenhum perfil de usuário encontrado no arquivo de configuração.[/bold red]")
            return False

        console.print(Panel(
            f"[bold cyan]Cadastro em Lote - {len(profiles)} Usuários[/bold cyan]\n"
            f"Processo automatizado de criação de contas e perfis",
            title="Bulk Operations"
        ))

        # Preparar lista de usuários
        user_list = list(profiles.items())
        results = []
        
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TaskProgressColumn(),
            console=console
        ) as progress:
            
            main_task = progress.add_task("[cyan]Processando usuários...", total=len(user_list))
            
            for idx, (profile_name, profile_data) in enumerate(user_list, 1):
                email = profile_data.get("email")
                password = profile_data.get("password")
                
                if not email or not password:
                    results.append({
                        "user": profile_name,
                        "email": email or "N/A",
                        "status": "❌ Erro Config",
                        "details": "Email ou senha faltando"
                    })
                    continue
                
                progress.update(main_task, description=f"[cyan]Processando {email}...")
                
                try:
                    # 1. Criar conta de usuário
                    user_created = sign_up_user(project_name, email, password, silent=True)
                    if not user_created:
                        results.append({
                            "user": profile_name,
                            "email": email,
                            "status": "❌ Erro Conta",
                            "details": "Falha ao criar conta"
                        })
                        continue
                    
                    # 2. Fazer login para obter token
                    session_response = client.auth.sign_in_with_password({
                        "email": email,
                        "password": password,
                    })
                    
                    if not session_response.session:
                        results.append({
                            "user": profile_name,
                            "email": email,
                            "status": "❌ Erro Login",
                            "details": "Falha ao autenticar"
                        })
                        continue
                    
                    # 3. Armazenar tokens
                    from datetime import datetime
                    now = datetime.now().isoformat()
                    token_data = {
                        "access_token": session_response.session.access_token,
                        "refresh_token": session_response.session.refresh_token,
                        "expires_at": session_response.session.expires_at,
                        "user_id": session_response.user.id,
                        "created_at": now,
                        "last_used": now
                    }
                    save_user_token(email, token_data)
                    
                    # 4. Detectar tipo de perfil e usar função correta
                    selected_profile = profiles.get(profile_name)
                    profile_data = selected_profile.get("profile_data", {})
                    org_data = profile_data.get("organization_data", {})
                    platform_role = org_data.get("platform_role", "").upper()
                    
                    # Se for CONSUMER ou role individual, usar perfil individual
                    if platform_role == "CONSUMER" or org_data.get("company_type") == "INDIVIDUAL":
                        profile_created = register_individual_profile_from_config(
                            project_name, 
                            profile_name
                        )
                    else:
                        profile_created = register_organization_profile_batch(
                            project_name, 
                            profile_name
                        )
                    
                    if profile_created:
                        results.append({
                            "user": profile_name,
                            "email": email,
                            "status": "✅ Sucesso",
                            "details": "Conta e perfil criados"
                        })
                    else:
                        results.append({
                            "user": profile_name,
                            "email": email,
                            "status": "⚠️ Parcial",
                            "details": "Conta criada, perfil falhou"
                        })
                
                except Exception as e:
                    results.append({
                        "user": profile_name,
                        "email": email,
                        "status": "❌ Erro",
                        "details": str(e)[:50] + "..."
                    })
                
                progress.advance(main_task)
                time.sleep(0.5)  # Pequena pausa entre operações
        
        # Relatório final
        console.print("\n" + "="*60)
        console.print("[bold green]RELATÓRIO FINAL[/bold green]")
        console.print("="*60)
        
        # Criar tabela de resultados
        table = Table(title="Resultados do Cadastro em Lote")
        table.add_column("Usuário", style="cyan")
        table.add_column("Email", style="magenta")
        table.add_column("Status", style="bold")
        table.add_column("Detalhes", style="dim")
        
        success_count = 0
        for result in results:
            table.add_row(
                result["user"],
                result["email"],
                result["status"],
                result["details"]
            )
            if "✅" in result["status"]:
                success_count += 1
        
        console.print(table)
        
        # Estatísticas
        stats_panel = Panel(
            f"[bold]Total Processado:[/bold] {len(results)}\n"
            f"[green]✅ Sucessos:[/green] {success_count}\n"
            f"[red]❌ Falhas:[/red] {len(results) - success_count}\n"
            f"[blue]📊 Taxa de Sucesso:[/blue] {(success_count/len(results)*100):.1f}%",
            title="Estatísticas"
        )
        console.print(stats_panel)
        
        # Salvar relatório
        if success_count > 0:
            console.print(f"\n[green]✅ {success_count} usuários cadastrados com sucesso![/green]")
            console.print("[cyan]📋 Todos os tokens foram armazenados automaticamente.[/cyan]")
        
        return success_count > 0
        
    except Exception as e:
        console.print(f"[bold red]Erro crítico no processo: {e}[/bold red]")
        return False

def create_users_with_filter(project_name: str, filter_roles: List[str] = None) -> bool:
    """
    Cria usuários filtrando por roles específicas.
    
    Args:
        project_name: Nome do projeto
        filter_roles: Lista de roles para filtrar (ex: ["FORNECEDOR", "COMERCIANTE"])
    """
    try:
        client = get_supabase_client(project_name)
        config = get_config(project_name)
        profiles = config.get("user_profiles", {})
        
        if not profiles:
            console.print("[bold red]Nenhum perfil encontrado.[/bold red]")
            return False

        # Filtrar por roles se especificado
        filtered_profiles = {}
        if filter_roles:
            for name, data in profiles.items():
                profile_data = data.get("profile_data", {})
                org_data = profile_data.get("organization_data", {})
                role = org_data.get("platform_role", "").upper()
                if role in [r.upper() for r in filter_roles]:
                    filtered_profiles[name] = data
            
            if not filtered_profiles:
                console.print(f"[yellow]Nenhum usuário encontrado com roles: {filter_roles}[/yellow]")
                return False
        else:
            filtered_profiles = profiles

        console.print(Panel(
            f"[cyan]Filtrando usuários por roles: {filter_roles or 'Todos'}[/cyan]\n"
            f"Usuários a processar: {len(filtered_profiles)}",
            title="Filtro de Roles"
        ))
        
        # Usar a função principal com os perfis filtrados
        # Salvando temporariamente os perfis originais
        original_profiles = profiles
        config["user_profiles"] = filtered_profiles
        
        try:
            return create_all_users_and_profiles(project_name)
        finally:
            # Restaurar perfis originais
            config["user_profiles"] = original_profiles
            
    except Exception as e:
        console.print(f"[bold red]Erro no filtro: {e}[/bold red]")
        return False
