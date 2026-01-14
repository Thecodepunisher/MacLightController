// Core/Plugins/PluginProtocol.swift
// MacLightController
//
// Base protocol that all plugins must implement

import Foundation

/// Base protocol that all plugins must implement
protocol PluginProtocol: AnyObject {
    /// Unique identifier for the plugin
    static var identifier: String { get }

    /// Human-readable name of the plugin
    static var displayName: String { get }

    /// Plugin version
    static var version: String { get }

    /// Description of plugin functionality
    static var description: String { get }

    /// Actions supported by this plugin
    static var supportedActions: [PluginAction] { get }

    /// Initialize the plugin
    init() throws

    /// Execute an action with specific parameters
    func execute(action: String, parameters: [String: Any]) async throws

    /// Check if the system supports this plugin
    func checkSystemCompatibility() -> PluginCompatibilityResult

    /// Cleanup when the plugin is unloaded
    func cleanup() async
}

// MARK: - Plugin Action

/// Represents an action that the plugin can execute
struct PluginAction: Identifiable, Codable, Equatable {
    let id: String
    let displayName: String
    let description: String
    let parameters: [PluginParameter]

    init(
        id: String,
        displayName: String,
        description: String,
        parameters: [PluginParameter] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.parameters = parameters
    }
}

// MARK: - Plugin Parameter

/// Parameter for an action
struct PluginParameter: Identifiable, Codable, Equatable {
    let id: String
    let displayName: String
    let type: ParameterType
    let isRequired: Bool
    let defaultValue: AnyCodable?
    let validation: ParameterValidation?

    init(
        id: String,
        displayName: String,
        type: ParameterType,
        isRequired: Bool = true,
        defaultValue: AnyCodable? = nil,
        validation: ParameterValidation? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.type = type
        self.isRequired = isRequired
        self.defaultValue = defaultValue
        self.validation = validation
    }

    enum ParameterType: String, Codable {
        case string
        case integer
        case float
        case boolean
        case time
        case date
        case selection
    }
}

// MARK: - Parameter Validation

/// Validation rules for a parameter
struct ParameterValidation: Codable, Equatable {
    let min: Double?
    let max: Double?
    let options: [String]?
    let pattern: String?

    init(min: Double? = nil, max: Double? = nil, options: [String]? = nil, pattern: String? = nil) {
        self.min = min
        self.max = max
        self.options = options
        self.pattern = pattern
    }
}

// MARK: - Compatibility Result

/// Result of system compatibility check
struct PluginCompatibilityResult {
    let isCompatible: Bool
    let missingRequirements: [String]
    let warnings: [String]

    init(isCompatible: Bool, missingRequirements: [String] = [], warnings: [String] = []) {
        self.isCompatible = isCompatible
        self.missingRequirements = missingRequirements
        self.warnings = warnings
    }

    static var compatible: PluginCompatibilityResult {
        PluginCompatibilityResult(isCompatible: true)
    }

    static func incompatible(reasons: [String]) -> PluginCompatibilityResult {
        PluginCompatibilityResult(isCompatible: false, missingRequirements: reasons)
    }
}

// MARK: - Plugin Info

/// Information about an available plugin
struct PluginInfo: Identifiable, Equatable, Hashable {
    let identifier: String
    let displayName: String
    let version: String
    let description: String
    let actions: [PluginAction]

    var id: String { identifier }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    static func == (lhs: PluginInfo, rhs: PluginInfo) -> Bool {
        lhs.identifier == rhs.identifier
    }
}
