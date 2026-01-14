// UI/Settings/PluginsTab.swift
// MacLightController
//
// Plugin management tab - Minimal Design

import SwiftUI

struct PluginsTab: View {
    @EnvironmentObject var engine: CoreEngine
    @State private var selectedPlugin: PluginInfo?
    
    var body: some View {
        HSplitView {
            // List
            pluginsList
                .frame(minWidth: 220, maxWidth: 300)
            
            // Detail
            pluginDetail
                .frame(minWidth: 300)
        }
        .background(Color.appBackground)
    }
    
    // MARK: - List
    
    private var pluginsList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Plugin")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color.appContentBackground)
            
            Divider()
            
            List(selection: $selectedPlugin) {
                ForEach(engine.getAvailablePlugins()) { plugin in
                    PluginListRow(plugin: plugin)
                        .tag(plugin)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
            }
            .listStyle(.plain)
        }
        .background(Color.appContentBackground)
    }
    
    // MARK: - Detail
    
    @ViewBuilder
    private var pluginDetail: some View {
        if let plugin = selectedPlugin {
            PluginDetailView(plugin: plugin)
                .padding()
                .background(Color.appBackground)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "puzzlepiece.extension")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary.opacity(0.3))
                Text("Seleziona un plugin")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
        }
    }
}

struct PluginListRow: View {
    let plugin: PluginInfo
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconForPlugin(plugin.identifier))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.displayName)
                    .font(.system(size: 13, weight: .medium))
                Text("v\(plugin.version)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func iconForPlugin(_ identifier: String) -> String {
        identifier == KeyboardBacklightPlugin.identifier ? "keyboard" : "puzzlepiece.extension"
    }
}

struct PluginDetailView: View {
    let plugin: PluginInfo
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plugin.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(plugin.identifier)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("Attivo")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(plugin.description)
                        .foregroundColor(.secondary)
                }
                .minimalCardStyle()
                
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Azioni Disponibili")
                    
                    ForEach(plugin.actions) { action in
                        PluginActionCard(action: action)
                    }
                }
            }
        }
    }
}

struct PluginActionCard: View {
    let action: PluginAction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(action.displayName)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(action.id)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Text(action.description)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            if !action.parameters.isEmpty {
                Divider()
                    .padding(.vertical, 4)
                
                Text("Parametri:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                ForEach(action.parameters) { param in
                    HStack {
                        Text("• \(param.displayName)")
                            .font(.caption)
                        Spacer()
                        if param.isRequired {
                            Text("Richiesto")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .minimalCardStyle()
    }
}

#Preview {
    PluginsTab()
        .environmentObject(CoreEngine.shared)
        .frame(width: 600, height: 400)
}
