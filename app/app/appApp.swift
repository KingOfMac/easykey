//
//  appApp.swift
//  app
//
//  Created by kingofmac on 31/8/2025.
//

import SwiftUI

@main
struct EasyKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Make windows stay on top
        NSApp.windows.first?.level = .floating
        NSApp.windows.first?.hidesOnDeactivate = false
        
        // Hide from dock if desired (uncomment to hide)
        // NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        // Ensure window stays on top when app becomes active
        NSApp.windows.first?.level = .floating
    }
}
