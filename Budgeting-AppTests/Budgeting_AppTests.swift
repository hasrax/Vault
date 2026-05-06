//
//  Budgeting_AppTests.swift
//  Budgeting-AppTests
//
//  Created by COBSCCOMP24.2P-023 on 2026-05-06.
//

import XCTest
@testable import Budgeting_App

final class Budgeting_AppTests: XCTestCase {
    func testBudgetHistoryTotalSpent() {
        let entry = BudgetHistoryEntry(
            monthKey: "2026-04",
            monthlyBudget: 4000,
            needsPercent: 50,
            wantsPercent: 30,
            savingsPercent: 20,
            needsSpent: 1200,
            wantsSpent: 800,
            savingsSpent: 400,
            carryOverAdded: 600,
            carryOverBalance: 1200
        )
        XCTAssertEqual(entry.totalSpent, 2400, accuracy: 0.001)
    }

    func testBudgetHistoryFirestoreRoundTrip() {
        let entry = BudgetHistoryEntry(
            monthKey: "2026-04",
            monthlyBudget: 3500,
            needsPercent: 50,
            wantsPercent: 25,
            savingsPercent: 25,
            needsSpent: 900,
            wantsSpent: 700,
            savingsSpent: 300,
            carryOverAdded: 1600,
            carryOverBalance: 2600
        )
        let decoded = BudgetHistoryEntry.fromFirestore(entry.firestoreData)
        XCTAssertEqual(decoded, entry)
    }

    func testBudgetLimitProgressAndNearLimit() {
        let limit = BudgetLimit(category: .needs, limit: 1000, spent: 760)
        XCTAssertEqual(limit.progress, 0.76, accuracy: 0.001)
        XCTAssertTrue(limit.isNearLimit)
        XCTAssertFalse(limit.isOverBudget)
    }

    func testBudgetLimitOverBudgetStatus() {
        let limit = BudgetLimit(category: .wants, limit: 500, spent: 700)
        XCTAssertTrue(limit.isOverBudget)
        XCTAssertEqual(limit.statusLabel, "Over budget")
    }

    func testBudgetLimitOnTrackStatus() {
        let limit = BudgetLimit(category: .savings, limit: 1200, spent: 600)
        XCTAssertFalse(limit.isOverBudget)
        XCTAssertFalse(limit.isNearLimit)
        XCTAssertEqual(limit.statusLabel, "On track")
    }

    func testSavingsGoalProgressAndCompletion() {
        let goal = SavingsGoal(name: "Trip", icon: "✈️", colorHex: "#00FF00", targetAmount: 1000, currentAmount: 1000)
        XCTAssertEqual(goal.progress, 1.0, accuracy: 0.001)
        XCTAssertTrue(goal.isComplete)
    }

    func testExpenseCategoryBudgetMapping() {
        XCTAssertEqual(ExpenseCategory.housing.budgetCategory, .needs)
        XCTAssertEqual(ExpenseCategory.dining.budgetCategory, .wants)
        XCTAssertEqual(ExpenseCategory.education.budgetCategory, .savings)
    }

    func testSemesterPlanStatusLabels() {
        XCTAssertEqual(SemesterPlanStatus.upcoming.label, "Upcoming")
        XCTAssertEqual(SemesterPlanStatus.current.label, "Current")
        XCTAssertEqual(SemesterPlanStatus.completed.label, "Completed")
    }
}
