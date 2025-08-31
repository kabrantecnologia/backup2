from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, Confirm
from core.session_manager import (
    get_all_tokens, 
    remove_user_token, 
    clear_all_tokens,
    get_current_user,
    get_current_token
)

console = Console()

def manage_tokens(project_name: str) -> bool:
    """Interface para gerenciar tokens de acesso armazenados."""
    console.print("\n[bold cyan]Gerenciador de Tokens de Acesso[/bold cyan]")
    console.print("=" * 40)
    
    while True:
        tokens = get_all_tokens()
        
        if not tokens:
            console.print("[yellow]Nenhum token armazenado.[/yellow]")
        else:
            # Criar tabela de tokens
            table = Table(title="Tokens Armazenados")
            table.add_column("Usuário", style="cyan")
            table.add_column("User ID", style="magenta")
            table.add_column("Expira em", style="yellow")
            table.add_column("Último uso", style="green")
            
            for email, token_data in tokens.items():
                expires_at = token_data.get("expires_at", "N/A")
                last_used = token_data.get("last_used", "N/A")
                user_id = token_data.get("user_id", "N/A")[:8] + "..."
                table.add_row(email, user_id, str(expires_at), str(last_used))
            
            console.print(table)
        
        # Menu de opções
        console.print("\n[bold]Opções:[/bold]")
        console.print("1. Visualizar tokens")
        console.print("2. Remover token específico")
        console.print("3. Limpar todos os tokens")
        console.print("4. Ver token atual")
        console.print("5. Voltar")
        
        choice = Prompt.ask(
            "\nEscolha uma opção",
            choices=["1", "2", "3", "4", "5"],
            default="1"
        )
        
        if choice == "1":
            continue  # Já está mostrando
        
        elif choice == "2":
            if not tokens:
                console.print("[red]Nenhum token para remover.[/red]")
                continue
                
            user_email = Prompt.ask("E-mail do usuário para remover token")
            if user_email in tokens:
                if Confirm.ask(f"Remover token de {user_email}?"):
                    remove_user_token(user_email)
                    console.print(f"[green]Token de {user_email} removido.[/green]")
            else:
                console.print("[red]Usuário não encontrado.[/red]")
        
        elif choice == "3":
            if tokens and Confirm.ask("Limpar TODOS os tokens?"):
                clear_all_tokens()
                console.print("[green]Todos os tokens foram removidos.[/green]")
        
        elif choice == "4":
            current_user = get_current_user()
            current_token = get_current_token()
            
            if current_user and current_token:
                panel = Panel(
                    f"Usuário: {current_user}\nToken: {current_token[:20]}...",
                    title="Token Atual",
                    style="green"
                )
                console.print(panel)
            else:
                console.print("[yellow]Nenhum usuário logado no momento.[/yellow]")
        
        elif choice == "5":
            break
    
    return True

def show_token_summary(project_name: str) -> bool:
    """Mostra um resumo rápido dos tokens armazenados."""
    tokens = get_all_tokens()
    
    if not tokens:
        console.print("[yellow]Nenhum token armazenado.[/yellow]")
        return True
    
    console.print(f"\n[bold]Resumo de Tokens:[/bold] {len(tokens)} usuário(s)")
    for email, data in tokens.items():
        current = " (atual)" if email == get_current_user() else ""
        console.print(f"  • {email}{current}")
    
    return True
