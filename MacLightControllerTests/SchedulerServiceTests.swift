// MacLightControllerTests/SchedulerServiceTests.swift
// MacLightController
//
// Unit tests for SchedulerService

import XCTest
@testable import MacLightController

final class SchedulerServiceTests: XCTestCase {

    var sut: SchedulerService!

    override func setUp() {
        super.setUp()
        sut = SchedulerService()
    }

    override func tearDown() {
        sut.stop()
        sut = nil
        super.tearDown()
    }

    func testSchedulerStarts() {
        sut.start()
        // Scheduler should be running (no direct way to check, but should not crash)
    }

    func testSchedulerStops() {
        sut.start()
        sut.stop()
        // Should not crash
    }

    func testScheduleTask() {
        let rule = AutomationRule(
            name: "Test",
            trigger: .time(ScheduleTime(hour: 12, minute: 0)),
            pluginIdentifier: "test",
            action: "test"
        )

        let expectation = XCTestExpectation(description: "Task scheduled")
        expectation.isInverted = true // We don't expect immediate execution

        sut.schedule(rule) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.1)
    }

    func testUnscheduleTask() {
        let rule = AutomationRule(
            name: "Test",
            trigger: .time(ScheduleTime(hour: 12, minute: 0)),
            pluginIdentifier: "test",
            action: "test"
        )

        sut.schedule(rule) {}
        sut.unschedule(rule.id)

        // Task should be removed (no direct way to check)
    }

    func testClearAllTasks() {
        let rule1 = AutomationRule(
            name: "Test1",
            trigger: .time(ScheduleTime(hour: 12, minute: 0)),
            pluginIdentifier: "test",
            action: "test"
        )

        let rule2 = AutomationRule(
            name: "Test2",
            trigger: .time(ScheduleTime(hour: 14, minute: 0)),
            pluginIdentifier: "test",
            action: "test"
        )

        sut.schedule(rule1) {}
        sut.schedule(rule2) {}
        sut.clearAll()

        let info = sut.getScheduledTasksInfo()
        XCTAssertTrue(info.isEmpty)
    }

    func testIntervalTrigger() async {
        let rule = AutomationRule(
            name: "Interval Test",
            trigger: .interval(seconds: 0.1),
            pluginIdentifier: "test",
            action: "test"
        )

        let expectation = XCTestExpectation(description: "Interval triggered")

        sut.schedule(rule) {
            expectation.fulfill()
        }

        sut.start()

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testLocationUpdate() {
        // Test that location update doesn't crash
        sut.updateLocation(latitude: 41.9028, longitude: 12.4964)
    }
}
