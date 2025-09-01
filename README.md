# 🔐 EasyKey

*A secure replacement for environment variables on macOS*

**EasyKey** is a comprehensive macOS solution that includes a beautiful native app, command-line tool, and Python package for storing your secrets securely in the system keychain with biometric authentication. Say goodbye to `.env` files, hardcoded credentials, and insecure environment variables.

> *This projects codebase was mainly written by Cursor and is intended for personal use. Please evaluate carefully before using it.*

## Why EasyKey?

**Traditional problems with environment variables:**
- ❌ Stored in plain text
- ❌ Accidentally committed to git
- ❌ Visible to other processes
- ❌ No access control
- ❌ Difficult to audit access

**EasyKey advantages:**
- ✅ Encrypted storage in macOS keychain
- ✅ Biometric authentication (Touch ID/Face ID)
- ✅ Beautiful native macOS app
- ✅ Never stored in plain text
- ✅ Audit trail with access reasons
- ✅ Device-local security
- ✅ Simple CLI and Python API

## Installation

### 🎯 Quick Install (Recommended)

Install everything (GUI app, CLI tool, and Python package) with one command:

```bash
git clone https://github.com/kingofmac/easykey.git
cd easykey
./install.sh
```

This will build and install the EasyKey app to your Applications folder.

### 📱 macOS App

The beautiful native EasyKey app provides a modern interface for managing your secrets with:

- **Modern UI**: Clean, intuitive design with smooth animations
- **Touch ID/Face ID**: Secure biometric authentication
- **Search & Filter**: Quickly find your secrets
- **Easy Management**: Add, view, copy, and delete secrets
- **Status Dashboard**: Overview of your vault

#### Install from Source
```bash
git clone https://github.com/kingofmac/easykey.git
cd easykey
./install.sh
```

The app will be installed to `/Applications/EasyKey.app` and can be launched from Spotlight or the Applications folder.

#### Uninstall
```bash
./uninstall.sh
```

*Note: Uninstalling the app does not remove your secrets from the keychain - they remain secure and accessible via the CLI.*

### 🖥️ CLI Tool

#### Build from Source
```bash
git clone https://github.com/kingofmac/easykey.git
cd easykey/cli
swift build -c release
cp .build/release/easykey /usr/local/bin/
```

#### Via Quick Install
The CLI tool is automatically included when using `./install.sh`.

*Homebrew installation coming soon*

### 🐍 Python Package

```bash
pip install easykey
```

*Note: The Python package requires the CLI tool to be installed first.*

## Quick Start

### 📱 Using the macOS App

1. Launch **EasyKey** from Applications or Spotlight
2. Authenticate with Touch ID/Face ID
3. Click **"+ Add"** to store your first secret
4. Search, view, and manage secrets with the intuitive interface

### 🖥️ Using the CLI

#### Store a Secret
```bash
easykey set DATABASE_URL "postgresql://user:pass@localhost/db"
```

#### Retrieve a Secret
```bash
easykey get DATABASE_URL
```

### 🐍 Using Python
```python
import easykey

# Get your database URL securely
db_url = easykey.secret("DATABASE_URL")
```

## CLI Documentation

### Commands

#### `easykey set <name> <value>`
Store a new secret or update an existing one.
```bash
easykey set API_KEY "sk-1234567890abcdef"
easykey set DATABASE_URL "postgresql://user:pass@localhost/db" --reason "Setting up production DB"
```

#### `easykey get <name>`
Retrieve a secret value.
```bash
easykey get API_KEY
easykey get DATABASE_URL --reason "Connecting to production" --quiet
```

#### `easykey list`
List all stored secret names.
```bash
easykey list
easykey list --verbose  # Include creation timestamps
easykey list --json     # Output as JSON
```

#### `easykey status`
Show vault status and statistics.
```bash
easykey status
```

#### `easykey remove <name>`
Delete a secret.
```bash
easykey remove OLD_API_KEY
```

#### `easykey cleanup`
Remove all EasyKey secrets (nuclear option).
```bash
easykey cleanup
```

