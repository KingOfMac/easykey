//
//  main.swift
//  easykey
//
//  Created by kingofmac
//

import Foundation
import Security
import LocalAuthentication

// MARK: - Constants

private let cliVersion = "0.1.0"
private let serviceName = "easykey"
private let metaServiceName = "easykey.meta"
private let lastAccessAccount = "last_access"

// MARK: - Utilities

@discardableResult
private func eprint(_ message: String) -> Bool {
    guard let data = (message + "\n").data(using: .utf8) else { return false }
    FileHandle.standardError.write(data)
    return true
}

private func format(date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
}

// MARK: - Errors

enum CLIError: Error, CustomStringConvertible {
    case invalidArguments(String)
    case keychain(String)
    case authentication(String)
    case notFound(String)

    var description: String {
        switch self {
        case .invalidArguments(let msg): return msg
        case .keychain(let msg): return msg
        case .authentication(let msg): return msg
        case .notFound(let msg): return msg
        }
    }
}

// MARK: - Keychain Manager

struct KeychainManager {
    let verbose: Bool

    private func makeAccessControl() throws -> SecAccessControl? {
        var error: Unmanaged<CFError>?
        // Try to require user presence (biometric or password) and keep data device-local
        // This may fail without proper entitlements in unsigned CLI apps
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .userPresence,
            &error
        ) else {
            if verbose {
                eprint("[debug] SecAccessControl failed (likely missing entitlements), falling back to basic keychain")
            }
            return nil
        }
        return access
    }

    private func authenticate(reason: String) throws -> LAContext? {
        let context = LAContext()
        var authError: NSError?
        let policy: LAPolicy = .deviceOwnerAuthentication
        guard context.canEvaluatePolicy(policy, error: &authError) else {
            if verbose {
                eprint("[debug] LAContext authentication not available (likely in unsigned CLI), skipping biometric auth")
            }
            return nil
        }
        let semaphore = DispatchSemaphore(value: 0)
        var authSuccess = false
        var authFailure: Error?
        context.evaluatePolicy(policy, localizedReason: reason) { success, error in
            authSuccess = success
            authFailure = error
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .distantFuture)
        guard authSuccess else {
            throw CLIError.authentication("Authentication failed: \(authFailure?.localizedDescription ?? "unknown error")")
        }
        return context
    }

    func setSecret(name: String, value: Data, reason: String) throws {
        let context = try authenticate(reason: reason)
        let access = try makeAccessControl()

        if verbose {
            eprint("[debug] Authentication context: \(context != nil ? "available" : "fallback mode")")
            eprint("[debug] Access control: \(access != nil ? "available" : "fallback mode")")
        }

        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: name,
            kSecValueData as String: value
        ]
        
        // Try different approaches based on available features
        if let access = access, let context = context {
            // Full security mode with biometric auth
            addQuery[kSecAttrAccessControl as String] = access
            addQuery[kSecUseAuthenticationContext as String] = context
        } else if let context = context {
            // Auth without access control
            addQuery[kSecUseAuthenticationContext as String] = context
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        } else {
            // Basic fallback mode
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        // Handle entitlement error by falling back to basic mode
        if status == errSecMissingEntitlement {
            if verbose { eprint("[debug] Entitlement error, retrying with basic keychain access") }
            // Retry with minimal security
            let basicQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: name,
                kSecValueData as String: value,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            let retryStatus = SecItemAdd(basicQuery as CFDictionary, nil)
            if retryStatus == errSecDuplicateItem {
                if verbose { eprint("[debug] Item exists; updating \(name) in basic mode") }
                let basicUpdateQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: serviceName,
                    kSecAttrAccount as String: name
                ]
                let updateAttrs: [String: Any] = [kSecValueData as String: value]
                let updateStatus = SecItemUpdate(basicUpdateQuery as CFDictionary, updateAttrs as CFDictionary)
                guard updateStatus == errSecSuccess else {
                    throw CLIError.keychain("Update failed (\(updateStatus))")
                }
            } else if retryStatus != errSecSuccess {
                throw CLIError.keychain("Add failed (\(retryStatus))")
            }
            try updateLastAccess(context: nil)
            return
        }
        
        if status == errSecDuplicateItem {
            if verbose { eprint("[debug] Item exists; updating \(name)") }
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: name
            ]
            if let context = context {
                query[kSecUseAuthenticationContext as String] = context
            }
            let updateAttrs: [String: Any] = [
                kSecValueData as String: value
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, updateAttrs as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw CLIError.keychain("Update failed (\(updateStatus))")
            }
        } else if status != errSecSuccess {
            throw CLIError.keychain("Add failed (\(status))")
        }

        try updateLastAccess(context: context)
    }

    func getSecret(name: String, reason: String) throws -> Data {
        let context = try authenticate(reason: reason)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: name,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
        }
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            throw CLIError.notFound("Secret not found: \(name)")
        }
        guard status == errSecSuccess, let data = item as? Data else {
            throw CLIError.keychain("Read failed (\(status))")
        }
        try updateLastAccess(context: context)
        return data
    }

    func removeSecret(name: String, reason: String) throws {
        let context = try authenticate(reason: reason)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: name
        ]
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
        }
        let status = SecItemDelete(query as CFDictionary)
        
        // Handle access control mismatch by trying multiple fallback approaches
        if status == errSecInvalidOwnerEdit || status == errSecMissingEntitlement {
            if verbose { eprint("[debug] Access control mismatch, trying fallback methods") }
            
            // Try 1: Without authentication context
            var basicQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: name
            ]
            var retryStatus = SecItemDelete(basicQuery as CFDictionary)
            
            if retryStatus == errSecSuccess || retryStatus == errSecItemNotFound {
                if verbose { eprint("[debug] Fallback method 1 succeeded") }
                try updateLastAccess(context: nil)
                return
            }
            
            // Try 2: Query first, then delete by reference
            if verbose { eprint("[debug] Fallback method 1 failed (\(retryStatus)), trying method 2") }
            basicQuery[kSecReturnRef as String] = true
            basicQuery[kSecMatchLimit as String] = kSecMatchLimitOne
            
            var item: CFTypeRef?
            let queryStatus = SecItemCopyMatching(basicQuery as CFDictionary, &item)
            
            if queryStatus == errSecSuccess, let itemRef = item {
                let deleteQuery: [String: Any] = [kSecValueRef as String: itemRef]
                retryStatus = SecItemDelete(deleteQuery as CFDictionary)
                
                if retryStatus == errSecSuccess {
                    if verbose { eprint("[debug] Fallback method 2 succeeded") }
                    try updateLastAccess(context: nil)
                    return
                }
            }
            
            if verbose { eprint("[debug] All fallback methods failed") }
            throw CLIError.keychain("Delete failed - secret may have incompatible access controls from different EasyKey version (\(status))")
        }
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CLIError.keychain("Delete failed (\(status))")
        }
        try updateLastAccess(context: context)
    }

    struct ListEntry: Codable {
        let name: String
        let createdAt: String?
    }

    func listSecrets(reason: String) throws -> [(name: String, createdAt: Date?)] {
        let context = try authenticate(reason: reason)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
        }
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return []
        }
        guard status == errSecSuccess else {
            throw CLIError.keychain("List failed (\(status))")
        }
        try updateLastAccess(context: context)
        guard let array = result as? [[String: Any]] else { return [] }
        return array.compactMap { attrs in
            guard let account = attrs[kSecAttrAccount as String] as? String else { return nil }
            let created = attrs[kSecAttrCreationDate as String] as? Date
            return (name: account, createdAt: created)
        }
    }

    func status(reason: String) throws -> (count: Int, lastAccess: Date?) {
        let context = try authenticate(reason: reason)
        // Count secrets
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
        }
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        let count: Int
        switch status {
        case errSecSuccess:
            count = (result as? [[String: Any]])?.count ?? 0
        case errSecItemNotFound:
            count = 0
        default:
            throw CLIError.keychain("Status failed (\(status))")
        }
        let last = try readLastAccess(context: context)
        return (count, last)
    }

    private func updateLastAccess(context: LAContext?) throws {
        let now = Date()
        let data = format(date: now).data(using: .utf8) ?? Data()
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: metaServiceName,
            kSecAttrAccount as String: lastAccessAccount
        ]
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
        }
        let updateAttrs: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttrs as CFDictionary)
        if updateStatus == errSecItemNotFound {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: metaServiceName,
                kSecAttrAccount as String: lastAccessAccount,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            _ = SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private func readLastAccess(context: LAContext?) throws -> Date? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: metaServiceName,
            kSecAttrAccount as String: lastAccessAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
        }
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess, let data = item as? Data, let text = String(data: data, encoding: .utf8) else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: text)
    }

    func cleanupAllSecrets(reason: String) throws -> Int {
        if verbose { eprint("[debug] Starting cleanup - this will remove ALL easykey secrets") }
        
        // Try to authenticate first, but continue even if it fails
        let context = try? authenticate(reason: reason)
        
        var deletedCount = 0
        
        // Method 1: Try to list and delete each secret individually
        do {
            let secrets = try listSecrets(reason: reason)
            for (name, _) in secrets {
                if verbose { eprint("[debug] Attempting to delete: \(name)") }
                do {
                    try removeSecret(name: name, reason: reason)
                    deletedCount += 1
                    if verbose { eprint("[debug] Deleted: \(name)") }
                } catch {
                    if verbose { eprint("[debug] Failed to delete \(name): \(error)") }
                }
            }
        } catch {
            if verbose { eprint("[debug] Could not list secrets for individual deletion: \(error)") }
        }
        
        // Method 2: Nuclear option - delete all items with our service name
        if verbose { eprint("[debug] Performing nuclear cleanup of all easykey items") }
        
        let queries: [[String: Any]] = [
            // Main secrets
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName
            ],
            // Metadata
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: metaServiceName
            ]
        ]
        
        for query in queries {
            let status = SecItemDelete(query as CFDictionary)
            if status == errSecSuccess {
                if verbose { eprint("[debug] Nuclear cleanup succeeded for service: \(query[kSecAttrService as String] as? String ?? "unknown")") }
            } else if status == errSecItemNotFound {
                if verbose { eprint("[debug] No items found for service: \(query[kSecAttrService as String] as? String ?? "unknown")") }
            } else {
                if verbose { eprint("[debug] Nuclear cleanup failed for service: \(query[kSecAttrService as String] as? String ?? "unknown") (\(status))") }
            }
        }
        
        return deletedCount
    }
}

