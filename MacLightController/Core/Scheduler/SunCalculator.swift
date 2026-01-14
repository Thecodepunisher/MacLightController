// Core/Scheduler/SunCalculator.swift
// MacLightController
//
// Calculates sunrise and sunset times based on location

import Foundation
import CoreLocation

/// Calculates sunrise and sunset times for a given location
struct SunCalculator {
    private let latitude: Double
    private let longitude: Double
    private let calendar: Calendar

    init(latitude: Double, longitude: Double, calendar: Calendar = .current) {
        self.latitude = latitude
        self.longitude = longitude
        self.calendar = calendar
    }

    init(coordinate: CLLocationCoordinate2D, calendar: Calendar = .current) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.calendar = calendar
    }

    // MARK: - Public Methods

    /// Calculate sunrise time for a given date
    func sunrise(for date: Date) -> Date? {
        calculateSunTime(for: date, isSunrise: true)
    }

    /// Calculate sunset time for a given date
    func sunset(for date: Date) -> Date? {
        calculateSunTime(for: date, isSunrise: false)
    }

    /// Calculate sunrise time with offset in minutes
    func sunrise(for date: Date, offsetMinutes: Int) -> Date? {
        guard let sunrise = sunrise(for: date) else { return nil }
        return calendar.date(byAdding: .minute, value: offsetMinutes, to: sunrise)
    }

    /// Calculate sunset time with offset in minutes
    func sunset(for date: Date, offsetMinutes: Int) -> Date? {
        guard let sunset = sunset(for: date) else { return nil }
        return calendar.date(byAdding: .minute, value: offsetMinutes, to: sunset)
    }

    // MARK: - Private Calculation

    /// Calculate sun time using simplified astronomical algorithm
    private func calculateSunTime(for date: Date, isSunrise: Bool) -> Date? {
        let timeZone = calendar.timeZone
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        // Convert to radians
        let latRad = latitude * .pi / 180

        // Calculate solar declination (simplified)
        let declination = -23.45 * cos(.pi * Double(dayOfYear + 10) / 182.5) * .pi / 180

        // Calculate hour angle
        let cosHourAngle = -tan(latRad) * tan(declination)

        // Check for polar day/night
        if cosHourAngle < -1 || cosHourAngle > 1 {
            return nil // No sunrise/sunset at this latitude on this day
        }

        let hourAngle = acos(cosHourAngle) * 180 / .pi

        // Calculate solar noon
        let solarNoon = 12 - (longitude / 15) - (Double(timeZone.secondsFromGMT()) / 3600.0)

        // Calculate sunrise/sunset time
        let time: Double
        if isSunrise {
            time = solarNoon - (hourAngle / 15)
        } else {
            time = solarNoon + (hourAngle / 15)
        }

        // Convert to Date
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        let hours = Int(time)
        let minutes = Int((time - Double(hours)) * 60)

        components.hour = hours
        components.minute = minutes
        components.second = 0

        return calendar.date(from: components)
    }
}

// MARK: - Default Locations

extension SunCalculator {
    /// Default calculator for Rome, Italy
    static var rome: SunCalculator {
        SunCalculator(latitude: 41.9028, longitude: 12.4964)
    }

    /// Default calculator for Milan, Italy
    static var milan: SunCalculator {
        SunCalculator(latitude: 45.4642, longitude: 9.1900)
    }

    /// Create calculator from optional coordinates
    static func from(latitude: Double?, longitude: Double?) -> SunCalculator? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return SunCalculator(latitude: lat, longitude: lon)
    }
}
