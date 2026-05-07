//
//  WeekDayStrip.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

struct WeekDayStrip: View {
    let shiftDays:  Set<String>
    private let calendar = Calendar.current
    private static let dayFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let now = context.date
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let dates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(dates, id: \.self) { date in
                        let dayLabel = Self.dayFormatter.string(from: date)
                        let dayNumber = calendar.component(.day, from: date)
                        let isToday = calendar.isDate(date, inSameDayAs: now)
                        let hasShift = shiftDays.contains(dayLabel)

                        VStack(spacing: 4) {
                            Text(dayLabel)
                                .scaledFont(size: 10, weight: .semibold, relativeTo: .caption2)
                                .textCase(.uppercase)
                                .foregroundStyle(isToday ? Color.white.opacity(0.7) : Color.secondary)

                            Text("\(dayNumber)")
                                .scaledFont(size: 15, weight: .bold, relativeTo: .headline)
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
                            "\(dayLabel) \(dayNumber)\(hasShift ? ", shift scheduled" : "")\(isToday ? ", today" : "")"
                        )
                    }
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
