// UI/MenuBar/Components/AutomationRowCompact.swift
// MacLightController
//
// Compact automation row for menu bar display

import SwiftUI

/// A compact row displaying an automation rule in the menu bar
struct AutomationRowCompact: View {
    let rule: AutomationRule

    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(rule.isEnabled ? Color.green : Color.gray)
                .frame(width: 6, height: 6)

            // Trigger icon
            Image(systemName: triggerIcon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)

            // Name
            Text(rule.name)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            // Trigger time/description
            Text(rule.trigger.shortDescription)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var triggerIcon: String {
        switch rule.trigger {
        case .time:
            return "clock"
        case .sunrise:
            return "sunrise"
        case .sunset:
            return "sunset"
        case .interval:
            return "timer"
        }
    }
}

/// A list of compact automation rows
struct AutomationRowCompactList: View {
    let rules: [AutomationRule]
    let maxItems: Int

    init(rules: [AutomationRule], maxItems: Int = 5) {
        self.rules = rules
        self.maxItems = maxItems
    }

    private var displayedRules: [AutomationRule] {
        Array(rules.prefix(maxItems))
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(displayedRules, id: \.id) { rule in
                AutomationRowCompact(rule: rule)
            }

            if rules.count > maxItems {
                HStack {
                    Spacer()
                    Text("+ \(rules.count - maxItems) altre...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
}

