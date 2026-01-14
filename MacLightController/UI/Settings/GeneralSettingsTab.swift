// UI/Settings/GeneralSettingsTab.swift
// MacLightController
//
// General settings tab - Minimal Design

import SwiftUI

struct GeneralSettingsTab: View {
    @EnvironmentObject var configStore: ConfigurationStore
    @StateObject private var launchService = LaunchAtLoginService.shared
    
    @State private var showingLocationError = false
    @State private var locationErrorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Startup
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Avvio")
                    
                    Toggle("Avvia al login", isOn: launchAtLoginBinding)
                        .toggleStyle(.switch)
                    
                    Divider()
                    
                    Toggle("Mostra nella menu bar", isOn: $configStore.globalSettings.showInMenuBar)
                        .toggleStyle(.switch)
                    
                    Divider()
                    
                    Toggle("Mostra nel Dock", isOn: $configStore.globalSettings.showInDock)
                        .toggleStyle(.switch)
                }
                .minimalCardStyle()
                
                // Notifications
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Notifiche")
                    
                    Toggle("Abilita notifiche", isOn: $configStore.globalSettings.notificationsEnabled)
                        .toggleStyle(.switch)
                    
                    if configStore.globalSettings.notificationsEnabled {
                        Divider()
                        Toggle("Suoni", isOn: $configStore.globalSettings.soundsEnabled)
                            .toggleStyle(.switch)
                    }
                }
                .minimalCardStyle()
                
                // Location
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Posizione")
                    
                    Toggle("Usa posizione automatica", isOn: $configStore.globalSettings.useAutomaticLocation)
                        .toggleStyle(.switch)
                    
                    Divider()
                    
                    if !configStore.globalSettings.useAutomaticLocation {
                        HStack(spacing: 12) {
                            TextField("Lat", value: $configStore.globalSettings.latitude, format: .number)
                                .textFieldStyle(.roundedBorder)
                            TextField("Lon", value: $configStore.globalSettings.longitude, format: .number)
                                .textFieldStyle(.roundedBorder)
                            Button("Salva") { saveSettings() }
                                .buttonStyle(MinimalButtonStyle(variant: .primary))
                        }
                    } else {
                        HStack {
                            if let coords = LocationService.shared.cachedCoordinates {
                                Text("\(String(format: "%.2f", coords.latitude)), \(String(format: "%.2f", coords.longitude))")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Nessuna posizione")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Aggiorna") { refreshLocation() }
                                .buttonStyle(MinimalButtonStyle())
                        }
                    }
                    
                    Text("Usata per calcolare alba e tramonto.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .minimalCardStyle()
                
                // Debug
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Avanzate")
                    Toggle("Log dettagliati", isOn: $configStore.globalSettings.verboseLogging)
                        .toggleStyle(.switch)
                }
                .minimalCardStyle()
            }
            .padding()
        }
        .background(Color.appBackground)
        .alert("Errore Posizione", isPresented: $showingLocationError) {
            Button("OK", role: .cancel) {}
        } message: { Text(locationErrorMessage) }
        .onChange(of: configStore.globalSettings) { _ in saveSettings() }
    }
    
    // MARK: - Bindings
    
    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchService.isEnabled },
            set: { newValue in
                do {
                    try launchService.setEnabled(newValue)
                    configStore.globalSettings.launchAtLogin = newValue
                    saveSettings()
                } catch { print("Failed to update launch at login: \(error)") }
            }
        )
    }
    
    private func saveSettings() {
        try? configStore.save()
    }
    
    private func refreshLocation() {
        Task {
            do {
                let coords = try await LocationService.shared.getCurrentCoordinates()
                configStore.globalSettings.latitude = coords.latitude
                configStore.globalSettings.longitude = coords.longitude
                saveSettings()
            } catch {
                locationErrorMessage = error.localizedDescription
                showingLocationError = true
            }
        }
    }
}

#Preview {
    GeneralSettingsTab()
        .environmentObject(ConfigurationStore())
        .frame(width: 500, height: 400)
}
