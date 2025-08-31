import subprocess
import os
from rich.console import Console
from rich.prompt import Confirm
from core.supabase_client import get_config

console = Console()

# Configurações dos bancos de dados por projeto
DB_CONFIGS = {
    "tricket": {
        "port": "5499",
        "user": "postgres.dev_tricket_tenant",
        "password": "yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH",
        "host": "localhost",
        "database": "postgres"
    },
    "integra": {
        "port": "5424",
        "user": "postgres.dev_integra_tenant",
        "password": "yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH",
        "host": "localhost",
        "database": "postgres"
    },
    "compliance": {
        "port": "5413",
        "user": "postgres.dev_compliance_tenant",
        "password": "yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH",
        "host": "localhost",
        "database": "postgres"
    },
    "projeto": {
        "port": "5411",
        "user": "postgres.dev_projeto_tenant",
        "password": "yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH",
        "host": "localhost",
        "database": "postgres"
    },
    "modelo": {
        "port": "5408",
        "user": "postgres.dev_modelo_tenant",
        "password": "yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH",
        "host": "localhost",
        "database": "postgres"
    }
}

def get_db_url(project_name: str) -> str:
    """Constrói a URL de conexão com o banco de dados para o projeto."""
    config = DB_CONFIGS.get(project_name.lower())
    if not config:
        raise ValueError(f"Configuração de banco não encontrada para o projeto: {project_name}")
    
    return f"postgresql://{config['user']}:{config['password']}@{config['host']}:{config['port']}/{config['database']}"

def get_project_backend_path(project_name: str) -> str:
    """Retorna o caminho do backend do projeto."""
    base_path = "/home/joaohenrique/Github"
    return os.path.join(base_path, f"{project_name.lower()}-backend")

def run_supabase_command(command: str, project_path: str, auto_confirm: bool = False) -> bool:
    """Executa um comando do Supabase no diretório do projeto."""
    try:
        console.print(f"[yellow]Executando: {command}[/yellow]")
        console.print(f"[dim]Diretório: {project_path}[/dim]")
        
        # Para comandos que precisam de confirmação automática, usa echo
        if auto_confirm:
            command = f'echo "y" | {command}'
        
        result = subprocess.run(
            command,
            shell=True,
            cwd=project_path,
            capture_output=True,
            text=True,
            timeout=300  # 5 minutos de timeout
        )
        
        if result.returncode == 0:
            console.print("[green]✓ Comando executado com sucesso![/green]")
            if result.stdout:
                console.print(f"[dim]{result.stdout}[/dim]")
            return True
        else:
            console.print(f"[red]✗ Erro ao executar comando (código: {result.returncode})[/red]")
            if result.stderr:
                console.print(f"[red]{result.stderr}[/red]")
            return False
            
    except subprocess.TimeoutExpired:
        console.print("[red]✗ Comando excedeu o tempo limite de 5 minutos[/red]")
        return False
    except Exception as e:
        console.print(f"[red]✗ Erro inesperado: {e}[/red]")
        return False

def supabase_db_push(project_name: str):
    """Executa o comando supabase db push para o projeto especificado."""
    try:
        console.print(f"[bold cyan]Supabase DB Push - {project_name.upper()}[/bold cyan]")
        console.print("="*50)
        
        # Verifica se o projeto existe nas configurações
        if project_name.lower() not in DB_CONFIGS:
            console.print(f"[red]Projeto '{project_name}' não encontrado nas configurações de banco.[/red]")
            console.print(f"[yellow]Projetos disponíveis: {', '.join(DB_CONFIGS.keys())}[/yellow]")
            return
        
        # Obtém o caminho do backend e a URL do banco
        project_path = get_project_backend_path(project_name)
        db_url = get_db_url(project_name)
        
        # Verifica se o diretório do projeto existe
        if not os.path.exists(project_path):
            console.print(f"[red]Diretório do projeto não encontrado: {project_path}[/red]")
            return
        
        console.print(f"[blue]Projeto:[/blue] {project_name}")
        console.print(f"[blue]Caminho:[/blue] {project_path}")
        console.print(f"[blue]Banco:[/blue] {DB_CONFIGS[project_name.lower()]['host']}:{DB_CONFIGS[project_name.lower()]['port']}")
        
        # Confirma a operação
        if not Confirm.ask(f"\n[yellow]Confirma o push das migrações para o banco {project_name.upper()}?[/yellow]"):
            console.print("[yellow]Operação cancelada pelo usuário.[/yellow]")
            return
        
        # Executa o comando
        command = f'supabase db push --db-url "{db_url}"'
        success = run_supabase_command(command, project_path)
        
        if success:
            console.print(f"\n[bold green]✓ Push concluído com sucesso para {project_name.upper()}![/bold green]")
        else:
            console.print(f"\n[bold red]✗ Falha no push para {project_name.upper()}[/bold red]")
            
    except Exception as e:
        console.print(f"[bold red]Erro inesperado no push: {e}[/bold red]")

