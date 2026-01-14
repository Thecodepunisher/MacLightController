// Core/Storage/ConfigurationStore.swift
// MacLightController
//
// Persistent configuration storage

import Foundation
import os.log

/// Errors that can occur during configuration operations
enum ConfigError: LocalizedError {
    case ruleNotFound
    case saveFailed(Error)
    case loadFailed(Error)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .ruleNotFound:
            return "Regola non trovata"
        case .saveFailed(let error):
            return "Salvataggio fallito: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Caricamento fallito: \(error.localizedDescription)"
        case .invalidData:
            return "Dati non validi"
        }
    }
}

/// Manages persistent storage of configuration
@MainActor
final class ConfigurationStore: ObservableObject {
    @Published var automationRules: [AutomationRule] = []
    @Published var globalSettings: GlobalSettings = GlobalSettings()

    private let logger = Logger(subsystem: "com.maclightcontroller", category: "ConfigurationStore")
    private let userDefaults = UserDefaults.standard
    private let rulesKey = "com.maclightcontroller.rules"
    private let settingsKey = "com.maclightcontroller.settings"

    init() {}

    /// Load configuration from persistent storage
    func load() async throws {
        logger.info("Loading configuration...")

        // Load automation rules
        if let data = userDefaults.data(forKey: rulesKey) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                automationRules = try decoder.decode([AutomationRule].self, from: data)
                logger.info("Loaded \(self.automationRules.count) automation rules")
            } catch {
                logger.error("Failed to decode automation rules: \(error.localizedDescription)")
                throw ConfigError.loadFailed(error)
            }
        }

        // Load global settings
        if let data = userDefaults.data(forKey: settingsKey) {
            do {
                let decoder = JSONDecoder()
                globalSettings = try decoder.decode(GlobalSettings.self, from: data)
                logger.info("Loaded global settings")
            } catch {
                logger.error("Failed to decode global settings: \(error.localizedDescription)")
                // Don't throw, just use defaults
                globalSettings = GlobalSettings()
            }
        }
    }

    /// Save configuration to persistent storage
    func save() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        do {
            let rulesData = try encoder.encode(automationRules)
            userDefaults.set(rulesData, forKey: rulesKey)

            let settingsData = try encoder.encode(globalSettings)
            userDefaults.set(settingsData, forKey: settingsKey)

            logger.info("Configuration saved successfully")
        } catch {
            logger.error("Failed to save configuration: \(error.localizedDescription)")
            throw ConfigError.saveFailed(error)
        }
    }

    // MARK: - Rule Management

    /// Add a new automation rule
    func addRule(_ rule: AutomationRule) throws {
        automationRules.append(rule)
        try save()
        logger.info("Added rule: \(rule.name)")
    }

    /// Update an existing automation rule
    func updateRule(_ rule: AutomationRule) throws {
        guard let index = automationRules.firstIndex(where: { $0.id == rule.id }) else {
            throw ConfigError.ruleNotFound
        }
        let updated = rule.withUpdatedTimestamp()
        automationRules[index] = updated
        try save()
        logger.info("Updated rule: \(rule.name)")
    }

    /// Delete an automation rule
    func deleteRule(_ id: UUID) throws {
        guard automationRules.contains(where: { $0.id == id }) else {
            throw ConfigError.ruleNotFound
        }
        automationRules.removeAll { $0.id == id }
        try save()
        logger.info("Deleted rule: \(id)")
    }

    /// Toggle rule enabled state
    func toggleRule(_ id: UUID) throws {
        guard let index = automationRules.firstIndex(where: { $0.id == id }) else {
            throw ConfigError.ruleNotFound
        }
        automationRules[index].isEnabled.toggle()
        automationRules[index] = automationRules[index].withUpdatedTimestamp()
        try save()
        logger.info("Toggled rule: \(id) -> \(self.automationRules[index].isEnabled)")
    }

    /// Get enabled rules only
    var enabledRules: [AutomationRule] {
        automationRules.filter { $0.isEnabled }
    }

    /// Get rules for a specific plugin
    func rules(forPlugin identifier: String) -> [AutomationRule] {
        automationRules.filter { $0.pluginIdentifier == identifier }
    }

    // MARK: - Settings Management

    /// Update global settings
    func updateSettings(_ settings: GlobalSettings) throws {
        globalSettings = settings
        try save()
        logger.info("Updated global settings")
    }

    // MARK: - Reset

    /// Reset all configuration to defaults
    func reset() throws {
        automationRules = []
        globalSettings = GlobalSettings()
        try save()
        logger.info("Configuration reset to defaults")
    }

    /// Export configuration as JSON data
    func exportConfiguration() throws -> Data {
        struct ExportData: Codable {
            let version: String
            let exportDate: Date
            let rules: [AutomationRule]
            let settings: GlobalSettings
        }

        let exportData = ExportData(
            version: "1.0.0",
            exportDate: Date(),
            rules: automationRules,
            settings: globalSettings
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportData)
    }

    /// Import configuration from JSON data
    func importConfiguration(from data: Data) throws {
        struct ImportData: Codable {
            let version: String
            let rules: [AutomationRule]
            let settings: GlobalSettings
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let importData = try decoder.decode(ImportData.self, from: data)

        automationRules = importData.rules
        globalSettings = importData.settings
        try save()

        logger.info("Imported \(importData.rules.count) rules from configuration")
    }
}
