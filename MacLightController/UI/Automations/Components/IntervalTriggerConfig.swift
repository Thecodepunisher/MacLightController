// UI/Automations/Components/IntervalTriggerConfig.swift
// MacLightController
//
// Interval trigger configuration component

import SwiftUI

/// Configuration view for interval-based triggers
struct IntervalTriggerConfig: View {
    @Binding var interval: TimeInterval

    private enum IntervalUnit: String, CaseIterable {
        case seconds = "Secondi"
        case minutes = "Minuti"
        case hours = "Ore"

        var multiplier: TimeInterval {
            switch self {
            case .seconds: return 1
            case .minutes: return 60
            case .hours: return 3600
            }
        }
    }

    @State private var value: Double = 30
    @State private var unit: IntervalUnit = .minutes

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Interval picker
            HStack(spacing: 8) {
                Text("Ogni")
                    .foregroundColor(.secondary)

                TextField("", value: $value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .onChange(of: value, perform: { _ in
                        updateInterval()
                    })

                Picker("Unità", selection: $unit) {
                    ForEach(IntervalUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .labelsHidden()
                .frame(width: 100)
                .onChange(of: unit, perform: { _ in
                    updateInterval()
                })
            }

            // Quick interval buttons
            HStack(spacing: 8) {
                QuickIntervalButton(label: "30s", interval: 30, currentInterval: $interval) { syncFromInterval() }
                QuickIntervalButton(label: "1m", interval: 60, currentInterval: $interval) { syncFromInterval() }
                QuickIntervalButton(label: "5m", interval: 300, currentInterval: $interval) { syncFromInterval() }
                QuickIntervalButton(label: "15m", interval: 900, currentInterval: $interval) { syncFromInterval() }
                QuickIntervalButton(label: "1h", interval: 3600, currentInterval: $interval) { syncFromInterval() }
            }

            // Preview
            Text(intervalDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            syncFromInterval()
        }
    }

    private func updateInterval() {
        interval = value * unit.multiplier
    }

    private func syncFromInterval() {
        if interval >= 3600 && interval.truncatingRemainder(dividingBy: 3600) == 0 {
            unit = .hours
            value = interval / 3600
        } else if interval >= 60 && interval.truncatingRemainder(dividingBy: 60) == 0 {
            unit = .minutes
            value = interval / 60
        } else {
            unit = .seconds
            value = interval
        }
    }

    private var intervalDescription: String {
        let seconds = Int(interval)
        if seconds < 60 {
            return "Esegui ogni \(seconds) secondi"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "Esegui ogni \(minutes) minuti"
        } else {
            let hours = seconds / 3600
            let remainingMinutes = (seconds % 3600) / 60
            if remainingMinutes > 0 {
                return "Esegui ogni \(hours) ore e \(remainingMinutes) minuti"
            }
            return "Esegui ogni \(hours) ore"
        }
    }
}

struct QuickIntervalButton: View {
    let label: String
    let interval: TimeInterval
    @Binding var currentInterval: TimeInterval
    let onSelect: () -> Void

    var body: some View {
        Button(label) {
            currentInterval = interval
            onSelect()
        }
        .buttonStyle(.bordered)
        .tint(currentInterval == interval ? .accentColor : .secondary)
    }
}

struct IntervalTriggerConfig_Previews: PreviewProvider {
    static var previews: some View {
        IntervalTriggerConfig(interval: .constant(300))
            .padding()
    }
}
