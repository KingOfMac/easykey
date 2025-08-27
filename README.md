# EasyKey

A secure command-line interface for managing secrets on macOS using the system Keychain with biometric authentication.

## Features

- 🔐 **Secure Storage**: Uses macOS Keychain with device-only access
- 🔒 **Biometric Auth**: Touch ID, Face ID, or password required for each access
- 📱 **Auto-Fallback**: Gracefully handles missing entitlements in development
- 🕒 **Audit Trail**: Tracks access timestamps and reasons
- 🔄 **Version Control**: Multiple concurrent versions for testing
- 📊 **Multiple Formats**: Plain text, JSON output support

## Quick Start

### Prerequisites

- macOS with Xcode or Command Line Tools
- Touch ID, Face ID, or system password configured

### Installation

1. **Clone and build:**
   ```bash
   git clone <repository-url>
   cd easykey
   
   # Set up Xcode toolchain (if using Xcode)
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   
   # Build the CLI
   scripts/build-test.sh 0
   scripts/link-test.sh 0
   ```

2. **Verify installation:**
   ```bash
   ./bin/easykey0 --help
   ```

### Basic Usage

```bash
# Store a secret
./bin/easykey0 set OPENAI_KEY "sk-1234567890abcdef" --reason "Development setup"

# Retrieve a secret
./bin/easykey0 get OPENAI_KEY --reason "Running ML script"

# Use in scripts (quiet mode)
export API_KEY=$(./bin/easykey0 get OPENAI_KEY --quiet)

# List all secrets
./bin/easykey0 list --verbose

# Check vault status
./bin/easykey0 status

# Remove a secret
./bin/easykey0 remove OLD_KEY --reason "Key rotation"
```

## Command Reference

### Global Options

| Flag | Description |
|------|-------------|
| `--help` | Show usage information |
| `--version` | Show CLI version |
| `--verbose` | Enable debug output (no secrets shown) |
| `--reason "text"` | Add audit reason for access logging |

### Commands

#### `set` - Store Secret

```bash
easykey set <SECRET_NAME> <SECRET_VALUE> [--reason "text"]
```

Stores a new secret or updates an existing one. Requires biometric confirmation.

**Examples:**
```bash
easykey set GITHUB_TOKEN "ghp_xxxxxxxxxxxx" --reason "Deploy workflow"
easykey set DATABASE_URL "postgresql://user:pass@host:5432/db"
easykey set STRIPE_SECRET "sk_live_xxxxxxxx" --reason "Payment processing"
```

#### `get` - Retrieve Secret

```bash
easykey get <SECRET_NAME> [--reason "text"] [--quiet]
```

Retrieves a secret. Triggers biometric authentication if required.

**Options:**
- `--quiet`: Suppress debug output (useful for scripts)

**Examples:**
```bash
easykey get OPENAI_KEY --reason "Embedding script"
easykey get DATABASE_URL --quiet

# Use in scripts
export API_KEY=$(easykey get OPENAI_KEY --quiet)
curl -H "Authorization: Bearer $API_KEY" https://api.example.com
```

#### `list` - Show Stored Secrets

```bash
easykey list [--json] [--verbose]
```

Shows secret names only (never values). Requires biometric authentication.

**Options:**
- `--json`: Output in JSON format
- `--verbose`: Include creation timestamps

**Examples:**
```bash
easykey list                    # Simple list
easykey list --verbose          # With timestamps
easykey list --json            # JSON format
easykey list --json --verbose  # JSON with timestamps
```

#### `remove` - Delete Secret

```bash
easykey remove <SECRET_NAME> [--reason "text"]
```

Permanently deletes a secret. Requires biometric confirmation.

**Examples:**
```bash
easykey remove OPENAI_KEY --reason "Key rotated"
easykey remove OLD_API_KEY
```

#### `status` - Vault Information

```bash
easykey status
```

Shows vault statistics and last access time.

**Output:**
```
secrets: 3
last_access: 2025-08-27T11:20:45.616Z
```

## Security

### Authentication

EasyKey uses multiple layers of security:

