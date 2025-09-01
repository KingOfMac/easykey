//
//  ContentView.swift
//  app
//
//  Created by kingofmac on 31/8/2025.
//

import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @StateObject private var easyKeyService = EasyKeyService()
    @State private var showingAddSecret = false
    @State private var showingSettings = false
    @State private var isUnlocked = false

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                StatusView(service: easyKeyService)
                SecretsView(service: easyKeyService)
            }
            .frame(minWidth: 500, idealWidth: 550, maxWidth: 700, minHeight: 500, idealHeight: 700, maxHeight: 900)
            .background(.regularMaterial)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    HStack(spacing: 8) {
                        Button(action: { showingAddSecret = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Add")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(LinearGradient(colors: [.green.opacity(0.8), .blue.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            Task {
                                await easyKeyService.refresh()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(.quaternary, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(easyKeyService.isLoading)
                        
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(.quaternary, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .sheet(isPresented: $showingAddSecret) {
                AddSecretView(service: easyKeyService)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Error", isPresented: .constant(easyKeyService.error != nil)) {
                Button("OK") {
                    easyKeyService.clearError()
                }
            } message: {
                Text(easyKeyService.error?.errorDescription ?? "")
            }

            // Authentication overlay
            if !isUnlocked {
                ZStack {
                    // Blurred background
                    Rectangle()
                        .fill(.regularMaterial)
                        .ignoresSafeArea()
                    
                    // Lock screen content
                    VStack(spacing: 32) {
                        VStack(spacing: 20) {
                            // App icon/logo area
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 100, height: 100)
                                    .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 8)
                                
                                Image(systemName: "key.horizontal.fill")
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("EasyKey")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Your secrets are protected")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Unlock button
                        Button(action: authenticate) {
                            HStack(spacing: 12) {
                                Image(systemName: "faceid")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Text("Unlock with Biometrics")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LinearGradient(colors: [.blue.opacity(0.9), .purple.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                                    .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 4)
                            }
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(1.0)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                // Add hover effect if needed
                            }
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 1.05))
                ))
            }
        }
        .onAppear(perform: authenticate)
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock EasyKey to access your secrets."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                        Task {
                            await easyKeyService.refresh()
                        }
                    } else {
                        // Handle error or user cancellation
                    }
                }
            }
        } else {
            // No biometrics available, unlock for now but this could be handled differently
            self.isUnlocked = true
             Task {
                await easyKeyService.refresh()
            }
        }
    }
}

#Preview {
    ContentView()
}
