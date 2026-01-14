// Core/Scheduler/SchedulerService.swift
// MacLightController
//
// Timer engine for scheduling automations

import Foundation
import Combine
import os.log

/// Service responsible for scheduling and triggering automations
final class SchedulerService {
    private let logger = Logger(subsystem: "com.maclightcontroller", category: "SchedulerService")
    private var scheduledTasks: [UUID: ScheduledTask] = [:]
    private var timer: DispatchSourceTimer?
    private let checkInterval: TimeInterval = 1.0 // Check every second
    private var sunCalculator: SunCalculator?

    struct ScheduledTask {
        let rule: AutomationRule
        let action: () async -> Void
        var lastExecution: Date?
        var nextTriggerTime: Date?
    }

    init() {}

    // MARK: - Lifecycle

    /// Start the scheduler
    func start() {
        guard timer == nil else { return }

        logger.info("Scheduler starting...")

        let newTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        newTimer.schedule(deadline: .now(), repeating: checkInterval)
        newTimer.setEventHandler { [weak self] in
            self?.performTriggerCheck()
        }
        newTimer.resume()
        timer = newTimer

        let taskCount = self.scheduledTasks.count
        logger.info("Scheduler started with \(taskCount) tasks")
    }

    /// Stop the scheduler
    func stop() {
        timer?.cancel()
        timer = nil
        logger.info("Scheduler stopped")
    }

    /// Update sun calculator with new location
    func updateLocation(latitude: Double, longitude: Double) {
        sunCalculator = SunCalculator(latitude: latitude, longitude: longitude)
        logger.info("Sun calculator updated with location: \(latitude), \(longitude)")
        updateSunTriggerTimes()
    }

    // MARK: - Task Management

    /// Schedule an automation rule
    func schedule(_ rule: AutomationRule, action: @escaping () async -> Void) {
        var task = ScheduledTask(
            rule: rule,
            action: action,
            lastExecution: nil,
            nextTriggerTime: nil
        )

        // Calculate next trigger time for sun-based triggers
        if case .sunrise = rule.trigger {
            task.nextTriggerTime = calculateNextSunriseTrigger(for: rule.trigger)
        } else if case .sunset = rule.trigger {
            task.nextTriggerTime = calculateNextSunsetTrigger(for: rule.trigger)
        }

        scheduledTasks[rule.id] = task
        logger.info("Scheduled task: \(rule.name)")
    }

    /// Remove a scheduled task
    func unschedule(_ ruleId: UUID) {
        if let task = scheduledTasks.removeValue(forKey: ruleId) {
            logger.info("Unscheduled task: \(task.rule.name)")
        }
    }

    /// Update an existing scheduled task
    func updateSchedule(_ rule: AutomationRule) {
        guard let existingTask = scheduledTasks[rule.id] else { return }

        var updatedTask = ScheduledTask(
            rule: rule,
            action: existingTask.action,
            lastExecution: existingTask.lastExecution,
            nextTriggerTime: nil
        )

        // Recalculate sun trigger times
        if case .sunrise = rule.trigger {
            updatedTask.nextTriggerTime = calculateNextSunriseTrigger(for: rule.trigger)
        } else if case .sunset = rule.trigger {
            updatedTask.nextTriggerTime = calculateNextSunsetTrigger(for: rule.trigger)
        }

        scheduledTasks[rule.id] = updatedTask
    }

    /// Clear all scheduled tasks
    func clearAll() {
        scheduledTasks.removeAll()
        logger.info("All scheduled tasks cleared")
    }

    // MARK: - Trigger Checking

    private func performTriggerCheck() {
        Task { @MainActor in
            self.checkTriggers()
        }
    }

    @MainActor
    private func checkTriggers() {
        let now = Date()
        let calendar = Calendar.current

        for (id, task) in scheduledTasks {
            guard task.rule.isEnabled else { continue }

            if shouldTrigger(task: task, at: now, calendar: calendar) {
                // Update last execution
                scheduledTasks[id]?.lastExecution = now

                // Update next sun trigger time if applicable
                if case .sunrise = task.rule.trigger {
                    scheduledTasks[id]?.nextTriggerTime = calculateNextSunriseTrigger(for: task.rule.trigger)
                } else if case .sunset = task.rule.trigger {
                    scheduledTasks[id]?.nextTriggerTime = calculateNextSunsetTrigger(for: task.rule.trigger)
                }

                // Execute action
                Task {
                    await task.action()
                }

                logger.info("Triggered: \(task.rule.name)")
            }
        }
    }

