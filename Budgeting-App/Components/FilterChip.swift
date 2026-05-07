//
//  FilterChip.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Pill-shaped filter chip — used in TransactionsView, BudgetView, WorkScheduleView.
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var accentColor: Color = .uniBlue
    let action: () -> Void
    @Environment(\.appHighContrast) private var appHighContrast

    var body: some View {
        Button(action: action) {
            Text(label)
                .scaledFont(size: 14, weight: isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? accentColor : Color(UIColor.secondarySystemBackground))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            appHighContrast ? accentColor.opacity(0.6) : Color.clear,
                            lineWidth: appHighContrast ? 1.2 : 0
                        )
                )
                .animation(.spring(duration: 0.25), value: isSelected)
        }
        .accessibilityLabel("\(label) filter")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    HStack {
        FilterChip(label: "All",     isSelected: true,  action: {})
        FilterChip(label: "Income",  isSelected: false, action: {})
        FilterChip(label: "Expense", isSelected: false, action: {})
    }
    .padding()
}
