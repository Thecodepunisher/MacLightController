// UI/MenuBar/MenuBarState.swift
// MacLightController
//
// State management for the menu bar

import SwiftUI
import Combine

/// State management for the menu bar view
@MainActor
final class MenuBarState: ObservableObject {
    @Published var currentBrightness: Float = 0.0
    @Published var isUpdatingBrightness: Bool = false
    @Published var lastError: String?
    @Published var isPluginAvailable: Bool = false
    @Published var isHardwareAvailable: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var brightnessUpdateTask: Task<Void, Never>?

    init() {
        loadCurrentBrightness()
        CoreEngine.shared.$isRunning
            .receive(on: RunLoop.main)
            .sink { [weak self] isRunning in
                guard isRunning else { return }
                self?.loadCurrentBrightness()
            }
            .store(in: &cancellables)
    }

    /// Load the current brightness from the plugin
    func loadCurrentBrightness() {
        Task {
            do {
                let plugin = try CoreEngine.shared.pluginManager.getPlugin(KeyboardBacklightPlugin.identifier)
                if let kbPlugin = plugin as? KeyboardBacklightPlugin {
                    currentBrightness = kbPlugin.brightness
                    isPluginAvailable = true
                    isHardwareAvailable = kbPlugin.hardwareAvailable
                }
            } catch {
                // Plugin not available, use default
                currentBrightness = 0.0
                isPluginAvailable = false
                isHardwareAvailable = false
            }
        }
    }

    /// Update brightness with debouncing for slider
    func updateBrightness(_ value: Float) {
        brightnessUpdateTask?.cancel()
        brightnessUpdateTask = Task {
            // Small delay for debouncing
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

            guard !Task.isCancelled else { return }

            isUpdatingBrightness = true
            defer { isUpdatingBrightness = false }

            do {
                try await CoreEngine.shared.executeQuickAction(
                    pluginIdentifier: KeyboardBacklightPlugin.identifier,
                    action: "setBrightness",
                    parameters: ["level": value]
                )
                lastError = nil
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    /// Turn on keyboard backlight
    func turnOn() async {
        do {
            try await CoreEngine.shared.executeQuickAction(
                pluginIdentifier: KeyboardBacklightPlugin.identifier,
                action: "turnOn",
                parameters: [:]
            )
            currentBrightness = 1.0
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Turn off keyboard backlight
    func turnOff() async {
        do {
            try await CoreEngine.shared.executeQuickAction(
                pluginIdentifier: KeyboardBacklightPlugin.identifier,
                action: "turnOff",
                parameters: [:]
            )
            currentBrightness = 0.0
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Toggle keyboard backlight
    func toggle() async {
        do {
            try await CoreEngine.shared.executeQuickAction(
                pluginIdentifier: KeyboardBacklightPlugin.identifier,
                action: "toggle",
                parameters: [:]
            )
            currentBrightness = currentBrightness > 0.1 ? 0.0 : 1.0
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}

// MARK: - Quick Action Types

enum QuickAction {
    case turnOn
    case turnOff
    case toggle
    case setBrightness(Float)

    var actionName: String {
        switch self {
        case .turnOn: return "turnOn"
        case .turnOff: return "turnOff"
        case .toggle: return "toggle"
        case .setBrightness: return "setBrightness"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .setBrightness(let level):
            return ["level": level]
        default:
            return [:]
        }
    }
}
