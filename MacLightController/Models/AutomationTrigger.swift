// Models/AutomationTrigger.swift
// MacLightController
//
// Supported trigger types for automations

import Foundation

/// Types of triggers supported by the scheduler
enum AutomationTrigger: Codable, Equatable, Hashable {
    /// Trigger at a specific time
    case time(ScheduleTime)

    /// Trigger at sunrise (with offset in minutes)
    case sunrise(offsetMinutes: Int)

    /// Trigger at sunset (with offset in minutes)
    case sunset(offsetMinutes: Int)

    /// Trigger at regular intervals
    case interval(seconds: TimeInterval)

    var displayName: String {
        switch self {
        case .time(let schedule):
            let dayString = schedule.daysOfWeek.isEmpty ? "Ogni giorno" : schedule.daysOfWeekDescription
            return String(format: "%02d:%02d - %@", schedule.hour, schedule.minute, dayString)
        case .sunrise(let offset):
            if offset == 0 { return "Alba" }
            return offset > 0 ? "Alba +\(offset)min" : "Alba \(offset)min"
        case .sunset(let offset):
            if offset == 0 { return "Tramonto" }
            return offset > 0 ? "Tramonto +\(offset)min" : "Tramonto \(offset)min"
        case .interval(let seconds):
            if seconds < 60 { return "Ogni \(Int(seconds))s" }
            if seconds < 3600 { return "Ogni \(Int(seconds / 60))min" }
            return "Ogni \(Int(seconds / 3600))h"
        }
    }

    var shortDescription: String {
        switch self {
        case .time(let schedule):
            return String(format: "%02d:%02d", schedule.hour, schedule.minute)
        case .sunrise(let offset):
            if offset == 0 { return "🌅 Alba" }
            return offset > 0 ? "🌅 +\(offset)m" : "🌅 \(offset)m"
        case .sunset(let offset):
            if offset == 0 { return "🌇 Tramonto" }
            return offset > 0 ? "🌇 +\(offset)m" : "🌇 \(offset)m"
        case .interval(let seconds):
            if seconds < 60 { return "⏱ \(Int(seconds))s" }
            if seconds < 3600 { return "⏱ \(Int(seconds / 60))m" }
            return "⏱ \(Int(seconds / 3600))h"
        }
    }
}

// MARK: - Schedule Time Model

/// Represents a specific time for scheduling
struct ScheduleTime: Codable, Equatable, Hashable {
    let hour: Int       // 0-23
    let minute: Int     // 0-59
    let daysOfWeek: Set<Int>  // 1-7 (Sunday = 1, Saturday = 7)

    init(hour: Int, minute: Int, daysOfWeek: Set<Int> = []) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
        self.daysOfWeek = daysOfWeek
    }

    /// Creates a daily schedule at the specified time
    static func daily(hour: Int, minute: Int) -> ScheduleTime {
        ScheduleTime(hour: hour, minute: minute, daysOfWeek: [])
    }

    /// Creates a weekday-only schedule (Monday-Friday)
    static func weekdays(hour: Int, minute: Int) -> ScheduleTime {
        ScheduleTime(hour: hour, minute: minute, daysOfWeek: [2, 3, 4, 5, 6])
    }

    /// Creates a weekend-only schedule (Saturday-Sunday)
    static func weekends(hour: Int, minute: Int) -> ScheduleTime {
        ScheduleTime(hour: hour, minute: minute, daysOfWeek: [1, 7])
    }

    /// Human-readable description of selected days
    var daysOfWeekDescription: String {
        if daysOfWeek.isEmpty {
            return "Ogni giorno"
        }

        let weekdays: Set<Int> = [2, 3, 4, 5, 6]
        let weekends: Set<Int> = [1, 7]

        if daysOfWeek == weekdays {
            return "Giorni feriali"
        }
        if daysOfWeek == weekends {
            return "Fine settimana"
        }

        let dayNames = ["", "Dom", "Lun", "Mar", "Mer", "Gio", "Ven", "Sab"]
        let sortedDays = daysOfWeek.sorted()
        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }

    /// Checks if this schedule should trigger on the given weekday
    func shouldTriggerOn(weekday: Int) -> Bool {
        daysOfWeek.isEmpty || daysOfWeek.contains(weekday)
    }
}

// MARK: - Trigger Type Enum (for UI)

/// Simplified trigger type for UI selection
enum TriggerType: String, CaseIterable, Identifiable {
    case time
    case sunrise
    case sunset
    case interval

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .time: return "Orario Specifico"
        case .sunrise: return "Alba"
        case .sunset: return "Tramonto"
        case .interval: return "Intervallo"
        }
    }

    var icon: String {
        switch self {
        case .time: return "clock"
        case .sunrise: return "sunrise"
        case .sunset: return "sunset"
        case .interval: return "timer"
        }
    }
}
