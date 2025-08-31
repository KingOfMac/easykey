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
        Form {
            Section(header: Text("Secret Details")) {
                TextField("Name (e.g., API_KEY)", text: $name)
                TextField("Value", text: $value)
            }
            
            Section(header: Text("Audit Log")) {
                TextField("Reason for change (Optional)", text: $reason)
            }
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Add Secret") {
                    addSecret()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit || isLoading)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 300)
        .padding()
        .navigationTitle("Add New Secret")
        .toolbar {
            if isLoading {
                ProgressView()
            }
        }
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
