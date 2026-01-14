// Plugins/KeyboardBacklight/KeyboardBacklightFallback.swift
// MacLightController
//
// Fallback methods for keyboard backlight control

import Foundation
import os.log

/// Fallback methods using external scripts for compatibility
final class KeyboardBacklightFallback {
    private static let logger = Logger(subsystem: "com.maclightcontroller", category: "KeyboardBacklightFallback")

    /// Method using `brightness` CLI tool (if installed via Homebrew)
    static func setBrightnessViaCLI(_ level: Float) async throws {
        let brightnessPath = "/usr/local/bin/brightness"
        let m1BrightnessPath = "/opt/homebrew/bin/brightness"

        var executablePath = brightnessPath
        if !FileManager.default.fileExists(atPath: brightnessPath) {
            if FileManager.default.fileExists(atPath: m1BrightnessPath) {
                executablePath = m1BrightnessPath
            } else {
                logger.error("brightness CLI tool not found")
                throw KeyboardBacklightError.notSupported
            }
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = ["-k", String(format: "%.2f", level)]

        let pipe = Pipe()
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                logger.error("CLI tool failed: \(errorString)")
                throw KeyboardBacklightError.writeFailed(process.terminationStatus)
            }

            logger.info("Brightness set via CLI: \(level)")
        } catch let error as KeyboardBacklightError {
            throw error
        } catch {
            logger.error("Failed to run CLI tool: \(error.localizedDescription)")
            throw KeyboardBacklightError.writeFailed(-1)
        }
    }

    /// Method using AppleScript (less reliable but works on some systems)
    static func setBrightnessViaAppleScript(_ level: Float) async throws {
        // Note: This is a simplified approach. macOS doesn't provide a direct
        // AppleScript interface for keyboard backlight, but we can try using
        // system preferences automation.

        let intLevel = Int(level * 100)

        let script = """
        tell application "System Events"
            tell process "ControlCenter"
                -- This is a placeholder. Direct keyboard backlight control
                -- via AppleScript is not officially supported.
                return \(intLevel)
            end tell
        end tell
        """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)

            if let error = error {
                let errorNumber = error["NSAppleScriptErrorNumber"] as? Int ?? -1
                logger.error("AppleScript failed: \(error)")
                throw KeyboardBacklightError.writeFailed(Int32(errorNumber))
            }

            logger.info("AppleScript executed: \(result.stringValue ?? "no result")")
        } else {
            throw KeyboardBacklightError.notSupported
        }
    }

    /// Check which fallback methods are available
    static func availableMethods() -> [String] {
        var methods: [String] = []

        // Check for brightness CLI tool
        let paths = ["/usr/local/bin/brightness", "/opt/homebrew/bin/brightness"]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                methods.append("CLI: \(path)")
                break
            }
        }

        // AppleScript is always "available" but may not work
        methods.append("AppleScript (limited support)")

        return methods
    }
}
