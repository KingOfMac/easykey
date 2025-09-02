# EasyKey Node.js Package

A simple Node.js wrapper for the [easykey](https://github.com/kingofmac/easykey) CLI that provides secure keychain access on macOS.

## Installation

### Prerequisites

1. First, ensure you have the `easykey` CLI installed and available in your PATH
2. Install this Node.js package:

```bash
npm install @kingofmac/easykey
```

### Local Development Installation

If you're working with the source code:

```bash
cd nodejs
npm install
npm link
```

## Usage

### Basic Secret Retrieval

```javascript
const easykey = require('@kingofmac/easykey');

// Get a secret (this will trigger biometric authentication)
const secret = easykey.secret('MySecretName');
console.log(secret);

// Get a secret with a reason for audit logging
const secret = easykey.secret('MySecretName', 'Connecting to production database');
```

### ES6 Import Syntax

```javascript
import { secret, list, status } from '@kingofmac/easykey';

// Get a secret
const mySecret = secret('MySecretName');
```

### TypeScript Support

```typescript
import { secret, list, status, SecretInfo, VaultStatus, EasyKeyError } from '@kingofmac/easykey';

// Get a secret with full type safety
try {
    const secretValue: string = secret('MySecretName', 'API access');
    console.log(secretValue);
} catch (error) {
    if (error instanceof EasyKeyError) {
        console.error('EasyKey operation failed:', error.message);
    }
}
```

### Listing and Status

```javascript
const easykey = require('@kingofmac/easykey');

// List all secret names
const secrets = easykey.list();
for (const secret of secrets) {
    console.log(`Secret: ${secret.name}`);
}

// List secrets with creation timestamps
const secretsWithTimestamps = easykey.list(true);
for (const secret of secretsWithTimestamps) {
    console.log(`Secret: ${secret.name}, Created: ${secret.createdAt || 'Unknown'}`);
}

// Get vault status
const status = easykey.status();
console.log(`Total secrets: ${status.secrets}`);
console.log(`Last access: ${status.last_access}`);
```

## API Reference

### Functions

- **`secret(name, reason?)`** - Retrieve a secret value
- **`getSecret(name, reason?)`** - Alias for `secret()`
- **`list(includeTimestamps?)`** - List all secrets
- **`status()`** - Get vault status information

### Parameters

- **`name`** (string): The name/identifier of the secret
- **`reason`** (string, optional): Reason for the operation (for audit logging)
- **`includeTimestamps`** (boolean, optional): Whether to include creation timestamps in list results

### Return Values

- **`secret()`** returns the secret value as a string
- **`list()`** returns an array of objects with secret information
- **`status()`** returns an object with vault status

### Exceptions

All functions may throw **`EasyKeyError`** if the underlying CLI operation fails.

## TypeScript Support

This package includes comprehensive TypeScript definitions:

```typescript
interface SecretInfo {
    name: string;
    createdAt?: string;
    [key: string]: any;
}

interface VaultStatus {
    secrets: number;
    last_access: string | null;
    [key: string]: any;
}
```

## Security Notes

- This package is a thin wrapper around the easykey CLI
- All security features (biometric authentication, keychain integration) are handled by the CLI
- Secrets are retrieved through child processes and are not cached in Node.js
- The package automatically locates the easykey binary in common installation paths

## Requirements

- macOS (required by the underlying easykey CLI)
- Node.js 12.0.0+
- easykey CLI installed and accessible

## Quick Start Example

```javascript
const easykey = require('@kingofmac/easykey');

async function example() {
    try {
        // Check vault status
        const vaultStatus = easykey.status();
        console.log(`Vault contains ${vaultStatus.secrets} secrets`);

        // List all secrets
        const secrets = easykey.list();
        for (const secret of secrets) {
            console.log(`Found secret: ${secret.name}`);
        }

        // Retrieve a specific secret (requires biometric authentication)
        const secretValue = easykey.secret('MySecretName', 'Accessing for API call');
        console.log(`Secret value: ${secretValue}`);
    } catch (error) {
        if (error instanceof easykey.EasyKeyError) {
            console.error('EasyKey error:', error.message);
        } else {
            console.error('Unexpected error:', error);
        }
    }
}

example();
```

**Note:** This is a **read-only** package. To store or manage secrets, use the easykey CLI directly:

```bash
easykey set SECRET_NAME "secret_value"
easykey remove SECRET_NAME
```

## License

MIT License - see the main easykey project for details.