// MARK: - CLI Parsing

enum Command {
    case get(name: String, quiet: Bool)
    case set(name: String, value: String)
    case remove(name: String)
    case list(json: Bool)
    case status
    case cleanup
    case uninstall
    case help
    case version
}

struct CLIOptions {
    var verbose: Bool = false
    var reason: String = "Authenticate to access easykey vault"
}

private func printUsage() {
    let usage = """
    easykey <command> [arguments] [flags]

    Global flags:
      --verbose             Show debug info (no secrets)
      --reason "text"       Optional reason for audit logging
      --help                Show this help
      --version             Show CLI version

    Commands:
      get <SECRET_NAME> [--reason "text"] [--quiet]
        Retrieve a secret. Triggers biometric if locked. Prints plaintext to stdout.

      set <SECRET_NAME> <SECRET_VALUE> [--reason "text"]
        Store a new secret or update existing. Biometric confirmation required.

      remove <SECRET_NAME> [--reason "text"]
        Delete a secret. Biometric confirmation required.

      list [--json] [--verbose]
        Show stored secret names only. With --verbose, include creation timestamps.

      status
        Show vault status: number of secrets and last access timestamp.

      cleanup
        Remove all easykey secrets from keychain (nuclear option for fixing access issues).

      uninstall
        Remove the EasyKey app from /Applications. Secrets remain in keychain.
    """
    print(usage)
}

