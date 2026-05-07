//
//   QuickActionButton.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Coloured gradient quick-action button in the Home screen grid.
struct QuickActionButton: View {
    let emoji:    String
    let label:    String
    let accent:   Color
    let action:   () -> Void
    @Environment(\.appHighContrast) private var appHighContrast

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .scaledFont(size: 24)
                Text(label)
                    .scaledFont(size: 12, weight: .semibold)
                    .foregroundStyle(Color.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                ZStack {
                    Color(UIColor.systemBackground)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        appHighContrast ? accent.opacity(0.75) : accent.opacity(0.35),
                        lineWidth: appHighContrast ? 1.5 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel(label)
        .accessibilityHint("Double tap to open \(label)")
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
        QuickActionButton(emoji: "📄", label: "History",  accent: .uniBlue,   action: {})
        QuickActionButton(emoji: "📅", label: "Planner",  accent: .uniPurple, action: {})
        QuickActionButton(emoji: "💼", label: "Jobs",     accent: .uniGreen,  action: {})
        QuickActionButton(emoji: "🍕", label: "Split",    accent: .uniOrange, action: {})
        QuickActionButton(emoji: "🛒", label: "Meals",    accent: .uniTeal,   action: {})
        QuickActionButton(emoji: "🐷", label: "Savings",  accent: .uniPink,   action: {})
    }
    .padding()
}
