//
//  ShiftCard.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

struct ShiftCard: View {
    let shift: WorkShift

    private var isCompleted: Bool { shift.status == .completed }

    var body: some View {
        HStack(spacing: 14) {

            // Day badge
            VStack(spacing: 2) {
                Text(shift.day)
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.secondary)
                Text(shift.date.components(separatedBy: " ").last ?? "")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.primary)
            }
            .frame(width: 48, height: 52)
            .background(isCompleted ? Color.income.opacity(0.10) : Color.uniBlue.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isCompleted ? Color.income.opacity(0.2) : Color.uniBlue.opacity(0.2),
                        lineWidth: 1
                    )
            )

            // Role + time
            VStack(alignment: .leading, spacing: 3) {
                Text(shift.role)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                Text("\(shift.start) – \(shift.end) · \(shift.hours)h")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            // Pay + status pill
            VStack(alignment: .trailing, spacing: 4) {
                Text(shift.pay.currencyRS)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isCompleted ? Color.income : Color.primary)

                Text(isCompleted ? "Done" : "Soon")
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(isCompleted ? Color.income : Color.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isCompleted ? Color.income.opacity(0.12) : Color.warning.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(shift.role), \(shift.date), \(shift.hours) hours, \(shift.pay.currencyRS), \(isCompleted ? "completed" : "upcoming")"
        )
    }
}

#Preview {
    VStack(spacing: 10) {
        ForEach(MockData.shifts) { shift in ShiftCard(shift: shift) }
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
