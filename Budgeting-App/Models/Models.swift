//
//  Untitled.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import Foundation
import SwiftUI

// MARK: - Transaction Types

enum TransactionType: String, CaseIterable, Codable {
    case income  = "income"
    case expense = "expense"
}

// MARK: - Expense Categories

enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case housing       = "Housing"
    case groceries     = "Groceries"
    case transport     = "Transport"
    case utilities     = "Utilities"
    case dining        = "Dining Out"
    case entertainment = "Entertainment"
    case shopping      = "Shopping"
    case subscriptions = "Subscriptions"
    case healthcare    = "Healthcare"
    case education     = "Education"
    case coffee        = "Coffee"
    case other         = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .housing:       return "🏠"
        case .groceries:     return "🛒"
        case .transport:     return "🚌"
        case .utilities:     return "⚡"
        case .dining:        return "🍽️"
        case .entertainment: return "🎬"
        case .shopping:      return "🛍️"
        case .subscriptions: return "📱"
        case .healthcare:    return "💊"
        case .education:     return "📚"
        case .coffee:        return "☕"
        case .other:         return "💰"
        }
    }

    var color: Color {
        switch self {
        case .housing, .groceries, .transport, .utilities:
            return Color.needsBlue
        case .dining, .entertainment, .shopping, .subscriptions, .coffee:
            return Color.wantsPurple
        case .healthcare, .education, .other:
            return Color.savingsGreen
        }
    }

    var budgetCategory: BudgetCategory {
        switch self {
        case .housing, .groceries, .transport, .utilities:
            return .needs
        case .dining, .entertainment, .shopping, .subscriptions, .coffee:
            return .wants
        case .healthcare, .education, .other:
            return .savings
        }
    }
}

// MARK: - Income Sources

enum IncomeSource: String, CaseIterable, Identifiable, Codable {
    case salary    = "Salary"
    case freelance = "Freelance"
    case parttime  = "Part-time"
    case allowance = "Allowance"
    case gift      = "Gift"
    case other     = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .salary:    return "💼"
        case .freelance: return "💻"
        case .parttime:  return "🏢"
        case .allowance: return "🎓"
        case .gift:      return "🎁"
        case .other:     return "💵"
        }
    }
}

// MARK: - Transaction

struct Transaction: Identifiable, Codable {
    let id: UUID
    var name: String
    var amount: Double
    var type: TransactionType
    var category: ExpenseCategory?
    var incomeSource: IncomeSource?
    var budgetCategory: BudgetCategory
    var date: Date
    var note: String

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        type: TransactionType,
        category: ExpenseCategory? = nil,
        incomeSource: IncomeSource? = nil,
        budgetCategory: BudgetCategory = .wants,
        date: Date = Date(),
        note: String = ""
    ) {
        self.id             = id
        self.name           = name
        self.amount         = amount
        self.type           = type
        self.category       = category
        self.incomeSource   = incomeSource
        self.budgetCategory = budgetCategory
        self.date           = date
        self.note           = note
    }
}

// MARK: - Budget Limit

struct BudgetLimit: Identifiable {
    let id: UUID
    var category: BudgetCategory
    var limit: Double
    var spent: Double

    init(id: UUID = UUID(), category: BudgetCategory, limit: Double, spent: Double) {
        self.id       = id
        self.category = category
        self.limit    = limit
        self.spent    = spent
    }

    var remaining:    Double { limit - spent }
    var progress:     Double { limit > 0 ? min(spent / limit, 1.0) : 0 }
    var isOverBudget: Bool   { spent > limit }
    var isNearLimit:  Bool   { progress >= 0.75 && !isOverBudget }

    var progressColor: Color {
        if isOverBudget { return Color.expense }
        if isNearLimit  { return Color.warning }
        return category.color
    }

    var statusLabel: String {
        if isOverBudget { return "Over budget" }
        if isNearLimit  { return "Near limit" }
        return "On track"
    }
}

// MARK: - Savings Goal

struct SavingsGoal: Identifiable {
    let id: UUID
    var name: String
    var icon: String
    var color: Color
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: Color,
        targetAmount: Double,
        currentAmount: Double,
        deadline: Date? = nil
    ) {
        self.id            = id
        self.name          = name
        self.icon          = icon
        self.color         = color
        self.targetAmount  = targetAmount
        self.currentAmount = currentAmount
        self.deadline      = deadline
    }

    var progress:   Double { targetAmount > 0 ? min(currentAmount / targetAmount, 1.0) : 0 }
    var isComplete: Bool   { currentAmount >= targetAmount }

    var daysLeft: Int? {
        guard let d = deadline else { return nil }
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
        return max(0, diff)
    }
}