private func parseCLI() throws -> (Command, CLIOptions) {
    var args = Array(CommandLine.arguments.dropFirst())
    var options = CLIOptions()
    var jsonFlag = false
    var quietFlag = false

    // Extract global flags first (order-agnostic)
    var i = 0
    while i < args.count {
        let arg = args[i]
        if arg == "--help" { return (.help, options) }
        if arg == "--version" { return (.version, options) }
        if arg == "--verbose" {
            options.verbose = true
            args.remove(at: i)
            continue
        }
        if arg == "--reason" {
            guard i + 1 < args.count else { throw CLIError.invalidArguments("--reason requires a value") }
            options.reason = args[i + 1]
            args.removeSubrange(i...(i+1))
            continue
        }
        if arg == "--json" {
            jsonFlag = true
            args.remove(at: i)
            continue
        }
        if arg == "--quiet" {
            quietFlag = true
            args.remove(at: i)
            continue
        }
        i += 1
    }

    guard let cmd = args.first else {
        throw CLIError.invalidArguments("Missing command. Use --help for usage.")
    }

    switch cmd.lowercased() {
    case "get":
        guard args.count >= 2 else { throw CLIError.invalidArguments("Usage: easykey get <SECRET_NAME> [--reason \"text\"] [--quiet]") }
        let name = args[1]
        return (.get(name: name, quiet: quietFlag), options)
    case "set":
        guard args.count >= 3 else { throw CLIError.invalidArguments("Usage: easykey set <SECRET_NAME> <SECRET_VALUE> [--reason \"text\"]") }
        let name = args[1]
        let value = args[2]
        return (.set(name: name, value: value), options)
    case "remove":
        guard args.count >= 2 else { throw CLIError.invalidArguments("Usage: easykey remove <SECRET_NAME> [--reason \"text\"]") }
        let name = args[1]
        return (.remove(name: name), options)
    case "list":
        return (.list(json: jsonFlag), options)
    case "status":
        return (.status, options)
    case "cleanup":
        return (.cleanup, options)
    case "uninstall":
        return (.uninstall, options)
    case "--help", "help":
        return (.help, options)
    default:
        throw CLIError.invalidArguments("Unknown command: \(cmd)")
    }
}

