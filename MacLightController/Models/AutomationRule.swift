// Models/AutomationRule.swift
// MacLightController
//
// Represents a single automation rule

import Foundation

/// Represents a single automation rule
struct AutomationRule: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var isEnabled: Bool
    var trigger: AutomationTrigger
    var pluginIdentifier: String
    var action: String
    var parameters: [String: AnyCodable]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        isEnabled: Bool = true,
        trigger: AutomationTrigger,
        pluginIdentifier: String,
        action: String,
        parameters: [String: AnyCodable] = [:]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isEnabled = isEnabled
        self.trigger = trigger
        self.pluginIdentifier = pluginIdentifier
        self.action = action
        self.parameters = parameters
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Creates a copy with updated timestamp
    func withUpdatedTimestamp() -> AutomationRule {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }
}

// MARK: - Hashable

extension AutomationRule: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
