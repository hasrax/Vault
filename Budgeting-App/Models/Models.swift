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

struct Transaction: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var amount: Double
    var type: TransactionType
    var category: ExpenseCategory?
    var incomeSource: IncomeSource?
    var budgetCategory: BudgetCategory
    var date: Date
    var note: String
    var linkedShiftId: String?
    var linkedSplitBillId: String?
    var linkedStudyExpenseId: String?
    var linkedMealEntryId: String?
    var receiptImageUrl: String?
    var receiptImageBase64: String?

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        type: TransactionType,
        category: ExpenseCategory? = nil,
        incomeSource: IncomeSource? = nil,
        budgetCategory: BudgetCategory = .wants,
        date: Date = Date(),
        note: String = "",
        linkedShiftId: String? = nil,
        linkedSplitBillId: String? = nil,
        linkedStudyExpenseId: String? = nil,
        linkedMealEntryId: String? = nil,
        receiptImageUrl: String? = nil,
        receiptImageBase64: String? = nil
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
        self.linkedShiftId  = linkedShiftId
        self.linkedSplitBillId = linkedSplitBillId
        self.linkedStudyExpenseId = linkedStudyExpenseId
        self.linkedMealEntryId = linkedMealEntryId
        self.receiptImageUrl = receiptImageUrl
        self.receiptImageBase64 = receiptImageBase64
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

struct SavingsGoal: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        targetAmount: Double,
        currentAmount: Double,
        deadline: Date? = nil
    ) {
        self.id            = id
        self.name          = name
        self.icon          = icon
        self.colorHex      = colorHex
        self.targetAmount  = targetAmount
        self.currentAmount = currentAmount
        self.deadline      = deadline
    }

    var color: Color { Color(hex: colorHex) }

    var progress:   Double { targetAmount > 0 ? min(currentAmount / targetAmount, 1.0) : 0 }
    var isComplete: Bool   { currentAmount >= targetAmount }

    var daysLeft: Int? {
        guard let d = deadline else { return nil }
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
        return max(0, diff)
    }
}

// MARK: - Work Shift

struct WorkShift: Identifiable, Equatable {
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

struct ImportantDate: Identifiable, Equatable {
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

// MARK: - Split Bill

enum SplitMethod: String, Codable, Equatable {
    case equal
    case custom
}

enum SplitBillStatus: String, Codable, Equatable {
    case open
    case settled
    case cancelled
}

enum SplitParticipantStatus: String, Codable, Equatable {
    case invited
    case accepted
    case declined
    case paid
}

struct SplitParticipant: Identifiable, Codable, Equatable {
    var userId: String
    var name: String
    var email: String
    var shareAmount: Double
    var status: SplitParticipantStatus
    var isCreator: Bool

    var id: String { userId }
}

struct SplitBill: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var totalAmount: Double
    var createdBy: String
    var createdAt: Date
    var splitMethod: SplitMethod
    var status: SplitBillStatus
    var participants: [SplitParticipant]
    var participantIds: [String]

    init(
        id: UUID = UUID(),
        title: String,
        totalAmount: Double,
        createdBy: String,
        createdAt: Date = Date(),
        splitMethod: SplitMethod,
        status: SplitBillStatus = .open,
        participants: [SplitParticipant]
    ) {
        self.id = id
        self.title = title
        self.totalAmount = totalAmount
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.splitMethod = splitMethod
        self.status = status
        self.participants = participants
        self.participantIds = participants.map { $0.userId }
    }
}

// MARK: - Notifications

struct AppNotification: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var message: String
    var type: NotiType
    var createdAt: Date
    var isRead: Bool