// MARK: - Main

do {
    let (command, options) = try parseCLI()
    let kc = KeychainManager(verbose: options.verbose)

    switch command {
    case .help:
        printUsage()
        break
    case .version:
        print(cliVersion)
        break
    case .set(let name, let value):
        if options.verbose { eprint("[debug] set name=\(name) reason=\(options.reason)") }
        try kc.setSecret(name: name, value: Data(value.utf8), reason: options.reason)
        if options.verbose { eprint("[debug] set: success") }
    case .get(let name, let quiet):
        if options.verbose && !quiet { eprint("[debug] get name=\(name) reason=\(options.reason)") }
        let data = try kc.getSecret(name: name, reason: options.reason)
        // Print plaintext to stdout only
        if let text = String(data: data, encoding: .utf8) {
            FileHandle.standardOutput.write((text + "\n").data(using: .utf8)!)
        } else {
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write("\n".data(using: .utf8)!)
        }
        if options.verbose && !quiet { eprint("[debug] get: success") }
    case .remove(let name):
        if options.verbose { eprint("[debug] remove name=\(name) reason=\(options.reason)") }
        try kc.removeSecret(name: name, reason: options.reason)
        if options.verbose { eprint("[debug] remove: success") }
    case .list(let json):
        if options.verbose { eprint("[debug] list reason=\(options.reason)") }
        let items = try kc.listSecrets(reason: options.reason)
        if json {
            struct JsonEntry: Codable { let name: String; let createdAt: String? }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let payload = items.map { JsonEntry(name: $0.name, createdAt: $0.createdAt.map { format(date: $0) }) }
            let data = try encoder.encode(payload)
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write("\n".data(using: .utf8)!)
        } else {
            for (name, createdAt) in items {
                if options.verbose, let createdAt {
                    print("\(name)\t\(format(date: createdAt))")
                } else {
                    print(name)
                }
            }
        }
        if options.verbose { eprint("[debug] list: success (\(items.count) items)") }
    case .status:
        if options.verbose { eprint("[debug] status reason=\(options.reason)") }
        let state = try kc.status(reason: options.reason)
        print("secrets: \(state.count)")
        print("last_access: \(state.lastAccess.map { format(date: $0) } ?? "-")")
        if options.verbose { eprint("[debug] status: success") }
    case .cleanup:
        if options.verbose { eprint("[debug] cleanup reason=\(options.reason)") }
        print("WARNING: This will delete ALL easykey secrets from the keychain!")
        print("This cannot be undone. Continue? (type 'yes' to confirm)")
        
        let input = readLine() ?? ""
        if input.lowercased() == "yes" {
            let deletedCount = try kc.cleanupAllSecrets(reason: options.reason)
            print("Cleanup complete. Removed \(deletedCount) secrets using individual deletion.")
            print("Nuclear cleanup also performed to ensure all easykey items are removed.")
            if options.verbose { eprint("[debug] cleanup: success") }
        } else {
            print("Cleanup cancelled.")
        }
    }
} catch let err as CLIError {
    eprint("error: \(err.description)")
    exit(1)
} catch {
    eprint("error: \(error.localizedDescription)")
    exit(1)
}
