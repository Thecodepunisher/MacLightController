// UI/MenuBar/Components/QuickActionButton.swift
// MacLightController
//
// Quick action button for menu bar

import SwiftUI

/// A button for quick actions in the menu bar
struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () async -> Void

    @State private var isPerforming = false

    var body: some View {
        Button {
            Task {
                isPerforming = true
                await action()
                isPerforming = false
            }
        } label: {
            HStack(spacing: 8) {
                if isPerforming {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: icon)
                        .frame(width: 16, height: 16)
                }

                Text(title)

                Spacer()
            }
        }
        .buttonStyle(MenuBarButtonStyle())
        .disabled(isPerforming)
    }
}

/// A compact version of the quick action button for toolbars
struct CompactQuickActionButton: View {
    let icon: String
    let tooltip: String
    let action: () async -> Void

    @State private var isPerforming = false

    var body: some View {
        Button {
            Task {
                isPerforming = true
                await action()
                isPerforming = false
            }
        } label: {
            if isPerforming {
                ProgressView()
                    .scaleEffect(0.6)
            } else {
                Image(systemName: icon)
            }
        }
        .help(tooltip)
        .disabled(isPerforming)
    }
}

#Preview {
    VStack(spacing: 0) {
        QuickActionButton(title: "Accendi", icon: "light.max") {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }

        QuickActionButton(title: "Spegni", icon: "light.min") {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
    .frame(width: 250)
}