    private func shouldTrigger(task: ScheduledTask, at date: Date, calendar: Calendar) -> Bool {
        let trigger = task.rule.trigger

        switch trigger {
        case .time(let scheduleTime):
            return checkTimeMatch(scheduleTime, currentDate: date, calendar: calendar, lastExecution: task.lastExecution)

        case .sunrise, .sunset:
            return checkSunTriggerMatch(task: task, currentDate: date, calendar: calendar)

        case .interval(let seconds):
            return checkIntervalMatch(seconds: seconds, lastExecution: task.lastExecution, currentDate: date)
        }
    }

    // MARK: - Time Trigger

    private func checkTimeMatch(_ scheduleTime: ScheduleTime, currentDate: Date, calendar: Calendar, lastExecution: Date?) -> Bool {
        let components = calendar.dateComponents([.hour, .minute, .weekday], from: currentDate)

        guard let hour = components.hour,
              let minute = components.minute,
              let weekday = components.weekday else {
            return false
        }

        // Check day of week
        if !scheduleTime.shouldTriggerOn(weekday: weekday) {
            return false
        }

        // Check time match
        guard hour == scheduleTime.hour && minute == scheduleTime.minute else {
            return false
        }

        // Check not already executed this minute
        if let lastExec = lastExecution {
            let lastComponents = calendar.dateComponents([.hour, .minute], from: lastExec)
            if lastComponents.hour == hour && lastComponents.minute == minute {
                // Check if it's the same day
                if calendar.isDate(lastExec, inSameDayAs: currentDate) {
                    return false
                }
            }
        }

        return true
    }

    // MARK: - Sun Trigger

    private func checkSunTriggerMatch(task: ScheduledTask, currentDate: Date, calendar: Calendar) -> Bool {
        guard let nextTrigger = task.nextTriggerTime else { return false }

        // Check if we're within the trigger window (2 seconds)
        let timeDifference = currentDate.timeIntervalSince(nextTrigger)
        guard timeDifference >= 0 && timeDifference < 2 else { return false }

        // Check not already executed
        if let lastExec = task.lastExecution {
            let lastDiff = lastExec.timeIntervalSince(nextTrigger)
            if abs(lastDiff) < 60 {
                return false
            }
        }

        return true
    }

    private func calculateNextSunriseTrigger(for trigger: AutomationTrigger) -> Date? {
        guard case .sunrise(let offsetMinutes) = trigger else { return nil }
        guard let calculator = sunCalculator else { return nil }

        let now = Date()
        let calendar = Calendar.current

        // Try today first
        if let sunrise = calculator.sunrise(for: now, offsetMinutes: offsetMinutes),
           sunrise > now {
            return sunrise
        }

        // Try tomorrow
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           let sunrise = calculator.sunrise(for: tomorrow, offsetMinutes: offsetMinutes) {
            return sunrise
        }

        return nil
    }

    private func calculateNextSunsetTrigger(for trigger: AutomationTrigger) -> Date? {
        guard case .sunset(let offsetMinutes) = trigger else { return nil }
        guard let calculator = sunCalculator else { return nil }

        let now = Date()
        let calendar = Calendar.current

        // Try today first
        if let sunset = calculator.sunset(for: now, offsetMinutes: offsetMinutes),
           sunset > now {
            return sunset
        }

        // Try tomorrow
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           let sunset = calculator.sunset(for: tomorrow, offsetMinutes: offsetMinutes) {
            return sunset
        }

        return nil
    }

    private func updateSunTriggerTimes() {
        for (id, task) in scheduledTasks {
            switch task.rule.trigger {
            case .sunrise:
                scheduledTasks[id]?.nextTriggerTime = calculateNextSunriseTrigger(for: task.rule.trigger)
            case .sunset:
                scheduledTasks[id]?.nextTriggerTime = calculateNextSunsetTrigger(for: task.rule.trigger)
            default:
                break
            }
        }
    }

    // MARK: - Interval Trigger

    private func checkIntervalMatch(seconds: TimeInterval, lastExecution: Date?, currentDate: Date) -> Bool {
        guard let lastExec = lastExecution else {
            // First execution - trigger immediately
            return true
        }

        let elapsed = currentDate.timeIntervalSince(lastExec)
        return elapsed >= seconds
    }

    // MARK: - Debug

    /// Get all scheduled tasks for debugging
    func getScheduledTasksInfo() -> [(name: String, trigger: String, lastExecution: Date?, nextTrigger: Date?)] {
        scheduledTasks.values.map { task in
            (
                name: task.rule.name,
                trigger: task.rule.trigger.displayName,
                lastExecution: task.lastExecution,
                nextTrigger: task.nextTriggerTime
            )
        }
    }
}
