// MacLightControllerTests/CoreEngineTests.swift
// MacLightController
//
// Unit tests for CoreEngine

import XCTest
@testable import MacLightController

@MainActor
final class CoreEngineTests: XCTestCase {

    override func setUp() async throws {
        // Reset engine state before each test
        await CoreEngine.shared.stop()
    }

    override func tearDown() async throws {
        await CoreEngine.shared.stop()
    }

    func testEngineStartsSuccessfully() async throws {
        XCTAssertFalse(CoreEngine.shared.isRunning)

        try await CoreEngine.shared.start()

        XCTAssertTrue(CoreEngine.shared.isRunning)
    }

    func testEngineStops() async throws {
        try await CoreEngine.shared.start()
        XCTAssertTrue(CoreEngine.shared.isRunning)

        await CoreEngine.shared.stop()

        XCTAssertFalse(CoreEngine.shared.isRunning)
    }

    func testPluginsAreLoaded() async throws {
        try await CoreEngine.shared.start()

        let plugins = CoreEngine.shared.getAvailablePlugins()

        // At minimum, keyboard backlight plugin should be loaded
        XCTAssertFalse(plugins.isEmpty)
        XCTAssertTrue(plugins.contains { $0.identifier == KeyboardBacklightPlugin.identifier })
    }

    func testAutomationRegistration() async throws {
        try await CoreEngine.shared.start()

        let rule = AutomationRule(
            name: "Test Rule",
            trigger: .time(ScheduleTime(hour: 8, minute: 0)),
            pluginIdentifier: KeyboardBacklightPlugin.identifier,
            action: "turnOn"
        )

        try await CoreEngine.shared.registerAutomation(rule)

        XCTAssertTrue(CoreEngine.shared.activeAutomations.contains { $0.id == rule.id })
    }

    func testAutomationUnregistration() async throws {
        try await CoreEngine.shared.start()

        let rule = AutomationRule(
            name: "Test Rule",
            trigger: .time(ScheduleTime(hour: 8, minute: 0)),
            pluginIdentifier: KeyboardBacklightPlugin.identifier,
            action: "turnOn"
        )

        try await CoreEngine.shared.registerAutomation(rule)
        CoreEngine.shared.unregisterAutomation(rule.id)

        XCTAssertFalse(CoreEngine.shared.activeAutomations.contains { $0.id == rule.id })
    }

    func testInvalidPluginThrowsError() async throws {
        try await CoreEngine.shared.start()

        let rule = AutomationRule(
            name: "Invalid Rule",
            trigger: .time(ScheduleTime(hour: 8, minute: 0)),
            pluginIdentifier: "com.invalid.plugin",
            action: "someAction"
        )

        do {
            try await CoreEngine.shared.registerAutomation(rule)
            XCTFail("Should have thrown an error for invalid plugin")
        } catch {
            // Expected
            XCTAssertTrue(error is CoreEngineError)
        }
    }
}
