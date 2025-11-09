#!/usr/bin/env python3
"""
Paystack Test Mode Diagnostic Tool
Tests your Paystack configuration and shows exactly what's wrong
"""

import os
import sys
import requests
import json
from dotenv import load_dotenv

load_dotenv()

def print_section(title):
    print("\n" + "="*60)
    print(f"  {title}")
    print("="*60)

def test_paystack_key():
    """Test Paystack API key with detailed diagnostics"""
    
    print_section("PAYSTACK TEST MODE DIAGNOSTIC")
    
    # Get configuration
    secret_key = os.getenv('PAYSTACK_SECRET_KEY', '')
    public_key = os.getenv('PAYSTACK_PUBLIC_KEY', '')
    is_test = os.getenv('PAYSTACK_IS_TEST', 'True')
    
    print(f"\n1. Configuration Check:")
    print(f"   PAYSTACK_IS_TEST: {is_test}")
    print(f"   Secret Key: {secret_key[:15]}{'*' * 20} (length: {len(secret_key)})")
    print(f"   Public Key: {public_key[:15]}{'*' * 20} (length: {len(public_key)})")
    
    # Check for common issues
    issues_found = []
    
    # Issue 1: Empty or placeholder key
    if not secret_key or 'YOUR_KEY' in secret_key:
        issues_found.append("❌ Secret key is empty or placeholder")
        print("\n❌ PROBLEM: API key not configured properly")
        print("\n   FIX: Go to https://dashboard.paystack.com/#/settings/developers")
        print("        1. Make sure you're in TEST MODE (toggle at top right)")
        print("        2. Copy 'Test Secret Key' (starts with sk_test_)")
        print("        3. Update your .env file:")
        print(f"           PAYSTACK_SECRET_KEY=sk_test_YOUR_ACTUAL_KEY")
        return False
    
    # Issue 2: Wrong key type
    if not secret_key.startswith('sk_test_') and not secret_key.startswith('sk_live_'):
        issues_found.append("❌ Invalid key format")
        print("\n❌ PROBLEM: Key doesn't start with 'sk_test_' or 'sk_live_'")
        print(f"   Your key starts with: {secret_key[:10]}")
        print("\n   FIX: Make sure you copied the SECRET key, not the PUBLIC key")
        return False
    
    # Issue 3: Using live key in test mode
    if secret_key.startswith('sk_live_') and is_test.lower() == 'true':
        issues_found.append("⚠️  Using LIVE key in TEST mode")
        print("\n⚠️  WARNING: You're using a LIVE key but PAYSTACK_IS_TEST=True")
        print("\n   FIX: Either:")
        print("        Option A: Use test key (recommended for development)")
        print("                  Get from: https://dashboard.paystack.com/#/settings/developers")
        print("                  PAYSTACK_SECRET_KEY=sk_test_...")
        print("        Option B: Set PAYSTACK_IS_TEST=False to use live mode")
    
    # Issue 4: Using test key in live mode
    if secret_key.startswith('sk_test_') and is_test.lower() == 'false':
        issues_found.append("⚠️  Using TEST key in LIVE mode")
        print("\n⚠️  WARNING: You're using a TEST key but PAYSTACK_IS_TEST=False")
        print("\n   FIX: Set PAYSTACK_IS_TEST=True")
    
    # Issue 5: Whitespace in key
    if secret_key != secret_key.strip():
        issues_found.append("❌ Whitespace in API key")
        print("\n❌ PROBLEM: Your API key has leading/trailing whitespace")
        print("\n   FIX: Remove spaces from your .env file")
        secret_key = secret_key.strip()
    
    print("\n✅ Key format looks correct" if not issues_found else "")
    
    # Test API connection
    print(f"\n2. Testing API Connection:")
    print("   Making request to Paystack API...")
    
    try:
        # Test with a simple endpoint
        response = requests.get(
            'https://api.paystack.co/bank',
            headers={
                'Authorization': f'Bearer {secret_key}',
                'Content-Type': 'application/json',
            },
            timeout=10
        )
        
        print(f"   Response Status: {response.status_code}")
        
        if response.status_code == 200:
            print("\n✅ SUCCESS! Your Paystack test mode is working correctly!")
            data = response.json()
            print(f"\n   API Response: {data.get('message', 'OK')}")
            if data.get('data'):
                print(f"   Found {len(data['data'])} banks available")
            return True
            
        elif response.status_code == 401:
            print("\n❌ PROBLEM: Authentication failed (401 Unauthorized)")
            print("\n   This means your API key is INVALID or EXPIRED")
            print("\n   FIX:")
            print("   1. Go to: https://dashboard.paystack.com/#/settings/developers")
            print("   2. Toggle to TEST MODE (top right corner)")
            print("   3. Click 'Reveal' on the Test Secret Key")
            print("   4. Copy the ENTIRE key (sk_test_...)")
            print("   5. Update your .env file:")
            print("      PAYSTACK_SECRET_KEY=sk_test_YOUR_COPIED_KEY")
            print("   6. Restart your Flask application")
            
            # Try to get more info from response
            try:
                error_data = response.json()
                print(f"\n   Paystack Error: {error_data.get('message', 'Unknown')}")
            except:
                pass
            
            return False
            
        elif response.status_code == 400:
            print("\n❌ PROBLEM: Bad Request (400)")
            try:
                error_data = response.json()
                error_msg = error_data.get('message', '')
                print(f"   Error: {error_msg}")
                
                if 'inactive' in error_msg.lower():
                    print("\n   This error in TEST MODE usually means:")
                    print("   1. You're using the wrong API key")
                    print("   2. Your API key is from a LIVE account that's not activated")
                    print("\n   FIX: Get your TEST key:")
                    print("   https://dashboard.paystack.com/#/settings/developers")
                    print("   (Make sure TEST MODE toggle is ON)")
                    
            except:
                print(f"   Response: {response.text}")
            
            return False
            
        else:
            print(f"\n❌ Unexpected response: {response.status_code}")
            print(f"   Response: {response.text[:200]}")
            return False
            
    except requests.exceptions.Timeout:
        print("\n❌ PROBLEM: Connection timeout")
        print("   Check your internet connection")
        return False
        
    except requests.exceptions.ConnectionError:
        print("\n❌ PROBLEM: Cannot connect to Paystack API")
        print("   Check your internet connection")
        return False
        
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        return False

