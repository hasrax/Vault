//
//  Untitled.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Selectable person row used in SplitBillView.
/// Shows avatar circle, name, and a filled/empty checkmark circle.
struct PersonRow: View {
    let avatar:     String
    let name:       String
    let color:      Color
    let isSelected: Bool
    let onTap:      () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(avatar)
                        .font(.system(size: 20))
                }

                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)

                Spacer()

                // Check circle
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.uniPurple : Color.white.opacity(0.12))
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(14)
            .background(
                isSelected
                    ? Color.uniPurple.opacity(0.12)
                    : Color.white.opacity(0.06)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.uniPurple : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .animation(.spring(duration: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")
    }
}

#Preview {
    VStack(spacing: 10) {
        PersonRow(avatar: "🎓", name: "You",     color: .uniBlue,   isSelected: true,  onTap: {})
        PersonRow(avatar: "😊", name: "Hasini",  color: .uniPurple, isSelected: true,  onTap: {})
        PersonRow(avatar: "😎", name: "Tharaka", color: .uniBlue,   isSelected: false, onTap: {})
        PersonRow(avatar: "🌟", name: "Amali",   color: .uniPink,   isSelected: false, onTap: {})
    }
    .padding()
    .background(Color(hex: "#0D0D0D"))
}
