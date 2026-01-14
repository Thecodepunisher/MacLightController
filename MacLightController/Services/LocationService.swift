// Services/LocationService.swift
// MacLightController
//
// Service for location management (used for sunrise/sunset calculations)

import Foundation
import CoreLocation
import os.log

/// Service for managing location for sunrise/sunset calculations
@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var lastError: Error?

    private let logger = Logger(subsystem: "com.maclightcontroller", category: "LocationService")
    private let locationManager = CLLocationManager()

    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // We only need rough location
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Authorization

    /// Request location authorization
    func requestAuthorization() {
        logger.info("Requesting location authorization")
        locationManager.requestWhenInUseAuthorization()
    }

    /// Check if location is authorized
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    // MARK: - Location

    /// Request current location
    func requestLocation() async throws -> CLLocation {
        guard isAuthorized else {
            throw LocationError.notAuthorized
        }

        if locationContinuation != nil {
            throw LocationError.requestInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.locationManager.requestLocation()
        }
    }

    /// Get current coordinates (lat, lon)
    func getCurrentCoordinates() async throws -> (latitude: Double, longitude: Double) {
        let location = try await requestLocation()
        return (location.coordinate.latitude, location.coordinate.longitude)
    }

    /// Get cached location if available
    var cachedCoordinates: (latitude: Double, longitude: Double)? {
        guard let location = currentLocation else { return nil }
        return (location.coordinate.latitude, location.coordinate.longitude)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.currentLocation = location
            self.lastError = nil
            self.logger.info("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")

            if let continuation = self.locationContinuation {
                self.locationContinuation = nil
                continuation.resume(returning: location)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = error
            self.logger.error("Location error: \(error.localizedDescription)")

            if let continuation = self.locationContinuation {
                self.locationContinuation = nil
                continuation.resume(throwing: error)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            self.logger.info("Location authorization changed: \(String(describing: manager.authorizationStatus))")
        }
    }
}

// MARK: - Location Errors

enum LocationError: LocalizedError {
    case notAuthorized
    case locationUnavailable
    case timeout
    case requestInProgress

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Accesso alla posizione non autorizzato"
        case .locationUnavailable:
            return "Posizione non disponibile"
        case .timeout:
            return "Timeout richiesta posizione"
        case .requestInProgress:
            return "Richiesta posizione già in corso"
        }
    }
}
