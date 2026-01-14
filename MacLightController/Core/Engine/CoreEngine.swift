// Core/Engine/CoreEngine.swift
// MacLightController
//
// Main orchestrator for the application

import Foundation
import Combine
import os.log

/// Main orchestrator that coordinates all modules
@MainActor
final class CoreEngine: ObservableObject {
    static let shared = CoreEngine()

    @Published private(set) var isRunning: Bool = false
    @Published private(set) var activeAutomations: [AutomationRule] = []

    let scheduler: SchedulerService
    let pluginManager: PluginManager
    let configStore: ConfigurationStore

    private let logger = Logger(subsystem: "com.maclightcontroller", category: "CoreEngine")
    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.scheduler = SchedulerService()
        self.pluginManager = PluginManager()
        self.configStore = ConfigurationStore()

        setupObservers()
    }

    // MARK: - Lifecycle

    /// Start the engine
    func start() async throws {
        guard !isRunning else {
            logger.warning("Engine already running")
            return
        }

        logger.info("Starting MacLightController engine...")

        // 1. Load configuration
        do {
            try await configStore.load()
            logger.info("Configuration loaded")
        } catch {
            logger.error("Failed to load configuration: \(error.localizedDescription)")
            throw CoreEngineError.configurationError(error)
        }

        // 2. Initialize plugins
        do {
            try await pluginManager.loadPlugins()
            logger.info("Plugins initialized")
        } catch {
            logger.error("Failed to load plugins: \(error.localizedDescription)")
            // Continue anyway, some plugins might have loaded
        }

        // 2b. Ensure keyboard backlight starts off
        if pluginManager.hasPlugin(KeyboardBacklightPlugin.identifier) {
            do {
                try await pluginManager.executeAction(
                    pluginIdentifier: KeyboardBacklightPlugin.identifier,
                    action: "setBrightness",
                    parameters: ["level": Float(0.0)]
                )
                logger.info("Keyboard backlight set to 0 on startup")
            } catch {
                logger.error("Failed to set keyboard backlight on startup: \(error.localizedDescription)")
            }
        }

        // 3. Update scheduler with location if available
        if let coords = configStore.globalSettings.coordinates {
            scheduler.updateLocation(latitude: coords.latitude, longitude: coords.longitude)
        }

        // 4. Start scheduler
        scheduler.start()
        logger.info("Scheduler started")

        // 5. Register saved automations
        for rule in configStore.enabledRules {
            do {
                try await registerAutomation(rule)
            } catch {
                logger.error("Failed to register automation '\(rule.name)': \(error.localizedDescription)")
            }
        }

        isRunning = true
        logger.info("MacLightController engine started successfully")
    }

    /// Stop the engine
    func stop() async {
        guard isRunning else { return }

        logger.info("Stopping MacLightController engine...")

        scheduler.stop()
        await pluginManager.unloadAllPlugins()
        activeAutomations.removeAll()

        isRunning = false
        logger.info("MacLightController engine stopped")
    }

    /// Restart the engine
    func restart() async throws {
        await stop()
        try await start()
    }

    // MARK: - Automation Management

    /// Register a new automation
    func registerAutomation(_ rule: AutomationRule) async throws {
        // Validate that the plugin exists
        guard pluginManager.hasPlugin(rule.pluginIdentifier) else {
            throw CoreEngineError.pluginNotFound(rule.pluginIdentifier)
        }

        // Register with scheduler
        scheduler.schedule(rule) { [weak self] in
            await self?.executeAutomation(rule)
        }

        // Add to active list if not already present
        if !activeAutomations.contains(where: { $0.id == rule.id }) {
            activeAutomations.append(rule)
        }

        logger.info("Registered automation: \(rule.name)")
    }

    /// Unregister an automation
    func unregisterAutomation(_ ruleId: UUID) {
        scheduler.unschedule(ruleId)
        activeAutomations.removeAll { $0.id == ruleId }
        logger.info("Unregistered automation: \(ruleId)")
    }

    /// Update an existing automation
    func updateAutomation(_ rule: AutomationRule) async throws {
        // Validate plugin
        guard pluginManager.hasPlugin(rule.pluginIdentifier) else {
            throw CoreEngineError.pluginNotFound(rule.pluginIdentifier)
        }

        // Update in scheduler
        scheduler.updateSchedule(rule)

        // Update in active list
        if let index = activeAutomations.firstIndex(where: { $0.id == rule.id }) {
            activeAutomations[index] = rule
        }

        // Update in config store
        try configStore.updateRule(rule)

        logger.info("Updated automation: \(rule.name)")
    }

    /// Execute an automation immediately
    func executeAutomation(_ rule: AutomationRule) async {
        logger.info("Executing automation: \(rule.name)")

        do {
            let plugin = try pluginManager.getPlugin(rule.pluginIdentifier)

            // Convert AnyCodable parameters to [String: Any]
            let params = rule.parameters.mapValues { $0.value }

            try await plugin.execute(action: rule.action, parameters: params)

            logger.info("Automation executed successfully: \(rule.name)")

            // Send notification if enabled
            if configStore.globalSettings.notificationsEnabled {
                await NotificationService.shared.sendSuccess(
                    title: "Automazione Eseguita",
                    message: rule.name
                )
            }
        } catch {
            logger.error("Automation failed: \(rule.name) - \(error.localizedDescription)")

            // Send error notification
            if configStore.globalSettings.notificationsEnabled {
                await NotificationService.shared.sendError(
                    title: "Automazione Fallita",
                    message: "\(rule.name): \(error.localizedDescription)"
                )
            }
        }
    }

    /// Execute a quick action (not a saved automation)
    func executeQuickAction(pluginIdentifier: String, action: String, parameters: [String: Any] = [:]) async throws {
        logger.info("Executing quick action: \(action) on \(pluginIdentifier)")

        try await pluginManager.executeAction(
            pluginIdentifier: pluginIdentifier,
            action: action,
            parameters: parameters
        )
    }

    // MARK: - Plugin Access

    /// Get available plugins
    func getAvailablePlugins() -> [PluginInfo] {
        pluginManager.getAvailablePlugins()
    }

    /// Get plugin info
    func getPluginInfo(_ identifier: String) -> PluginInfo? {
        pluginManager.getPluginInfo(identifier)
    }

    // MARK: - Private

    private func setupObservers() {
        // Observe configuration changes
        configStore.$automationRules
            .dropFirst()
            .sink { [weak self] rules in
                Task { @MainActor in
                    await self?.syncAutomations(with: rules)
                }
            }
            .store(in: &cancellables)

        // Observe location changes
        configStore.$globalSettings
            .dropFirst()
            .sink { [weak self] settings in
                if let coords = settings.coordinates {
                    self?.scheduler.updateLocation(latitude: coords.latitude, longitude: coords.longitude)
                }
            }
            .store(in: &cancellables)
    }

    private func syncAutomations(with rules: [AutomationRule]) async {
        // Find rules to remove
        let currentIds = Set(activeAutomations.map { $0.id })
        let newIds = Set(rules.filter { $0.isEnabled }.map { $0.id })

        // Remove old rules
        for id in currentIds.subtracting(newIds) {
            unregisterAutomation(id)
        }

        // Add/update new rules
        for rule in rules where rule.isEnabled {
            if activeAutomations.contains(where: { $0.id == rule.id }) {
                // Update existing
                scheduler.updateSchedule(rule)
                if let index = activeAutomations.firstIndex(where: { $0.id == rule.id }) {
                    activeAutomations[index] = rule
                }
            } else {
                // Add new
                do {
                    try await registerAutomation(rule)
                } catch {
                    logger.error("Failed to register automation: \(error.localizedDescription)")
                }
            }
        }
    }
}
