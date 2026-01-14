// Core/Plugins/PluginError.swift
// MacLightController
//
// Errors related to plugin operations

import Foundation

/// Errors that can occur during plugin operations
enum PluginError: LocalizedError {
    case notFound(String)
    case initializationFailed(String, Error)
    case actionNotSupported(String)
    case invalidParameters(String)
    case executionFailed(String, Error)
    case incompatible(String, [String])

    var errorDescription: String? {
        switch self {
        case .notFound(let identifier):
            return "Plugin non trovato: \(identifier)"
        case .initializationFailed(let identifier, let error):
            return "Inizializzazione plugin '\(identifier)' fallita: \(error.localizedDescription)"
        case .actionNotSupported(let action):
            return "Azione non supportata: \(action)"
        case .invalidParameters(let details):
            return "Parametri non validi: \(details)"
        case .executionFailed(let action, let error):
            return "Esecuzione '\(action)' fallita: \(error.localizedDescription)"
        case .incompatible(let identifier, let reasons):
            return "Plugin '\(identifier)' non compatibile: \(reasons.joined(separator: ", "))"
        }
    }
}
