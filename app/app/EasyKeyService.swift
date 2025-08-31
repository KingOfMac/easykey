//
//  EasyKeyService.swift
//  app
//
//  Created by kingofmac on 31/8/2025.
//

import Foundation
import Combine
import Security
import LocalAuthentication

// MARK: - Models

struct Secret: Identifiable, Codable {
    let id = UUID()
    let name: String
    let createdAt: String?
    
    // Exclude id from Codable since it's generated locally
    private enum CodingKeys: String, CodingKey {
        case name
        case createdAt
    }
    
    var displayCreatedAt: String {
        guard let createdAt = createdAt else { return "Unknown" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
}

struct VaultStatus: Codable {
    let secrets: Int
    let lastAccess: String?
    
    var displayLastAccess: String {
        guard let lastAccess = lastAccess, lastAccess != "-" else { return "Never" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: lastAccess) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return lastAccess
    }
}

enum EasyKeyError: LocalizedError, Identifiable {
    case keychain(String)
    case authentication(String)
    case notFound(String)
    case general(String)

    var id: String { errorDescription ?? "unknown" }
    
    var errorDescription: String? {
        switch self {
        case .keychain(let message):
            return "Keychain Error: \(message)"
        case .authentication(let message):
            return "Authentication failed: \(message)"
        case .notFound(let message):
            return "Not Found: \(message)"
        case .general(let message):
            return message
        }
    }
}

// MARK: - Service

@MainActor
class EasyKeyService: ObservableObject {
    @Published var secrets: [Secret] = []
    @Published var status: VaultStatus?
    @Published var isLoading = false
    @Published var error: EasyKeyError?
    
    private let keychainManager = KeychainManager(verbose: true) // Enable verbose for debugging
    
    init() {
        // Initial load
        Task {
            await refresh()
        }
    }

    private func format(date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    
    // MARK: - Public Methods
    
    func refreshSecrets() async {
        isLoading = true
        error = nil
        
        do {
            let items = try keychainManager.listSecrets(reason: "Accessing secrets from EasyKey app")
            self.secrets = items.map { Secret(name: $0.name, createdAt: $0.createdAt.map(format)) }
        } catch {
            self.error = .keychain(error.localizedDescription)
            self.secrets = []
        }
        
        isLoading = false
    }
    
    func refreshStatus() async {
        do {
            let (count, lastAccess) = try keychainManager.status(reason: "Checking status from EasyKey app")
            self.status = VaultStatus(secrets: count, lastAccess: lastAccess.map(format))
        } catch {
            self.error = .keychain(error.localizedDescription)
        }
    }
    
    func getSecret(_ name: String) async throws -> String {
        let data = try await keychainManager.getSecret(name: name, reason: "Reading secret '\(name)'")
        guard let string = String(data: data, encoding: .utf8) else {
            throw EasyKeyError.general("Failed to decode secret from data.")
        }
        return string
    }
    
    func setSecret(name: String, value: String, reason: String? = nil) async {
        do {
            try await keychainManager.setSecret(
                name: name,
                value: Data(value.utf8),
                reason: reason ?? "Saving secret '\(name)'"
            )
            await refresh()
        } catch {
            self.error = .keychain("Failed to set secret: \(error.localizedDescription)")
        }
    }
    
    func removeSecret(_ name: String, reason: String? = nil) async {
        do {
            try await keychainManager.removeSecret(name: name, reason: reason ?? "Deleting secret '\(name)'")
            await refresh()
        } catch {
            self.error = .keychain("Failed to remove secret: \(error.localizedDescription)")
        }
    }
    
    func refresh() async {
        await refreshSecrets()
        await refreshStatus()
    }
    
    func clearError() {
        error = nil
    }
}

// MARK: - Keychain Manager (Integrated from CLI)

private let serviceName = "easykey"
private let metaServiceName = "easykey.meta"
private let lastAccessAccount = "last_access"

struct KeychainManager {
    let verbose: Bool

    private func makeAccessControl() throws -> SecAccessControl? {
        var error: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .userPresence,
            &error
        ) else {
            if verbose { print("[debug] SecAccessControl failed, falling back to basic keychain") }
            return nil
        }
        return access
    }

    private func authenticate(reason: String) async throws -> LAContext {
        let context = LAContext()
        var authError: NSError?
        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometricsOrWatch
        
        guard context.canEvaluatePolicy(policy, error: &authError) else {
            // Fallback for simulators or devices without biometrics
            let fallbackPolicy: LAPolicy = .deviceOwnerAuthentication
            guard context.canEvaluatePolicy(fallbackPolicy, error: &authError) else {
                 throw EasyKeyError.authentication("Biometrics or passcode not available.")
            }
            do {
                let success = try await context.evaluatePolicy(fallbackPolicy, localizedReason: reason)
                if !success {
                    throw EasyKeyError.authentication("Authentication failed.")
                }
            } catch {
                throw EasyKeyError.authentication(error.localizedDescription)
            }
            return context
        }
        
        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            if !success {
                throw EasyKeyError.authentication("Authentication failed.")
            }
        } catch {
            throw EasyKeyError.authentication(error.localizedDescription)
        }
        return context
    }

    func setSecret(name: String, value: Data, reason: String) async throws {
        let context = try await authenticate(reason: reason)
        
        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: name,
            kSecValueData as String: value,
            kSecUseAuthenticationContext as String: context
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            if verbose { print("[debug] Item exists; updating \(name)") }
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: name,
                kSecUseAuthenticationContext as String: context
            ]
            let updateAttrs: [String: Any] = [kSecValueData as String: value]
            let updateStatus = SecItemUpdate(query as CFDictionary, updateAttrs as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw EasyKeyError.keychain("Update failed (\(updateStatus))")
            }
        } else if status != errSecSuccess {
            throw EasyKeyError.keychain("Add failed (\(status))")
        }

