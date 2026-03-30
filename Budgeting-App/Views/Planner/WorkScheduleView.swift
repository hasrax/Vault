//
//  WorkScheduleView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Work Schedule
struct WorkScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @State private var activeTab = "week"
    @State private var viewMode = "hours"
    private let shifts = MockData.shifts
    private var shiftDays: Set<String> { Set(shifts.map(\.day)) }
    private var completed: [WorkShift] { shifts.filter{$0.status == .completed} }
    private var upcoming: [WorkShift]  { shifts.filter{$0.status == .upcoming} }
    private var totalEarned:     Double { completed.reduce(0){$0+$1.pay} }
    private var projectedEarnings: Double { shifts.reduce(0){$0+$1.pay} }
    private var totalHours:      Int { completed.reduce(0){$0+$1.hours} }

    private var displayedShifts: [WorkShift] {
        switch activeTab {
        case "upcoming":  return upcoming
        case "completed": return completed
        default:          return shifts
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Dark header
                ZStack(alignment: .bottom) {
                    LinearGradient.headerGrad
                        .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft,.bottomRight]))
                    VStack(spacing: 20) {
                        HStack(spacing:12) {
                            GlassStatCard(label:"Earned",    value:totalEarned.shortCurrency,       sub:"\(totalHours)h worked", valueColor:Color.income)
                            GlassStatCard(label:"Projected", value:projectedEarnings.shortCurrency, sub:"this month",            valueColor:Color.uniBlue)
                            GlassStatCard(label:"Upcoming",  value:"\(upcoming.count)",             sub:"shifts left",           valueColor:Color.warning)
                        }
                        WeekDayStrip(shiftDays: shiftDays)
                    }
                    .padding(.horizontal,16)
                    .padding(.vertical,24)
                }

                // View mode toggle
                HStack(spacing:10) {
                    ForEach([("hours","2-hour view"),("monthly","Monthly view")],id:\.0) { id,label in
                        FilterChip(label:label, isSelected:viewMode == id) { viewMode = id }
                    }
                    Spacer()
                }
                .padding(.horizontal,16).padding(.top,16)

                // Info card
                VStack(alignment:.leading,spacing:4) {
                    Text(viewMode == "hours" ? "Recommended block" : "Monthly pacing")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    Text(viewMode == "hours" ? "2h × 3 sessions" : "5 blocks · 20h")
                        .font(.system(size:22,weight:.bold,design:.rounded))
                    Text(viewMode == "hours"
                         ? "Split your shifts into smaller two-hour bursts when classes are tight."
                         : "Average pay per hour \(Double(totalEarned / max(Double(totalHours),1)).currencyRS)")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                }
                .padding(16)
                .frame(maxWidth:.infinity,alignment:.leading)
                .lightCard()
                .padding(.horizontal,16).padding(.top,12)

                // Tab filter
                HStack(spacing:10) {
                    ForEach([("week","Week"),("upcoming","Upcoming"),("completed","Completed")],id:\.0) { id,label in
                        FilterChip(label:label,isSelected:activeTab == id) { activeTab = id }
                    }
                    Spacer()
                }
                .padding(.horizontal,16).padding(.top,16)

                // Shifts
                VStack(spacing:10) {
                    ForEach(displayedShifts) { shift in ShiftCard(shift:shift) }
                }
                .padding(.horizontal,16).padding(.top,12)

                // Add shift
                Button {
                } label: {
                    Label("Add Shift",systemImage:"plus")
                        .font(.system(size:15,weight:.semibold)).foregroundStyle(Color.white)
                        .frame(maxWidth:.infinity).frame(height:50)
                        .background(LinearGradient.ctaGrad)
                        .clipShape(RoundedRectangle(cornerRadius:14))
                }
                .padding(.horizontal,16).padding(.top,20).padding(.bottom,40)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Work Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
    }
}

#Preview("Work") { NavigationStack { WorkScheduleView() } }
