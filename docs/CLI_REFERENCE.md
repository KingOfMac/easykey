# EasyKey CLI Reference

Complete command-line interface reference for EasyKey secret management.

## Table of Contents

- [Installation](#installation)
- [Global Options](#global-options)
- [Commands](#commands)
- [Exit Codes](#exit-codes)
- [Output Formats](#output-formats)
- [Environment Variables](#environment-variables)

## Installation

### Prerequisites

- macOS 10.15+ (Catalina or later)
- Xcode or Command Line Tools
- Touch ID, Face ID, or system password configured

### Build from Source

```bash
# Clone repository
git clone <repository-url>
cd easykey

# Configure toolchain (choose one)
# For Xcode users:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# For Command Line Tools only:
sudo xcode-select -s /Library/Developer/CommandLineTools

# Build and install
scripts/build-test.sh stable
scripts/link-test.sh stable

# Verify installation
./bin/easkeystable --version
```

## Global Options

These options can be used with any command:

### `--help`
**Usage:** `easykey --help` or `easykey <command> --help`

Shows usage information and exits.

```bash
easykey --help           # General help
easykey set --help       # Command-specific help (shows general help)
```

### `--version`
**Usage:** `easykey --version`

Shows the CLI version and exits.

```bash
easykey --version
# Output: 0.1.0
```

### `--verbose`
**Usage:** `easykey --verbose <command> [args]`

Enables debug output. Secrets are never shown in debug output.

```bash
easykey --verbose set API_KEY "value"
# Shows authentication status, fallback modes, operation details
```

**Debug Output Examples:**
```
[debug] set name=API_KEY reason=Authenticate to access easykey vault
[debug] Authentication context: available
[debug] Access control: available
[debug] Entitlement error, retrying with basic keychain access
[debug] set: success
```

### `--reason "text"`
**Usage:** `easykey --reason "audit message" <command> [args]`

Adds an audit reason for access logging. Highly recommended for compliance and debugging.

```bash
easykey --reason "Deploy to production" get API_KEY
easykey --reason "Key rotation" remove OLD_KEY
```

**Default Reason:** `"Authenticate to access easykey vault"`

## Commands

### `set` - Store Secret

**Syntax:** `easykey set <SECRET_NAME> <SECRET_VALUE> [options]`

Stores a new secret or updates an existing one. Requires biometric authentication.

**Parameters:**
- `SECRET_NAME`: Unique identifier for the secret (alphanumeric, underscores, hyphens)
- `SECRET_VALUE`: The secret data to store (any string)

**Options:**
- Global options (`--verbose`, `--reason`)

**Examples:**
```bash
# Basic usage
easykey set GITHUB_TOKEN "ghp_xxxxxxxxxxxx"

# With audit reason
easykey set DATABASE_URL "postgresql://user:pass@host:5432/db" --reason "Development setup"

# Update existing secret
easykey set API_KEY "new-value" --reason "Key rotation"

# Verbose mode
easykey set SECRET_KEY "value" --verbose --reason "Testing"
```

**Behavior:**
- Creates new secret if name doesn't exist
- Updates existing secret if name already exists
- Requires biometric authentication
- Updates last access timestamp

**Error Cases:**
- Authentication failure
- Invalid secret name characters
- Keychain access denied

### `get` - Retrieve Secret

**Syntax:** `easykey get <SECRET_NAME> [options]`

Retrieves and outputs a secret. Requires biometric authentication.

**Parameters:**
- `SECRET_NAME`: Name of the secret to retrieve

**Options:**
- `--quiet`: Suppress debug output (recommended for scripts)
- Global options (`--verbose`, `--reason`)

**Examples:**
```bash
# Basic retrieval
easykey get GITHUB_TOKEN

# Quiet mode for scripts
API_KEY=$(easykey get API_KEY --quiet)

# With audit reason
easykey get DATABASE_URL --reason "Starting application"

# Debug mode
easykey get SECRET --verbose --reason "Troubleshooting"
```

**Output:**
- Secret value followed by newline
- Debug information to stderr (if `--verbose` and not `--quiet`)

**Script Usage:**
```bash
# Export to environment
export API_KEY=$(easykey get API_KEY --quiet)

# Conditional usage
if SECRET=$(easykey get SECRET_NAME --quiet); then
  echo "Retrieved: $SECRET"
else
  echo "Failed to retrieve secret"
  exit 1
fi

# Direct usage in commands
curl -H "Authorization: Bearer $(easykey get API_TOKEN --quiet)" https://api.example.com
```

**Error Cases:**
- Secret not found
- Authentication failure
- Keychain access denied

### `list` - Show Secrets

**Syntax:** `easykey list [options]`

Lists all stored secret names (never shows values). Requires biometric authentication.

**Options:**
- `--json`: Output in JSON format
- `--verbose`: Include creation timestamps
- Global options (`--verbose`, `--reason`)

**Output Formats:**

**Default (names only):**
```
GITHUB_TOKEN
DATABASE_URL
API_KEY
```

**Verbose (with timestamps):**
```
GITHUB_TOKEN    2025-08-27T10:15:30.123Z
DATABASE_URL    2025-08-27T10:16:45.456Z
API_KEY         2025-08-27T10:17:12.789Z
```

**JSON format:**
```json
[
  {
    "name": "GITHUB_TOKEN",
    "createdAt": "2025-08-27T10:15:30.123Z"
  },
  {
    "name": "DATABASE_URL",
    "createdAt": "2025-08-27T10:16:45.456Z"
  }
]
```

**JSON without timestamps:**
```json
[
  {
    "name": "GITHUB_TOKEN",
    "createdAt": null
  }
]
```

**Examples:**
```bash
# Simple list
easykey list

# With creation times
easykey list --verbose

# JSON output
easykey list --json

# JSON with timestamps
easykey list --json --verbose

# Parse JSON in scripts
easykey list --json | jq -r '.[].name'
```

**Error Cases:**
- Authentication failure
- Keychain access denied
- No secrets stored (returns empty output, exit code 0)

### `remove` - Delete Secret

**Syntax:** `easykey remove <SECRET_NAME> [options]`

Permanently deletes a secret. Requires biometric authentication.

**Parameters:**
- `SECRET_NAME`: Name of the secret to delete

**Options:**
- Global options (`--verbose`, `--reason`)

**Examples:**
```bash
# Basic removal
easykey remove OLD_API_KEY

# With audit reason
easykey remove GITHUB_TOKEN --reason "Key rotation"

# Verbose mode
easykey remove SECRET --verbose --reason "Cleanup"
```

**Behavior:**
- Permanently deletes the secret
- No confirmation prompt
- Updates last access timestamp
- Succeeds silently if secret doesn't exist

**Error Cases:**
- Authentication failure
- Keychain access denied

### `status` - Vault Information

**Syntax:** `easykey status [options]`

Shows vault statistics and metadata. Requires biometric authentication.

**Options:**
- Global options (`--verbose`, `--reason`)

**Output Format:**
```
secrets: 3
last_access: 2025-08-27T11:20:45.616Z
```

**Fields:**
- `secrets`: Number of stored secrets
- `last_access`: ISO8601 timestamp of last vault access, or "-" if never accessed

**Examples:**
```bash
# Basic status
easykey status

# With debug output
easykey status --verbose

# With audit reason
easykey status --reason "Security audit"
```

**Script Usage:**
```bash
# Parse status output
COUNT=$(easykey status | grep "secrets:" | cut -d: -f2 | tr -d ' ')
echo "Found $COUNT secrets"

# Check if vault has secrets
if easykey status | grep -q "secrets: 0"; then
  echo "Vault is empty"
fi
```

**Error Cases:**
- Authentication failure
- Keychain access denied

## Exit Codes

EasyKey uses standard exit codes:

| Code | Meaning | Description |
|------|---------|-------------|
| 0 | Success | Operation completed successfully |
| 1 | Error | General error (authentication, keychain, not found) |
| 2 | Usage Error | Invalid arguments or command syntax |

**Examples:**
```bash
# Check for success
if easykey get API_KEY --quiet >/dev/null; then
  echo "Secret exists"
fi

# Handle different error types
easykey get NONEXISTENT --quiet
case $? in
  0) echo "Success" ;;
  1) echo "Secret not found or authentication failed" ;;
  2) echo "Invalid command usage" ;;
esac
```

## Output Formats

### Standard Output (stdout)

**Secret Values:**
- `get` command outputs secret value + newline
- Always UTF-8 encoded
- No additional formatting

**Lists and Status:**
- Plain text format by default
- JSON format with `--json` flag
- Tab-separated for timestamps

### Error Output (stderr)

**Debug Information:**
- Enabled with `--verbose`
- Prefixed with `[debug]`
- Never contains secret values

**Error Messages:**
- Always to stderr
- Prefixed with `error:`
- Human-readable descriptions

### JSON Schema

**List Command JSON:**
```json
{
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "name": {
        "type": "string",
        "description": "Secret name"
      },
      "createdAt": {
        "type": ["string", "null"],
        "format": "date-time",
        "description": "ISO8601 creation timestamp or null"
      }
    },
    "required": ["name", "createdAt"]
  }
}
```

## Environment Variables

EasyKey doesn't use environment variables for configuration, but it's commonly used to set them:

### Setting Environment Variables

```bash
# Export for current session
export API_KEY=$(easykey get API_KEY --quiet)

# Export multiple secrets
eval $(easykey list --json | jq -r '.[] | "export " + .name + "=$(easykey get " + .name + " --quiet)"')

# Conditional export
if API_KEY=$(easykey get API_KEY --quiet); then
  export API_KEY
  echo "API_KEY exported"
fi
```

### Script Integration

```bash
#!/bin/bash
set -e

# Load secrets into environment
export DATABASE_URL=$(easykey get DATABASE_URL --quiet --reason "Application startup")
export API_KEY=$(easykey get API_KEY --quiet --reason "Application startup")

# Run application with secrets
./my-app
```

### Docker Integration

```bash
# Pass secrets to Docker
docker run \
  -e API_KEY="$(easykey get API_KEY --quiet)" \
  -e DB_URL="$(easykey get DATABASE_URL --quiet)" \
  my-app:latest
```

## Best Practices

### Command Usage

1. **Always use `--reason`** for audit trails
2. **Use `--quiet` in scripts** to avoid debug output
3. **Check exit codes** in automated scripts
4. **Use JSON format** for structured data parsing

### Security

1. **Never log secret values** (EasyKey doesn't, but your scripts might)
2. **Use environment variables** for temporary secret access
3. **Regularly rotate secrets** with `remove` + `set`
4. **Monitor vault status** for unexpected changes

### Automation

```bash
# Good script pattern
#!/bin/bash
set -euo pipefail

# Retrieve secrets with error handling
if ! API_KEY=$(easykey get API_KEY --quiet --reason "Deployment script"); then
  echo "Failed to retrieve API key" >&2
  exit 1
fi

# Use secret
deploy_app --api-key "$API_KEY"

# Clear from memory
unset API_KEY
```
