#!/usr/bin/env python3
"""
Example usage of the easykey Python package.

This script demonstrates how to use the easykey package to interact
with the macOS keychain through the easykey CLI.

Note: The Python package is read-only. To store or remove secrets,
use the easykey CLI directly:
  easykey set SECRET_NAME "secret_value"
  easykey remove SECRET_NAME
"""

import easykey
import subprocess

def run_cli_command(args):
    """Helper to run easykey CLI commands."""
    try:
        result = subprocess.run(['easykey'] + args, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        raise easykey.EasyKeyError(f"CLI command failed: {e.stderr.strip()}")
    except FileNotFoundError:
        raise easykey.EasyKeyError("easykey CLI not found. Please install the easykey CLI first.")

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
        print(f"   Last access: {status.get('last_access', 'Never')}")
        
        # List existing secrets
        print("\n2. Listing existing secrets...")
        secrets = easykey.list()
        if secrets:
            for secret in secrets:
                print(f"   - {secret['name']}")
        else:
            print("   No secrets found")
        
        # Store a secret using CLI (Python package is read-only)
        print(f"\n3. Storing secret '{secret_name}' using CLI...")
        print("   Note: Using CLI directly since Python package is read-only")
        try:
            run_cli_command(['set', secret_name, 'my-example-secret-value', '--reason', 'Example script demonstration'])
            print("   Secret stored successfully!")
        except easykey.EasyKeyError as e:
            print(f"   Failed to store secret: {e}")
            print("   Continuing with example assuming secret exists...")
        
        # Retrieve the secret using Python package
        print(f"\n4. Retrieving secret '{secret_name}' using Python...")
        try:
            retrieved_secret = easykey.secret(
                secret_name, 
                "Example script retrieval"
            )
            print(f"   Retrieved: {retrieved_secret}")
        except easykey.EasyKeyError as e:
            print(f"   Could not retrieve secret: {e}")
            print("   Make sure the secret exists by running: easykey set example_secret 'test-value'")
        
        # List secrets again with timestamps
        print("\n5. Listing secrets with timestamps...")
        secrets = easykey.list(include_timestamps=True)
        for secret in secrets:
            created = secret.get('createdAt', 'Unknown')
            print(f"   - {secret['name']} (created: {created})")
        
        # Clean up - remove the example secret using CLI
        print(f"\n6. Cleaning up - removing '{secret_name}' using CLI...")
        try:
            run_cli_command(['remove', secret_name, '--reason', 'Example script cleanup'])
            print("   Secret removed successfully!")
        except easykey.EasyKeyError as e:
            print(f"   Note: Could not remove secret (might not exist): {e}")
        
        print("\n✅ Example completed successfully!")
        print("\n💡 Tips:")
        print("   - Use the easykey CLI for storing/removing secrets")
        print("   - Use the Python package for reading secrets in your applications")
        print("   - All operations require biometric authentication")
        
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
