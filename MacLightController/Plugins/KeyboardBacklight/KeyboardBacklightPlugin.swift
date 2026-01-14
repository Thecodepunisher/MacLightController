// Plugins/KeyboardBacklight/KeyboardBacklightPlugin.swift
// MacLightController
//
// Plugin for controlling keyboard backlight on Apple Silicon Macs
// Uses private IOKit APIs that work on M1/M2/M3 Macs

import Foundation
import AppKit
import ApplicationServices
import IOKit
import os.log

// Private IOKit function declarations for keyboard backlight control
@_silgen_name("IOHIDSetModifierLockState")
func IOHIDSetModifierLockState(_ handle: mach_port_t, _ selector: Int32, _ state: Bool) -> kern_return_t

@_silgen_name("IOHIDGetModifierLockState")
func IOHIDGetModifierLockState(_ handle: mach_port_t, _ selector: Int32, _ state: UnsafeMutablePointer<Bool>) -> kern_return_t

/// Plugin for controlling the Mac keyboard backlight
final class KeyboardBacklightPlugin: PluginProtocol {

    // MARK: - Plugin Identity

    static let identifier = "com.maclightcontroller.keyboard-backlight"
    static let displayName = "Keyboard Backlight"
    static let version = "1.0.0"
    static let description = "Controlla la retroilluminazione della tastiera del Mac"

    static let supportedActions: [PluginAction] = [
        PluginAction(
            id: "setBrightness",
            displayName: "Imposta Luminosità",
            description: "Imposta il livello di luminosità della tastiera",
            parameters: [
                PluginParameter(
                    id: "level",
                    displayName: "Livello",
                    type: .float,
                    isRequired: true,
                    defaultValue: AnyCodable(1.0),
                    validation: ParameterValidation(min: 0.0, max: 1.0)
                )
            ]
        ),
        PluginAction(
            id: "turnOn",
            displayName: "Accendi",
            description: "Accende la retroilluminazione al massimo",
            parameters: []
        ),
        PluginAction(
            id: "turnOff",
            displayName: "Spegni",
            description: "Spegne la retroilluminazione",
            parameters: []
        ),
        PluginAction(
            id: "toggle",
            displayName: "Toggle",
            description: "Inverte lo stato attuale",
            parameters: []
        ),
        PluginAction(
            id: "fadeTo",
            displayName: "Fade To",
            description: "Transizione graduale alla luminosità specificata",
            parameters: [
                PluginParameter(
                    id: "level",
                    displayName: "Livello Target",
                    type: .float,
                    isRequired: true,
                    defaultValue: AnyCodable(1.0),
                    validation: ParameterValidation(min: 0.0, max: 1.0)
                ),
                PluginParameter(
                    id: "duration",
                    displayName: "Durata (secondi)",
                    type: .float,
                    isRequired: false,
                    defaultValue: AnyCodable(2.0),
                    validation: ParameterValidation(min: 0.1, max: 10.0)
                )
            ]
        )
    ]

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.maclightcontroller", category: "KeyboardBacklight")
    private var currentBrightness: Float = 0.5
    private var isHardwareAvailable: Bool = false
    private let hardwareBrightnessInverted = true
    private let keySimulationInverted = true

    // IOKit connection for direct hardware access
    private var dataPort: mach_port_t = 0
    private var hidConnection: io_connect_t = 0

    // Function selectors for keyboard backlight
    private let kGetKeyboardBacklightBrightness: UInt32 = 0
    private let kSetKeyboardBacklightBrightness: UInt32 = 1

    // MARK: - Initialization

    required init() throws {
        // Try to setup direct hardware connection
        do {
            try setupHardwareConnection()
            isHardwareAvailable = true

            // Try to read current brightness
            if let brightness = try? readCurrentBrightness() {
                currentBrightness = brightness
            }

            logger.info("KeyboardBacklightPlugin initialized with hardware control, brightness: \(self.currentBrightness)")
        } catch {
            // Check if keyboard backlight exists in the system
            if checkKeyboardBacklightCapability() {
                isHardwareAvailable = true
                logger.warning("Keyboard backlight detected but direct IOKit control not available: \(error.localizedDescription)")
                logger.info("KeyboardBacklightPlugin will use alternative control method")
            } else {
                isHardwareAvailable = false
                logger.warning("No keyboard backlight hardware detected")
            }
        }
    }

    deinit {
        if hidConnection != 0 {
            IOServiceClose(hidConnection)
        }
    }

    // MARK: - Hardware Connection Setup

