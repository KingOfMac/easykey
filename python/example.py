#!/usr/bin/env python3
"""
Example usage of the easykey Python package.

This script demonstrates how to use the easykey package to interact
with the macOS keychain through the easykey CLI.
"""

import easykey

def main():
    print("EasyKey Python Package Example")
    print("=" * 40)
    
    # Example secret name
    secret_name = "example_secret"
    
    try:
        # Check vault status
        print("\n1. Checking vault status...")
        status = easykey.status()
        print(f"   Total secrets: {status['secrets']}")
        print(f"   Last access: {status['last_access']}")
        
        # List existing secrets
        print("\n2. Listing existing secrets...")
        secrets = easykey.list_secrets()
        if secrets:
            for secret in secrets:
                print(f"   - {secret['name']}")
        else:
            print("   No secrets found")
        
        # Store a secret
        print(f"\n3. Storing secret '{secret_name}'...")
        easykey.set_secret(
            secret_name, 
            "my-example-secret-value", 
            "Example script demonstration"
        )
        print("   Secret stored successfully!")
        
        # Retrieve the secret
        print(f"\n4. Retrieving secret '{secret_name}'...")
        retrieved_secret = easykey.secret(
            secret_name, 
            "Example script retrieval"
        )
        print(f"   Retrieved: {retrieved_secret}")
        
        # List secrets again to show the new one
        print("\n5. Listing secrets again...")
        secrets = easykey.list_secrets(include_timestamps=True)
        for secret in secrets:
            created = secret.get('createdAt', 'Unknown')
            print(f"   - {secret['name']} (created: {created})")
        
        # Clean up - remove the example secret
        print(f"\n6. Cleaning up - removing '{secret_name}'...")
        easykey.remove_secret(secret_name, "Example script cleanup")
        print("   Secret removed successfully!")
        
        print("\n✅ Example completed successfully!")
        
    except easykey.EasyKeyError as e:
        print(f"\n❌ EasyKey error: {e}")
        return 1
    except KeyboardInterrupt:
        print("\n\n🛑 Interrupted by user")
        return 1
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
