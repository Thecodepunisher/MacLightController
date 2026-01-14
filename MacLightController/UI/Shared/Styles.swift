// UI/Shared/Styles.swift
// MacLightController
//
// Common styles used throughout the app - Minimal macOS Design

import SwiftUI

// MARK: - Colors & Constants

extension Color {
    static let appAccent = Color.accentColor
    static let appBackground = Color(NSColor.windowBackgroundColor)
    static let appContentBackground = Color(NSColor.controlBackgroundColor)
    static let appSecondaryText = Color.secondary
}

enum AppLayout {
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 10
    static let smallCornerRadius: CGFloat = 6
}

// MARK: - Button Styles

struct MenuBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                configuration.isPressed
                    ? Color.secondary.opacity(0.1)
                    : Color.clear
            )
            .contentShape(Rectangle())
            .cornerRadius(AppLayout.smallCornerRadius)
    }
}

struct MinimalButtonStyle: ButtonStyle {
    var variant: Variant = .secondary
    
    enum Variant {
        case primary, secondary, destructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .foregroundColor(foregroundColor(isPressed: configuration.isPressed))
            .cornerRadius(AppLayout.smallCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.smallCornerRadius)
                    .stroke(borderColor, lineWidth: variant == .secondary ? 1 : 0)
            )
    }
    
    private func backgroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return Color.accentColor.opacity(isPressed ? 0.8 : 1)
        case .secondary:
            return isPressed ? Color.secondary.opacity(0.1) : Color.clear
        case .destructive:
            return Color.red.opacity(isPressed ? 0.8 : 0.1)
        }
    }
    
    private func foregroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary: return .white
        case .secondary: return .primary
        case .destructive: return variant == .destructive && !isPressed ? .red : .white
        }
    }
    
    private var borderColor: Color {
        variant == .secondary ? Color.secondary.opacity(0.2) : .clear
    }
}

// MARK: - View Modifiers

struct MinimalCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppLayout.padding)
            .background(Color.appContentBackground)
            .cornerRadius(AppLayout.cornerRadius)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

extension View {
    func minimalCardStyle() -> some View {
        modifier(MinimalCardModifier())
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let isActive: Bool
    let size: CGFloat
    
    init(isActive: Bool, size: CGFloat = 6) {
        self.isActive = isActive
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(isActive ? Color.green : Color.orange)
            .frame(width: size, height: size)
            .shadow(color: isActive ? Color.green.opacity(0.4) : Color.clear, radius: 2)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    
    init(_ title: String) {
        self.title = title.uppercased()
    }
    
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }
}
