// UI/MenuBar/MenuBarView.swift
// MacLightController
//
// Main menu bar view - Minimal Design

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var engine: CoreEngine
    @StateObject private var menuState = MenuBarState()
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            
            mainControls
            
            if !engine.activeAutomations.isEmpty {
                Divider()
                automationsList
            }
            
            Divider()
            footerMenu
        }
        .frame(width: 280)
        .background(Color.appContentBackground)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 14))
                Text("MacLightController")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.primary)
            
            Spacer()
            
            StatusIndicator(isActive: engine.isRunning)
                .help(engine.isRunning ? "Motore Attivo" : "Motore Inattivo")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Main Controls
    
    private var mainControls: some View {
        VStack(spacing: 16) {
            // Brightness Slider
            VStack(spacing: 10) {
                HStack {
                    Text("Luminosità")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(Int(menuState.currentBrightness * 100))%")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "sun.min.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Slider(value: $menuState.currentBrightness, in: 0...1)
                        .controlSize(.small)
                        .tint(Color.primary)
                        .onChange(of: menuState.currentBrightness) { newValue in
                            menuState.updateBrightness(newValue)
                        }
                    
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick Toggles
            HStack(spacing: 12) {
                Button {
                    Task { await menuState.turnOn() }
                } label: {
                    Label("Accendi", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(MinimalButtonStyle(variant: .secondary))
                
                Button {
                    Task { await menuState.turnOff() }
                } label: {
                    Label("Spegni", systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(MinimalButtonStyle(variant: .secondary))
            }
            
            // Error State
            if let error = menuState.lastError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.caption2)
                .foregroundColor(.orange)
            }
        }
        .padding(16)
    }
    
    // MARK: - Automations
    
    private var automationsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("Automazioni Attive")
            
            AutomationRowCompactList(
                rules: engine.activeAutomations,
                maxItems: 3
            )
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Footer
    
    private var footerMenu: some View {
        VStack(spacing: 0) {
            MenuButton(title: "Impostazioni...", icon: "gearshape") {
                openSettings()
            }
            
            MenuButton(title: "Automazioni...", icon: "clock") {
                openAutomations()
            }
            
            Divider()
                .padding(.vertical, 4)
            
            MenuButton(title: "Esci", icon: "arrow.right.circle") {
                NSApp.terminate(nil)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    
    private func openSettings() {
        if let window = NSApp.windows.first(where: { $0.title == "Impostazioni" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            NSApp.sendAction(#selector(AppDelegate.openSettings), to: nil, from: nil)
        }
    }
    
    private func openAutomations() {
        if let window = NSApp.windows.first(where: { $0.title == "Automazioni" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            NSApp.sendAction(#selector(AppDelegate.openAutomations), to: nil, from: nil)
        }
    }
}

// MARK: - Components

struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .frame(width: 16)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
            }
        }
        .buttonStyle(MenuBarButtonStyle())
    }
}

#Preview {
    MenuBarView()
        .environmentObject(CoreEngine.shared)
}
