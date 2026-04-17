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
    @EnvironmentObject var plannerVM: PlannerViewModel
    @EnvironmentObject var appState: AppState
    @State private var activeTab = "week"
    @State private var viewMode = "hours"
    @State private var showAddShift = false
    @State private var shiftDay = ""
    @State private var shiftDate = ""
    @State private var selectedDate = Date()
    @State private var shiftRole = ""
    @State private var shiftStart = ""
    @State private var shiftEnd = ""
    @State private var shiftStartTime = Date()
    @State private var shiftEndTime = Date()
    @State private var shiftHours = ""
    @State private var shiftPay = ""
    @State private var shiftStatus: WorkShift.ShiftStatus = .upcoming
    @State private var repeatMonthly = false
    @State private var repeatMonths = 6
    @State private var repeatWeekly = false
    @State private var repeatWeeks = 4
    @State private var sortNewestFirst = true
    @State private var editShift: WorkShift?
    private var shifts: [WorkShift] { plannerVM.workShifts }
    private var shiftDays: Set<String> { Set(shifts.map(\.day)) }
    private var completed: [WorkShift] { shifts.filter{$0.status == .completed} }
    private var upcoming: [WorkShift]  { shifts.filter{$0.status == .upcoming} }
    private var totalEarned:     Double { completed.reduce(0){$0+$1.pay} }
    private var projectedEarnings: Double { shifts.reduce(0){$0+$1.pay} }
    private var totalHours:      Int { completed.reduce(0){$0+$1.hours} }
    private var statValueColor:  Color { Color(white: 0.88) }
    private var statLabelColor:  Color { Color(white: 0.70) }
    private var statSubColor:    Color { Color(white: 0.62) }
    private var accent: Color { appState.plannerTheme.color(for: "workSchedule") }
    private var grad: LinearGradient {
        let base = appState.plannerTheme.color(for: "workSchedule")
        return LinearGradient(
            colors: [base.opacity(0.75), base.opacity(0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var displayedShifts: [WorkShift] {
        switch activeTab {
        case "upcoming":  return upcoming
        case "completed": return completed
        default:          return shifts
        }
    }

    private var sortedShifts: [WorkShift] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return displayedShifts.sorted { a, b in
            let da = fmt.date(from: a.date) ?? Date.distantPast
            let db = fmt.date(from: b.date) ?? Date.distantPast
            return sortNewestFirst ? da > db : da < db
        }
    }

    var body: some View {
        ScrollView {
            mainContent
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Work Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button {
                        showAddShift = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add shift")
                }
            }
        }
        .sheet(isPresented: $showAddShift) {
            NavigationStack {
                Form {
                    if viewMode == "monthly" {
                        Section("Monthly Salary") {
                            DatePicker("Month", selection: $selectedDate, displayedComponents: .date)
                            TextField("Role", text: $shiftRole)
                            TextField("Monthly salary", text: $shiftPay)
                                .keyboardType(.numberPad)
                            Picker("Status", selection: $shiftStatus) {
                                Text("Upcoming").tag(WorkShift.ShiftStatus.upcoming)
                                Text("Completed").tag(WorkShift.ShiftStatus.completed)
                            }
                        }
                        Section("Repeat") {
                            Toggle("Repeat monthly", isOn: $repeatMonthly)
                            if repeatMonthly {
                                Picker("Months", selection: $repeatMonths) {
                                    Text("3").tag(3)
                                    Text("6").tag(6)
                                    Text("12").tag(12)
                                }
                            }
                        }
                    } else {
                        Section("Basics") {
                            weekdayQuickSelect
                            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            TextField("Role", text: $shiftRole)
                        }
                        Section("Time") {
                            HStack(spacing: 12) {
                                TextField("Start (HH:mm)", text: $shiftStart)
                                    .keyboardType(.numbersAndPunctuation)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                DatePicker("", selection: $shiftStartTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            HStack(spacing: 12) {
                                TextField("End (HH:mm)", text: $shiftEnd)
                                    .keyboardType(.numbersAndPunctuation)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                DatePicker("", selection: $shiftEndTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            TextField("Hours", text: $shiftHours)
                                .keyboardType(.numberPad)
                                .disabled(!shiftStart.isEmpty && !shiftEnd.isEmpty)
                                .foregroundStyle((!shiftStart.isEmpty && !shiftEnd.isEmpty) ? Color.secondary : Color.primary)
                        }
                        Section("Pay") {
                            TextField("Amount", text: $shiftPay)
                                .keyboardType(.numberPad)
                            Picker("Status", selection: $shiftStatus) {
                                Text("Upcoming").tag(WorkShift.ShiftStatus.upcoming)
                                Text("Completed").tag(WorkShift.ShiftStatus.completed)
                            }
                        }
                        Section("Repeat") {
                            Toggle("Repeat weekly", isOn: $repeatWeekly)
                            if repeatWeekly {
                                Picker("Weeks", selection: $repeatWeeks) {
                                    Text("4").tag(4)
                                    Text("8").tag(8)
                                    Text("12").tag(12)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("New Shift")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { showAddShift = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add") {
                            let role = shiftRole.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !role.isEmpty else { return }
                            if viewMode == "monthly" && repeatMonthly {
                                let pay = Double(shiftPay) ?? 0
                                let monthDate = firstOfMonth(selectedDate)
                                plannerVM.addMonthlyShifts(
                                    startDate: monthDate,
                                    months: repeatMonths,
                                    role: role,
                                    start: shiftStart,
                                    end: shiftEnd,
                                    hours: 0,
                                    monthlyPay: pay,
                                    status: shiftStatus
                                )
                            } else if viewMode == "monthly" {
                                let pay = Double(shiftPay) ?? 0
                                let monthDate = firstOfMonth(selectedDate)
                                plannerVM.addMonthlyShifts(
                                    startDate: monthDate,
                                    months: 1,
                                    role: role,
                                    start: shiftStart,
                                    end: shiftEnd,
                                    hours: 0,
                                    monthlyPay: pay,
                                    status: shiftStatus
                                )
                            } else {
                                let day = dayString(selectedDate)
                                let date = dateString(selectedDate)
                                let hours = Int(shiftHours) ?? 0
                                let pay = Double(shiftPay) ?? 0
                                if repeatWeekly {
                                    plannerVM.addWeeklyShifts(
                                        startDate: selectedDate,
                                        weeks: repeatWeeks,
                                        role: role,
                                        start: shiftStart,
                                        end: shiftEnd,
                                        hours: hours,
                                        pay: pay,
                                        status: shiftStatus
                                    )
                                } else {
                                    plannerVM.addWorkShift(
                                        day: day,
                                        date: date,
                                        role: role,
                                        start: shiftStart,
                                        end: shiftEnd,
                                        hours: hours,
                                        pay: pay,
                                        status: shiftStatus
                                    )
                                }
                            }
                            shiftDay = ""
                            shiftDate = ""
                            shiftRole = ""
                            shiftStart = ""
                            shiftEnd = ""
                            shiftHours = ""
                            shiftPay = ""
                            shiftStatus = .upcoming
                            showAddShift = false
                        }
                    }
                }
                .onAppear {
                    if let start = timeDate(from: shiftStart) { shiftStartTime = start }
                    if let end = timeDate(from: shiftEnd) { shiftEndTime = end }
                    if shiftStart.isEmpty { shiftStart = timeString(shiftStartTime) }
                    if shiftEnd.isEmpty { shiftEnd = timeString(shiftEndTime) }
                    if !shiftStart.isEmpty && !shiftEnd.isEmpty { updateHoursFromTimes() }
                }
            }
        }
        .sheet(item: $editShift) { shift in
            NavigationStack {
                Form {
                    Section("Basics") {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        TextField("Role", text: $shiftRole)
                    }
                    Section("Time") {
                        HStack(spacing: 12) {
                            TextField("Start (HH:mm)", text: $shiftStart)
                                .keyboardType(.numbersAndPunctuation)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                            DatePicker("", selection: $shiftStartTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        HStack(spacing: 12) {
                            TextField("End (HH:mm)", text: $shiftEnd)
                                .keyboardType(.numbersAndPunctuation)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                            DatePicker("", selection: $shiftEndTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        TextField("Hours", text: $shiftHours)
                            .keyboardType(.numberPad)
                            .disabled(!shiftStart.isEmpty && !shiftEnd.isEmpty)
                            .foregroundStyle((!shiftStart.isEmpty && !shiftEnd.isEmpty) ? Color.secondary : Color.primary)
                    }
                    Section("Pay") {
                        TextField("Amount", text: $shiftPay)
                            .keyboardType(.numberPad)
                        Picker("Status", selection: $shiftStatus) {
                            Text("Upcoming").tag(WorkShift.ShiftStatus.upcoming)
                            Text("Completed").tag(WorkShift.ShiftStatus.completed)
                        }
                    }
                }
                .navigationTitle("Edit Shift")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { editShift = nil }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            let role = shiftRole.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !role.isEmpty else { return }
                            let hours = Int(shiftHours) ?? 0
                            let pay = Double(shiftPay) ?? 0
                            let updated = WorkShift(
                                id: shift.id,
                                day: dayString(selectedDate),
                                date: dateString(selectedDate),
                                role: role,
                                start: shiftStart,
                                end: shiftEnd,
                                hours: hours,
                                pay: pay,
                                status: shiftStatus
                            )
                            plannerVM.updateWorkShift(updated)
                            editShift = nil
                        }
                    }
                }
                .onAppear {
                    selectedDate = parseDate(shift.date) ?? Date()
                    shiftRole = shift.role
                    shiftStart = shift.start
                    shiftEnd = shift.end
                    shiftHours = String(shift.hours)
                    shiftPay = String(Int(shift.pay))
                    shiftStatus = shift.status
                    if let start = timeDate(from: shiftStart) { shiftStartTime = start }
                    if let end = timeDate(from: shiftEnd) { shiftEndTime = end }
                }
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            shiftDay = dayString(newDate)
            shiftDate = dateString(newDate)
        }
        .onChange(of: shiftStartTime) { _, newValue in
            shiftStart = timeString(newValue)
            updateHoursFromTimes()
        }
        .onChange(of: shiftEndTime) { _, newValue in
            shiftEnd = timeString(newValue)
            updateHoursFromTimes()
        }
        .onChange(of: shiftHours) { _, newValue in
            updateEndFromHours()
        }
        .onChange(of: shiftStart) { _, _ in
            if let date = timeDate(from: shiftStart) {
                let normalized = timeString(date)
                if normalized != shiftStart { shiftStart = normalized; return }
                if timeString(shiftStartTime) != normalized { shiftStartTime = date }
            }
            updateHoursFromTimes()
        }
        .onChange(of: shiftEnd) { _, _ in
            if let date = timeDate(from: shiftEnd) {
                let normalized = timeString(date)
                if normalized != shiftEnd { shiftEnd = normalized; return }
                if timeString(shiftEndTime) != normalized { shiftEndTime = date }
            }
            updateHoursFromTimes()
        }
        .onChange(of: viewMode) { _, _ in
            repeatMonthly = false
            repeatWeekly = false
        }
    }

    private var topSummaryCard: some View {
        let earnedValue = totalEarned.shortCurrency
        let earnedSub = "\(totalHours)h worked"
        let projectedValue = projectedEarnings.shortCurrency
        let upcomingValue = "\(upcoming.count)"
        return VStack(spacing: 20) {
            HStack(spacing: 12) {
                statCard(label: "Earned", value: earnedValue, sub: earnedSub)
                statCard(label: "Projected", value: projectedValue, sub: "this month")
                statCard(label: "Upcoming", value: upcomingValue, sub: "shifts left")
            }
            WeekDayStrip(shiftDays: shiftDays)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(grad)
        .overlay(Color.black.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var mainContent: some View {
        return VStack(spacing: 0) {
            topSummaryCard
            viewModeToggle
            infoCard
            tabFilter
            shiftsHeader
            shiftsList
            addShiftButton
        }
    }

    private var viewModeToggle: some View {
        return HStack(spacing: 10) {
            ForEach([("hours","2-hour view"),("monthly","Monthly view")],id:\.0) { id,label in
                FilterChip(label: label, isSelected: viewMode == id) { viewMode = id }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var infoCard: some View {
        return VStack(alignment: .leading, spacing: 4) {
            Text(viewMode == "hours" ? "Recommended block" : "Monthly pacing")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary)
            Text(viewMode == "hours" ? "2h × 3 sessions" : "5 blocks · 20h")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(viewMode == "hours"
                 ? "Split your shifts into smaller two-hour bursts when classes are tight."
                 : "Average pay per hour \(Double(totalEarned / max(Double(totalHours),1)).currencyRS)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .plannerModuleCard(accent: accent)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var tabFilter: some View {
        return HStack(spacing: 10) {
            ForEach([("week","Week"),("upcoming","Upcoming"),("completed","Completed")],id:\.0) { id,label in
                FilterChip(label: label, isSelected: activeTab == id) { activeTab = id }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var shiftsHeader: some View {
        return HStack {
            Text("Shifts")
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            Button { sortNewestFirst.toggle() } label: {
                Image(systemName: sortNewestFirst ? "arrow.down" : "arrow.up")
            }
            .accessibilityLabel("Change sort order")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var shiftsList: some View {
        return VStack(spacing: 10) {
            ForEach(sortedShifts) { shift in
                ZStack(alignment: .trailing) {
                    ShiftCard(shift: shift)
                    Button {
                        if shift.status != .completed { editShift = shift }
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.trailing, 12)
                    .buttonStyle(.plain)
                    .disabled(shift.status == .completed)
                    .accessibilityLabel("Edit shift")
                }
                .contextMenu {
                    Button {
                        if shift.status != .completed { editShift = shift }
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .disabled(shift.status == .completed)
                    Button(role: .destructive) {
                        plannerVM.deleteWorkShift(shift)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var addShiftButton: some View {
        return Button {
            showAddShift = true
        } label: {
            Label("Add Shift",systemImage:"plus")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(LinearGradient.ctaGrad)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 40)
    }

    private func statCard(label: String, value: String, sub: String) -> some View {
        GlassStatCard(
            label: label,
            value: value,
            sub: sub,
            valueColor: statValueColor,
            labelColor: statLabelColor,
            subColor: statSubColor
        )
    }

    private func updateEndFromHours() {
        guard shiftEnd.isEmpty else { return }
        guard let hours = Int(shiftHours), hours > 0 else { return }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        guard let start = fmt.date(from: shiftStart) else { return }
        if let end = Calendar.current.date(byAdding: .hour, value: hours, to: start) {
            let endText = fmt.string(from: end)
            if endText != shiftEnd {
                shiftEnd = endText
            }
        }
    }

    private func updateHoursFromTimes() {
        guard !shiftStart.isEmpty, !shiftEnd.isEmpty else { return }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        guard let start = fmt.date(from: shiftStart), let end = fmt.date(from: shiftEnd) else { return }
        var diff = end.timeIntervalSince(start)
        if diff < 0 { diff += 24 * 60 * 60 }
        let hours = Int(round(diff / 3600))
        guard hours > 0 else { return }
        let text = String(hours)
        if text != shiftHours {
            shiftHours = text
        }
    }

    private var weekdayQuickSelect: some View {
        HStack(spacing: 8) {
            ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], id: \.self) { day in
                Button(day) {
                    if let date = nearestDate(for: day, from: selectedDate) {
                        selectedDate = date
                    }
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(dayString(selectedDate) == day ? Color.uniBlue.opacity(0.2) : Color(UIColor.secondarySystemBackground))
                .clipShape(Capsule())
            }
        }
    }

    private func dayString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: date)
    }

    private func dateString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }

    private func timeDate(from text: String) -> Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        if let date = fmt.date(from: text) { return date }
        let alt = DateFormatter()
        alt.dateFormat = "H:mm"
        return alt.date(from: text)
    }

    private func firstOfMonth(_ date: Date) -> Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        return Calendar.current.date(from: comps) ?? date
    }

    private func nearestDate(for day: String, from base: Date) -> Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        guard let target = ["Sun":1,"Mon":2,"Tue":3,"Wed":4,"Thu":5,"Fri":6,"Sat":7][day] else { return nil }
        let weekday = Calendar.current.component(.weekday, from: base)
        let delta = target - weekday
        return Calendar.current.date(byAdding: .day, value: delta, to: base)
    }

    private func parseDate(_ text: String) -> Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.date(from: text)
    }
}

#Preview("Work") {
    let vm = PlannerViewModel(transactionsVM: TransactionsViewModel())
    vm.workShifts = MockData.shifts
    return NavigationStack { WorkScheduleView().environmentObject(vm).environmentObject(AppState()) }
}
