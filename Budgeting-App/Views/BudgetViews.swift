//
//  BudgetViews.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI
import Charts

// MARK: - Budget View
struct BudgetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var activeFilter: BudgetFilter = .all
    @State private var showAnalytics = false
    @State private var showEditBudget = false

    enum BudgetFilter: String, CaseIterable { case all="All"; case needs="Needs"; case wants="Wants"; case savings="Savings" }

    private var totalBudget: Double { budgetLimits.reduce(0){$0+$1.limit} }
    private var totalSpent:  Double { budgetLimits.reduce(0){$0+$1.spent} }

    private var budgetLimits: [BudgetLimit] {
        let needsLimit = appState.monthlyBudget * appState.needsPercent / 100
        let wantsLimit = appState.monthlyBudget * appState.wantsPercent / 100
        let savingsLimit = appState.monthlyBudget * appState.savingsPercent / 100

        let needsSpent = appState.transactions
            .filter { $0.budgetCategory == .needs && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        let wantsSpent = appState.transactions
            .filter { $0.budgetCategory == .wants && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        let savingsSpent = appState.transactions
            .filter { $0.budgetCategory == .savings && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }

        return [
            BudgetLimit(category: .needs, limit: needsLimit, spent: needsSpent),
            BudgetLimit(category: .wants, limit: wantsLimit, spent: wantsSpent),
            BudgetLimit(category: .savings, limit: savingsLimit, spent: savingsSpent)
        ]
    }

    private var filtered: [BudgetLimit] {
        activeFilter == .all ? budgetLimits
        : budgetLimits.filter { $0.category.rawValue == activeFilter.rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Dark header summary
                    glassSummaryHeader

                    // Filter tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(BudgetFilter.allCases, id:\.self) { f in
                                FilterChip(label:f.rawValue, isSelected:activeFilter == f) {
                                    activeFilter = f
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    // Cards
                    VStack(spacing: 14) {
                        ForEach(filtered) { limit in
                            BudgetCategoryCard(limit: limit)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.clear)
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BackButton { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showEditBudget = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                        Button {
                            showAnalytics = true
                        } label: {
                            Image(systemName: "chart.bar.xaxis")
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showAnalytics) { AnalyticsView() }
            .sheet(isPresented: $showEditBudget) {
                SetupBudgetView(isEditing: true)
            }
        }
    }

    // Dark glass summary at top
    private var glassSummaryHeader: some View {
        ZStack {
            LinearGradient.headerGrad
                .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Budget").font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.5))
                        Text(totalBudget.currencyRS)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Spent").font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.5))
                        Text(totalSpent.currencyRS)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                    }
                }
                UniProgressBar(progress: min(totalSpent / totalBudget, 1),
                               color: totalSpent > totalBudget ? Color.expense : Color.uniBlue,
                               height: 8)
                Text("\((totalBudget - totalSpent).currencyRS) remaining (\(Int(max(0,(totalBudget-totalSpent)/totalBudget*100)))%)")
                    .font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var timeFilter = "Month"
    private let timeFilters = ["Week", "Month", "Year"]

    private var filteredExpenses: [Transaction] {
        let expenses = appState.transactions.filter { $0.type == .expense }
        guard let start = startDate else { return expenses }
        return expenses.filter { $0.date >= start }
    }

    private var startDate: Date? {
        let cal = Calendar.current
        let now = Date()
        switch timeFilter {
        case "Week":
            return cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now))
        case "Month":
            return cal.date(byAdding: .day, value: -27, to: cal.startOfDay(for: now))
        case "Year":
            return cal.date(byAdding: .month, value: -11, to: cal.startOfDay(for: now))
        default:
            return nil
        }
    }

    private var totalSpent: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    private var topCategories: [(BudgetCategory, Double, Double)] {
        let totals = BudgetCategory.allCases.map { cat in
            (cat, filteredExpenses.filter { $0.budgetCategory == cat }.reduce(0) { $0 + $1.amount })
        }
        let total = totals.reduce(0) { $0 + $1.1 }
        return totals
            .sorted { $0.1 > $1.1 }
            .map { ($0.0, $0.1, total > 0 ? $0.1 / total : 0) }
    }

    private var weeklySpending: [WeeklySpend] {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())

        switch timeFilter {
        case "Week":
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE"
            return (0..<7).map { offset in
                let day = cal.date(byAdding: .day, value: -6 + offset, to: now) ?? now
                let dayTotal = filteredExpenses
                    .filter { cal.isDate($0.date, inSameDayAs: day) }
                    .reduce(0) { $0 + $1.amount }
                return WeeklySpend(day: fmt.string(from: day), amount: dayTotal)
            }
        case "Month":
            let start = cal.date(byAdding: .day, value: -27, to: now) ?? now
            var buckets = Array(repeating: 0.0, count: 4)
            for tx in filteredExpenses {
                let days = cal.dateComponents([.day], from: start, to: tx.date).day ?? 0
                let idx = min(3, max(0, days / 7))
                buckets[idx] += tx.amount
            }
            return buckets.enumerated().map { idx, amount in
                WeeklySpend(day: "W\(idx + 1)", amount: amount)
            }
        case "Year":
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM"
            return (0..<12).map { offset in
                let monthDate = cal.date(byAdding: .month, value: -11 + offset, to: now) ?? now
                let comps = cal.dateComponents([.year, .month], from: monthDate)
                let amount = filteredExpenses
                    .filter {
                        let txComps = cal.dateComponents([.year, .month], from: $0.date)
                        return txComps.year == comps.year && txComps.month == comps.month
                    }
                    .reduce(0) { $0 + $1.amount }
                return WeeklySpend(day: fmt.string(from: monthDate), amount: amount)
            }
        default:
            return []
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time filter
                HStack(spacing: 4) {
                    ForEach(timeFilters, id: \.self) { f in
                        let isActive = timeFilter == f
                        Button {
                            timeFilter = f
                        } label: {
                            Text(f)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(isActive ? Color.white : Color.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(isActive ? Color.uniBlue : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(4)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius:14))

                if filteredExpenses.isEmpty {
                    ContentUnavailableView(
                        "No analytics yet",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Add a few expenses to see trends here.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    // Total spending card
                    VStack(spacing: 12) {
                        Text("Total Spending").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                        Text(totalSpent.currencyRS)
                            .font(.system(size:40,weight:.bold,design:.rounded))
                    }
                    .frame(maxWidth:.infinity)
                    .padding(24)
                    .lightCard()

                    // Weekly bar chart
                    VStack(alignment:.leading, spacing:14) {
                        Text("Spending Trend").font(.system(size: 18, weight: .semibold))
                        Chart(weeklySpending) { day in
                            BarMark(
                                x:.value("Day", day.day),
                                y:.value("Amount", day.amount)
                            )
                            .foregroundStyle(LinearGradient.primaryGrad)
                            .cornerRadius(6)
                        }
                        .frame(height: 160)
                        .chartYAxis(.hidden)
                    }
                    .padding(20)
                    .lightCard()

                    // Top categories
                    VStack(alignment:.leading, spacing:14) {
                        Text("Top Spending Categories").font(.system(size: 18, weight: .semibold))
                        VStack(spacing:0) {
                            ForEach(Array(topCategories.enumerated()), id:\.offset) { idx, item in
                                let (cat, spent, pct) = item
                                VStack(spacing:0) {
                                    HStack(spacing:14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius:10)
                                                .fill(cat.color.opacity(0.12))
                                                .frame(width:44,height:44)
                                            Image(systemName: cat.icon)
                                                .font(.system(size:18))
                                                .foregroundStyle(cat.color)
                                        }
                                        VStack(alignment:.leading,spacing:4) {
                                            HStack {
                                                Text(cat.rawValue).font(.system(size: 15, weight: .semibold))
                                                Spacer()
                                                Text(spent.currencyRS).font(.system(size: 15, weight: .semibold))
                                            }
                                            HStack(spacing:10) {
                                                UniProgressBar(progress:pct,color:cat.color)
                                                Text("\(Int(pct*100))%")
                                                    .font(.system(size: 11)).foregroundStyle(Color.secondary)
                                                    .frame(width:30)
                                            }
                                        }
                                    }
                                    .padding(.vertical,14)
                                    if idx < topCategories.count - 1 {
                                        Divider().padding(.leading,58)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal,16).padding(.vertical,20)
                    .lightCard()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color.clear)
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
    }
}

#Preview("Budget")    { BudgetView().environmentObject(AppState()) }
#Preview("Analytics") { NavigationStack { AnalyticsView() } }
