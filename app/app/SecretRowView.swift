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
        VStack {
            HStack {
                Image(systemName: "key.horizontal.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .background(LinearGradient(colors: [.accentColor.opacity(0.3), .accentColor.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                    .clipShape(Circle())

                VStack(alignment: .leading) {
                    Text(secret.name)
                        .font(.headline)
                    Text(secret.displayCreatedAt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    toggleExpand()
                }
            }

            if isExpanded {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if let secretValue = secretValue {
                    VStack(alignment: .leading, spacing: 15) {
                        Text(secretValue)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                        
                        HStack {
                            Button("Copy Value") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(secretValue, forType: .string)
                            }
                            
                            Spacer()
                            
                            Button("Delete", role: .destructive) {
                                isShowingDeleteAlert = true
                            }
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
        .alert("Delete Secret?", isPresented: $isShowingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSecret()
            }
        } message: {
            Text("Are you sure you want to delete the secret '\(secret.name)'?")
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
