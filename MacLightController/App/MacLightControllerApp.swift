// App/MacLightControllerApp.swift
// MacLightController
//
// Main entry point for the application

import SwiftUI

/// Main entry point for MacLightController
@main
struct MacLightControllerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We use AppDelegate for menu bar management, so we provide a minimal Settings scene
        Settings {
            SettingsView()
                .environmentObject(CoreEngine.shared)
                .environmentObject(CoreEngine.shared.configStore)
        }
    }
}
