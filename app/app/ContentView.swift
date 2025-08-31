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
            VStack(spacing: 0) {
                StatusView(service: easyKeyService)
                SecretsView(service: easyKeyService)
            }
            .frame(minWidth: 400, idealWidth: 450, maxWidth: 600, minHeight: 400, idealHeight: 600, maxHeight: 800)
            .toolbar {
                ToolbarItemGroup {
                    Button(action: { showingAddSecret = true }) {
                        Label("Add Secret", systemImage: "plus")
                    }
                    
                    Button(action: {
                        Task {
                            await easyKeyService.refresh()
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(easyKeyService.isLoading)
                    
                    Button(action: { showingSettings = true }) {
                        Label("Settings", systemImage: "gear")
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

            if !isUnlocked {
                VStack {
                    Text("EasyKey Locked")
                        .font(.largeTitle)
                        .padding()
                    Button(action: authenticate) {
                        Label("Unlock with Biometrics", systemImage: "lock.fill")
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.regularMaterial)
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