        try updateLastAccess()
    }

    func getSecret(name: String, reason: String) async throws -> Data {
        let context = try await authenticate(reason: reason)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: name,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            throw EasyKeyError.notFound("Secret not found: \(name)")
        }
        guard status == errSecSuccess, let data = item as? Data else {
            throw EasyKeyError.keychain("Read failed (\(status))")
        }
        try updateLastAccess()
        return data
    }

    func removeSecret(name: String, reason: String) async throws {
        let context = try await authenticate(reason: reason)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: name,
            kSecUseAuthenticationContext as String: context
        ]
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw EasyKeyError.keychain("Delete failed (\(status))")
        }
        try updateLastAccess()
    }

    func listSecrets(reason: String) throws -> [(name: String, createdAt: Date?)] {
        // Listing does not require authentication in this implementation for smoother UX
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return []
        }
        guard status == errSecSuccess else {
            throw EasyKeyError.keychain("List failed (\(status))")
        }
        try updateLastAccess()
        guard let array = result as? [[String: Any]] else { return [] }
        return array.compactMap { attrs in
            guard let account = attrs[kSecAttrAccount as String] as? String else { return nil }
            let created = attrs[kSecAttrCreationDate as String] as? Date
            return (name: account, createdAt: created)
        }
    }

    func status(reason: String) throws -> (count: Int, lastAccess: Date?) {
        let secrets = try listSecrets(reason: reason)
        let last = try readLastAccess()
        return (secrets.count, last)
    }

    private func updateLastAccess() throws {
        let now = Date()
        let data = format(date: now).data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: metaServiceName,
            kSecAttrAccount as String: lastAccessAccount
        ]
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

    private func readLastAccess() throws -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: metaServiceName,
            kSecAttrAccount as String: lastAccessAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess, let data = item as? Data, let text = String(data: data, encoding: .utf8) else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: text)
    }
    
    private func format(date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
