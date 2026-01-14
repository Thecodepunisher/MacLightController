// Core/Storage/GlobalSettings.swift
// MacLightController
//
// Global application settings

import Foundation

/// Global settings for the application
struct GlobalSettings: Codable, Equatable {
    var launchAtLogin: Bool = false
    var showInMenuBar: Bool = true
    var showInDock: Bool = false
    var notificationsEnabled: Bool = true
    var soundsEnabled: Bool = false

    // Location for sunrise/sunset calculations
    var latitude: Double?
    var longitude: Double?
    var useAutomaticLocation: Bool = true

    // Debug settings
    var verboseLogging: Bool = false

    init() {}

    /// Check if location is configured
    var hasLocation: Bool {
        if useAutomaticLocation {
            return true // Will use CoreLocation
        }
        return latitude != nil && longitude != nil
    }

    /// Get coordinates if available
    var coordinates: (latitude: Double, longitude: Double)? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return (lat, lon)
    }
}
