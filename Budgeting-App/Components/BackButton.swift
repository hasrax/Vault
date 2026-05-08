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
                    .fill(Color(UIColor.systemBackground))
                    .frame(width: 44, height: 44)

                Image(systemName: "chevron.left")
                    .scaledFont(size: 14, weight: .semibold, relativeTo: .body)
                    .foregroundStyle(isDark ? Color.white : Color.uniBlue)
            }
        }
        .buttonStyle(CircleButtonStyle())
        .accessibilityLabel("Go back")
        .accessibilityHint("Returns to the previous screen")
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
