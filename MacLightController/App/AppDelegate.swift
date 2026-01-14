// App/AppDelegate.swift
// MacLightController
//
// Application delegate for menu bar and window management

import AppKit
import SwiftUI

/// Application delegate handling menu bar and windows
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?
    private var automationsWindow: NSWindow?

    private var eventMonitor: Any?

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup menu bar
        setupMenuBar()

        // Setup event monitor for clicking outside popover
        setupEventMonitor()

        // Setup services and start engine
        Task { @MainActor in
            await setupServices()
            do {
                try await CoreEngine.shared.start()
            } catch {
                print("Failed to start engine: \(error)")
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            await CoreEngine.shared.stop()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't terminate when windows are closed - we're a menu bar app
        return false
    }

    // MARK: - Services Setup

    @MainActor
    private func setupServices() async {
        // Request notification authorization
        await NotificationService.shared.requestAuthorization()
        NotificationService.shared.setupCategories()

        // Request location authorization if needed
        if CoreEngine.shared.configStore.globalSettings.useAutomaticLocation {
            LocationService.shared.requestAuthorization()
        }
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "MacLightController")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.animates = true

        let menuBarView = MenuBarView()
            .environmentObject(CoreEngine.shared)
            .environmentObject(CoreEngine.shared.configStore)

        popover.contentViewController = NSHostingController(rootView: menuBarView)

        self.popover = popover
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    // MARK: - Actions

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Bring popover window to front
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @MainActor
    @objc func openSettings() {
        if settingsWindow == nil {
            settingsWindow = makeSettingsWindow()
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor
    @objc func openAutomations() {
        if automationsWindow == nil {
            automationsWindow = makeAutomationsWindow()
        }

        automationsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Window Builders

    @MainActor
    private func makeSettingsWindow() -> NSWindow {
        let settingsView = SettingsView()
            .environmentObject(CoreEngine.shared)
            .environmentObject(CoreEngine.shared.configStore)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Impostazioni"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.setFrameAutosaveName("SettingsWindow")
        window.isReleasedWhenClosed = false
        window.delegate = self
        return window
    }

    @MainActor
    private func makeAutomationsWindow() -> NSWindow {
        let automationsView = AutomationsListView()
            .environmentObject(CoreEngine.shared)
            .environmentObject(CoreEngine.shared.configStore)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Automazioni"
        window.contentView = NSHostingView(rootView: automationsView)
        window.center()
        window.setFrameAutosaveName("AutomationsWindow")
        window.isReleasedWhenClosed = false
        window.delegate = self
        return window
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window == settingsWindow {
            settingsWindow = nil
        } else if window == automationsWindow {
            automationsWindow = nil
        }
    }

    // MARK: - Cleanup

    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
