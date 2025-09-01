//
//  AddSecretView.swift
//  app
//
//  Created by kingofmac on 31/8/2025.
//

import SwiftUI

struct AddSecretView: View {
    @ObservedObject var service: EasyKeyService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var value = ""
    @State private var reason = ""
    @State private var isLoading = false
    
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.green.opacity(0.8), .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Add New Secret")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Securely store a new secret in your keychain")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)
                
                // Form sections
                VStack(spacing: 20) {
                    // Secret Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "key.horizontal")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                            
                            Text("Secret Details")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 12) {
                            // Name field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                TextField("e.g., API_KEY, DATABASE_URL", text: $name)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 15, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(.quaternary)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(name.isEmpty ? .clear : .blue.opacity(0.3), lineWidth: 2)
                                            }
                                    }
                            }
                            
                            // Value field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Value")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter the secret value", text: $value, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .lineLimit(3...6)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(.quaternary)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(value.isEmpty ? .clear : .blue.opacity(0.3), lineWidth: 2)
                                            }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    }
                    
                    // Audit Log Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.orange)
                            
                            Text("Audit Log")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Reason (Optional)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            TextField("Why are you adding this secret?", text: $reason, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.system(size: 15, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .lineLimit(2...4)
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.quaternary)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(reason.isEmpty ? .clear : .orange.opacity(0.3), lineWidth: 2)
                                        }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    }
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.quaternary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { addSecret() }) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            
                            Text(isLoading ? "Adding..." : "Add Secret")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(LinearGradient(colors: [.green.opacity(0.8), .blue.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                                .opacity(canSubmit && !isLoading ? 1.0 : 0.6)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit || isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(.regularMaterial)
    }
    
    private func addSecret() {
        isLoading = true
        Task {
            do {
                let reasonToUse = reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : reason
                try await service.setSecret(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    value: value.trimmingCharacters(in: .whitespacesAndNewlines),
                    reason: reasonToUse
                )
                await service.refresh()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                // Error is handled by the service
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AddSecretView(service: EasyKeyService())
}
