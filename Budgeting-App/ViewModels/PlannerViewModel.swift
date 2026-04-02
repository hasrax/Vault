//
//  PlannerViewModel.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-04-02.
//

import Foundation
import Combine
import FirebaseFirestore

final class PlannerViewModel: ObservableObject {
    @Published var importantDates: [ImportantDate] = []
    @Published var semesterGoals: [SemesterGoal] = []
    @Published var workShifts: [WorkShift] = []

    private var importantDatesListener: ListenerRegistration?
    private var semesterGoalsListener: ListenerRegistration?
    private var workShiftsListener: ListenerRegistration?
    private let transactionsVM: TransactionsViewModel

    init(transactionsVM: TransactionsViewModel) {
        self.transactionsVM = transactionsVM
    }

    func loadRemote() {
        PlannerService.fetchImportantDates { result in
            DispatchQueue.main.async {
                if case let .success(items) = result {
                    self.importantDates = items
                }
            }
        }
        PlannerService.fetchSemesterGoals { result in
            DispatchQueue.main.async {
                if case let .success(items) = result {
                    self.semesterGoals = items
                }
            }
        }
        PlannerService.fetchWorkShifts { result in
            DispatchQueue.main.async {
                if case let .success(items) = result {
                    self.workShifts = items
                }
            }
        }
    }

    func startListeners() {
        stopListeners()
        importantDatesListener = PlannerService.listenImportantDates { result in
            DispatchQueue.main.async {
                if case let .success(items) = result { self.importantDates = items }
            }
        }
        semesterGoalsListener = PlannerService.listenSemesterGoals { result in
            DispatchQueue.main.async {
                if case let .success(items) = result { self.semesterGoals = items }
            }
        }
        workShiftsListener = PlannerService.listenWorkShifts { result in
            DispatchQueue.main.async {
                if case let .success(items) = result { self.workShifts = items }
            }
        }
    }

    func stopListeners() {
        importantDatesListener?.remove()
        semesterGoalsListener?.remove()
        workShiftsListener?.remove()
        importantDatesListener = nil
        semesterGoalsListener = nil
        workShiftsListener = nil
    }

    // MARK: - Semester Goals
    func addSemesterGoal(title: String, progress: Int?) {
        let goal = SemesterGoal(title: title, completed: false, progress: progress)
        semesterGoals.insert(goal, at: 0)
        PlannerService.addSemesterGoal(goal)
    }

    func toggleSemesterGoal(_ goal: SemesterGoal) {
        guard let idx = semesterGoals.firstIndex(where: { $0.id == goal.id }) else { return }
        var updated = goal
        updated.completed.toggle()
        if updated.completed { updated.progress = nil }
        semesterGoals[idx] = updated
        PlannerService.updateSemesterGoal(updated)
    }

    func updateSemesterGoal(_ goal: SemesterGoal) {
        guard let idx = semesterGoals.firstIndex(where: { $0.id == goal.id }) else { return }
        semesterGoals[idx] = goal
        PlannerService.updateSemesterGoal(goal)
    }

    func deleteSemesterGoal(_ goal: SemesterGoal) {
        semesterGoals.removeAll { $0.id == goal.id }
        PlannerService.deleteSemesterGoal(goal.id)
    }

    // MARK: - Important Dates
    func addImportantDate(title: String, date: Date, type: ImportantDate.DateType, amount: Double?, icon: String) {
        let item = ImportantDate(title: title, date: date, type: type, amount: amount, icon: icon)
        importantDates.append(item)
        PlannerService.addImportantDate(item)
    }

    func updateImportantDate(_ item: ImportantDate) {
        guard let idx = importantDates.firstIndex(where: { $0.id == item.id }) else { return }
        importantDates[idx] = item
        PlannerService.updateImportantDate(item)
    }

    func deleteImportantDate(_ item: ImportantDate) {
        importantDates.removeAll { $0.id == item.id }
        PlannerService.deleteImportantDate(item.id)
    }

    // MARK: - Work Shifts
    func addWorkShift(day: String, date: String, role: String, start: String, end: String, hours: Int, pay: Double, status: WorkShift.ShiftStatus) {
        let shift = WorkShift(day: day, date: date, role: role, start: start, end: end, hours: hours, pay: pay, status: status)
        workShifts.append(shift)
        PlannerService.addWorkShift(shift)

        if pay > 0 {
            let txDate = parseShiftDate(date) ?? Date()
            let tx = Transaction(
                name: "Work: \(role)",
                amount: pay,
                type: .income,
                incomeSource: .parttime,
                budgetCategory: .savings,
                date: txDate,
                note: "Shift income",
                linkedShiftId: shift.id.uuidString
            )
            transactionsVM.addTransaction(tx)
        }
    }

    func updateWorkShift(_ shift: WorkShift) {
        guard let idx = workShifts.firstIndex(where: { $0.id == shift.id }) else { return }
        workShifts[idx] = shift
        PlannerService.updateWorkShift(shift)
        transactionsVM.updateLinkedShiftTransaction(shift)
    }

    func deleteWorkShift(_ shift: WorkShift) {
        workShifts.removeAll { $0.id == shift.id }
        PlannerService.deleteWorkShift(shift.id)
        transactionsVM.deleteLinkedShiftTransaction(shiftId: shift.id.uuidString)
    }

    func addMonthlyShifts(
        startDate: Date,
        months: Int,
        role: String,
        start: String,
        end: String,
        hours: Int,
        monthlyPay: Double,
        status: WorkShift.ShiftStatus
    ) {
        let calendar = Calendar.current
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "MMM yyyy"

        for offset in 0..<months {
            guard let date = calendar.date(byAdding: .month, value: offset, to: startDate) else { continue }
            let day = "Monthly"
            let dateStr = dateFmt.string(from: date)
            addWorkShift(
                day: day,
                date: dateStr,
                role: role,
                start: start,
                end: end,
                hours: hours,
                pay: monthlyPay,
                status: status
            )
        }
    }

    func addWeeklyShifts(
        startDate: Date,
        weeks: Int,
        role: String,
        start: String,
        end: String,
        hours: Int,
        pay: Double,
        status: WorkShift.ShiftStatus
    ) {
        let calendar = Calendar.current
        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "EEE"
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "MMM d"

        for offset in 0..<weeks {
            guard let date = calendar.date(byAdding: .day, value: offset * 7, to: startDate) else { continue }
            let day = dayFmt.string(from: date)
            let dateStr = dateFmt.string(from: date)
            addWorkShift(
                day: day,
                date: dateStr,
                role: role,
                start: start,
                end: end,
                hours: hours,
                pay: pay,
                status: status
            )
        }
    }

    private func parseShiftDate(_ dateString: String) -> Date? {
        let fmt1 = DateFormatter()
        fmt1.dateFormat = "MMM d"
        let fmt2 = DateFormatter()
        fmt2.dateFormat = "MMM yyyy"
        return fmt1.date(from: dateString) ?? fmt2.date(from: dateString)
    }
}
