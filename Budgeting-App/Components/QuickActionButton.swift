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
    let gradient: LinearGradient
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 24))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel(label)
        .accessibilityHint("Double tap to open \(label)")
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
        QuickActionButton(emoji: "📄", label: "History",  gradient: .primaryGrad, action: {})
        QuickActionButton(emoji: "📅", label: "Planner",  gradient: .purpleGrad,  action: {})
        QuickActionButton(emoji: "💼", label: "Jobs",     gradient: .greenGrad,   action: {})
        QuickActionButton(emoji: "🍕", label: "Split",    gradient: .orangeGrad,  action: {})
        QuickActionButton(emoji: "🛒", label: "Meals",    gradient: .tealGrad,    action: {})
        QuickActionButton(emoji: "🐷", label: "Savings",  gradient: .pinkGrad,    action: {})
    }
    .padding()
}
