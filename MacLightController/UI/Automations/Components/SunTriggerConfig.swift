// UI/Automations/Components/SunTriggerConfig.swift
// MacLightController
//
// Sun-based trigger configuration component

import SwiftUI

/// Configuration view for sunrise/sunset triggers
struct SunTriggerConfig: View {
    @Binding var offset: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Offset picker
            HStack(spacing: 8) {
                Text("Offset:")
                    .foregroundColor(.secondary)

                Picker("Direzione", selection: Binding(
                    get: { offset >= 0 },
                    set: { isPositive in
                        offset = isPositive ? abs(offset) : -abs(offset)
                    }
                )) {
                    Text("Prima").tag(false)
                    Text("Dopo").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)

                Stepper(
                    value: Binding(
                        get: { abs(offset) },
                        set: { newValue in
                            offset = offset >= 0 ? newValue : -newValue
                        }
                    ),
                    in: 0...120,
                    step: 5
                ) {
                    Text("\(abs(offset)) minuti")
                        .monospacedDigit()
                }
            }

            // Quick offset buttons
            HStack(spacing: 8) {
                OffsetButton(label: "0m", value: 0, currentOffset: $offset)
                OffsetButton(label: "-30m", value: -30, currentOffset: $offset)
                OffsetButton(label: "-15m", value: -15, currentOffset: $offset)
                OffsetButton(label: "+15m", value: 15, currentOffset: $offset)
                OffsetButton(label: "+30m", value: 30, currentOffset: $offset)
            }

            // Preview
            Text(offsetDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var offsetDescription: String {
        if offset == 0 {
            return "Esattamente all'ora dell'evento"
        } else if offset > 0 {
            return "\(offset) minuti dopo l'evento"
        } else {
            return "\(abs(offset)) minuti prima dell'evento"
        }
    }
}

struct OffsetButton: View {
    let label: String
    let value: Int
    @Binding var currentOffset: Int

    var body: some View {
        Button(label) {
            currentOffset = value
        }
        .buttonStyle(.bordered)
        .tint(currentOffset == value ? .accentColor : .secondary)
    }
}

#Preview {
    SunTriggerConfig(offset: .constant(-15))
        .padding()
}
