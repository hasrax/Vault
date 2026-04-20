//
//  MockData.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import Foundation
import SwiftUI

// MARK: - Mock Data
// All types are defined in Models.swift — this file contains only data arrays.
// Phase 2: replace these arrays with @FetchRequest from Core Data.

struct MockData {

    // MARK: - User
    static let userName      = "Kasun"
    static let userEmail     = "kasun@university.lk"
    static let userAvatar    = "🎓"
    static let monthlyBudget: Double = 45000

    // MARK: - Transactions
    static var transactions: [Transaction] = [
        Transaction(name: "Rent payment",       amount: 18000, type: .expense, category: .housing,       budgetCategory: .needs,   date: daysAgo(1)),
        Transaction(name: "Grocery run",         amount: 3200,  type: .expense, category: .groceries,     budgetCategory: .needs,   date: daysAgo(2)),
        Transaction(name: "Part-time salary",    amount: 15000, type: .income,  incomeSource: .parttime,  budgetCategory: .savings, date: daysAgo(3)),
        Transaction(name: "Netflix",             amount: 1190,  type: .expense, category: .subscriptions, budgetCategory: .wants,   date: daysAgo(4)),
        Transaction(name: "Dinner with friends", amount: 2400,  type: .expense, category: .dining,        budgetCategory: .wants,   date: daysAgo(5)),
        Transaction(name: "Emergency fund",      amount: 5000,  type: .expense, category: .other,         budgetCategory: .savings, date: daysAgo(6)),
        Transaction(name: "Bus pass",            amount: 1500,  type: .expense, category: .transport,     budgetCategory: .needs,   date: daysAgo(7)),
        Transaction(name: "Cinema tickets",      amount: 800,   type: .expense, category: .entertainment, budgetCategory: .wants,   date: daysAgo(8)),
        Transaction(name: "Coffee shop",         amount: 450,   type: .expense, category: .coffee,        budgetCategory: .wants,   date: daysAgo(9)),
        Transaction(name: "Allowance",           amount: 20000, type: .income,  incomeSource: .allowance, budgetCategory: .savings, date: daysAgo(10)),
        Transaction(name: "Electric bill",       amount: 2800,  type: .expense, category: .utilities,     budgetCategory: .needs,   date: daysAgo(12)),
        Transaction(name: "Shopping",            amount: 3500,  type: .expense, category: .shopping,      budgetCategory: .wants,   date: daysAgo(14)),
    ]

    // MARK: - Budget Limits
    static var budgetLimits: [BudgetLimit] = [
        BudgetLimit(category: .needs,   limit: 22500, spent: 25500),
        BudgetLimit(category: .wants,   limit: 11250, spent: 4390),
        BudgetLimit(category: .savings, limit: 11250, spent: 5000),
    ]

    // MARK: - Spending by Category (Analytics)
    static var spendingByCategory: [SpendingByCategory] = [
        SpendingByCategory(category: .housing,       spent: 18000),
        SpendingByCategory(category: .groceries,     spent: 3200),
        SpendingByCategory(category: .dining,        spent: 2400),
        SpendingByCategory(category: .utilities,     spent: 2800),
        SpendingByCategory(category: .subscriptions, spent: 1190),
        SpendingByCategory(category: .transport,     spent: 1500),
        SpendingByCategory(category: .entertainment, spent: 800),
        SpendingByCategory(category: .coffee,        spent: 450),
    ]

    // MARK: - Weekly Spending (Analytics chart)
    static var weeklySpending: [WeeklySpend] = [
        WeeklySpend(day: "Mon", amount: 3200),
        WeeklySpend(day: "Tue", amount: 1200),
        WeeklySpend(day: "Wed", amount: 4500),
        WeeklySpend(day: "Thu", amount: 800),
        WeeklySpend(day: "Fri", amount: 6200),
        WeeklySpend(day: "Sat", amount: 2100),
        WeeklySpend(day: "Sun", amount: 900),
    ]

    // MARK: - Savings Goals
    static var savingsGoals: [SavingsGoal] = [
        SavingsGoal(name: "New Laptop",     icon: "💻", colorHex: "#3B82F6", targetAmount: 120000, currentAmount: 45000, deadline: monthsAhead(4)),
        SavingsGoal(name: "Emergency Fund", icon: "🛡️", colorHex: "#22C55E", targetAmount: 50000,  currentAmount: 5000,  deadline: monthsAhead(6)),
        SavingsGoal(name: "Summer Trip",    icon: "✈️", colorHex: "#8B5CF6", targetAmount: 80000,  currentAmount: 12000, deadline: monthsAhead(5)),
        SavingsGoal(name: "Textbooks",      icon: "📚", colorHex: "#F97316", targetAmount: 15000,  currentAmount: 15000, deadline: nil),
    ]

    // MARK: - Work Shifts
    static var shifts: [WorkShift] = [
        WorkShift(day: "Mon", date: "Mar 17", role: "Library Assistant", start: "09:00", end: "13:00", hours: 4, pay: 5200, status: .completed),
        WorkShift(day: "Wed", date: "Mar 19", role: "Library Assistant", start: "14:00", end: "18:00", hours: 4, pay: 5200, status: .completed),
        WorkShift(day: "Fri", date: "Mar 21", role: "Café Helper",       start: "08:00", end: "12:00", hours: 4, pay: 4800, status: .upcoming),
        WorkShift(day: "Sat", date: "Mar 22", role: "Library Assistant", start: "10:00", end: "14:00", hours: 4, pay: 5200, status: .upcoming),
        WorkShift(day: "Mon", date: "Mar 24", role: "Library Assistant", start: "09:00", end: "13:00", hours: 4, pay: 5200, status: .upcoming),
    ]