    private func setupHardwareConnection() throws {
        // Try connecting to AppleARMPWMBacklight first (Apple Silicon)
        var hidService = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleARMPWMBacklight"))
        if hidService != IO_OBJECT_NULL {
            defer { IOObjectRelease(hidService) }
            let result = IOServiceOpen(hidService, mach_task_self_, 0, &hidConnection)
            if result == KERN_SUCCESS {
                logger.info("Connected to AppleARMPWMBacklight")
                return
            }
            IOObjectRelease(hidService)
            hidService = IO_OBJECT_NULL
        }

        // Try connecting to AppleARMBacklight
        hidService = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleARMBacklight"))
        if hidService != IO_OBJECT_NULL {
            defer { IOObjectRelease(hidService) }
            let result = IOServiceOpen(hidService, mach_task_self_, 0, &hidConnection)
            if result == KERN_SUCCESS {
                logger.info("Connected to AppleARMBacklight")
                return
            }
            IOObjectRelease(hidService)
            hidService = IO_OBJECT_NULL
        }

        // Try connecting to AppleS5L8920XPWM (legacy Apple Silicon PWM)
        hidService = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleS5L8920XPWM"))
        if hidService != IO_OBJECT_NULL {
            defer { IOObjectRelease(hidService) }
            let result = IOServiceOpen(hidService, mach_task_self_, 0, &hidConnection)
            if result == KERN_SUCCESS {
                logger.info("Connected to AppleS5L8920XPWM")
                return
            }
            IOObjectRelease(hidService)
            hidService = IO_OBJECT_NULL
        }

        // Fallback to IOHIDSystem (legacy method)
        hidService = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))

        guard hidService != IO_OBJECT_NULL else {
            throw KeyboardBacklightError.serviceNotFound
        }

        defer { IOObjectRelease(hidService) }

        // Open connection to the HID system
        let result = IOServiceOpen(hidService, mach_task_self_, 0, &hidConnection)

        guard result == KERN_SUCCESS else {
            logger.error("Failed to open IOHIDSystem: \(result)")
            throw KeyboardBacklightError.connectionFailed(result)
        }

        logger.info("Connected to IOHIDSystem")
    }

    /// Check if the system has keyboard backlight capability
    private func checkKeyboardBacklightCapability() -> Bool {
        // Method 1: Check for kbd-backlight PWM device (Apple Silicon)
        if let matching = IOServiceMatching("AppleARMPWMBacklight") {
            var iterator: io_iterator_t = 0
            let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)

            if result == KERN_SUCCESS {
                defer { IOObjectRelease(iterator) }
                if IOIteratorNext(iterator) != IO_OBJECT_NULL {
                    logger.info("Found AppleARMPWMBacklight device")
                    return true
                }
            }
        }

        // Method 2: Check for kbd-backlight PWM device (Apple Silicon)
        if let matching = IOServiceMatching("AppleARMBacklight") {
            var iterator: io_iterator_t = 0
            let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)

            if result == KERN_SUCCESS {
                defer { IOObjectRelease(iterator) }
                if IOIteratorNext(iterator) != IO_OBJECT_NULL {
                    logger.info("Found AppleARMBacklight device")
                    return true
                }
            }
        }

        // Method 3: Check for kbd-backlight PWM device (Apple Silicon)
        if let matching = IOServiceMatching("AppleARMPWMDevice") {
            var iterator: io_iterator_t = 0
            let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)

            if result == KERN_SUCCESS {
                defer { IOObjectRelease(iterator) }
                if IOIteratorNext(iterator) != IO_OBJECT_NULL {
                    logger.info("Found AppleARMPWMDevice")
                    return true
                }
            }
        }

        // Method 4: Check for kbd-backlight PWM device (Apple Silicon)
        if let matching = IOServiceMatching("AppleS5L8920XPWM") {
            var iterator: io_iterator_t = 0
            let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)

            if result == KERN_SUCCESS {
                defer { IOObjectRelease(iterator) }
                if IOIteratorNext(iterator) != IO_OBJECT_NULL {
                    logger.info("Found AppleS5L8920XPWM")
                    return true
                }
            }
        }

        // Method 5: Check for kbd-backlight PWM device (legacy)
        if let matching = IOServiceMatching("AppleARMPWMDevice") {
            var iterator: io_iterator_t = 0
            let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)

            if result == KERN_SUCCESS {
                defer { IOObjectRelease(iterator) }
                var service = IOIteratorNext(iterator)
                while service != IO_OBJECT_NULL {
                    if let namePtr = IORegistryEntryCreateCFProperty(
                        service,
                        "name" as CFString,
                        kCFAllocatorDefault,
                        0
                    ) {
                        let name = namePtr.takeRetainedValue()
                        if let nameData = name as? Data,
                           let nameStr = String(data: nameData, encoding: .utf8),
                           nameStr.contains("kbd-backlight") {
                            IOObjectRelease(service)
                            logger.info("Found kbd-backlight device")
                            return true
                        }
                    }
                    IOObjectRelease(service)
                    service = IOIteratorNext(iterator)
                }
            }
        }

        return false
    }

    /// Read current brightness level from hardware
    private func readCurrentBrightness() throws -> Float {
        // Try to read via IOHIDSystem
        guard hidConnection != 0 else {
            throw KeyboardBacklightError.notConnected
        }

        var outputCount: UInt32 = 1
        var brightness: UInt64 = 0

        let result = IOConnectCallScalarMethod(
            hidConnection,
            kGetKeyboardBacklightBrightness,
            nil,
            0,
            &brightness,
            &outputCount
        )

        if result == KERN_SUCCESS {
            let normalized = Float(brightness) / Float(0xFFFF)
            let mapped = hardwareBrightnessInverted ? (1.0 - normalized) : normalized
            logger.info("Read brightness raw=\(brightness) normalized=\(normalized) mapped=\(mapped)")
            return mapped
        }

        logger.warning("Read brightness failed with code \(result)")
        // Return default if read fails
        return 0.5
    }

    // MARK: - Plugin Protocol Implementation

    func execute(action: String, parameters: [String: Any]) async throws {
        switch action {
        case "setBrightness":
            let level = extractFloatParameter(from: parameters, key: "level") ?? 1.0
            try await setBrightness(level)

        case "turnOn":
            try await setBrightness(1.0)

        case "turnOff":
            try await setBrightness(0.0)

        case "toggle":
            let newLevel: Float = currentBrightness > 0.1 ? 0.0 : 1.0
            try await setBrightness(newLevel)

        case "fadeTo":
            let level = extractFloatParameter(from: parameters, key: "level") ?? 1.0
            let duration = extractFloatParameter(from: parameters, key: "duration") ?? 2.0
            try await fadeBrightness(to: level, duration: duration)

        default:
            throw KeyboardBacklightError.unknownAction(action)
        }
    }

    func checkSystemCompatibility() -> PluginCompatibilityResult {
        var missingRequirements: [String] = []
        var warnings: [String] = []

        #if !arch(arm64)
        missingRequirements.append("Richiede Apple Silicon (M1/M2/M3)")
        #endif

        if !checkKeyboardBacklightCapability() {
            warnings.append("Retroilluminazione tastiera non rilevata")
        }

        return PluginCompatibilityResult(
            isCompatible: missingRequirements.isEmpty,
            missingRequirements: missingRequirements,
            warnings: warnings
        )
    }

    func cleanup() async {
        if hidConnection != 0 {
            IOServiceClose(hidConnection)
            hidConnection = 0
            logger.info("HID connection closed")
        }
    }

    // MARK: - Brightness Control

    /// Set brightness level (0.0 - 1.0)
    func setBrightness(_ level: Float) async throws {
        let clampedLevel = max(0.0, min(1.0, level))
        logger.info("Set brightness requested=\(level) clamped=\(clampedLevel)")

        // Try direct IOKit control first
        if hidConnection != 0 {
            let hardwareLevel = hardwareBrightnessInverted ? (1.0 - clampedLevel) : clampedLevel
            let rawValue = UInt64(hardwareLevel * Float(0xFFFF))
            logger.info("IOKit target hardware=\(hardwareLevel) raw=\(rawValue)")
            var input = rawValue
            var outputCount: UInt32 = 0

            let result = IOConnectCallScalarMethod(
                hidConnection,
                kSetKeyboardBacklightBrightness,
                &input,
                1,
                nil,
                &outputCount
            )

            if result == KERN_SUCCESS {
                currentBrightness = clampedLevel
                logger.info("Brightness set to \(clampedLevel) via IOKit")
                return
            }

            logger.warning("IOKit set failed with code \(result)")
        }

        // Fallback: Use keyboard brightness keys simulation via CGEvent
        logger.info("Falling back to key simulation")
        let success = await simulateKeyboardBrightnessChange(to: clampedLevel)

        if success {
            currentBrightness = clampedLevel
            logger.info("Brightness set to \(clampedLevel) via key simulation")
            return
        }

        if await tryFallbackBrightnessControl(level: clampedLevel) {
            currentBrightness = clampedLevel
            logger.info("Brightness set to \(clampedLevel) via fallback")
            return
        }

        // Last resort: just update internal state
        currentBrightness = clampedLevel
        logger.warning("Could not control hardware - brightness simulated to \(clampedLevel)")
    }

    private func tryFallbackBrightnessControl(level: Float) async -> Bool {
        do {
            logger.info("Fallback CLI set to \(level)")
            try await KeyboardBacklightFallback.setBrightnessViaCLI(level)
            return true
        } catch {
            logger.warning("CLI fallback failed: \(error.localizedDescription)")
        }

        do {
            logger.info("Fallback AppleScript set to \(level)")
            try await KeyboardBacklightFallback.setBrightnessViaAppleScript(level)
            return true
        } catch {
            logger.warning("AppleScript fallback failed: \(error.localizedDescription)")
        }

        return false
    }

    /// Simulate keyboard brightness change using media keys
    private func simulateKeyboardBrightnessChange(to targetLevel: Float) async -> Bool {
        if !AXIsProcessTrusted() {
            requestAccessibilityIfNeeded()
            logger.warning("Accessibility permission required for key simulation")
            return false
        }

        let currentLevel = currentBrightness
        let delta = targetLevel - currentLevel
        logger.info("Key simulation current=\(currentLevel) target=\(targetLevel) delta=\(delta) inverted=\(self.keySimulationInverted)")

        // Each key press changes brightness by ~6.25% (16 steps from 0 to 100%)
        let stepSize: Float = 1.0 / 16.0
        let stepsNeeded = Int(abs(delta) / stepSize)

        guard stepsNeeded > 0 else { return true }

        let shouldIncrease = delta > 0
        let keyCode: Int32
        if keySimulationInverted {
            keyCode = shouldIncrease ? 21 : 22
        } else {
            keyCode = shouldIncrease ? 22 : 21
        }

        for _ in 0..<stepsNeeded {
            await postKeyboardBrightnessKey(keyCode: keyCode, keyDown: true)
            try? await Task.sleep(nanoseconds: 10_000_000)
            await postKeyboardBrightnessKey(keyCode: keyCode, keyDown: false)
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        return true
    }

    /// Post a keyboard brightness media key event
    private func postKeyboardBrightnessKey(keyCode: Int32, keyDown: Bool) async {
        let flags: Int32 = keyDown ? 0x0a00 : 0x0b00

        if hidConnection != 0 {
            var event = NXEventData()
            event.compound.subType = Int16(8) // NX_SUBTYPE_AUX_CONTROL_BUTTONS

            withUnsafeMutableBytes(of: &event.compound.misc) { ptr in
                ptr.storeBytes(of: Int32((keyCode << 16) | flags), toByteOffset: 0, as: Int32.self)
            }

            var eventRecord = IOGPoint(x: 0, y: 0)

            IOHIDPostEvent(
                hidConnection,
                UInt32(NX_SYSDEFINED),
                eventRecord,
                &event,
                UInt32(MemoryLayout<NXEventData>.size),
                0,
                0
            )

            return
        }

        await postKeyboardBrightnessKeyViaCGEvent(keyCode: keyCode, flags: flags)
    }

    private func postKeyboardBrightnessKeyViaCGEvent(keyCode: Int32, flags: Int32) async {
        await MainActor.run {
            let data1 = Int((keyCode << 16) | flags)
            let modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(flags))

            if let event = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: modifierFlags,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            ) {
                event.cgEvent?.post(tap: .cghidEventTap)
            }
        }
    }

    private func requestAccessibilityIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Fade brightness to target level over duration
    func fadeBrightness(to targetLevel: Float, duration: Float) async throws {
        let startLevel = currentBrightness
        let clampedTarget = max(0.0, min(1.0, targetLevel))

        let steps = max(1, Int(duration * 30)) // 30 fps for smoother fade
        let stepDelay = UInt64((duration / Float(steps)) * 1_000_000_000)

        logger.info("Fading from \(startLevel) to \(clampedTarget) over \(duration)s (\(steps) steps)")

        for step in 0...steps {
            let progress = Float(step) / Float(steps)
            let currentLevel = startLevel + (clampedTarget - startLevel) * progress

            try await setBrightness(currentLevel)

            if step < steps {
                try await Task.sleep(nanoseconds: stepDelay)
            }
        }

        try await setBrightness(clampedTarget)
    }

    // MARK: - Helpers

    private func extractFloatParameter(from parameters: [String: Any], key: String) -> Float? {
        if let value = parameters[key] as? Float {
            return value
        }
        if let value = parameters[key] as? Double {
            return Float(value)
        }
        if let value = parameters[key] as? Int {
            return Float(value)
        }
        if let value = parameters[key] as? NSNumber {
            return value.floatValue
        }
        return nil
    }

    // MARK: - Public Accessors

    var brightness: Float {
        currentBrightness
    }

    var isOn: Bool {
        currentBrightness > 0.01
    }

    var hardwareAvailable: Bool {
        isHardwareAvailable
    }
}
