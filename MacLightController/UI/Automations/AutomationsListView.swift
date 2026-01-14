// UI/Automations/AutomationsListView.swift
// MacLightController
//
// Minimal Automation List

import SwiftUI

struct AutomationsListView: View {
    @EnvironmentObject var engine: CoreEngine
    @EnvironmentObject var configStore: ConfigurationStore
    
    @State private var selectedRule: AutomationRule?
    @State private var showingEditor = false
    @State private var editorMode: AutomationEditorMode = .create
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationTitle("Automazioni")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorMode = .create
                    showingEditor = true
                } label: {
                    Label("Aggiungi", systemImage: "plus")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Cerca...")
        .sheet(isPresented: $showingEditor) {
            AutomationEditorView(mode: editorMode) { rule in
                saveRule(rule)
            }
            .environmentObject(engine)
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List(selection: $selectedRule) {
            if filteredRules.isEmpty {
                emptyListState
            } else {
                ForEach(filteredRules) { rule in
                    AutomationListRow(rule: rule)
                        .tag(rule)
                        .contextMenu {
                            Button(rule.isEnabled ? "Disabilita" : "Abilita") {
                                toggleRule(rule)
                            }
                            Divider()
                            Button("Modifica") {
                                editorMode = .edit(rule)
                                showingEditor = true
                            }
                            Button("Elimina", role: .destructive) {
                                deleteRule(rule)
                            }
                        }
                }
            }
        }
    }
    
    private var emptyListState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Nessuna Automazione")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Detail View
    
    @ViewBuilder
    private var detailView: some View {
        if let rule = selectedRule {
            AutomationDetailView(
                rule: rule,
                onEdit: {
                    editorMode = .edit(rule)
                    showingEditor = true
                },
                onDelete: {
                    deleteRule(rule)
                    selectedRule = nil
                },
                onExecute: { executeRule(rule) }
            )
        } else {
            VStack(spacing: 16) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.3))
                Text("Seleziona un'automazione")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var filteredRules: [AutomationRule] {
        if searchText.isEmpty {
            return configStore.automationRules
        }
        return configStore.automationRules.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func saveRule(_ rule: AutomationRule) {
        do {
            if configStore.automationRules.contains(where: { $0.id == rule.id }) {
                try configStore.updateRule(rule)
            } else {
                try configStore.addRule(rule)
            }
        } catch { print("Failed to save: \(error)") }
    }
    
    private func deleteRule(_ rule: AutomationRule) {
        try? configStore.deleteRule(rule.id)
    }
    
    private func toggleRule(_ rule: AutomationRule) {
        try? configStore.toggleRule(rule.id)
    }
    
    private func executeRule(_ rule: AutomationRule) {
        Task { await engine.executeAutomation(rule) }
    }
}

struct AutomationListRow: View {
    let rule: AutomationRule
    
    var body: some View {
        HStack(spacing: 10) {
            StatusIndicator(isActive: rule.isEnabled, size: 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.system(size: 13, weight: .medium))
                Text(rule.trigger.shortDescription)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AutomationDetailView: View {
    let rule: AutomationRule
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onExecute: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        StatusIndicator(isActive: rule.isEnabled)
                        Text(rule.isEnabled ? "Attiva" : "Disattivata")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button("Modifica") { onEdit() }
                    .buttonStyle(MinimalButtonStyle())
            }
            
            Divider()
            
            // Info Cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                InfoCard(title: "Trigger", value: rule.trigger.displayName, icon: "clock")
                InfoCard(title: "Azione", value: rule.action, icon: "bolt")
                InfoCard(title: "Plugin", value: rule.pluginIdentifier, icon: "puzzlepiece")
                InfoCard(title: "Modificata", value: rule.updatedAt.formatted(date: .abbreviated, time: .shortened), icon: "calendar")
            }
            
            Spacer()
            
            // Footer Actions
            HStack {
                Button("Esegui test") { onExecute() }
                    .buttonStyle(MinimalButtonStyle())
                Spacer()
                Button("Elimina") { onDelete() }
                    .buttonStyle(MinimalButtonStyle(variant: .destructive))
            }
        }
        .padding()
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .minimalCardStyle()
    }
}
