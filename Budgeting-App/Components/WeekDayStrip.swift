//
//  WeekDayStrip.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

struct WeekDayStrip: View {
    let shiftDays:  Set<String>
    var todayIndex: Int = 4
    var startDate:  Int = 17

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    let isToday  = index == todayIndex
                    let hasShift = shiftDays.contains(day)

                    VStack(spacing: 4) {
                        Text(day)
                            .font(.system(size: 10, weight: .semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(isToday ? Color.white.opacity(0.7) : Color.secondary)

                        Text("\(startDate + index)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(isToday ? Color.white : Color.primary)

                        Circle()
                            .fill(
                                isToday  ? Color.white.opacity(0.7) :
                                hasShift ? Color.uniBlue : Color.clear
                            )
                            .frame(width: 5, height: 5)
                    }
                    .frame(width: 44)
                    .padding(.vertical, 10)
                    .background(
                        isToday  ? LinearGradient.primaryGrad :
                        hasShift ? LinearGradient(
                                        colors: [Color.uniBlue.opacity(0.08)],
                                        startPoint: .top, endPoint: .bottom) :
                                   LinearGradient(
                                        colors: [Color(UIColor.secondarySystemBackground)],
                                        startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                hasShift && !isToday ? Color.uniBlue.opacity(0.25) : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .accessibilityLabel(
                        "\(day) \(startDate + index)\(hasShift ? ", shift scheduled" : "")\(isToday ? ", today" : "")"
                    )
                }
            }
        }
    }
}

#Preview {
    WeekDayStrip(shiftDays: ["Mon", "Wed", "Fri", "Sat"])
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
}
