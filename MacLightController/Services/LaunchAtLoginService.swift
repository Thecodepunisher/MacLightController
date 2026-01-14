// Services/LaunchAtLoginService.swift
// MacLightController
//
// Service for managing launch at login functionality

import Foundation
import ServiceManagement
import os.log

/// Service for managing the app's launch at login behavior
@MainActor
final class LaunchAtLoginService: ObservableObject {
    static let shared = LaunchAtLoginService()

    @Published private(set) var isEnabled: Bool = false

    private let logger = Logger(subsystem: "com.maclightcontroller", category: "LaunchAtLoginService")

    private init() {
        refreshStatus()
    }

    /// Refresh the current status
    func refreshStatus() {
        if #available(macOS 13.0, *) {
            isEnabled = SMAppService.mainApp.status == .enabled
        } else {
            // Fallback for older macOS versions
            isEnabled = false
        }
        logger.info("Launch at login status: \(self.isEnabled)")
    }

    /// Enable launch at login
    func enable() throws {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                isEnabled = true
                logger.info("Launch at login enabled")
            } catch {
                logger.error("Failed to enable launch at login: \(error.localizedDescription)")
                throw LaunchAtLoginError.registrationFailed(error)
            }
        } else {
            throw LaunchAtLoginError.unsupportedOS
        }
    }

    /// Disable launch at login
    func disable() throws {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
                isEnabled = false
                logger.info("Launch at login disabled")
            } catch {
                logger.error("Failed to disable launch at login: \(error.localizedDescription)")
                throw LaunchAtLoginError.unregistrationFailed(error)
            }
        } else {
            throw LaunchAtLoginError.unsupportedOS
        }
    }

    /// Toggle launch at login
    func toggle() throws {
        if isEnabled {
            try disable()
        } else {
            try enable()
        }
    }

    /// Set launch at login state
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try enable()
        } else {
            try disable()
        }
    }
}

// MARK: - Errors

enum LaunchAtLoginError: LocalizedError {
    case unsupportedOS
    case registrationFailed(Error)
    case unregistrationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unsupportedOS:
            return "Avvio automatico non supportato su questa versione di macOS"
        case .registrationFailed(let error):
            return "Impossibile abilitare l'avvio automatico: \(error.localizedDescription)"
        case .unregistrationFailed(let error):
            return "Impossibile disabilitare l'avvio automatico: \(error.localizedDescription)"
        }
    }
}
