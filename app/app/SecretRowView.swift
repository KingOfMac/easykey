//
//  SecretRowView.swift
//  app
//
//  Created by kingofmac on 31/8/2025.
//

import SwiftUI
import LocalAuthentication

struct SecretRowView: View {
    let secret: Secret
    @ObservedObject var service: EasyKeyService
    
    @State private var isExpanded = false
    @State private var secretValue: String?
    @State private var isLoading = false
    @State private var isShowingDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(spacing: 16) {
                // Icon with enhanced design
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [.purple.opacity(0.8), .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 2)
                    
                    Image(systemName: "key.horizontal.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Secret info
                VStack(alignment: .leading, spacing: 4) {
                    Text(secret.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(secret.displayCreatedAt)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Expand indicator with enhanced animation
                ZStack {
                    Circle()
                        .fill(.secondary.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    toggleExpand()
                }
            }

            // Expanded content with animation
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 20)
                    
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.purple)
                            
                            Text("Authenticating...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 24)
                    } else if let secretValue = secretValue {
                        VStack(alignment: .leading, spacing: 16) {
                            // Secret value display
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Secret Value")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                
                                Text(secretValue)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .background {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(.quaternary)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .stroke(.tertiary, lineWidth: 1)
                                            }
                                    }
                                    .textSelection(.enabled)
                                    .lineLimit(nil)
                            }
                            
                            // Action buttons
                            HStack(spacing: 12) {
                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(secretValue, forType: .string)
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("Copy Value")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Spacer()
                                
                                Button(action: {
                                    isShowingDeleteAlert = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("Delete")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(.red.opacity(0.1))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(.red.opacity(0.3), lineWidth: 1)
                                            }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .top)),
                    removal: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .top))
                ))
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(isExpanded ? 0.4 : 0.2), lineWidth: 1)
                }
        }
        .scaleEffect(isExpanded ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        .alert("Delete Secret?", isPresented: $isShowingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSecret()
            }
        } message: {
            Text("Are you sure you want to delete the secret '\(secret.name)'? This action cannot be undone.")
        }
    }

    private func toggleExpand() {
        isExpanded.toggle()
        if isExpanded && secretValue == nil {
            authenticateAndLoad()
        }
    }
    
    private func authenticateAndLoad() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Reveal the secret for \(secret.name)."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        loadSecretValue()
                    } else {
                        isExpanded = false // Stay closed if auth fails
                    }
                }
            }
        } else {
            // No biometrics, load directly
            loadSecretValue()
        }
    }
    
    private func loadSecretValue() {
        isLoading = true
        Task {
            do {
                let value = try await service.getSecret(secret.name)
                await MainActor.run {
                    self.secretValue = value
                    self.isLoading = false
                }
            } catch {
                // Handle error
                await MainActor.run {
                    self.isLoading = false
                    self.isExpanded = false // Close on error
                }
            }
        }
    }
    
    private func deleteSecret() {
        Task {
            await service.removeSecret(secret.name)
        }
    }
}

#Preview {
    SecretRowView(
        secret: Secret(name: "API_KEY", createdAt: "2025-01-31T10:30:00.000Z"),
        service: EasyKeyService()
    )
    .padding()
    .frame(width: 380)
}
