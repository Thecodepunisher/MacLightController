// Plugins/KeyboardBacklight/KeyboardBacklightError.swift
// MacLightController
//
// Errors specific to keyboard backlight operations

import Foundation

/// Errors that can occur during keyboard backlight operations
enum KeyboardBacklightError: LocalizedError {
    case serviceNotFound
    case connectionFailed(Int32)
    case readFailed(Int32)
    case writeFailed(Int32)
    case invalidParameter(String)
    case unknownAction(String)
    case notSupported
    case brightnessOutOfRange
    case notConnected

    var errorDescription: String? {
        switch self {
        case .serviceNotFound:
            return "Servizio keyboard backlight non trovato. Assicurati di avere un Mac con tastiera retroilluminata."
        case .connectionFailed(let code):
            return "Impossibile connettersi al servizio keyboard (codice: \(code))"
        case .readFailed(let code):
            return "Impossibile leggere luminosità corrente (codice: \(code))"
        case .writeFailed(let code):
            return "Impossibile impostare luminosità (codice: \(code))"
        case .invalidParameter(let param):
            return "Parametro non valido: \(param)"
        case .unknownAction(let action):
            return "Azione sconosciuta: \(action)"
        case .notSupported:
            return "Questa funzionalità non è supportata su questo Mac"
        case .brightnessOutOfRange:
            return "Il valore di luminosità deve essere compreso tra 0.0 e 1.0"
        case .notConnected:
            return "Non connesso al servizio keyboard backlight"
        }
    }
}
