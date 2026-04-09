//
//  BackButton.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Back / close button used on all sub-screens.
/// isDark = true  → white icon on transparent dark bg  (used inside dark headers)
/// isDark = false → primary colour on system secondary bg (used on light screens)
struct BackButton: View {
    let action: () -> Void
    var isDark: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isDark ? .white : Color.uniBlue)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(BackButtonStyle(isDark: isDark))
        .accessibilityLabel("Go back")
    }
}

private struct BackButtonStyle: ButtonStyle {
    let isDark: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Group {
                    if isDark {
                        Color.white.opacity(configuration.isPressed ? 0.20 : 0.12)
                    } else {
                        Color(UIColor.secondarySystemBackground)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isDark ? Color.black.opacity(0.25) : Color.black.opacity(0.10),
                radius: configuration.isPressed ? 2 : 6,
                x: 0,
                y: configuration.isPressed ? 1 : 3
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    HStack(spacing: 20) {
        BackButton(action: {})
        BackButton(action: {}, isDark: true)
            .padding()
            .background(Color.black)
    }
    .padding()
}
