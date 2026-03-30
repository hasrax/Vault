//
//  InsightCard.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Coloured insight / tip card — green (positive) or amber (warning).
/// Used in AnalyticsView and AICoachView risk dashboard.
struct InsightCard: View {
    let emoji:       String
    let title:       String
    let message:     String
    let bgColor:     Color
    let borderColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.system(size: 24))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

#Preview {
    VStack(spacing: 12) {
        InsightCard(
            emoji: "🎯",
            title: "Great job on groceries!",
            message: "You spent 20% less than last month on groceries.",
            bgColor: Color.income.opacity(0.08),
            borderColor: Color.income.opacity(0.2)
        )
        InsightCard(
            emoji: "☕",
            title: "Coffee spending alert",
            message: "Making coffee at home could save you Rs 12,000 each month.",
            bgColor: Color.warning.opacity(0.08),
            borderColor: Color.warning.opacity(0.2)
        )
        InsightCard(
            emoji: "⚠️",
            title: "Needs over budget",
            message: "Rs.3,000 over your Needs limit this month.",
            bgColor: Color.expense.opacity(0.08),
            borderColor: Color.expense.opacity(0.2)
        )
    }
    .padding()
}
