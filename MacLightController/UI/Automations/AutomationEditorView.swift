// UI/Automations/AutomationEditorView.swift
// MacLightController
//
// Minimal Automation Editor

import SwiftUI

struct AutomationEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var engine: CoreEngine
    
    let mode: AutomationEditorMode
    let onSave: (AutomationRule) -> Void
    
    // State
    @State private var name: String = ""
    @State private var isEnabled: Bool = true
    @State private var triggerType: TriggerType = .time
    
    // Trigger Data
    @State private var hour: Int = 8
    @State private var minute: Int = 0
    @State private var selectedDays: Set<Int> = []
    @State private var sunOffset: Int = 0
    @State private var interval: TimeInterval = 300
    
    // Action Data
    // Defaulting to KeyboardBacklightPlugin since it's the main use case
    @State private var selectedPlugin: String = KeyboardBacklightPlugin.identifier
    @State private var selectedAction: String = "turnOn"
    @State private var parameters: [String: AnyCodable] = [:]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 16) {
                        TextField("Nome Automazione", text: $name)
                            .font(.system(size: 18, weight: .semibold))
                            .textFieldStyle(.plain)
                            .padding(.bottom, 4)
                            .overlay(Rectangle().frame(height: 1).padding(.top, 30).foregroundColor(.secondary.opacity(0.2)), alignment: .bottom)
                        
                        HStack {
                            Text("Stato")
                            Spacer()
                            Toggle("", isOn: $isEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                    }
                    .minimalCardStyle()
                    
                    // Trigger Card
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader("Quando")
                        
                        Picker("", selection: $triggerType) {
                            ForEach(TriggerType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        
                        triggerConfigView
                            .padding(.top, 8)
                    }
                    .minimalCardStyle()
                    
                    // Action Card
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader("Fai questo")
                        
                        if let pluginInfo = engine.getPluginInfo(selectedPlugin) {
                            // Simplified Action Picker
                            HStack {
                                Text("Azione")
                                Spacer()
                                Picker("", selection: $selectedAction) {
                                    ForEach(pluginInfo.actions) { action in
                                        Text(action.displayName).tag(action.id)
                                    }
                                }
                                .labelsHidden()
                                .fixedSize()
                            }
                            
                            Divider()
                            
                            // Parameters
                            if let action = pluginInfo.actions.first(where: { $0.id == selectedAction }) {
                                parametersView(for: action)
                            }
                        }
                    }
                    .minimalCardStyle()
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle(mode.isCreate ? "Nuova Regola" : "Modifica Regola")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { saveAutomation() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { loadExistingRule() }
        }
        .frame(width: 450, height: 600)
    }
    
    // MARK: - Views
    
    @ViewBuilder
    private var triggerConfigView: some View {
        switch triggerType {
        case .time:
            TimeTriggerConfig(
                hour: $hour,
                minute: $minute,
                selectedDays: $selectedDays
            )
        case .sunrise, .sunset:
            SunTriggerConfig(offset: $sunOffset)
        case .interval:
            IntervalTriggerConfig(interval: $interval)
        }
    }
    
    @ViewBuilder
    private func parametersView(for action: PluginAction) -> some View {
        if !action.parameters.isEmpty {
            VStack(spacing: 16) {
                ForEach(action.parameters) { param in
                    ParameterField(
                        parameter: param,
                        value: Binding(
                            get: { parameters[param.id] ?? param.defaultValue },
                            set: { parameters[param.id] = $0 }
                        )
                    )
                }
            }
        } else {
            Text("Nessuna configurazione necessaria")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Logic
    
    private func loadExistingRule() {
        guard let rule = mode.existingRule else { return }
        name = rule.name
        isEnabled = rule.isEnabled
        selectedPlugin = rule.pluginIdentifier
        selectedAction = rule.action
        parameters = rule.parameters
        
        switch rule.trigger {
        case .time(let t):
            triggerType = .time
            hour = t.hour
            minute = t.minute
            selectedDays = t.daysOfWeek
        case .sunrise(let o):
            triggerType = .sunrise
            sunOffset = o
        case .sunset(let o):
            triggerType = .sunset
            sunOffset = o
        case .interval(let s):
            triggerType = .interval
            interval = s
        }
    }
    
    private func saveAutomation() {
        let rule = AutomationRule(
            id: mode.existingRule?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            description: "", // Simplified out
            isEnabled: isEnabled,
            trigger: buildTrigger(),
            pluginIdentifier: selectedPlugin,
            action: selectedAction,
            parameters: parameters
        )
        onSave(rule)
        dismiss()
    }
    
    private func buildTrigger() -> AutomationTrigger {
        switch triggerType {
        case .time:
            return .time(ScheduleTime(hour: hour, minute: minute, daysOfWeek: selectedDays))
        case .sunrise:
            return .sunrise(offsetMinutes: sunOffset)
        case .sunset:
            return .sunset(offsetMinutes: sunOffset)
        case .interval:
            return .interval(seconds: interval)
        }
    }
}

// MARK: - Editor Mode

enum AutomationEditorMode {
    case create
    case edit(AutomationRule)
    
    var isCreate: Bool {
        if case .create = self { return true }
        return false
    }
    
    var existingRule: AutomationRule? {
        if case .edit(let rule) = self { return rule }
        return nil
    }
}

