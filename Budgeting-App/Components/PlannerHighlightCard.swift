//
//  PlannerHighlightCard.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Compact planner highlight row — title, detail, chevron.
/// Used in HomeView "Planner highlights" section.
struct PlannerHighlightCard: View {
    let title:  String
    let detail: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(accent)
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accent.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(detail)")
        .accessibilityHint("Double tap to open")
    }
}

#Preview {
    VStack(spacing: 8) {
        PlannerHighlightCard(title: "Semester Planner", detail: "9 weeks remaining", accent: .purple, action: {})
        PlannerHighlightCard(title: "Work Schedule",    detail: "2 shifts this week", accent: .green,  action: {})
        PlannerHighlightCard(title: "Split Bill",       detail: "Settle dinner with Hasini & co.", accent: .orange, action: {})
    }
    .padding()
}