// MARK: - Work Shift

struct WorkShift: Identifiable {
    let id: UUID
    var day: String
    var date: String
    var role: String
    var start: String
    var end: String
    var hours: Int
    var pay: Double
    var status: ShiftStatus

    init(
        id: UUID = UUID(),
        day: String, date: String, role: String,
        start: String, end: String,
        hours: Int, pay: Double,
        status: ShiftStatus
    ) {
        self.id     = id
        self.day    = day
        self.date   = date
        self.role   = role
        self.start  = start
        self.end    = end
        self.hours  = hours
        self.pay    = pay
        self.status = status
    }

    enum ShiftStatus: String, Codable {
        case completed, upcoming
    }
}

// MARK: - Semester

struct SemesterGoal: Identifiable {
    let id: UUID
    var title: String
    var completed: Bool
    var progress: Int?

    init(id: UUID = UUID(), title: String, completed: Bool, progress: Int? = nil) {
        self.id        = id
        self.title     = title
        self.completed = completed
        self.progress  = progress
    }
}

struct ImportantDate: Identifiable {
    let id: UUID
    var title: String
    var date: Date
    var type: DateType
    var amount: Double?
    var icon: String

    init(id: UUID = UUID(), title: String, date: Date,
         type: DateType, amount: Double? = nil, icon: String) {
        self.id     = id
        self.title  = title
        self.date   = date
        self.type   = type
        self.amount = amount
        self.icon   = icon
    }

    enum DateType { case bill, income, event }

    var color: Color {
        switch type {
        case .bill:   return Color.expense
        case .income: return Color.income
        case .event:  return Color.uniBlue
        }
    }
}

// MARK: - Social

struct Roommate: Identifiable {
    let id: UUID
    var name: String
    var avatar: String
    var color: Color

    init(id: UUID = UUID(), name: String, avatar: String, color: Color) {
        self.id     = id
        self.name   = name
        self.avatar = avatar
        self.color  = color
    }
}

// MARK: - Notifications

struct AppNotification: Identifiable {
    let id: UUID
    var title: String
    var message: String
    var type: NotiType
    var time: String

    init(id: UUID = UUID(), title: String, message: String,
         type: NotiType, time: String) {
        self.id      = id
        self.title   = title
        self.message = message
        self.type    = type
        self.time    = time
    }

    enum NotiType: String {
        case budget, meal, work, planner

        var chipColor: Color {
            switch self {
            case .budget:  return Color.uniBlue
            case .meal:    return Color.uniOrange
            case .work:    return Color.uniGreen
            case .planner: return Color.uniPurple
            }
        }
    }
}

// MARK: - AI Coach

struct CoachMessage: Identifiable {
    let id: UUID
    var text: String
    var isFromUser: Bool
    var riskLevel: RiskLevel?

    init(id: UUID = UUID(), text: String,
         isFromUser: Bool, riskLevel: RiskLevel? = nil) {
        self.id         = id
        self.text       = text
        self.isFromUser = isFromUser
        self.riskLevel  = riskLevel
    }

    enum RiskLevel {
        case safe, caution, danger

        var color: Color {
            switch self {
            case .safe:    return Color.income
            case .caution: return Color.warning
            case .danger:  return Color.expense
            }
        }
        var icon: String {
            switch self {
            case .safe:    return "checkmark.circle.fill"
            case .caution: return "exclamationmark.triangle.fill"
            case .danger:  return "xmark.circle.fill"
            }
        }
        var label: String {
            switch self {
            case .safe:    return "Looks good"
            case .caution: return "Be careful"
            case .danger:  return "Warning"
            }
        }
    }
}

// MARK: - Analytics

struct SpendingByCategory: Identifiable {
    let id: UUID
    var category: ExpenseCategory
    var spent: Double

    init(id: UUID = UUID(), category: ExpenseCategory, spent: Double) {
        self.id       = id
        self.category = category
        self.spent    = spent
    }
}

struct WeeklySpend: Identifiable {
    let id: UUID
    var day: String
    var amount: Double

    init(id: UUID = UUID(), day: String, amount: Double) {
        self.id     = id
        self.day    = day
        self.amount = amount
    }
}

// MARK: - Planner Module

struct PlannerModule: Identifiable {
    let id: String
    var title: String
    var description: String
    var pill: String
    var icon: String
    var gradient: LinearGradient
    var destination: String
}

// MARK: - User Profile

struct UserProfile: Identifiable {
    let id: String
    var name: String
    var email: String
    var createdAt: Date?
    var monthlyBudget: Double?
    var needsPercent: Double?
    var wantsPercent: Double?
    var savingsPercent: Double?
    var hasCompletedSetup: Bool
}
