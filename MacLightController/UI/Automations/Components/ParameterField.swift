// UI/Automations/Components/ParameterField.swift
// MacLightController
//
// Dynamic parameter input field component - Minimal Design

import SwiftUI

struct ParameterField: View {
    let parameter: PluginParameter
    @Binding var value: AnyCodable?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            parameterInput
        }
    }
    
    @ViewBuilder
    private var parameterInput: some View {
        switch parameter.type {
        case .string:
            stringField
        case .integer:
            integerField
        case .float:
            floatField
        case .boolean:
            booleanField
        case .time:
            timeField
        case .date:
            dateField
        case .selection:
            selectionField
        }
    }
    
    // MARK: - Field Types
    
    private var stringField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(parameter.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("", text: Binding(
                get: { value?.stringValue ?? "" },
                set: { value = AnyCodable($0) }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }
    
    private var integerField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(parameter.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("", value: Binding(
                get: { value?.intValue ?? 0 },
                set: { value = AnyCodable($0) }
            ), format: .number)
            .textFieldStyle(.roundedBorder)
        }
    }
    
    private var floatField: some View {
        VStack(alignment: .leading, spacing: 8) {
            let floatValue = Binding<Float>(
                get: { value?.floatValue ?? Float(parameter.defaultValue?.floatValue ?? 0) },
                set: { value = AnyCodable(Double($0)) }
            )
            
            if let validation = parameter.validation,
               let min = validation.min,
               let max = validation.max {
                
                HStack {
                    Text(parameter.displayName)
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    if min == 0 && max == 1 {
                        Text("\(Int(floatValue.wrappedValue * 100))%")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    } else {
                        Text(String(format: "%.2f", floatValue.wrappedValue))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
                
                Slider(value: Binding(
                    get: { Double(floatValue.wrappedValue) },
                    set: { floatValue.wrappedValue = Float($0) }
                ), in: min...max)
                .tint(.accentColor)
                
            } else {
                Text(parameter.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("", value: floatValue, format: .number)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    private var booleanField: some View {
        Toggle(isOn: Binding(
            get: { value?.boolValue ?? false },
            set: { value = AnyCodable($0) }
        )) {
            Text(parameter.displayName)
                .font(.system(size: 13))
        }
        .toggleStyle(.switch)
    }
    
    private var timeField: some View {
        HStack {
            Text(parameter.displayName)
                .font(.system(size: 13))
            Spacer()
            DatePicker(
                "",
                selection: Binding(
                    get: { parseTimeValue() },
                    set: { date in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        value = AnyCodable(formatter.string(from: date))
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
        }
    }
    
    private var dateField: some View {
        HStack {
            Text(parameter.displayName)
                .font(.system(size: 13))
            Spacer()
            DatePicker(
                "",
                selection: Binding(
                    get: { parseDateValue() },
                    set: { date in
                        let formatter = ISO8601DateFormatter()
                        value = AnyCodable(formatter.string(from: date))
                    }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
        }
    }
    
    private var selectionField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(parameter.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let options = parameter.validation?.options {
                Picker("", selection: Binding(
                    get: { value?.stringValue ?? options.first ?? "" },
                    set: { value = AnyCodable($0) }
                )) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .labelsHidden()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func parseTimeValue() -> Date {
        if let doubleValue = value?.doubleValue {
            return Date(timeIntervalSince1970: doubleValue)
        }
        if let timeString = value?.stringValue {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            if let timeDate = formatter.date(from: timeString) {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: timeDate)
                return calendar.date(
                    bySettingHour: components.hour ?? 0,
                    minute: components.minute ?? 0,
                    second: 0,
                    of: Date()
                ) ?? Date()
            }
            let isoFormatter = ISO8601DateFormatter()
            if let isoDate = isoFormatter.date(from: timeString) { return isoDate }
        }
        return Date()
    }
    
    private func parseDateValue() -> Date {
        if let doubleValue = value?.doubleValue {
            return Date(timeIntervalSince1970: doubleValue)
        }
        if let dateString = value?.stringValue {
            let isoFormatter = ISO8601DateFormatter()
            if let isoDate = isoFormatter.date(from: dateString) { return isoDate }
        }
        return Date()
    }
}

#Preview {
    VStack(spacing: 16) {
        ParameterField(
            parameter: PluginParameter(
                id: "level",
                displayName: "Livello",
                type: .float,
                isRequired: true,
                defaultValue: AnyCodable(0.5),
                validation: ParameterValidation(min: 0, max: 1)
            ),
            value: .constant(AnyCodable(0.75))
        )

        ParameterField(
            parameter: PluginParameter(
                id: "enabled",
                displayName: "Abilitato",
                type: .boolean,
                isRequired: false,
                defaultValue: AnyCodable(true)
            ),
            value: .constant(AnyCodable(true))
        )
    }
    .padding()
    .frame(width: 300)
}
