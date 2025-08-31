#!/usr/bin/env python3
"""
Teste simples para verificar se todos os imports estão funcionando
"""

import sys
import traceback

def test_import(module_name, description):
    """Testa importação de um módulo"""
    try:
        __import__(module_name)
        print(f"✅ {description}: {module_name}")
        return True
    except ImportError as e:
        print(f"❌ {description}: {module_name} - {e}")
        return False
    except Exception as e:
        print(f"🔶 {description}: {module_name} - Erro: {e}")
        traceback.print_exc()
        return False

def main():
    print("=== Teste de Importações - Cappta Fake Simulator ===\n")
    
    success_count = 0
    total_tests = 0
    
    # Testa dependências externas
    external_deps = [
        ("fastapi", "FastAPI Framework"),
        ("uvicorn", "ASGI Server"),
        ("pydantic", "Data Validation"),
        ("pydantic_settings", "Settings Management"),
        ("sqlalchemy", "Database ORM"),
        ("httpx", "HTTP Client"),
        ("psutil", "System Utils")
    ]
    
    print("📦 Dependências Externas:")
    for module, desc in external_deps:
        total_tests += 1
        if test_import(module, desc):
            success_count += 1
    
    print("\n📁 Módulos Internos:")
    # Testa módulos internos
    internal_modules = [
        ("config.settings", "Configurações"),
        ("app.models.common", "Modelos Comuns"),
        ("app.models.merchant", "Modelos de Comerciante"),
        ("app.models.transaction", "Modelos de Transação"),
        ("app.database.models", "Modelos de Banco"),
        ("app.database.connection", "Conexão com Banco"),
        ("app.api.auth", "Autenticação"),
        ("app.api.health", "Health Check"),
        ("app.api.merchants", "API de Comerciantes"),
        ("app.api.transactions", "API de Transações"),
        ("app.services.asaas_client", "Cliente Asaas"),
        ("app.services.transaction_processor", "Processador de Transações")
    ]
    
    for module, desc in internal_modules:
        total_tests += 1
        if test_import(module, desc):
            success_count += 1
    
    print(f"\n=== Resultado: {success_count}/{total_tests} módulos importados com sucesso ===")
    
    if success_count == total_tests:
        print("🎉 Todos os imports estão funcionando!")
        return True
    else:
        print(f"⚠️  {total_tests - success_count} módulos com problemas")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)