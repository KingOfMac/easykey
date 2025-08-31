//
//  SettingsView.swift
//  app
//
//  Created by kingofmac on 31/8/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("App Information")) {
                SettingRow(
                    icon: "info.circle.fill",
                    color: .blue,
                    title: "Version",
                    value: "1.0.0"
                )
            }
            
            Section(header: Text("Security")) {
                SettingRow(
                    icon: "shield.lefthalf.filled",
                    color: .green,
                    title: "Keychain",
                    value: "Secrets are stored in the macOS Keychain."
                )
            }
            
            Section(header: Text("Dangerous")) {
                Button(role: .destructive, action: {
                    // Handle cleanup
                }) {
                    Text("Delete All Secrets")
                }
            }
            
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 300)
        .padding()
        .navigationTitle("Settings")
    }
}

struct SettingRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}
