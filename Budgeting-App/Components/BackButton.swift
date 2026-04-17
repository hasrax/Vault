//
//  BackButton.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Back / close button used on all sub-screens.
/// isDark = true  → white icon on translucent dark circle  (dark headers)
/// isDark = false → uniBlue icon on white/system circle    (light screens)
struct BackButton: View {
    let action: () -> Void
    var isDark: Bool = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isDark
                          ? Color.white.opacity(0.15)
                          : Color(UIColor.systemBackground))
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(isDark ? 0.0 : 0.08),
                            radius: 6, x: 0, y: 2)

                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isDark ? Color.white : Color.uniBlue)
            }
        }
        .buttonStyle(CircleButtonStyle())
        .accessibilityLabel("Go back")
    }
}

private struct CircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(duration: 0.18), value: configuration.isPressed)
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
