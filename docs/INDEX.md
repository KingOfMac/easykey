# EasyKey Documentation Index

Complete documentation for EasyKey - the secure macOS secret management CLI.

## 📖 Documentation Overview

### Quick Start
- **[README.md](../README.md)** - Installation, basic usage, and quick reference
- **[CLI Reference](CLI_REFERENCE.md)** - Complete command-line interface documentation

### Deep Dive
- **[Security Model](SECURITY.md)** - Security architecture, threat model, and best practices
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues, solutions, and debugging

### Examples & Workflows
- **[Usage Examples](examples/WORKFLOWS.md)** - Real-world scenarios and automation scripts

## 🚀 Getting Started

1. **[Installation Guide](../README.md#installation)** - Build and set up EasyKey
2. **[Quick Start](../README.md#quick-start)** - Basic commands and first secrets
3. **[Security Overview](SECURITY.md#security-architecture)** - Understand the security model

## 📚 Reference Documentation

### Command Reference
| Command | Purpose | Documentation |
|---------|---------|---------------|
| `set` | Store secrets | [CLI Reference](CLI_REFERENCE.md#set---store-secret) |
| `get` | Retrieve secrets | [CLI Reference](CLI_REFERENCE.md#get---retrieve-secret) |
| `list` | Show secret names | [CLI Reference](CLI_REFERENCE.md#list---show-secrets) |
| `remove` | Delete secrets | [CLI Reference](CLI_REFERENCE.md#remove---delete-secret) |
| `status` | Vault information | [CLI Reference](CLI_REFERENCE.md#status---vault-information) |

### Options Reference
| Option | Purpose | Documentation |
|--------|---------|---------------|
| `--help` | Show usage | [CLI Reference](CLI_REFERENCE.md#--help) |
| `--version` | Show version | [CLI Reference](CLI_REFERENCE.md#--version) |
| `--verbose` | Debug output | [CLI Reference](CLI_REFERENCE.md#--verbose) |
| `--reason` | Audit logging | [CLI Reference](CLI_REFERENCE.md#--reason-text) |
| `--quiet` | Silent mode | [CLI Reference](CLI_REFERENCE.md#get---retrieve-secret) |
| `--json` | JSON output | [CLI Reference](CLI_REFERENCE.md#list---show-secrets) |

## 🔒 Security Documentation

### Security Features
- **[Authentication](SECURITY.md#authentication-methods)** - Biometric and password auth
- **[Storage](SECURITY.md#data-storage)** - Keychain encryption and access control
- **[Threat Model](SECURITY.md#threat-model)** - What's protected and limitations
- **[Best Practices](SECURITY.md#best-practices)** - Secure usage guidelines

### Compliance
- **[GDPR/Privacy](SECURITY.md#compliance-considerations)** - Data protection compliance
- **[SOX/Financial](SECURITY.md#compliance-considerations)** - Financial audit requirements
- **[PCI DSS](SECURITY.md#compliance-considerations)** - Payment data security

## 🛠 Development & Operations

### Development Workflows
- **[Local Development](examples/WORKFLOWS.md#development-workflows)** - Setting up dev environments
- **[Team Collaboration](examples/WORKFLOWS.md#team-collaboration)** - Sharing secrets securely
- **[Version Management](examples/WORKFLOWS.md#development-workflows)** - Multiple EasyKey versions

### Production Deployment
- **[CI/CD Integration](examples/WORKFLOWS.md#cicd-integration)** - GitHub Actions, Jenkins
- **[Container Deployment](examples/WORKFLOWS.md#docker-integration)** - Docker and Kubernetes
- **[Blue-Green Deployment](examples/WORKFLOWS.md#blue-green-deployment)** - Zero-downtime deployments

### Operations
- **[Backup & Restore](examples/WORKFLOWS.md#backup-and-restore)** - Data protection procedures
- **[Secret Rotation](examples/WORKFLOWS.md#automated-secret-rotation)** - Automated key management
- **[Monitoring](examples/WORKFLOWS.md#health-monitoring)** - Vault health checks

## 🔧 Troubleshooting

### Common Issues
- **[Installation Problems](TROUBLESHOOTING.md#installation-issues)** - Build and setup errors
- **[Authentication Failures](TROUBLESHOOTING.md#authentication-problems)** - Biometric and password issues
- **[Keychain Errors](TROUBLESHOOTING.md#keychain-errors)** - macOS Keychain problems

### Debugging
- **[Debug Techniques](TROUBLESHOOTING.md#debug-techniques)** - Verbose mode and system debugging
- **[Error Reference](TROUBLESHOOTING.md#error-reference)** - Error codes and meanings
- **[Reset Procedures](TROUBLESHOOTING.md#getting-help)** - Clean slate recovery

## 📋 Cheat Sheets

### Essential Commands
```bash
# Basic secret management
easykey set API_KEY "value" --reason "Setup"
easykey get API_KEY --quiet
easykey list --verbose
easykey remove OLD_KEY --reason "Cleanup"
easykey status

# Script integration
export SECRET=$(easykey get SECRET --quiet --reason "Script")
easykey list --json | jq -r '.[].name'

# Development
scripts/build-test.sh 0
scripts/link-test.sh 0
./bin/easykey0 --help
```

### Common Patterns
```bash
# Environment setup
for env in dev staging prod; do
  easykey set "${env}_API_KEY" "value" --reason "Environment setup"
done

# Bulk operations
easykey list | while read secret; do
  easykey get "$secret" --quiet --reason "Backup"
done

# Conditional secret access
if SECRET=$(easykey get API_KEY --quiet 2>/dev/null); then
  export API_KEY="$SECRET"
fi
```

## 🔗 Quick Links

### Documentation Files
- [README.md](../README.md) - Main documentation
- [CLI_REFERENCE.md](CLI_REFERENCE.md) - Complete CLI reference
- [SECURITY.md](SECURITY.md) - Security architecture
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Problem solving
- [WORKFLOWS.md](examples/WORKFLOWS.md) - Usage examples

### Key Sections
- [Installation](../README.md#installation)
- [Security Architecture](SECURITY.md#security-architecture)
- [Error Reference](TROUBLESHOOTING.md#error-reference)
- [Best Practices](SECURITY.md#best-practices)
- [Development Workflows](examples/WORKFLOWS.md#development-workflows)

### External Resources
- [macOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [Local Authentication Framework](https://developer.apple.com/documentation/localauthentication)
- [Secure Enclave](https://support.apple.com/guide/security/secure-enclave-sec59b0b31ff/web)

---

## 📝 Documentation Maintenance

This documentation is organized into focused sections:

- **README.md**: Entry point with installation and basic usage
- **CLI_REFERENCE.md**: Complete command reference and technical details  
- **SECURITY.md**: Security model, threat analysis, and compliance
- **TROUBLESHOOTING.md**: Problem diagnosis and solutions
- **WORKFLOWS.md**: Real-world examples and automation patterns

Each document is self-contained but cross-references related information. Keep documentation updated when adding features or changing behavior.

Last updated: $(date '+%Y-%m-%d')
