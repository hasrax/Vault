//
//  Budgeting_AppTests.swift
//  Budgeting-AppTests
//
//  Created by COBSCCOMP24.2P-023 on 2026-05-06.
//

import XCTest
@testable import Budgeting_App

//this checks the total spent, if its equals to sum of needs + wants + savings
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

//this checks and verify the key fields and created at are prserves see encode to decode
    func testBudgetHistoryFirestoreRoundTrip() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
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
            carryOverBalance: 2600,
            createdAt: fixedDate
        )
        guard let decoded = BudgetHistoryEntry.fromFirestore(entry.firestoreData) else {
            return XCTFail("Failed to decode BudgetHistoryEntry")
        }
        XCTAssertEqual(decoded.monthKey, entry.monthKey)
        XCTAssertEqual(decoded.monthlyBudget, entry.monthlyBudget, accuracy: 0.001)
        XCTAssertEqual(decoded.needsSpent, entry.needsSpent, accuracy: 0.001)
        XCTAssertEqual(decoded.wantsSpent, entry.wantsSpent, accuracy: 0.001)
        XCTAssertEqual(decoded.savingsSpent, entry.savingsSpent, accuracy: 0.001)
        XCTAssertEqual(decoded.carryOverAdded, entry.carryOverAdded, accuracy: 0.001)
        XCTAssertEqual(decoded.carryOverBalance, entry.carryOverBalance, accuracy: 0.001)
        let createdDelta = abs(decoded.createdAt.timeIntervalSince1970 - fixedDate.timeIntervalSince1970)
        XCTAssertLessThan(createdDelta, 0.001)
    }

//this tests if the defaults are 0 getting and decodes minimal firestore data
    func testBudgetHistoryFromFirestoreDefaults() {
        let dict: [String: Any] = ["monthKey": "2026-03"]
        let decoded = BudgetHistoryEntry.fromFirestore(dict)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.monthlyBudget, 0)
        XCTAssertEqual(decoded?.totalSpent, 0)
    }

//Tests and validates the progress, near limit and isoverbudget for a near-limit case
    func testBudgetLimitProgressAndNearLimit() {
        let limit = BudgetLimit(category: .needs, limit: 1000, spent: 760)
        XCTAssertEqual(limit.progress, 0.76, accuracy: 0.001)
        XCTAssertTrue(limit.isNearLimit)
        XCTAssertFalse(limit.isOverBudget)
    }

//checks and test the budget remaining limit-spent
    func testBudgetLimitRemaining() {
        let limit = BudgetLimit(category: .needs, limit: 1200, spent: 450)
        XCTAssertEqual(limit.remaining, 750, accuracy: 0.001)
    }

//tests over budget detection and status label
    func testBudgetLimitOverBudgetStatus() {
        let limit = BudgetLimit(category: .wants, limit: 500, spent: 700)
        XCTAssertTrue(limit.isOverBudget)
        XCTAssertEqual(limit.statusLabel, "Over budget")
    }

//confirms the on track status
    func testBudgetLimitOnTrackStatus() {
        let limit = BudgetLimit(category: .savings, limit: 1200, spent: 600)
        XCTAssertFalse(limit.isOverBudget)
        XCTAssertFalse(limit.isNearLimit)
        XCTAssertEqual(limit.statusLabel, "On track")
    }

//ensure the progress and tests
    func testSavingsGoalProgressAndCompletion() {
        let goal = SavingsGoal(name: "Trip", icon: "plane", colorHex: "#00FF00", targetAmount: 1000, currentAmount: 1000)
        XCTAssertEqual(goal.progress, 1.0, accuracy: 0.001)
        XCTAssertTrue(goal.isComplete)
    }

    func testSavingsGoalDaysLeftFuture() {
        let future = Calendar.current.date(byAdding: .day, value: 10, to: Date())
        let goal = SavingsGoal(name: "Trip", icon: "plane", colorHex: "#00FF00", targetAmount: 1000, currentAmount: 100, deadline: future)
        let expected = Calendar.current.dateComponents([.day], from: Date(), to: future ?? Date()).day ?? 0
        let actual = goal.daysLeft ?? 0
        XCTAssertTrue(actual == max(0, expected) || actual == max(0, expected - 1))
    }

    func testSavingsGoalDaysLeftPastIsZero() {
        let past = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        let goal = SavingsGoal(name: "Trip", icon: "plane", colorHex: "#00FF00", targetAmount: 1000, currentAmount: 100, deadline: past)
        XCTAssertEqual(goal.daysLeft, 0)
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

    func testTransactionDefaults() {
        let tx = Transaction(name: "Coffee", amount: 450, type: .expense)
        XCTAssertEqual(tx.budgetCategory, .wants)
        XCTAssertEqual(tx.note, "")
        XCTAssertNil(tx.linkedShiftId)
        XCTAssertNil(tx.linkedSplitBillId)
        XCTAssertNil(tx.linkedStudyExpenseId)
        XCTAssertNil(tx.linkedMealEntryId)
    }
}
