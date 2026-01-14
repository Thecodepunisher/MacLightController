// UI/Automations/Components/TimeTriggerConfig.swift
// MacLightController
//
// Time trigger configuration component

import SwiftUI

/// Configuration view for time-based triggers
struct TimeTriggerConfig: View {
    @Binding var hour: Int
    @Binding var minute: Int
    @Binding var selectedDays: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Time Picker
            HStack(spacing: 4) {
                Text("Alle")
                    .foregroundColor(.secondary)

                DatePicker("", selection: Binding(
                    get: {
                        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
                    },
                    set: { newDate in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                        hour = components.hour ?? 0
                        minute = components.minute ?? 0
                    }
                ), displayedComponents: .hourAndMinute)
                .labelsHidden()
            }

            // Day Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Giorni della settimana")
                    .font(.caption)
                    .foregroundColor(.secondary)

                DayOfWeekPicker(selectedDays: $selectedDays, useFullNames: true)

                DayPresetButtons(selectedDays: $selectedDays)

                Text(selectedDays.isEmpty ? "Ogni giorno" : "Giorni selezionati: \(selectedDays.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    TimeTriggerConfig(
        hour: .constant(8),
        minute: .constant(30),
        selectedDays: .constant([2, 3, 4, 5, 6])
    )
    .padding()
}
