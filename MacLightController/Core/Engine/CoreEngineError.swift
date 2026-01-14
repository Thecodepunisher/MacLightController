// Core/Engine/CoreEngineError.swift
// MacLightController
//
// Errors related to core engine operations

import Foundation

/// Errors that can occur in the core engine
enum CoreEngineError: LocalizedError {
    case alreadyRunning
    case notRunning
    case pluginNotFound(String)
    case schedulerError(Error)
    case configurationError(Error)

    var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            return "Il motore è già in esecuzione"
        case .notRunning:
            return "Il motore non è in esecuzione"
        case .pluginNotFound(let identifier):
            return "Plugin non trovato: \(identifier)"
        case .schedulerError(let error):
            return "Errore scheduler: \(error.localizedDescription)"
        case .configurationError(let error):
            return "Errore configurazione: \(error.localizedDescription)"
        }
    }
}
