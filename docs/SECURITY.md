# EasyKey Security Model

Understanding EasyKey's security architecture, threat model, and best practices.

## Table of Contents

- [Security Architecture](#security-architecture)
- [Threat Model](#threat-model)
- [Authentication Methods](#authentication-methods)
- [Data Storage](#data-storage)
- [Fallback Behavior](#fallback-behavior)
- [Best Practices](#best-practices)
- [Security Considerations](#security-considerations)

## Security Architecture

EasyKey implements a multi-layered security model:

```
┌─────────────────────────────────────────────────────────────┐
│                    EasyKey CLI                              │
├─────────────────────────────────────────────────────────────┤
│               Local Authentication                          │
│            (LAContext + SecAccessControl)                   │
├─────────────────────────────────────────────────────────────┤
│                 macOS Keychain                             │
│          (Secure Enclave + Hardware TEE)                   │
├─────────────────────────────────────────────────────────────┤
│                  Hardware Security                         │
│        (T1/T2/M1+ Secure Enclave + Biometrics)            │
└─────────────────────────────────────────────────────────────┘
```

### Layer 1: EasyKey CLI
- **Argument validation** and sanitization
- **Process isolation** from other applications
- **Memory protection** for secret handling
- **Audit logging** with timestamps and reasons

### Layer 2: Local Authentication
- **Biometric authentication** (Touch ID / Face ID)
- **System password** fallback
- **User presence verification** for each access
- **Context-based authentication** sessions

### Layer 3: macOS Keychain
- **Encrypted storage** using AES-256
- **Hardware-backed keys** when available
- **Access control lists** (ACLs)
- **Device-only storage** (no iCloud sync)

### Layer 4: Hardware Security
- **Secure Enclave** for key storage and crypto operations
- **Biometric template protection**
- **Hardware root of trust**
- **Anti-tampering** measures

## Threat Model

### Protected Against

✅ **Local File Access**
- Secrets not stored in plain text files
- No configuration files with embedded secrets
- Protected against file system compromise

✅ **Memory Dumps**
- Secrets cleared from memory after use
- Process memory protection
- No secret persistence in swap files

✅ **Network Interception**
- No network communication
- Secrets never transmitted
- Offline-only operation

✅ **Unauthorized Access**
- Biometric authentication required
- User presence verification
- Per-operation authentication

✅ **Malicious Applications**
- Keychain access control
- System-level permission enforcement
- Isolated secret storage

✅ **Device Theft (Screen Locked)**
- Hardware-backed encryption
- Secure Enclave protection
- Biometric template security

### Not Protected Against

❌ **Physical Access (Unlocked Device)**
- If device is unlocked and user can authenticate
- Mitigation: Use strong system passwords

❌ **Malware with Admin Privileges**
- Root access can potentially bypass protections
- Mitigation: Keep system updated, use anti-malware

❌ **Advanced Persistent Threats**
- Nation-state level attacks with custom exploits
- Mitigation: Defense in depth, monitoring

❌ **Social Engineering**
- User providing authentication when tricked
- Mitigation: User education, audit logging

❌ **Debug/Development Access**
- Debugger attachment to running process
- Mitigation: Production deployment only

## Authentication Methods

### Primary: Biometric Authentication

**Touch ID / Face ID:**
```
User Request → LAContext.evaluatePolicy() → Biometric Scan → 
Secure Enclave Verification → Authentication Context → Keychain Access
```

**Security Properties:**
- Biometric templates stored in Secure Enclave
- Never transmitted or accessible to applications
- False acceptance rate: < 1 in 1,000,000 (Face ID)
- False acceptance rate: < 1 in 50,000 (Touch ID)

### Fallback: System Password

**When Biometrics Unavailable:**
- System administrator password
- Local user account password
- Apple Watch unlock (if configured)

**Security Properties:**
- Password verified by macOS security framework
- Subject to system password policies
- Integrated with enterprise authentication (if configured)

### Development Fallback

**Unsigned Binaries:**
- Basic Keychain access without SecAccessControl
- Still requires system authentication
- Graceful degradation maintains functionality

```bash
# Example debug output showing fallback
[debug] LAContext authentication not available (likely in unsigned CLI), skipping biometric auth
[debug] SecAccessControl failed (likely missing entitlements), falling back to basic keychain
[debug] Entitlement error, retrying with basic keychain access
```

## Data Storage

### Keychain Storage Model

**Service Name:** `easykey`
- All secrets stored under consistent service identifier
- Allows for bulk operations and management
- Namespace isolation from other applications

**Account Names:** User-defined secret names
- Unique identifiers for each secret
- Alphanumeric characters, underscores, hyphens recommended
- Case-sensitive

**Access Control:**
```swift
// Production mode (with entitlements)
kSecAttrAccessibleWhenUnlockedThisDeviceOnly + .userPresence

// Development fallback
kSecAttrAccessibleWhenUnlockedThisDeviceOnly
```

**Metadata Storage:**
- Service: `easykey.meta`
- Last access timestamps
- Audit trail information

### Encryption Details

**At Rest:**
- AES-256 encryption (Keychain default)
- Hardware-backed keys when available
- Secure Enclave storage for encryption keys

**In Memory:**
- Temporary storage during operations
- Cleared immediately after use
- Process memory protection

**In Transit:**
- No network transmission
- Local IPC only (to Keychain daemon)
- Encrypted channels for system communication

## Fallback Behavior

EasyKey implements graceful security degradation:

### Full Security Mode
```
SecAccessControl + LAContext + Keychain
↓
Touch ID/Face ID → Secure Enclave → Encrypted Storage
```

### Development Mode
```
LAContext + Basic Keychain
↓
System Password → Keychain → Encrypted Storage
```

### Minimal Mode
```
Basic Keychain Only
↓
System Authentication → Keychain → Encrypted Storage
```

### Security Comparison

| Mode | Authentication | Storage | Entitlements | Use Case |
|------|---------------|---------|--------------|----------|
| Full | Touch ID/Face ID | Secure Enclave | Required | Production |
| Development | System Password | Hardware AES | Optional | Testing |
| Minimal | System Password | Software AES | None | Debug |

## Best Practices

### Secret Management

1. **Use Strong Secret Names**
   ```bash
   # Good
   easykey set PROD_DATABASE_URL "..."
   easykey set STAGING_API_KEY "..."
   
   # Avoid
   easykey set db "..."
   easykey set key "..."
   ```

2. **Regular Secret Rotation**
   ```bash
   # Rotate secrets periodically
   easykey remove OLD_API_KEY --reason "Monthly rotation"
   easykey set API_KEY "new-value" --reason "Monthly rotation"
   ```

3. **Environment Separation**
   ```bash
   # Separate dev/staging/prod secrets
   easykey set DEV_API_KEY "dev-value"
   easykey set STAGING_API_KEY "staging-value"
   easykey set PROD_API_KEY "prod-value"
   ```

### Operational Security

1. **Always Use Audit Reasons**
   ```bash
   easykey get API_KEY --reason "Deploy to production"
   easykey set NEW_KEY "value" --reason "Service migration"
   ```

2. **Monitor Vault Status**
   ```bash
   # Regular status checks
   easykey status --reason "Security audit"
   
   # Alert on unexpected changes
   COUNT=$(easykey status | grep "secrets:" | cut -d: -f2 | tr -d ' ')
   if [ "$COUNT" -ne "$EXPECTED_COUNT" ]; then
     echo "WARNING: Unexpected secret count change"
   fi
   ```

3. **Secure Script Practices**
   ```bash
   #!/bin/bash
   set -euo pipefail
   
   # Retrieve secret
   SECRET=$(easykey get API_KEY --quiet --reason "Script execution")
   
   # Use secret
   api_call --key "$SECRET"
   
   # Clear from memory
   unset SECRET
   ```

### Development Security

1. **Version Isolation**
   ```bash
   # Use different versions for different environments
   ./bin/easykey-dev set DEV_KEY "value"
   ./bin/easykey-staging set STAGING_KEY "value"
   ./bin/easykey-prod set PROD_KEY "value"
   ```

2. **Test with Fallback Mode**
   ```bash
   # Verify fallback behavior works
   easykey set TEST_KEY "value" --verbose
   # Should show fallback messages in development
   ```

## Security Considerations

### Limitations

1. **Process Memory**
   - Secrets temporarily in process memory
   - Vulnerable to memory dumps during execution
   - Cleared after use, but not guaranteed secure deletion

2. **Command History**
   - Secret values visible in shell history
   - Use input redirection or environment variables
   ```bash
   # Avoid
   easykey set API_KEY "visible-in-history"
   
   # Better
   read -s SECRET && easykey set API_KEY "$SECRET"
   ```

3. **Process Arguments**
   - Command arguments visible in process list
   - Brief exposure during execution
   ```bash
   # Potential exposure
   ps aux | grep easykey
   ```

### Mitigations

1. **Quick Execution**
   - Secrets cleared from memory immediately
   - Minimal exposure window

2. **Audit Trail**
   - All access logged with timestamps
   - Reasons tracked for accountability

3. **System Integration**
   - Leverages macOS security frameworks
   - Hardware-backed protection when available

### Compliance Considerations

**GDPR / Privacy:**
- No personally identifiable information stored
- Local storage only (no cloud sync)
- User control over all data

**SOX / Financial:**
- Audit trail for all secret access
- Immutable timestamps
- Access reason logging

**HIPAA / Healthcare:**
- Encryption at rest and in transit
- Access controls and authentication
- Audit logging capabilities

**PCI DSS:**
- Secure storage of payment credentials
- Access controls and monitoring
- Regular security assessments recommended

## Incident Response

### Suspected Compromise

1. **Immediate Actions**
   ```bash
   # List all stored secrets
   easykey list --json > secret_inventory.json
   
   # Check last access
   easykey status --reason "Security incident response"
   
   # Rotate all secrets (external to EasyKey)
   ```

2. **Investigation**
   - Review system logs for authentication events
   - Check for unauthorized access patterns
   - Correlate with application logs

3. **Recovery**
   ```bash
   # Remove compromised secrets
   easykey remove COMPROMISED_KEY --reason "Security incident"
   
   # Add new secrets
   easykey set NEW_KEY "value" --reason "Post-incident recovery"
   ```

### Prevention

1. **Regular Monitoring**
   - Periodic secret inventory
   - Unexpected access pattern detection
   - System security updates

2. **Access Reviews**
   - Regular audit of stored secrets
   - Removal of unused secrets
   - Team access verification

3. **Security Training**
   - Proper EasyKey usage
   - Social engineering awareness
   - Incident reporting procedures