def supabase_db_reset(project_name: str):
    """Executa o comando supabase db reset para o projeto especificado."""
    try:
        console.print(f"[bold red]Supabase DB Reset - {project_name.upper()}[/bold red]")
        console.print("="*50)
        
        # Verifica se o projeto existe nas configurações
        if project_name.lower() not in DB_CONFIGS:
            console.print(f"[red]Projeto '{project_name}' não encontrado nas configurações de banco.[/red]")
            console.print(f"[yellow]Projetos disponíveis: {', '.join(DB_CONFIGS.keys())}[/yellow]")
            return
        
        # Obtém o caminho do backend e a URL do banco
        project_path = get_project_backend_path(project_name)
        db_url = get_db_url(project_name)
        
        # Verifica se o diretório do projeto existe
        if not os.path.exists(project_path):
            console.print(f"[red]Diretório do projeto não encontrado: {project_path}[/red]")
            return
        
        console.print(f"[blue]Projeto:[/blue] {project_name}")
        console.print(f"[blue]Caminho:[/blue] {project_path}")
        console.print(f"[blue]Banco:[/blue] {DB_CONFIGS[project_name.lower()]['host']}:{DB_CONFIGS[project_name.lower()]['port']}")
        
        # Aviso importante sobre reset
        console.print("\n[bold red]⚠️  ATENÇÃO: Esta operação irá:[/bold red]")
        console.print("[red]   • Apagar TODOS os dados do banco[/red]")
        console.print("[red]   • Recriar todas as tabelas do zero[/red]")
        console.print("[red]   • Aplicar todas as migrações novamente[/red]")
        console.print("[red]   • Executar os dados de seed (se existirem)[/red]")
        
        # Dupla confirmação para reset
        if not Confirm.ask(f"\n[bold red]Tem CERTEZA que deseja resetar o banco {project_name.upper()}?[/bold red]"):
            console.print("[yellow]Operação cancelada pelo usuário.[/yellow]")
            return
            
        if not Confirm.ask("[bold red]Esta ação é IRREVERSÍVEL. Confirma novamente?[/bold red]"):
            console.print("[yellow]Operação cancelada pelo usuário.[/yellow]")
            return
        
        # Executa o comando
        command = f'supabase db reset --db-url "{db_url}"'
        success = run_supabase_command(command, project_path, auto_confirm=True)
        
        if success:
            console.print(f"\n[bold green]✓ Reset concluído com sucesso para {project_name.upper()}![/bold green]")
        else:
            console.print(f"\n[bold red]✗ Falha no reset para {project_name.upper()}[/bold red]")
            
    except Exception as e:
        console.print(f"[bold red]Erro inesperado no reset: {e}[/bold red]")


def supabase_db_reset_force(project_name: str, silent: bool = False) -> bool:
    """Executa o comando supabase db reset para o projeto especificado sem confirmação."""
    try:
        if not silent:
            console.print(f"[bold red]Supabase DB Reset (Forçado) - {project_name.upper()}[/bold red]")
            console.print("="*50)

        if project_name.lower() not in DB_CONFIGS:
            console.print(f"[red]Projeto '{project_name}' não encontrado nas configurações de banco.[/red]")
            return False

        project_path = get_project_backend_path(project_name)
        db_url = get_db_url(project_name)

        if not os.path.exists(project_path):
            console.print(f"[red]Diretório do projeto não encontrado: {project_path}[/red]")
            return False

        if not silent:
            console.print(f"[blue]Projeto:[/blue] {project_name}")
            console.print(f"[blue]Caminho:[/blue] {project_path}")
            console.print(f"[blue]Banco:[/blue] {DB_CONFIGS[project_name.lower()]['host']}:{DB_CONFIGS[project_name.lower()]['port']}")
            console.print("\n[bold yellow]⚠️  Aviso: Reset forçado sem confirmação.[/bold yellow]")

        command = f'supabase db reset --db-url "{db_url}"'
        success = run_supabase_command(command, project_path, auto_confirm=True)

        if success:
            if not silent:
                console.print(f"\n[bold green]✓ Reset (Forçado) concluído com sucesso para {project_name.upper()}![/bold green]")
            return True
        else:
            if not silent:
                console.print(f"\n[bold red]✗ Falha no reset (Forçado) para {project_name.upper()}[/bold red]")
            return False

    except Exception as e:
        if not silent:
            console.print(f"[bold red]Erro inesperado no reset (Forçado): {e}[/bold red]")
        return False

def force_reset_and_signup(project_name: str):
    """Executa um reset forçado do banco de dados e, em seguida, cadastra um novo usuário."""
    console.print(f"[bold yellow]Operação Composta: Reset Forçado e Cadastro de Usuário para {project_name.upper()}[/bold yellow]")
    console.print("="*70)

    # Etapa 1: Reset Forçado
    console.print("\n[cyan]Etapa 1 de 2: Resetando o banco de dados (sem confirmação)...[/cyan]")
    reset_success = supabase_db_reset_force(project_name, silent=True)

    if not reset_success:
        console.print("\n[bold red]✗ A Etapa 1 (Reset do Banco) falhou. A operação foi interrompida.[/bold red]")
        return

    console.print("[bold green]✓ Etapa 1 concluída com sucesso![/bold green]")

    # Etapa 2: Cadastro de Usuário
    console.print("\n[cyan]Etapa 2 de 2: Cadastrando o usuário de teste...[/cyan]")
    
    # Precisamos importar sign_up aqui para evitar dependência circular no topo do arquivo
    from operations.auth import create_user_from_profile
    
    try:
        create_user_from_profile(project_name)
        console.print("[bold green]✓ Etapa 2 concluída com sucesso![/bold green]")
    except Exception as e:
        console.print(f"[bold red]✗ A Etapa 2 (Cadastro de Usuário) falhou: {e}[/bold red]")
        console.print("[yellow]O banco de dados foi resetado, mas o usuário não foi criado.[/yellow]")

    console.print("\n[bold green]Operação composta concluída.[/bold green]")