    // MARK: - Semester Goals
    static var semesterGoals: [SemesterGoal] = [
        SemesterGoal(title: "Stay under budget each month", completed: true,  progress: nil),
        SemesterGoal(title: "Save Rs 150,000 for summer",  completed: false, progress: 65),
        SemesterGoal(title: "Build emergency fund",         completed: false, progress: 40),
        SemesterGoal(title: "Reduce food spending by 20%", completed: true,  progress: nil),
    ]

    // MARK: - Important Dates
    static var importantDates: [ImportantDate] = [
        ImportantDate(title: "Tuition Due",   date: daysAhead(5),  type: .bill,   amount: 2500, icon: "🎓"),
        ImportantDate(title: "Financial Aid", date: daysAhead(10), type: .income, amount: 1500, icon: "💰"),
        ImportantDate(title: "Rent Due",      date: daysAhead(10), type: .bill,   amount: 650,  icon: "🏠"),
        ImportantDate(title: "Spring Break",  date: daysAhead(15), type: .event,  amount: nil,  icon: "🏖️"),
        ImportantDate(title: "Finals Week",   date: daysAhead(50), type: .event,  amount: nil,  icon: "📚"),
    ]

    // MARK: - Roommates
    static var roommates: [Roommate] = [
        Roommate(name: "Hasini",  avatar: "😊", color: .uniPurple),
        Roommate(name: "Tharaka", avatar: "😎", color: .uniBlue),
        Roommate(name: "Amali",   avatar: "🌟", color: .uniPink),
    ]

    // MARK: - Notifications
    static var notifications: [AppNotification] = [
        AppNotification(title: "Needs budget exceeded!",   message: "You've spent Rs.25,500 — Rs.3,000 over your Rs.22,500 Needs limit.",       type: .budget,  createdAt: Date()),
        AppNotification(title: "Shift reminder",           message: "Library Assistant shift starts in 1 hour. Don't forget to clock in!",       type: .work,    createdAt: daysAgo(0)),
        AppNotification(title: "Meal swipes running low",  message: "Only 63 swipes left for the semester — use ~1.8/day to last.",              type: .meal,    createdAt: daysAgo(0)),
        AppNotification(title: "Tuition due in 5 days",    message: "Rs.2,500 tuition payment is due on Mar 25. Make sure funds are ready.",     type: .planner, createdAt: daysAgo(1)),
        AppNotification(title: "Savings on track!",        message: "You've saved Rs.5,000 toward your emergency fund — 10% complete!",          type: .budget,  createdAt: daysAgo(2)),
    ]

    // MARK: - AI Coach starter messages
    static var coachMessages: [CoachMessage] = [
        CoachMessage(
            text: "Hi! I'm your Vault AI coach. I track your spending patterns to help you stay on budget. Ask me anything!",
            isFromUser: false,
            riskLevel: .safe
        ),
    ]

    // MARK: - Planner Modules
    static var plannerModules: [PlannerModule] = [
        PlannerModule(id: "semesterPlanner", title: "Semester Planner",  description: "Track academic weeks, tuition fees, and every major assignment in one glance.", pill: "Deadlines", icon: "📅", gradient: .semesterGrad, destination: "semesterPlanner"),
        PlannerModule(id: "workSchedule",    title: "Work Schedule",     description: "See upcoming shifts, projected earnings, and how many hours you still owe.",    pill: "Work",      icon: "💼", gradient: .workGrad,     destination: "workSchedule"),
        PlannerModule(id: "mealPlan",        title: "Meal & Study Plan", description: "Balance swipes, dining rupees, and study expenses so you don't run out.",       pill: "Lifestyle", icon: "🍽️", gradient: .orangeGrad,   destination: "mealPlan"),
        PlannerModule(id: "savings",         title: "Savings Goals",     description: "Auto-allocate rupees toward books, rent, and the semester emergency stash.",    pill: "Future",    icon: "🎯", gradient: .greenGrad,    destination: "savings"),
        PlannerModule(id: "splitBill",       title: "Split Bill",        description: "Settle rupee spends with roommates and friends in one view.",                   pill: "Roomies",   icon: "🤝", gradient: .splitGrad,    destination: "splitBill"),
        PlannerModule(id: "analytics",       title: "Analytics",         description: "Spending insights, weekly charts, and tips to spend smarter.",                  pill: "Insights",  icon: "📊", gradient: .tealGrad,     destination: "analytics"),
    ]

    // MARK: - Computed totals
    static var totalIncome:  Double { transactions.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount } }
    static var totalExpense: Double { transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    static var balance:      Double { monthlyBudget + totalIncome - totalExpense }

    static var weeklyHoursWorked: Int    { shifts.filter { $0.status == .completed }.reduce(0) { $0 + $1.hours } }
    static var weeklyEarnings:    Double { shifts.filter { $0.status == .completed }.reduce(0) { $0 + $1.pay   } }

    // MARK: - Date helpers
    static func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date()
    }
    static func daysAhead(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: n, to: Date()) ?? Date()
    }
    static func monthsAhead(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: n, to: Date()) ?? Date()
    }
}