    init(id: UUID = UUID(), title: String, message: String,
         type: NotiType, createdAt: Date = Date(), isRead: Bool = false) {
        self.id      = id
        self.title   = title
        self.message = message
        self.type    = type
        self.createdAt = createdAt
        self.isRead = isRead
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, message, type, createdAt, isRead, time
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        type = try container.decodeIfPresent(NotiType.self, forKey: .type) ?? .planner
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        _ = try container.decodeIfPresent(String.self, forKey: .time)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        try container.encode(type, forKey: .type)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isRead, forKey: .isRead)
    }

    enum NotiType: String, Codable, Equatable {
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

struct CoachMessage: Identifiable, Codable {
    let id: UUID
    var text: String
    var isFromUser: Bool
    var riskLevel: RiskLevel?
    var createdAt: Date

    init(id: UUID = UUID(), text: String,
         isFromUser: Bool, riskLevel: RiskLevel? = nil,
         createdAt: Date = Date()) {
        self.id         = id
        self.text       = text
        self.isFromUser = isFromUser
        self.riskLevel  = riskLevel
        self.createdAt  = createdAt
    }

    enum RiskLevel: String, Codable {
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

// MARK: - Budget History

struct BudgetHistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var monthKey: String
    var monthlyBudget: Double
    var needsPercent: Double
    var wantsPercent: Double
    var savingsPercent: Double
    var needsSpent: Double
    var wantsSpent: Double
    var savingsSpent: Double
    var carryOverAdded: Double
    var carryOverBalance: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        monthKey: String,
        monthlyBudget: Double,
        needsPercent: Double,
        wantsPercent: Double,
        savingsPercent: Double,
        needsSpent: Double,
        wantsSpent: Double,
        savingsSpent: Double,
        carryOverAdded: Double,
        carryOverBalance: Double,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.monthKey = monthKey
        self.monthlyBudget = monthlyBudget
        self.needsPercent = needsPercent
        self.wantsPercent = wantsPercent
        self.savingsPercent = savingsPercent
        self.needsSpent = needsSpent
        self.wantsSpent = wantsSpent
        self.savingsSpent = savingsSpent
        self.carryOverAdded = carryOverAdded
        self.carryOverBalance = carryOverBalance
        self.createdAt = createdAt
    }

    var totalSpent: Double {
        needsSpent + wantsSpent + savingsSpent
    }

    var firestoreData: [String: Any] {
        [
            "id": id.uuidString,
            "monthKey": monthKey,
            "monthlyBudget": monthlyBudget,
            "needsPercent": needsPercent,
            "wantsPercent": wantsPercent,
            "savingsPercent": savingsPercent,
            "needsSpent": needsSpent,
            "wantsSpent": wantsSpent,
            "savingsSpent": savingsSpent,
            "carryOverAdded": carryOverAdded,
            "carryOverBalance": carryOverBalance,
            "createdAt": createdAt.timeIntervalSince1970
        ]
    }

    static func fromFirestore(_ dict: [String: Any]) -> BudgetHistoryEntry? {
        let id = (dict["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()
        guard let monthKey = dict["monthKey"] as? String else { return nil }
        let monthlyBudget = dict["monthlyBudget"] as? Double ?? 0
        let needsPercent = dict["needsPercent"] as? Double ?? 0
        let wantsPercent = dict["wantsPercent"] as? Double ?? 0
        let savingsPercent = dict["savingsPercent"] as? Double ?? 0
        let needsSpent = dict["needsSpent"] as? Double ?? 0
        let wantsSpent = dict["wantsSpent"] as? Double ?? 0
        let savingsSpent = dict["savingsSpent"] as? Double ?? 0
        let carryOverAdded = dict["carryOverAdded"] as? Double ?? 0
        let carryOverBalance = dict["carryOverBalance"] as? Double ?? 0
        let createdAtSeconds = dict["createdAt"] as? TimeInterval ?? Date().timeIntervalSince1970
        let createdAt = Date(timeIntervalSince1970: createdAtSeconds)
        return BudgetHistoryEntry(
            id: id,
            monthKey: monthKey,
            monthlyBudget: monthlyBudget,
            needsPercent: needsPercent,
            wantsPercent: wantsPercent,
            savingsPercent: savingsPercent,
            needsSpent: needsSpent,
            wantsSpent: wantsSpent,
            savingsSpent: savingsSpent,
            carryOverAdded: carryOverAdded,
            carryOverBalance: carryOverBalance,
            createdAt: createdAt
        )
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

// MARK: - Meal Plan

enum MealType: String, CaseIterable, Identifiable, Codable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var label: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch:     return "Lunch"
        case .dinner:    return "Dinner"
        case .snack:     return "Snack"
        }
    }

    var emoji: String {
        switch self {
        case .breakfast: return "🥣"
        case .lunch:     return "🥗"
        case .dinner:    return "🍲"
        case .snack:     return "🍎"
        }
    }
}

struct MealEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var date: Date
    var type: MealType
    var amount: Double
    var location: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        type: MealType,
        amount: Double = 0,
        location: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.type = type
        self.amount = amount
        self.location = location
        self.notes = notes
    }
}