1. **Biometric Authentication**: Touch ID, Face ID, or system password
2. **Keychain Access Control**: macOS SecAccessControl with user presence
3. **Device-Only Storage**: Secrets never sync to iCloud or other devices
4. **Audit Logging**: Access timestamps and reasons tracked

### Fallback Behavior

When running unsigned binaries (development), EasyKey automatically falls back to basic Keychain storage while maintaining security:

- Still requires system authentication
- Secrets remain device-only
- Graceful degradation without compromising functionality

### Best Practices

- Always use `--reason` for audit trails
- Use `--quiet` in automated scripts
- Regularly rotate secrets with `remove` + `set`
- Monitor access with `status` command

## Development

### Building Test Versions

The project supports concurrent versions for testing:

```bash
# Build numbered versions
scripts/build-test.sh 0      # Creates easykey0
scripts/build-test.sh 01     # Creates easykey01
scripts/build-test.sh 02     # Creates easykey02

# Auto-increment (finds next number)
scripts/build-test.sh        # Creates easykey03, easykey04, etc.

# Link for easy access
scripts/link-test.sh 0       # Creates bin/easykey0
```

### Project Structure

```
easykey/
├── easykey/
│   └── main.swift          # CLI implementation
├── scripts/
│   ├── build-test.sh       # Build versioned binaries
│   └── link-test.sh        # Create symlinks
├── .dist/                  # Built binaries
├── bin/                    # Symlinks for easy access
└── README.md              # This file
```

### Build Script Usage

```bash
# Build specific version
scripts/build-test.sh 05

# Auto-increment from existing versions
scripts/build-test.sh

# Link to bin/ directory
scripts/link-test.sh 05

# Combined build and link
scripts/build-test.sh 05 && scripts/link-test.sh 05
```

## Troubleshooting

### Common Issues

**"Authentication not available"**
- Ensure Touch ID/Face ID is configured in System Preferences
- Check that you can authenticate for other system functions

**"Add failed (-34018)"**
- This is normal for unsigned binaries
- EasyKey automatically falls back to basic Keychain access
- Functionality remains fully intact

**"Secret not found"**
- Use `list` to see available secrets
- Check for typos in secret names
- Ensure you're using the same version that stored the secret

**Build Errors**
- Ensure Xcode Command Line Tools are installed: `xcode-select --install`
- For Xcode users: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

### Debug Mode

Use `--verbose` for detailed output:

```bash
easykey0 set API_KEY "value" --verbose
# Shows: authentication status, fallback modes, operation success
```

## Examples

### Development Workflow

```bash
# Store development secrets
./bin/easykey0 set DEV_DB_URL "postgresql://localhost:5432/myapp_dev"
./bin/easykey0 set OPENAI_KEY "sk-dev-xxxxxxxxxx" --reason "Local development"
./bin/easykey0 set STRIPE_TEST_KEY "sk_test_xxxxxxxx"

# Use in environment setup script
export DEV_DB_URL=$(./bin/easykey0 get DEV_DB_URL --quiet)
export OPENAI_KEY=$(./bin/easykey0 get OPENAI_KEY --quiet --reason "Starting dev server")

# Check what's stored
./bin/easykey0 list --verbose
```

### CI/CD Integration

```bash
# Store deployment keys
./bin/easykey0 set PROD_API_KEY "key" --reason "CI deployment setup"
./bin/easykey0 set AWS_ACCESS_KEY "key" --reason "Infrastructure deployment"

# Use in deployment script
if API_KEY=$(./bin/easykey0 get PROD_API_KEY --quiet --reason "Deployment"); then
  echo "Deploying with API key..."
  deploy --api-key "$API_KEY"
else
  echo "Failed to retrieve API key"
  exit 1
fi
```

### Key Rotation

```bash
# Rotate an API key
./bin/easykey0 remove OLD_OPENAI_KEY --reason "Key rotation"
./bin/easykey0 set OPENAI_KEY "sk-new-xxxxxxxxxx" --reason "Updated API key"

# Verify the change
./bin/easykey0 list --verbose
./bin/easykey0 status
```

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]
