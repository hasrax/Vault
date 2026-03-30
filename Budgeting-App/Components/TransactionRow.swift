//
//  TransactionRow.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Single transaction row used in HomeView, HistoryView, TransactionsView.
/// Shows coloured icon circle, title + subtitle, and coloured amount.
struct TransactionRow: View {
    let transaction: Transaction

    private var icon: String {
        transaction.category?.icon ?? transaction.incomeSource?.icon ?? "💰"
    }
    private var iconColor: Color {
        transaction.category?.color ?? (transaction.type == .income ? Color.income : Color.uniBlue)
    }
    private var categoryLabel: String {
        transaction.category?.rawValue ?? transaction.incomeSource?.rawValue ?? "Other"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(icon)
                    .font(.system(size: 18))
            }
            .accessibilityHidden(true)

            // Title + meta
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(categoryLabel)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.secondary)
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                    Text(transaction.date, style: .date)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
            }

            Spacer()

            // Amount
            Text(
                "\(transaction.type == .income ? "+" : "−")\(transaction.amount.currencyRS)"
            )
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(transaction.type == .income ? Color.income : Color.expense)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(transaction.name), \(categoryLabel), \(transaction.type == .income ? "income" : "expense") \(transaction.amount.currencyRS)"
        )
    }
}

#Preview {
    VStack(spacing: 0) {
        TransactionRow(transaction: MockData.transactions[0])
            .padding(.horizontal)
        Divider().padding(.leading, 72)
        TransactionRow(transaction: MockData.transactions[2])
            .padding(.horizontal)
    }
    .padding(.vertical, 8)
    .background(Color(UIColor.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding()
}
