//
//  AccessibilitySettingsView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-04-20.
//

import SwiftUI

struct AccessibilitySettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section("Text size") {
                Picker("App font size", selection: $appState.appFontScale) {
                    ForEach(AppFontScale.allCases) { scale in
                        Text(scale.label).tag(scale)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Contrast") {
                Toggle("High contrast", isOn: $appState.highContrastEnabled)
            }

            Section("Voice Assistant") {
                Toggle("Speak Screen button", isOn: $appState.inAppVoiceEnabled)
            }

            Section {
                Text("Changes apply immediately across the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview { NavigationStack { AccessibilitySettingsView() }.environmentObject(AppState()) }
