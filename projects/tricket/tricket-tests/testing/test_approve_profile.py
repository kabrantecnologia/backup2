#!/usr/bin/env python3
"""
Script para testar a aprovação de um profile específico
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from operations.profile_approval import approve_user_profile

def test_approve_profile():
    """Testa a aprovação de um profile específico"""
    
    project_name = "tricket"
    profile_id = "04e67001-f238-4f7f-aeb0-46e5afc71e6d"
    
    print(f"Aprovando profile ID: {profile_id}")
    
    success = approve_user_profile(project_name, profile_id)
    
    if success:
        print("✅ Profile aprovado com sucesso!")
    else:
        print("❌ Falha ao aprovar profile")

if __name__ == "__main__":
    test_approve_profile()
