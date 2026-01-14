// Core/Plugins/PluginManager.swift
// MacLightController
//
// Manages plugin loading and lifecycle

import Foundation
import os.log

/// Manages plugin loading, unloading, and lifecycle
final class PluginManager {
    private let logger = Logger(subsystem: "com.maclightcontroller", category: "PluginManager")
    private var loadedPlugins: [String: any PluginProtocol] = [:]
    private let pluginTypes: [any PluginProtocol.Type]

    init() {
        // Register all built-in plugins
        self.pluginTypes = [
            KeyboardBacklightPlugin.self,
            // Future plugins:
            // DisplayBrightnessPlugin.self,
            // AudioVolumePlugin.self,
            // DarkModePlugin.self,
        ]
    }

    /// Load all registered plugins
    func loadPlugins() async throws {
        logger.info("Loading plugins...")

        for pluginType in pluginTypes {
            do {
                let plugin = try pluginType.init()
                let compatibility = plugin.checkSystemCompatibility()

                if compatibility.isCompatible {
                    loadedPlugins[pluginType.identifier] = plugin
                    logger.info("✅ Plugin loaded: \(pluginType.displayName)")

                    if !compatibility.warnings.isEmpty {
                        for warning in compatibility.warnings {
                            logger.warning("⚠️ \(pluginType.displayName): \(warning)")
                        }
                    }
                } else {
                    logger.warning("⚠️ Plugin not compatible: \(pluginType.displayName)")
                    for requirement in compatibility.missingRequirements {
                        logger.warning("   Missing: \(requirement)")
                    }
                }
            } catch {
                logger.error("❌ Failed to load plugin \(pluginType.displayName): \(error.localizedDescription)")
            }
        }

        logger.info("Plugin loading complete. \(self.loadedPlugins.count) plugins active.")
    }

    /// Check if a plugin is loaded
    func hasPlugin(_ identifier: String) -> Bool {
        loadedPlugins[identifier] != nil
    }

    /// Get a loaded plugin by identifier
    func getPlugin(_ identifier: String) throws -> any PluginProtocol {
        guard let plugin = loadedPlugins[identifier] else {
            throw PluginError.notFound(identifier)
        }
        return plugin
    }

    /// Get information about all available plugins
    func getAvailablePlugins() -> [PluginInfo] {
        loadedPlugins.values.map { plugin in
            PluginInfo(
                identifier: type(of: plugin).identifier,
                displayName: type(of: plugin).displayName,
                version: type(of: plugin).version,
                description: type(of: plugin).description,
                actions: type(of: plugin).supportedActions
            )
        }.sorted { $0.displayName < $1.displayName }
    }

    /// Get plugin info by identifier
    func getPluginInfo(_ identifier: String) -> PluginInfo? {
        guard let plugin = loadedPlugins[identifier] else { return nil }
        return PluginInfo(
            identifier: type(of: plugin).identifier,
            displayName: type(of: plugin).displayName,
            version: type(of: plugin).version,
            description: type(of: plugin).description,
            actions: type(of: plugin).supportedActions
        )
    }

    /// Execute an action on a specific plugin
    func executeAction(
        pluginIdentifier: String,
        action: String,
        parameters: [String: Any]
    ) async throws {
        let plugin = try getPlugin(pluginIdentifier)

        do {
            try await plugin.execute(action: action, parameters: parameters)
            logger.info("Action '\(action)' executed on \(pluginIdentifier)")
        } catch {
            logger.error("Action '\(action)' failed on \(pluginIdentifier): \(error.localizedDescription)")
            throw PluginError.executionFailed(action, error)
        }
    }

    /// Unload all plugins
    func unloadAllPlugins() async {
        logger.info("Unloading all plugins...")

        for (identifier, plugin) in loadedPlugins {
            await plugin.cleanup()
            logger.info("Plugin unloaded: \(identifier)")
        }

        loadedPlugins.removeAll()
    }

    /// Unload a specific plugin
    func unloadPlugin(_ identifier: String) async {
        guard let plugin = loadedPlugins[identifier] else { return }
        await plugin.cleanup()
        loadedPlugins.removeValue(forKey: identifier)
        logger.info("Plugin unloaded: \(identifier)")
    }

    /// Reload a specific plugin
    func reloadPlugin(_ identifier: String) async throws {
        await unloadPlugin(identifier)

        guard let pluginType = pluginTypes.first(where: { $0.identifier == identifier }) else {
            throw PluginError.notFound(identifier)
        }

        let plugin = try pluginType.init()
        let compatibility = plugin.checkSystemCompatibility()

        guard compatibility.isCompatible else {
            throw PluginError.incompatible(identifier, compatibility.missingRequirements)
        }

        loadedPlugins[identifier] = plugin
        logger.info("Plugin reloaded: \(identifier)")
    }
}
