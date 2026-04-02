//
//  SavingsGoalsViewModel.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-04-02.
//

import Foundation
import FirebaseFirestore

final class SavingsGoalsViewModel: ObservableObject {
    @Published var goals: [SavingsGoal] = []

    private var listener: ListenerRegistration?
    private let userIdProvider: () -> String?
    private let addTransaction: (Transaction) -> Void

    init(
        userIdProvider: @escaping () -> String? = { nil },
        addTransaction: @escaping (Transaction) -> Void = { _ in }
    ) {
        self.userIdProvider = userIdProvider
        self.addTransaction = addTransaction
    }

    func loadCached(uid: String) {
        goals = CoreDataCache.shared.fetchSavingsGoals(ownerId: uid)
    }

    func loadRemote(uid: String) {
        SavingsGoalService.listenGoals { result in
            DispatchQueue.main.async {
                if case let .success(items) = result {
                    self.goals = items
                    CoreDataCache.shared.replaceSavingsGoals(items, ownerId: uid)
                }
            }
        }?.remove()
    }

    func startListener(uid: String) {
        stopListener()
        listener = SavingsGoalService.listenGoals { result in
            DispatchQueue.main.async {
                if case let .success(items) = result {
                    self.goals = items
                    CoreDataCache.shared.replaceSavingsGoals(items, ownerId: uid)
                }
            }
        }
    }

    func stopListener() {
        listener?.remove()
        listener = nil
    }

    func addSavingsGoal(
        name: String,
        icon: String,
        colorHex: String,
        targetAmount: Double,
        currentAmount: Double,
        deadline: Date?
    ) {
        let goal = SavingsGoal(
            name: name,
            icon: icon,
            colorHex: colorHex,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            deadline: deadline
        )
        goals.insert(goal, at: 0)
        if let uid = userIdProvider() {
            CoreDataCache.shared.upsertSavingsGoal(goal, ownerId: uid)
        }
        SavingsGoalService.addGoal(goal) { error in
            if error != nil, let uid = self.userIdProvider() {
                if let data = try? JSONEncoder().encode(goal),
                   let payload = String(data: data, encoding: .utf8) {
                    CoreDataCache.shared.enqueuePendingWrite(ownerId: uid, type: "savings_goal_upsert", payload: payload)
                }
            }
        }

        if currentAmount > 0 {
            let tx = Transaction(
                name: "Savings: \(goal.name)",
                amount: currentAmount,
                type: .expense,
                category: nil,
                incomeSource: nil,
                budgetCategory: .savings,
                date: Date(),
                note: "Initial savings"
            )
            addTransaction(tx)
        }
    }

    func updateSavingsGoal(_ goal: SavingsGoal) {
        if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[idx] = goal
        }
        if let uid = userIdProvider() {
            CoreDataCache.shared.upsertSavingsGoal(goal, ownerId: uid)
        }
        SavingsGoalService.updateGoal(goal) { error in
            if error != nil, let uid = self.userIdProvider() {
                if let data = try? JSONEncoder().encode(goal),
                   let payload = String(data: data, encoding: .utf8) {
                    CoreDataCache.shared.enqueuePendingWrite(ownerId: uid, type: "savings_goal_upsert", payload: payload)
                }
            }
        }
    }

    func deleteSavingsGoal(_ goal: SavingsGoal) {
        goals.removeAll { $0.id == goal.id }
        SavingsGoalService.deleteGoal(goal.id)
        if let uid = userIdProvider() {
            CoreDataCache.shared.deleteSavingsGoal(goal.id, ownerId: uid)
        }
    }

    func addMoney(to goal: SavingsGoal, amount: Double) {
        guard amount > 0 else { return }
        var updated = goal
        updated.currentAmount += amount
        updateSavingsGoal(updated)

        let tx = Transaction(
            name: "Savings: \(goal.name)",
            amount: amount,
            type: .expense,
            category: nil,
            incomeSource: nil,
            budgetCategory: .savings,
            date: Date(),
            note: "Savings goal contribution"
        )
        addTransaction(tx)
    }
}
