// UI/Shared/DayToggle.swift
// MacLightController
//
// Toggle button for day selection

import SwiftUI

/// A circular toggle button for selecting a day of the week
struct DayToggle: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

/// A row of day toggles for selecting days of the week
struct DayOfWeekPicker: View {
    @Binding var selectedDays: Set<Int>

    private let days: [(Int, String)] = [
        (1, "D"),  // Sunday
        (2, "L"),  // Monday
        (3, "M"),  // Tuesday
        (4, "M"),  // Wednesday
        (5, "G"),  // Thursday
        (6, "V"),  // Friday
        (7, "S")   // Saturday
    ]

    private let fullDayNames: [(Int, String)] = [
        (1, "Dom"),
        (2, "Lun"),
        (3, "Mar"),
        (4, "Mer"),
        (5, "Gio"),
        (6, "Ven"),
        (7, "Sab")
    ]

    var useFullNames: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(useFullNames ? fullDayNames : days, id: \.0) { day in
                DayToggle(
                    label: day.1,
                    isSelected: selectedDays.contains(day.0)
                ) {
                    toggleDay(day.0)
                }
            }
        }
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

/// Quick selection buttons for common day patterns
struct DayPresetButtons: View {
    @Binding var selectedDays: Set<Int>

    var body: some View {
        HStack(spacing: 8) {
            PresetButton(title: "Tutti", isSelected: selectedDays.isEmpty) {
                selectedDays = []
            }

            PresetButton(title: "Feriali", isSelected: selectedDays == [2, 3, 4, 5, 6]) {
                selectedDays = [2, 3, 4, 5, 6]
            }

            PresetButton(title: "Weekend", isSelected: selectedDays == [1, 7]) {
                selectedDays = [1, 7]
            }
        }
    }
}

private struct PresetButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        DayOfWeekPicker(selectedDays: .constant([2, 4, 6]))

        DayOfWeekPicker(selectedDays: .constant([1, 7]), useFullNames: true)

        DayPresetButtons(selectedDays: .constant([2, 3, 4, 5, 6]))
    }
    .padding()
}
