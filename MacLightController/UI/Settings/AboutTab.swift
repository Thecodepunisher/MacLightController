// UI/Settings/AboutTab.swift
// MacLightController
//
// About tab - Minimal Design

import SwiftUI

struct AboutTab: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(spacing: 4) {
                    Text("MacLightController")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("v\(appVersion) (\(buildNumber))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            
            // Info Card
            VStack(spacing: 12) {
                InfoRow(label: "Piattaforma", value: "macOS 13+ (Apple Silicon)")
                Divider()
                InfoRow(label: "Architettura", value: architectureString)
                Divider()
                InfoRow(label: "Autore", value: "Dada")
            }
            .padding()
            .frame(maxWidth: 350)
            .background(Color.appContentBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            // Links
            HStack(spacing: 24) {
                Link(destination: URL(string: "https://github.com")!) {
                    Label("GitHub", systemImage: "link")
                }
                
                Link(destination: URL(string: "https://github.com/issues")!) {
                    Label("Segnala Bug", systemImage: "ant")
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.accentColor)
            
            Spacer()
            
            // Footer
            Text("© 2024 MacLightController")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
    
    private var architectureString: String {
        #if arch(arm64)
        return "Apple Silicon"
        #elseif arch(x86_64)
        return "Intel (x86_64)"
        #else
        return "Unknown"
        #endif
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.system(size: 13))
    }
}

#Preview {
    AboutTab()
        .frame(width: 500, height: 400)
}
