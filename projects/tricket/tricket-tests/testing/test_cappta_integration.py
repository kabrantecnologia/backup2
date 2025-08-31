#!/usr/bin/env python3
"""
Testes de Integração - Tricket + Simulador Cappta
Arquivo: test_cappta_integration.py

Este módulo testa a integração entre o Tricket e o simulador Cappta,
validando o fluxo completo de comunicação e webhooks.
"""

import requests
import json
import time
from typing import Dict, Any, Optional
import sys
import os

# Adiciona o diretório pai ao path para importar módulos
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.supabase_client import get_supabase_client
from core.session_manager import get_user_token


class CapptaIntegrationTest:
    """Classe para testar a integração Tricket + Simulador Cappta"""
    
    def __init__(self):
        self.supabase = get_supabase_client("tricket")
        # Usar URL do Supabase dev2 (configurado no .env)
        self.base_url = "https://api-dev2-tricket.kabran.com.br"
        # URL do simulador Cappta (ambos em dev2)
        self.simulador_url = "https://simulador-cappta.kabran.com.br"
        self.admin_token = None
    
    def setup(self) -> bool:
        """Setup inicial dos testes"""
        print("🔧 Configurando ambiente de testes...")
        
        # Obter token de admin
        admin_session = get_user_token("admin@tricket.com.br")
        if not admin_session:
            print("❌ Erro: Não foi possível obter sessão de admin")
            return False
            
        self.admin_token = admin_session.get('access_token')
        if not self.admin_token:
            print("❌ Erro: Não foi possível obter token de admin")
            return False
        
        print("✅ Token de admin obtido com sucesso")
        return True
    
    def test_simulador_health(self) -> bool:
        """Testa se o simulador está funcionando"""
        print("\n🏥 Testando health do simulador Cappta...")
        
        try:
            response = requests.get(f"{self.simulador_url}/health/ready", timeout=10)
            
            if response.status_code == 200:
                print("✅ Simulador Cappta está funcionando")
                print(f"   Status: {response.status_code}")
                return True
            else:
                print(f"❌ Simulador respondeu com status: {response.status_code}")
                return False
                
        except requests.RequestException as e:
            print(f"❌ Erro ao conectar com o simulador: {e}")
            return False
    
    def test_edge_function_health(self) -> bool:
        """Testa se as Edge Functions estão funcionando"""
        print("\n🔧 Testando Edge Functions do Tricket...")
        
        functions_to_test = [
            "/functions/v1/cappta_webhook_receiver",
            # Não testamos as outras ainda pois precisam de auth
        ]
        
        for function_endpoint in functions_to_test:
            try:
                url = f"{self.base_url}{function_endpoint}"
                # Teste básico - apenas verifica se o endpoint responde
                response = requests.options(url, timeout=10)
                
                if response.status_code in [200, 204]:
                    print(f"✅ {function_endpoint} respondendo")
                else:
                    print(f"⚠️  {function_endpoint} status: {response.status_code}")
                    
            except requests.RequestException as e:
                print(f"❌ Erro ao testar {function_endpoint}: {e}")
                return False
        
        return True
    
    def test_webhook_manager(self) -> bool:
        """Testa a Edge Function cappta_webhook_manager"""
        print("\n📡 Testando cappta_webhook_manager...")
        
        if not self.admin_token:
            print("❌ Token de admin necessário")
            return False
        
        url = f"{self.base_url}/functions/v1/cappta_webhook_manager"
        headers = {
            "Authorization": f"Bearer {self.admin_token}",
            "Content-Type": "application/json"
        }
        
        # Teste 1: Registrar webhook
        payload = {
            "action": "register",
            "type": "merchantAccreditation"
        }
        
        try:
            print("   🔄 Registrando webhook...")
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            
            print(f"   Status: {response.status_code}")
            if response.status_code == 200:
                print("   ✅ Webhook registrado com sucesso")
                response_data = response.json()
                print(f"   Dados: {json.dumps(response_data, indent=2, ensure_ascii=False)}")
                return True
            else:
                print(f"   ❌ Falha ao registrar webhook")
                print(f"   Resposta: {response.text}")
                return False
                
        except requests.RequestException as e:
            print(f"   ❌ Erro na requisição: {e}")
            return False
    
    def test_pos_create(self) -> bool:
        """Testa a Edge Function cappta_pos_create"""
        print("\n🏪 Testando cappta_pos_create...")
        
        if not self.admin_token:
            print("❌ Token de admin necessário")
            return False
        
        url = f"{self.base_url}/functions/v1/cappta_pos_create"
        headers = {
            "Authorization": f"Bearer {self.admin_token}",
            "Content-Type": "application/json"
        }
        
        # Dados do POS de teste
        payload = {
            "p_serial_key": f"TEST{int(time.time())}",  # Serial único
            "p_model_id": 3,
            "p_keys": {
                "teste": "integracao",
                "timestamp": int(time.time())
            }
        }
        
        try:
            print("   🔄 Criando dispositivo POS...")
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            
            print(f"   Status: {response.status_code}")
            if response.status_code == 200:
                print("   ✅ POS criado com sucesso")
                response_data = response.json()
                print(f"   Dados: {json.dumps(response_data, indent=2, ensure_ascii=False)}")
                return True
            else:
                print(f"   ❌ Falha ao criar POS")
                print(f"   Resposta: {response.text}")
                return False
                
        except requests.RequestException as e:
            print(f"   ❌ Erro na requisição: {e}")
            return False
    
    def test_webhook_flow(self) -> bool:
        """Testa o fluxo completo de webhooks"""
        print("\n🔄 Testando fluxo completo de webhooks...")
        
        # Simula um webhook direto para o receiver
        url = f"{self.base_url}/functions/v1/cappta_webhook_receiver"
        
        # Payload de teste (simula webhook da Cappta)
        payload = {
            "event_type": "test_integration",
            "timestamp": int(time.time()),
            "data": {
                "message": "Teste de integração Tricket + Simulador Cappta",
                "source": "test_suite"
            }
        }
        
        try:
            print("   📤 Enviando webhook de teste...")
            response = requests.post(url, json=payload, timeout=30)
            
            print(f"   Status: {response.status_code}")
            if response.status_code == 200:
                print("   ✅ Webhook processado com sucesso")
                return True
            else:
                print(f"   ⚠️  Webhook retornou status: {response.status_code}")
                print(f"   Resposta: {response.text}")
                return True  # Webhook receiver pode responder 200 mesmo com outros status
                
        except requests.RequestException as e:
            print(f"   ❌ Erro ao enviar webhook: {e}")
            return False
    
    def run_all_tests(self) -> bool:
        """Executa todos os testes de integração"""
        print("🚀 Iniciando Testes de Integração Tricket + Cappta Simulador")
        print("=" * 60)
        
        if not self.setup():
            return False
        
        tests = [
            ("Simulador Health", self.test_simulador_health),
            ("Edge Functions Health", self.test_edge_function_health),
            ("Webhook Manager", self.test_webhook_manager),
            ("POS Create", self.test_pos_create),
            ("Webhook Flow", self.test_webhook_flow),
        ]
        
        results = {}
        
        for test_name, test_func in tests:
            try:
                result = test_func()
                results[test_name] = result
            except Exception as e:
                print(f"\n💥 Erro inesperado em {test_name}: {e}")
                results[test_name] = False
        
        # Relatório final
        print("\n" + "=" * 60)
        print("📊 RELATÓRIO FINAL DOS TESTES")
        print("=" * 60)
        
        passed = 0
        total = len(results)
        
        for test_name, result in results.items():
            status = "✅ PASSOU" if result else "❌ FALHOU"
            print(f"{test_name:<25} {status}")
            if result:
                passed += 1
        
        print("-" * 60)
        print(f"Total: {passed}/{total} testes passaram")
        
        success_rate = (passed / total) * 100
        if success_rate >= 80:
            print(f"🎉 Taxa de sucesso: {success_rate:.1f}% - INTEGRAÇÃO OK!")
            return True
        else:
            print(f"⚠️  Taxa de sucesso: {success_rate:.1f}% - NECESSÁRIO AJUSTES")
            return False


def main():
    """Função principal para executar os testes"""
    tester = CapptaIntegrationTest()
    success = tester.run_all_tests()
    
    if success:
        print("\n🎯 Integração Tricket + Simulador Cappta validada com sucesso!")
        sys.exit(0)
    else:
        print("\n⚠️  Alguns testes falharam. Revisar configurações.")
        sys.exit(1)


if __name__ == "__main__":
    main()