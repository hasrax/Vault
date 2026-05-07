//
//  GlassStatCard.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Glass stat tile used inside the dark Work Schedule header.
/// Shows LABEL (muted, uppercase) / VALUE (coloured) / SUB (muted small).
struct GlassStatCard: View {
    let label:      String
    let value:      String
    let sub:        String?
    let valueColor: Color
    var labelColor: Color = .white.opacity(0.75)
    var subColor:   Color = .white.opacity(0.65)

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .scaledFont(size: 11, weight: .semibold, relativeTo: .caption2)
                .foregroundStyle(labelColor)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(value)
                .scaledFont(size: 22, weight: .bold, design: .rounded, relativeTo: .title3)
                .foregroundStyle(valueColor)

            if let s = sub {
                Text(s)
                    .scaledFont(size: 11, relativeTo: .caption2)
                    .foregroundStyle(subColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)\(sub != nil ? ", \(sub!)" : "")")
    }
}

#Preview {
    HStack(spacing: 12) {
        GlassStatCard(label: "Earned",    value: "Rs.10k",  sub: "8h worked",    valueColor: .income)
        GlassStatCard(label: "Projected", value: "Rs.26k",  sub: "this month",   valueColor: .uniBlue)
        GlassStatCard(label: "Upcoming",  value: "3",       sub: "shifts left",  valueColor: .warning)
    }
    .padding()
    .background(Color.black)
}
