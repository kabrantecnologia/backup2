#!/usr/bin/env python3
import os
import sys
sys.path.append(os.path.dirname(__file__))

from core.supabase_client import get_supabase_client, get_config
from core.session_manager import save_session

def login_admin():
    """Login as admin and get token for testing"""
    try:
        # Set environment variable for Supabase URL
        os.environ['SUPABASE_URL'] = 'https://api-dev2-tricket.kabran.com.br'
        
        client = get_supabase_client("tricket")
        
        # Admin credentials from config
        email = "admin@tricket.com.br"
        password = "Senha#993"
        
        print(f"Attempting login for: {email}")
        session_response = client.auth.sign_in_with_password({
            "email": email,
            "password": password,
        })

        if session_response.session:
            print("Login successful!")
            token = session_response.session.access_token
            print(f"Access Token: {token}")
            
            # Save session for future use
            session_data = session_response.session.model_dump(mode='json')
            session_data["user_id"] = session_response.user.id
            session_data["project"] = "tricket"
            save_session(session_data)
            
            return token
        else:
            print("Login failed: invalid credentials or user doesn't exist")
            return None

    except Exception as e:
        print(f"Error during login: {e}")
        return None

if __name__ == "__main__":
    token = login_admin()
    if token:
        print(f"\nToken ready for testing: {token[:20]}...")
        
        # Now test the Cappta webhook manager with this token
        import requests
        
        print("\nTesting Cappta webhook manager...")
        response = requests.post(
            "https://api-dev2-tricket.kabran.com.br/functions/v1/cappta_webhook_manager",
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            },
            json={
                "action": "register",
                "type": "merchantAccreditation"
            }
        )
        
        print(f"Response Status: {response.status_code}")
        print(f"Response Body: {response.text}")
    else:
        print("Could not obtain token")