// UI/Settings/SettingsView.swift
// MacLightController
//
// Main settings window view

import SwiftUI

/// Main settings view with tabs
struct SettingsView: View {
    @EnvironmentObject var engine: CoreEngine
    @EnvironmentObject var configStore: ConfigurationStore

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("Generale", systemImage: "gear")
                }

            AutomationsTab()
                .tabItem {
                    Label("Automazioni", systemImage: "clock.arrow.circlepath")
                }

            PluginsTab()
                .tabItem {
                    Label("Plugin", systemImage: "puzzlepiece.extension")
                }

            AboutTab()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
        }
        .frame(width: 650, height: 500)
    }
}

#Preview {
    SettingsView()
        .environmentObject(CoreEngine.shared)
        .environmentObject(ConfigurationStore())
}