def test_transaction_initialization():
    """Test actual transaction initialization"""
    
    print_section("TESTING TRANSACTION INITIALIZATION")
    
    secret_key = os.getenv('PAYSTACK_SECRET_KEY', '').strip()
    
    if not secret_key or 'YOUR_KEY' in secret_key:
        print("⚠️  Skipping transaction test - configure API key first")
        return False
    
    print("\nTrying to initialize a test transaction...")
    
    try:
        response = requests.post(
            'https://api.paystack.co/transaction/initialize',
            headers={
                'Authorization': f'Bearer {secret_key}',
                'Content-Type': 'application/json',
            },
            json={
                'email': 'test@example.com',
                'amount': 100000,  # 1000 KES in kobo
                'currency': 'KES',
            },
            timeout=10
        )
        
        print(f"Response Status: {response.status_code}")
        
        if response.status_code == 200:
            print("\n✅ SUCCESS! Transaction initialization works!")
            data = response.json()
            if data.get('status'):
                print(f"   Authorization URL: {data['data']['authorization_url'][:50]}...")
                print(f"   Reference: {data['data']['reference']}")
            return True
        else:
            print(f"\n❌ Failed: {response.status_code}")
            try:
                error_data = response.json()
                print(f"   Error: {error_data.get('message', 'Unknown error')}")
                
                if 'inactive' in str(error_data).lower():
                    print("\n   🔥 ROOT CAUSE FOUND!")
                    print("   Your Paystack account is INACTIVE even in test mode.")
                    print("\n   SOLUTIONS:")
                    print("   1. Create a NEW Paystack account (fresh test account)")
                    print("   2. Use IntaSend instead for Kenya (M-Pesa)")
                    print("   3. Contact Paystack support: support@paystack.com")
                    
            except:
                print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        return False

def show_env_file_example():
    """Show example .env configuration"""
    
    print_section("EXAMPLE .ENV CONFIGURATION")
    
    print("""
# Copy this into your .env file with your actual keys

# Paystack Test Mode (for development)
PAYSTACK_SECRET_KEY=sk_test_1234567890abcdefghijklmnopqrstuvwxyz
PAYSTACK_PUBLIC_KEY=pk_test_1234567890abcdefghijklmnopqrstuvwxyz
PAYSTACK_IS_TEST=True

# Get your keys from:
# https://dashboard.paystack.com/#/settings/developers
# (Make sure TEST MODE is toggled ON)

# For M-Pesa payments (Kenya only)
INTASEND_PUBLISHABLE_KEY=ISPubKey_test_your_key_here
INTASEND_SECRET_KEY=ISSecretKey_test_your_key_here
INTASEND_IS_TEST=True

# Get IntaSend keys from:
# https://sandbox.intasend.com/
    """)

def main():
    print("""
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          PAYSTACK TEST MODE DIAGNOSTIC TOOL                  ║
║          Troubleshooting "Merchant Inactive" Error           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    """)
    
    # Run tests
    basic_test_passed = test_paystack_key()
    
    if basic_test_passed:
        print("\n✅ Basic authentication works!")
        transaction_test_passed = test_transaction_initialization()
        
        if transaction_test_passed:
            print("\n" + "="*60)
            print("  🎉 ALL TESTS PASSED!")
            print("="*60)
            print("\nYour Paystack test mode is configured correctly.")
            print("The error in your application might be coming from:")
            print("  1. Cached environment variables (restart your app)")
            print("  2. Different .env file location")
            print("  3. Code not reading the .env file properly")
        else:
            print("\n" + "="*60)
            print("  ⚠️  TRANSACTION TEST FAILED")
            print("="*60)
            print("\nBasic auth works but transaction init fails.")
            print("This is the EXACT error your app is getting.")
    else:
        print("\n" + "="*60)
        print("  ❌ CONFIGURATION ISSUES FOUND")
        print("="*60)
        print("\nFix the issues above and run this script again.")
    
    show_env_file_example()
    
    print("\n" + "="*60)
    print("  NEXT STEPS")
    print("="*60)
    print("""
1. Fix your .env file with correct test keys
2. Restart your Flask application
3. Run this script again to verify
4. If still failing, try creating a NEW Paystack test account

Need help? Contact Paystack support: support@paystack.com
    """)

if __name__ == '__main__':
    main()