# EasyKey Troubleshooting Guide

Common issues, solutions, and debugging techniques for EasyKey.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Authentication Problems](#authentication-problems)
- [Keychain Errors](#keychain-errors)
- [Performance Issues](#performance-issues)
- [Debug Techniques](#debug-techniques)
- [Error Reference](#error-reference)

## Installation Issues

### Build Failures

**Problem:** Build fails with "command not found: swiftc"
```
./scripts/build-test.sh: line 45: swiftc: command not found
```

**Solution:**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Or set proper developer directory
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

**Verification:**
```bash
which swiftc
swiftc --version
```

---

**Problem:** Build fails with module import errors
```
error: no such module 'Foundation'
error: no such module 'Security'
```

**Solution:**
```bash
# Check SDK availability
xcrun --sdk macosx --show-sdk-path

# Rebuild with explicit SDK
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
scripts/build-test.sh 0
```

---

**Problem:** Permission denied when running build script
```
./scripts/build-test.sh: Permission denied
```

**Solution:**
```bash
chmod +x scripts/build-test.sh
chmod +x scripts/link-test.sh
```

### Version Management Issues

**Problem:** Binary not found after build
```
./bin/easykey0: No such file or directory
```

**Solution:**
```bash
# Check if binary was built
ls -la .dist/

# Re-link binary
scripts/link-test.sh 0

# Verify symlink
ls -la bin/
```

---

**Problem:** Multiple versions conflicting
```bash
# Clean up old versions
rm -rf .dist/easykey*
rm -rf bin/easykey*

# Rebuild specific version
scripts/build-test.sh 0
scripts/link-test.sh 0
```

## Authentication Problems

### Biometric Authentication Failures

**Problem:** "Authentication not available" error
```
error: Authentication not available: Biometry is not available on this device.
```

**Diagnosis:**
```bash
# Check biometric availability
system_profiler SPHardwareDataType | grep -i "touch\|face"

# Check system authentication settings
# System Preferences > Touch ID & Passcode (or Face ID & Passcode)
```

**Solutions:**
1. **Enable Touch ID/Face ID:**
   - System Preferences → Touch ID & Passcode
   - Add fingerprints or set up Face ID
   - Enable "Use Touch ID for unlocking your Mac"

2. **Use password fallback:**
   ```bash
   # EasyKey automatically falls back to password authentication
   easykey set TEST_KEY "value" --verbose
   # Should show: [debug] LAContext authentication not available, skipping biometric auth
   ```

---

**Problem:** Authentication prompt not appearing
```
error: Authentication failed: User interaction is not allowed.
```

**Diagnosis:**
```bash
# Check if running in GUI session
echo $DISPLAY
who

# Check for SSH session
echo $SSH_CLIENT
```

**Solutions:**
1. **Run from local terminal:** Authentication requires GUI interaction
2. **Use screen sharing:** Remote access through macOS screen sharing
3. **Check accessibility permissions:** System Preferences → Security & Privacy → Accessibility

---

**Problem:** Repeated authentication prompts
```
# Every command asks for authentication
easykey get API_KEY  # Prompts for auth
easykey get DB_URL   # Prompts again
```

**Explanation:** This is expected behavior for security. Each EasyKey operation requires fresh authentication.

**Optimization for scripts:**
```bash
# Batch secret retrieval
{
  echo "API_KEY=$(easykey get API_KEY --quiet --reason 'Batch load')"
  echo "DB_URL=$(easykey get DB_URL --quiet --reason 'Batch load')"
  echo "SECRET=$(easykey get SECRET --quiet --reason 'Batch load')"
} > temp_secrets.env

source temp_secrets.env
rm temp_secrets.env
```

## Keychain Errors

### Error -34018 (errSecMissingEntitlement)

**Problem:** "Add failed (-34018)" error
```
error: Add failed (-34018)
```

**Explanation:** This occurs when running unsigned binaries without proper entitlements.

**Solution:** EasyKey automatically handles this with fallback mode:
```bash
# Run with verbose output to see fallback
easykey set TEST_KEY "value" --verbose

# Expected output:
# [debug] Entitlement error, retrying with basic keychain access
# [debug] set: success
```

**No action required** - fallback maintains security while allowing development use.

---

### Error -25300 (errSecItemNotFound)

**Problem:** "Secret not found" when you expect it to exist
```
error: Secret not found: API_KEY
```

**Diagnosis:**
```bash
# List all secrets
easykey list --verbose

# Check if using different EasyKey version
ls -la bin/easykey*
ls -la .dist/easykey*

# Verify secret name (case-sensitive)
easykey list | grep -i api_key
```

**Solutions:**
1. **Check secret name case:**
   ```bash
   # These are different secrets
   easykey set api_key "value"    # lowercase
   easykey set API_KEY "value"    # uppercase
   ```

2. **Check EasyKey version:**
   ```bash
   # Different versions have separate keychains
   ./bin/easykey0 list
   ./bin/easykey1 list
   ```

3. **Re-create secret:**
   ```bash
   easykey set API_KEY "new-value" --reason "Recreating missing secret"
   ```

---

### Error -25308 (errSecInteractionNotAllowed)

**Problem:** "User interaction is not allowed"
```
error: Authentication failed: User interaction is not allowed.
```

**Common causes:**
1. Running via SSH without screen sharing
2. Running from non-interactive shell
3. System security settings blocking interaction

**Solutions:**
1. **Local terminal access:** Run from local Terminal.app
2. **Screen sharing:** Use macOS screen sharing instead of SSH
3. **Accessibility settings:** Grant terminal accessibility permissions

## Performance Issues

### Slow Authentication

**Problem:** Long delays during authentication prompts

**Diagnosis:**
```bash
# Time authentication operations
time easykey get API_KEY --verbose
```

**Solutions:**
1. **Clean sensor:** Clean Touch ID sensor or position Face ID properly
2. **Re-enroll biometrics:** Remove and re-add fingerprints/face
3. **Check system load:** Monitor system resources

---

### Large Secret Counts

**Problem:** Slow `list` operations with many secrets

**Optimization:**
```bash
# Use specific secret retrieval instead of listing
easykey get SPECIFIC_SECRET --quiet

# Use JSON output for parsing
easykey list --json | jq -r '.[] | select(.name | startswith("PROD_"))'
```

## Debug Techniques

### Verbose Mode

Enable detailed debugging output:
```bash
# Add --verbose to any command
easykey set API_KEY "value" --verbose --reason "Debug session"

# Example debug output:
# [debug] set name=API_KEY reason=Debug session
# [debug] Authentication context: available
# [debug] Access control: available
# [debug] set: success
```

### System-Level Debugging

**Keychain Access.app:**
1. Open Keychain Access application
2. View → Show Keychains → login
3. Search for "easykey" to see stored items
4. Double-click items to view access control settings

**Console.app:**
1. Open Console application
2. Search for "easykey" or "Security"
3. Monitor real-time authentication events

**Activity Monitor:**
1. Monitor EasyKey process memory usage
2. Check for hung authentication processes

### Command-Line Debugging

```bash
# Check EasyKey binary info
file ./bin/easykey0
otool -L ./bin/easykey0

# Monitor system authentication
log stream --predicate 'subsystem == "com.apple.LocalAuthentication"'

# Check Keychain daemon
ps aux | grep securityd
```

### Network and System State

```bash
# Check system time (affects timestamps)
date

# Check available disk space
df -h

# Check system load
uptime
top -l 1 | head -10
```

## Error Reference

### Exit Codes

| Code | Description | Common Causes |
|------|-------------|---------------|
| 0 | Success | Operation completed |
| 1 | General error | Authentication failure, keychain error, secret not found |
| 2 | Usage error | Invalid arguments, missing parameters |

### Keychain Error Codes

| Code | Constant | Description | EasyKey Handling |
|------|----------|-------------|------------------|
| -34018 | errSecMissingEntitlement | Missing app entitlements | Auto-fallback to basic keychain |
| -25300 | errSecItemNotFound | Secret not found | Clear error message |
| -25308 | errSecInteractionNotAllowed | User interaction blocked | Authentication error |
| -25293 | errSecAuthFailed | Authentication failed | Re-prompt or error |
| -25308 | errSecUserCancel | User cancelled auth | Operation cancelled |

### Authentication Error Codes

| Error | Description | Solution |
|-------|-------------|----------|
| LAErrorBiometryNotAvailable | No biometric hardware | Use password authentication |
| LAErrorBiometryNotEnrolled | No biometrics enrolled | Enroll fingerprints/face |
| LAErrorBiometryLockout | Too many failed attempts | Use password or wait |
| LAErrorUserCancel | User cancelled prompt | Retry operation |
| LAErrorUserFallback | User chose password | Normal fallback behavior |

### Common Error Messages

**"Build failed with exit code 1"**
- Check Xcode installation and SDK availability
- Verify DEVELOPER_DIR setting
- Try clean rebuild

**"Linked: No such file or directory"**
- Binary build failed, check build output
- Rebuild binary before linking
- Check file permissions

**"Secret not found: NAME"**
- Verify secret name spelling and case
- Check if using correct EasyKey version
- List secrets to see what's available

**"Authentication failed"**
- Check biometric enrollment
- Verify system authentication settings
- Try from local terminal instead of SSH

## Getting Help

### Diagnostic Information

When reporting issues, include:

```bash
# System information
sw_vers
uname -a

# EasyKey version
./bin/easykey0 --version

# Build information
ls -la .dist/
ls -la bin/

# Error output with verbose mode
easykey command --verbose 2>&1

# System authentication status
system_profiler SPHardwareDataType | grep -A5 -B5 "Touch ID\|Touch Bar"
```

### Reset Procedures

**Complete Reset (removes all secrets):**
```bash
# WARNING: This deletes all stored secrets!
# Backup first if needed

# Stop any running EasyKey processes
pkill -f easykey

# Clear all binaries
rm -rf .dist/ bin/

# Remove secrets from keychain
security delete-generic-password -s "easykey" -a "*" 2>/dev/null || true
security delete-generic-password -s "easykey.meta" -a "*" 2>/dev/null || true

# Rebuild
scripts/build-test.sh 0
scripts/link-test.sh 0

# Verify clean state
./bin/easykey0 list
```

**Partial Reset (keep secrets, rebuild binary):**
```bash
# Remove only binaries
rm -rf .dist/ bin/

# Rebuild
scripts/build-test.sh 0
scripts/link-test.sh 0

# Verify secrets preserved
./bin/easykey0 list
```

This troubleshooting guide covers the most common issues. For complex problems, use the diagnostic commands to gather information and the reset procedures as last resorts.
