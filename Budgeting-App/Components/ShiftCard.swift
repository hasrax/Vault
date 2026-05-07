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
    private var badgeFill: Color { Color(UIColor.systemGray6) }
    private var badgeStroke: Color { Color(UIColor.systemGray4) }
    private var statusTextColor: Color { Color.secondary }
    private var statusFill: Color { Color(UIColor.systemGray5) }

    var body: some View {
        HStack(spacing: 14) {

            // Day badge
            VStack(spacing: 2) {
                Text(shift.day)
                    .scaledFont(size: 10, weight: .semibold, relativeTo: .caption2)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.secondary)
                Text(shift.date.components(separatedBy: " ").last ?? "")
                    .scaledFont(size: 18, weight: .bold, relativeTo: .title3)
                    .foregroundStyle(Color.primary)
            }
            .frame(width: 48, height: 52)
            .background(badgeFill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(badgeStroke, lineWidth: 1)
            )

            // Role + time
            VStack(alignment: .leading, spacing: 3) {
                Text(shift.role)
                    .scaledFont(size: 15, weight: .semibold, relativeTo: .headline)
                    .lineLimit(1)
                Text("\(shift.start) – \(shift.end) · \(shift.hours)h")
                    .scaledFont(size: 13, relativeTo: .subheadline)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            // Pay + status pill
            VStack(alignment: .trailing, spacing: 4) {
                Text(shift.pay.currencyRS)
                    .scaledFont(size: 15, weight: .bold, relativeTo: .headline)
                    .foregroundStyle(Color.primary)

                Text(isCompleted ? "Done" : "Soon")
                    .scaledFont(size: 10, weight: .semibold, relativeTo: .caption2)
                    .textCase(.uppercase)
                    .foregroundStyle(statusTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusFill)
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
