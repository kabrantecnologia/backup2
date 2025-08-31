#!/usr/bin/env python3
"""
Teste de integração para o sistema de rastreamento de erros de produtos
"""

import json
from core.supabase_client import get_supabase_client
from core.session_manager import SessionManager


def test_product_error_tracking():
    """Testa o sistema completo de rastreamento de erros de produtos"""
    
    print("🧪 Iniciando teste do sistema de rastreamento de erros de produtos...")
    
    # Inicializar cliente Supabase
    supabase = get_supabase_client()
    session_manager = SessionManager(supabase)
    
    try:
        # 1. Criar um produto de teste (se não existir)
        print("\n📦 Criando produto de teste...")
        
        # Primeiro, verificar se já existe um produto para teste
        existing_products = supabase.table('marketplace_products').select('*').limit(1).execute()
        
        if existing_products.data:
            test_product_id = existing_products.data[0]['id']
            print(f"✅ Usando produto existente: {test_product_id}")
        else:
            # Criar um produto de teste
            new_product = {
                'name': 'Produto Teste - Sistema de Erros',
                'gtin': '7891234567890',
                'status': 'ACTIVE',
                'description': 'Produto criado para testar sistema de erros'
            }
            
            result = supabase.table('marketplace_products').insert(new_product).execute()
            if result.data:
                test_product_id = result.data[0]['id']
                print(f"✅ Produto de teste criado: {test_product_id}")
            else:
                raise Exception("Falha ao criar produto de teste")
        
        # 2. Testar inativação de produto com erro
        print("\n🚫 Testando inativação de produto com erro...")
        
        error_data = {
            'p_product_id': test_product_id,
            'p_error_type': 'BROKEN_IMAGE',
            'p_error_description': 'Imagem do produto não carrega corretamente',
            'p_error_details': {
                'image_url': 'https://example.com/broken-image.jpg',
                'error_code': 'IMG_404',
                'user_agent': 'Test Agent'
            }
        }
        
        result = supabase.rpc('inactivate_product_with_error', error_data).execute()
        
        if result.data and result.data.get('success'):
            error_id = result.data['error_id']
            print(f"✅ Produto inativado com sucesso. Error ID: {error_id}")
            print(f"   Status anterior: {result.data['previous_status']}")
            print(f"   Status atual: {result.data['new_status']}")
        else:
            raise Exception(f"Falha ao inativar produto: {result.data}")
        
        # 3. Verificar se o produto foi realmente inativado
        print("\n🔍 Verificando status do produto...")
        
        product_check = supabase.table('marketplace_products').select('status').eq('id', test_product_id).execute()
        
        if product_check.data and product_check.data[0]['status'] == 'INACTIVE':
            print("✅ Produto confirmado como INACTIVE")
        else:
            raise Exception("Produto não foi inativado corretamente")
        
        # 4. Testar listagem de produtos com erros
        print("\n📋 Testando listagem de produtos com erros...")
        
        errors_list = supabase.rpc('get_products_with_errors', {
            'p_error_status': 'ACTIVE',
            'p_limit': 10
        }).execute()
        
        if errors_list.data:
            print(f"✅ Encontrados {len(errors_list.data)} produtos com erros ativos")
            for error in errors_list.data[:3]:  # Mostrar apenas os primeiros 3
                print(f"   - {error['product_name']} ({error['error_type']})")
        else:
            print("⚠️  Nenhum produto com erro encontrado")
        
        # 5. Testar consulta da view de relatórios
        print("\n📊 Testando view de relatórios...")
        
        view_result = supabase.table('v_product_errors_summary').select('*').limit(5).execute()
        
        if view_result.data:
            print(f"✅ View retornou {len(view_result.data)} registros")
            for record in view_result.data[:2]:  # Mostrar apenas os primeiros 2
                print(f"   - {record['product_name']}: {record['error_type']} ({record['error_status']})")
        else:
            print("⚠️  View não retornou dados")
        
        # 6. Testar reativação do produto
        print("\n🔄 Testando reativação do produto...")
        
        reactivate_data = {
            'p_product_id': test_product_id,
            'p_error_id': error_id,
            'p_resolution_notes': 'Imagem foi corrigida e testada com sucesso'
        }
        
        reactivate_result = supabase.rpc('reactivate_product_resolve_error', reactivate_data).execute()
        
        if reactivate_result.data and reactivate_result.data.get('success'):
            print("✅ Produto reativado com sucesso")
            print(f"   Erro resolvido em: {reactivate_result.data['resolved_at']}")
        else:
            raise Exception(f"Falha ao reativar produto: {reactivate_result.data}")
        
        # 7. Verificar se o produto foi reativado
        print("\n🔍 Verificando reativação do produto...")
        
        final_check = supabase.table('marketplace_products').select('status').eq('id', test_product_id).execute()
        
        if final_check.data and final_check.data[0]['status'] == 'ACTIVE':
            print("✅ Produto confirmado como ACTIVE novamente")
        else:
            raise Exception("Produto não foi reativado corretamente")
        
        # 8. Verificar se o erro foi marcado como resolvido
        print("\n✅ Verificando resolução do erro...")
        
        error_check = supabase.table('marketplace_product_errors').select('status').eq('id', error_id).execute()
        
        if error_check.data and error_check.data[0]['status'] == 'RESOLVED':
            print("✅ Erro marcado como RESOLVED")
        else:
            raise Exception("Erro não foi marcado como resolvido")
        
        print("\n🎉 Todos os testes passaram com sucesso!")
        print("\n📋 Resumo dos testes realizados:")
        print("   ✅ Criação/verificação de produto de teste")
        print("   ✅ Inativação de produto com registro de erro")
        print("   ✅ Verificação de status do produto inativado")
        print("   ✅ Listagem de produtos com erros")
        print("   ✅ Consulta da view de relatórios")
        print("   ✅ Reativação de produto e resolução de erro")
        print("   ✅ Verificação de status do produto reativado")
        print("   ✅ Verificação de resolução do erro")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Erro durante o teste: {str(e)}")
        return False


def test_error_type_validation():
    """Testa validação de tipos de erro"""
    
    print("\n🔍 Testando validação de tipos de erro...")
    
    supabase = get_supabase_client()
    
    # Tentar usar um tipo de erro inválido
    invalid_error_data = {
        'p_product_id': '00000000-0000-0000-0000-000000000000',  # UUID fictício
        'p_error_type': 'INVALID_TYPE',
        'p_error_description': 'Teste de validação'
    }
    
    result = supabase.rpc('inactivate_product_with_error', invalid_error_data).execute()
    
    if result.data and not result.data.get('success') and 'Invalid error type' in result.data.get('error', ''):
        print("✅ Validação de tipo de erro funcionando corretamente")
        return True
    else:
        print(f"❌ Validação de tipo de erro falhou: {result.data}")
        return False


if __name__ == "__main__":
    print("🚀 Executando testes do sistema de rastreamento de erros de produtos\n")
    
    # Executar testes
    test1_passed = test_product_error_tracking()
    test2_passed = test_error_type_validation()
    
    print(f"\n📊 Resultado final:")
    print(f"   Teste principal: {'✅ PASSOU' if test1_passed else '❌ FALHOU'}")
    print(f"   Teste de validação: {'✅ PASSOU' if test2_passed else '❌ FALHOU'}")
    
    if test1_passed and test2_passed:
        print("\n🎉 Todos os testes passaram! Sistema funcionando corretamente.")
        exit(0)
    else:
        print("\n❌ Alguns testes falharam. Verifique os logs acima.")
        exit(1)
