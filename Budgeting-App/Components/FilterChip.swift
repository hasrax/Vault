//
//  FilterChip.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Pill-shaped filter chip — used in HistoryView, BudgetView, WorkScheduleView.
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.uniBlue : Color(UIColor.secondarySystemBackground))
                .clipShape(Capsule())
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