struct StudyExpense: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var amount: Double
    var date: Date
    var category: String
    var notes: String?

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        date: Date,
        category: String,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.notes = notes
    }
}

// MARK: - User Profile

struct UserProfile: Identifiable {
    let id: String
    var name: String
    var email: String
    var createdAt: Date?
    var photoURL: String?
    var photoBase64: String?
    var monthlyBudget: Double?
    var needsPercent: Double?
    var wantsPercent: Double?
    var savingsPercent: Double?
    var hasCompletedSetup: Bool
}

// MARK: - Planner Theme

/// Per-module accent colours that the student can customise.
/// Defaults match the existing gradient start colours in DesignSystem.swift.
struct PlannerTheme: Codable, Equatable {
    var semesterHex:  String = "#4C1D95"
    var workHex:      String = "#0F766E"
    var mealHex:      String = "#F97316"
    var savingsHex:   String = "#22C55E"
    var splitBillHex: String = "#7C3AED"
    var analyticsHex: String = "#14B8A6"

    // Primary hex for a given module id
    func hex(for moduleId: String) -> String {
        switch moduleId {
        case "semesterPlanner": return semesterHex
        case "workSchedule":    return workHex
        case "mealPlan":        return mealHex
        case "savings":         return savingsHex
        case "splitBill":       return splitBillHex
        case "analytics":       return analyticsHex
        default:                return "#1E3A8A"
        }
    }

    // SwiftUI Color
    func color(for moduleId: String) -> Color {
        Color(hex: hex(for: moduleId))
    }

    // Vibrant card/header gradient — used in PlannerView cards & sub-screen headers
    func gradient(for moduleId: String) -> LinearGradient {
        let c = color(for: moduleId)
        // Darken the colour slightly for the start stop so headers have depth
        return LinearGradient(
            colors: [c.opacity(0.80), c],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Human readable name for the picker UI
    static func moduleName(for id: String) -> String {
        switch id {
        case "semesterPlanner": return "Semester Planner"
        case "workSchedule":    return "Work Schedule"
        case "mealPlan":        return "Meal & Study"
        case "savings":         return "Savings Goals"
        case "splitBill":       return "Split Bill"
        case "analytics":       return "Analytics"
        default:                return id
        }
    }

    // Module icon for the picker UI
    static func moduleIcon(for id: String) -> String {
        switch id {
        case "semesterPlanner": return "📅"
        case "workSchedule":    return "💼"
        case "mealPlan":        return "🍽️"
        case "savings":         return "🎯"
        case "splitBill":       return "🤝"
        case "analytics":       return "📊"
        default:                return "🎨"
        }
    }

    // All module IDs in display order
    static let allModuleIds = [
        "semesterPlanner", "workSchedule", "mealPlan",
        "savings", "splitBill", "analytics"
    ]

    // Mutate a single module's hex
    mutating func setHex(_ hex: String, for moduleId: String) {
        switch moduleId {
        case "semesterPlanner": semesterHex  = hex
        case "workSchedule":    workHex      = hex
        case "mealPlan":        mealHex      = hex
        case "savings":         savingsHex   = hex
        case "splitBill":       splitBillHex = hex
        case "analytics":       analyticsHex = hex
        default: break
        }
    }

    // Firestore dict representation
    var firestoreData: [String: Any] {
        [
            "semesterHex":  semesterHex,
            "workHex":      workHex,
            "mealHex":      mealHex,
            "savingsHex":   savingsHex,
            "splitBillHex": splitBillHex,
            "analyticsHex": analyticsHex,
        ]
    }

    init() {}

    init?(from dict: [String: Any]) {
        guard !dict.isEmpty else { return nil }
        semesterHex  = dict["semesterHex"]  as? String ?? "#4C1D95"
        workHex      = dict["workHex"]      as? String ?? "#0F766E"
        mealHex      = dict["mealHex"]      as? String ?? "#F97316"
        savingsHex   = dict["savingsHex"]   as? String ?? "#22C55E"
        splitBillHex = dict["splitBillHex"] as? String ?? "#7C3AED"
        analyticsHex = dict["analyticsHex"] as? String ?? "#14B8A6"
    }
}
