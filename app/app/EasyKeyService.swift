//
//  EasyKeyService.swift
//  app
//
//  Created by Meir Itkin on 31/8/2025.
//

import Foundation
import Combine

// MARK: - Models

struct Secret: Identifiable, Codable {
    let id = UUID()
    let name: String
    let createdAt: String?
    
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
    case cliNotFound
    case executionFailed(String)
    case authenticationFailed
    case secretNotFound(String)
    case invalidInput(String)
    
    var id: String { errorDescription ?? "unknown" }
    
    var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "EasyKey CLI not found. Please ensure easykey is installed and available in PATH."
        case .executionFailed(let message):
            return "Command failed: \(message)"
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .secretNotFound(let name):
            return "Secret '\(name)' not found."
        case .invalidInput(let message):
            return "Invalid input: \(message)"
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
    
    private let cliPath: String
    
    init() {
        // Try to find easykey CLI in common locations
        self.cliPath = Self.findCLI() ?? "easykey"
    }
    
    private static func findCLI() -> String? {
        let possiblePaths = [
            "/usr/local/bin/easykey",
            "/opt/homebrew/bin/easykey",
            "/Users/\(NSUserName())/Documents/Code/Projects/easykey/cli/.build/release/easykey",
            "easykey"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Try which easykey
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = ["easykey"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            // Fall through to return nil
        }
        
        return nil
    }
    
    private func executeCommand(_ arguments: [String]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let task = Process()
            task.launchPath = cliPath
            task.arguments = arguments
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            task.standardOutput = outputPipe
            task.standardError = errorPipe
            
            task.terminationHandler = { process in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                let output = String(data: outputData, encoding: .utf8) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let errorMessage = errorOutput.isEmpty ? "Command failed" : errorOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if errorMessage.contains("Authentication failed") {
                        continuation.resume(throwing: EasyKeyError.authenticationFailed)
                    } else if errorMessage.contains("not found") {
                        continuation.resume(throwing: EasyKeyError.secretNotFound(""))
                    } else {
                        continuation.resume(throwing: EasyKeyError.executionFailed(errorMessage))
                    }
                }
            }
            
            do {
                try task.run()
            } catch {
                continuation.resume(throwing: EasyKeyError.cliNotFound)
            }
        }
    }
    
    // MARK: - Public Methods
    
    func refreshSecrets() async {
        isLoading = true
        error = nil
        
        do {
            let output = try await executeCommand(["list", "--json"])
            let data = output.data(using: .utf8) ?? Data()
            self.secrets = try JSONDecoder().decode([Secret].self, from: data)
        } catch {
            if let easyKeyError = error as? EasyKeyError {
                self.error = easyKeyError
            } else {
                self.error = EasyKeyError.executionFailed(error.localizedDescription)
            }
            self.secrets = []
        }
        
        isLoading = false
    }
    
    func refreshStatus() async {
        do {
            let output = try await executeCommand(["status"])
            let lines = output.components(separatedBy: .newlines).compactMap { line in
                line.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty }
            
            var secrets = 0
            var lastAccess: String?
            
            for line in lines {
                if line.hasPrefix("secrets: ") {
                    secrets = Int(String(line.dropFirst(9))) ?? 0
                } else if line.hasPrefix("last_access: ") {
                    lastAccess = String(line.dropFirst(13))
                }
            }
            
            self.status = VaultStatus(secrets: secrets, lastAccess: lastAccess)
        } catch {
            if let easyKeyError = error as? EasyKeyError {
                self.error = easyKeyError
            } else {
                self.error = EasyKeyError.executionFailed(error.localizedDescription)
            }
        }
    }
    
    func getSecret(_ name: String) async throws -> String {
        let output = try await executeCommand(["get", name, "--quiet"])
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func setSecret(name: String, value: String, reason: String? = nil) async throws {
        var args = ["set", name, value]
        if let reason = reason, !reason.isEmpty {
            args.append(contentsOf: ["--reason", reason])
        }
        _ = try await executeCommand(args)
    }
    
    func removeSecret(_ name: String, reason: String? = nil) async throws {
        var args = ["remove", name]
        if let reason = reason, !reason.isEmpty {
            args.append(contentsOf: ["--reason", reason])
        }
        _ = try await executeCommand(args)
    }
    
    func cleanup() async throws -> String {
        // Note: This doesn't handle the interactive confirmation
        // We'll need to handle this differently in the UI
        let output = try await executeCommand(["cleanup"])
        return output
    }
    
    func refresh() async {
        await refreshSecrets()
        await refreshStatus()
    }
    
    func clearError() {
        error = nil
    }
}