### Global Flags

- `--verbose` - Show debug information
- `--reason "text"` - Provide reason for audit logging
- `--quiet` - Suppress non-essential output
- `--help` - Show help information
- `--version` - Show version information

### Examples

```bash
# Store multiple secrets
easykey set STRIPE_KEY "sk_live_..."
easykey set JWT_SECRET "super-secret-key"
easykey set DB_PASSWORD "secure-password-123"

# List all secrets
easykey list

# Get a secret for use in a script
export DATABASE_URL=$(easykey get DATABASE_URL --quiet)

# Use with docker
docker run -e API_KEY="$(easykey get API_KEY --quiet)" myapp

# Remove old secrets
easykey remove OLD_STRIPE_KEY
```

## Python Package Documentation

### Installation
```bash
pip install easykey
```

### Basic Usage

```python
import easykey

# Retrieve secrets
api_key = easykey.secret("API_KEY")
db_url = easykey.secret("DATABASE_URL", reason="Connecting to production")

# List all secrets
secrets = easykey.list()
for secret in secrets:
    print(f"Secret: {secret['name']}")

# Get vault status
status = easykey.status()
print(f"Total secrets: {status['secrets']}")
```

### API Reference

#### `easykey.secret(name, reason=None)`
Retrieve a secret value.
- **name** (str): Secret identifier
- **reason** (str, optional): Reason for access (audit logging)
- **Returns**: Secret value as string
- **Raises**: `EasyKeyError` if secret not found or access denied

#### `easykey.list(include_timestamps=False)`
List all secrets.
- **include_timestamps** (bool): Include creation timestamps
- **Returns**: List of dictionaries with secret information
- **Raises**: `EasyKeyError` if listing fails

#### `easykey.status()`
Get vault status.
- **Returns**: Dictionary with vault information (secret count, last access)
- **Raises**: `EasyKeyError` if status check fails


### Exception Handling

```python
import easykey

try:
    secret = easykey.secret("NON_EXISTENT_KEY")
except easykey.EasyKeyError as e:
    print(f"Failed to get secret: {e}")
```

## Security Features

- **🔐 Keychain Integration**: Uses macOS keychain for encrypted storage
- **👆 Biometric Authentication**: Requires Touch ID or Face ID for access
- **🔒 Device-Local**: Secrets never leave your device
- **📝 Audit Trail**: Optional reason logging for all access
- **🚫 No Plain Text**: Secrets are never stored in plain text
- **⏰ Access Tracking**: Monitors last access times
- **🛡️ Fallback Security**: Graceful degradation if biometrics unavailable

## Migration from Environment Variables

### Before (insecure)
```bash
# .env file
DATABASE_URL=postgresql://user:pass@localhost/db
API_KEY=sk-1234567890abcdef
JWT_SECRET=super-secret-key

# Usage
export $(cat .env | xargs)
python app.py
```

### After (secure)
```bash
# Store secrets once
easykey set DATABASE_URL "postgresql://user:pass@localhost/db"
easykey set API_KEY "sk-1234567890abcdef" 
easykey set JWT_SECRET "super-secret-key"

# Use in Python
import easykey
database_url = easykey.secret("DATABASE_URL")

# Or in shell scripts
export DATABASE_URL=$(easykey get DATABASE_URL --quiet)
```

## Development

### Building from Source

The project includes a comprehensive `.gitignore` that excludes:
- Xcode build artifacts and user data
- Python build directories and package metadata  
- macOS system files and IDE configurations
- Environment variables and sensitive files

### Project Structure
```
easykey/
├── app/                 # macOS SwiftUI application
├── cli/                 # Swift command-line tool
├── python/              # Python package
├── install.sh           # One-command installer
├── uninstall.sh         # Clean uninstaller
└── README.md           # This documentation
```

## Compatibility

- **Platform**: macOS 10.12+ (Sierra and later)
- **Architecture**: Apple Silicon 
- **Python**: 3.7+ (for Python package)
- **Swift**: 5.5+ (for building from source)