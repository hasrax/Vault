//
//  Untitled.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Budget card showing icon, name, spent/limit, animated progress bar, status badge.
/// Used in BudgetView for each of Needs / Wants / Savings.
struct BudgetCategoryCard: View {
    let limit: BudgetLimit
    @Environment(\.appHighContrast) private var appHighContrast

    var body: some View {
        VStack(spacing: 12) {
            // Header row
            HStack(spacing: 12) {
                // Emoji icon in gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(limit.category.color.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Text(limit.category.emoji)
                        .scaledFont(size: 20)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(limit.category.rawValue)
                        .scaledFont(size: 15, weight: .semibold)
                    Text("\(limit.spent.currencyRS) of \(limit.limit.currencyRS)")
                        .scaledFont(size: 12)
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                // Status badge
                Text(limit.statusLabel)
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundStyle(limit.progressColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(limit.progressColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Progress bar
            UniProgressBar(progress: limit.progress, color: limit.progressColor)

            // Footer row
            HStack {
                Text("\(limit.remaining.currencyRS) left")
                    .scaledFont(size: 12)
                    .foregroundStyle(Color.secondary)
                Spacer()
                Text("\(Int(limit.progress * 100))% used")
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundStyle(limit.progressColor)
            }
        }
        .padding(16)
        .lightCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    limit.isOverBudget
                        ? Color.expense.opacity(appHighContrast ? 0.6 : 0.35)
                        : Color.clear,
                    lineWidth: appHighContrast ? 2 : 1.5
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(limit.category.rawValue) budget. \(limit.statusLabel). \(Int(limit.progress * 100)) percent used. \(limit.remaining.currencyRS) remaining."
        )
    }
}

#Preview {
    VStack(spacing: 14) {
        BudgetCategoryCard(limit: MockData.budgetLimits[0])
        BudgetCategoryCard(limit: MockData.budgetLimits[1])
        BudgetCategoryCard(limit: MockData.budgetLimits[2])
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
