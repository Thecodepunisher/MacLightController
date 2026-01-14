// UI/Settings/AutomationsTab.swift
// MacLightController
//
// Automations management tab - Minimal Design

import SwiftUI

struct AutomationsTab: View {
    @EnvironmentObject var engine: CoreEngine
    @EnvironmentObject var configStore: ConfigurationStore
    
    @State private var selectedRule: AutomationRule?
    @State private var showingEditor = false
    @State private var editorMode: AutomationEditorMode = .create
    @State private var showingDeleteConfirmation = false
    @State private var ruleToDelete: AutomationRule?
    
    var body: some View {
        HSplitView {
            // List
            automationsList
                .frame(minWidth: 220, maxWidth: 300)
            
            // Detail
            detailView
                .frame(minWidth: 300)
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showingEditor) {
            AutomationEditorView(mode: editorMode) { rule in
                saveRule(rule)
            }
            .environmentObject(engine)
        }
        .confirmationDialog(
            "Elimina Automazione",
            isPresented: $showingDeleteConfirmation,
            presenting: ruleToDelete
        ) { rule in
            Button("Elimina", role: .destructive) { deleteRule(rule) }
            Button("Annulla", role: .cancel) {}
        } message: { rule in
            Text("Eliminare definitivamente '\(rule.name)'?")
        }
    }
    
    // MARK: - List
    
    private var automationsList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Regole")
                    .font(.headline)
                Spacer()
                Button {
                    editorMode = .create
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(MinimalButtonStyle(variant: .secondary))
            }
            .padding()
            .background(Color.appContentBackground)
            
            Divider()
            
            if configStore.automationRules.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Nessuna regola")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(selection: $selectedRule) {
                    ForEach(configStore.automationRules) { rule in
                        AutomationListRow(rule: rule)
                            .tag(rule)
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .contextMenu {
                                Button("Modifica") {
                                    editorMode = .edit(rule)
                                    showingEditor = true
                                }
                                Button(rule.isEnabled ? "Disabilita" : "Abilita") {
                                    toggleRule(rule)
                                }
                                Divider()
                                Button("Elimina", role: .destructive) {
                                    ruleToDelete = rule
                                    showingDeleteConfirmation = true
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color.appContentBackground)
    }
    
    // MARK: - Detail
    
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
                    ruleToDelete = rule
                    showingDeleteConfirmation = true
                },
                onExecute: { executeRule(rule) }
            )
            .padding()
            .background(Color.appBackground)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary.opacity(0.3))
                Text("Seleziona una regola")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
        }
    }
    
    // MARK: - Actions
    
    private func saveRule(_ rule: AutomationRule) {
        do {
            if configStore.automationRules.contains(where: { $0.id == rule.id }) {
                try configStore.updateRule(rule)
            } else {
                try configStore.addRule(rule)
            }
        } catch { print("Error saving rule: \(error)") }
    }
    
    private func deleteRule(_ rule: AutomationRule) {
        try? configStore.deleteRule(rule.id)
        if selectedRule?.id == rule.id { selectedRule = nil }
    }
    
    private func toggleRule(_ rule: AutomationRule) {
        try? configStore.toggleRule(rule.id)
    }
    
    private func executeRule(_ rule: AutomationRule) {
        Task { await engine.executeAutomation(rule) }
    }
}


#Preview {
    AutomationsTab()
        .environmentObject(CoreEngine.shared)
        .environmentObject(ConfigurationStore())
        .frame(width: 600, height: 400)
}
