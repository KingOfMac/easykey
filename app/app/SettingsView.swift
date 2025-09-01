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
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.gray.opacity(0.8), .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                            .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "gear")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Settings")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Manage your EasyKey preferences")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // Settings sections
                VStack(spacing: 16) {
                    // App Information Section
                    SettingsSection(
                        title: "App Information",
                        icon: "info.circle.fill",
                        iconColor: .blue
                    ) {
                        VStack(spacing: 12) {
                            EnhancedSettingRow(
                                icon: "app.badge",
                                iconColor: .blue,
                                title: "Version",
                                subtitle: "Current app version",
                                value: "1.0.0"
                            )
                            
                            EnhancedSettingRow(
                                icon: "apple.logo",
                                iconColor: .gray,
                                title: "Platform",
                                subtitle: "Operating system",
                                value: "macOS"
                            )
                        }
                    }
                    
                    // Security Section
                    SettingsSection(
                        title: "Security",
                        icon: "shield.lefthalf.filled",
                        iconColor: .green
                    ) {
                        VStack(spacing: 12) {
                            EnhancedSettingRow(
                                icon: "key.icloud",
                                iconColor: .green,
                                title: "Keychain Storage",
                                subtitle: "Secrets are encrypted and stored securely",
                                value: "macOS Keychain",
                                isMultiline: true
                            )
                            
                            EnhancedSettingRow(
                                icon: "faceid",
                                iconColor: .purple,
                                title: "Biometric Auth",
                                subtitle: "Touch ID / Face ID protection",
                                value: "Enabled"
                            )
                        }
                    }
                    
                    // Dangerous Actions Section
                    SettingsSection(
                        title: "Dangerous Actions",
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .red
                    ) {
                        VStack(spacing: 12) {
                            Button(action: {
                                // Handle cleanup - TODO: implement
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(.red.opacity(0.1))
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.red)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Delete All Secrets")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.red)
                                        
                                        Text("Permanently remove all stored secrets")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.red.opacity(0.05))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(.red.opacity(0.2), lineWidth: 1)
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Done button
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(minWidth: 500, minHeight: 450)
        .background(.regularMaterial)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
}

struct EnhancedSettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let value: String
    let isMultiline: Bool
    
    init(icon: String, iconColor: Color, title: String, subtitle: String, value: String, isMultiline: Bool = false) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(isMultiline ? 3 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.5))
        }
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
