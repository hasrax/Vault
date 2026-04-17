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
    @EnvironmentObject var transactionsVM: TransactionsViewModel
    @State private var activeFilter: BudgetFilter = .all
    @State private var showAnalytics = false
    @State private var showEditBudget = false
    @State private var showHistory = false

    enum BudgetFilter: String, CaseIterable { case all="All"; case needs="Needs"; case wants="Wants"; case savings="Savings" }

    private var totalBudget: Double { budgetLimits.reduce(0){$0+$1.limit} }
    private var totalSpent:  Double { budgetLimits.reduce(0){$0+$1.spent} }

    private var currentMonthExpenses: [Transaction] {
        let cal = Calendar.current
        return transactionsVM.transactions.filter {
            $0.type == .expense && cal.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
    }

    private var budgetLimits: [BudgetLimit] {
        let needsLimit = appState.monthlyBudget * appState.needsPercent / 100
        let wantsLimit = appState.monthlyBudget * appState.wantsPercent / 100
        let savingsLimit = (appState.monthlyBudget * appState.savingsPercent / 100) + appState.carryOverBalance

        let needsSpent = currentMonthExpenses
            .filter { $0.budgetCategory == .needs }
            .reduce(0) { $0 + $1.amount }
        let wantsSpent = currentMonthExpenses
            .filter { $0.budgetCategory == .wants }
            .reduce(0) { $0 + $1.amount }
        let savingsSpent = currentMonthExpenses
            .filter { $0.budgetCategory == .savings }
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

                    // History summary
                    VStack(spacing: 10) {
                        HStack {
                            Text("Monthly history")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Button("See all") { showHistory = true }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.uniBlue)
                        }

                        if let latest = appState.budgetHistory.first {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formatMonth(latest.monthKey))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.primary)
                                    Text("Spent \(latest.totalSpent.currencyRS)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Carry-over")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.secondary)
                                    Text(latest.carryOverAdded.currencyRS)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.primary)
                                }
                            }
                            .padding(12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Text("No history yet")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

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
            .ignoresSafeArea(edges: .top)
            .background(Color.clear)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showAnalytics) { AnalyticsView() }
            .sheet(isPresented: $showEditBudget) {
                SetupBudgetView(isEditing: true)
            }
            .sheet(isPresented: $showHistory) {
                BudgetHistoryView()
            }
        }
        .statusBarStyle(.lightContent)
    }

    // Dark glass summary at top
    private var glassSummaryHeader: some View {
        let topInset: CGFloat = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 47

        return ZStack(alignment: .bottom) {
            HomeHeaderBackground()
                .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))
                .ignoresSafeArea(edges: .top)

            let safeTotal = max(totalBudget, 1)
            VStack(spacing: 12) {
                HStack {
                    BackButton(action: { dismiss() }, isDark: true)
                    Spacer()
                    Button {
                        showEditBudget = true
                    } label: {
                        Text("Edit")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(headerText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(headerButtonBg)
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Edit Budget")
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Budget")
                            .font(.system(size: 12))
                            .foregroundStyle(headerSubText)
                        Text(totalBudget.currencyRS)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(headerText)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Spent")
                            .font(.system(size: 12))
                            .foregroundStyle(headerSubText)
                        Text(totalSpent.currencyRS)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(headerText)
                    }
                }
                UniProgressBar(progress: min(totalSpent / safeTotal, 1),
                               color: totalSpent > totalBudget ? Color.expense : Color.uniBlue,
                               height: 8)
                Text("\((totalBudget - totalSpent).currencyRS) remaining (\(Int(max(0,(totalBudget-totalSpent)/safeTotal*100)))%)")
                    .font(.system(size: 12))
                    .foregroundStyle(headerSubText)
                if appState.carryOverBalance > 0 {
                    Text("Savings pool: \(appState.carryOverBalance.currencyRS)")
                        .font(.system(size: 12))
                        .foregroundStyle(headerSubText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, topInset + 10)
            .padding(.bottom, 24)
        }
        .frame(height: topInset + 180)
        .padding(.bottom, 4)
    }

    private var headerText: Color { Color.white }
    private var headerSubText: Color { Color.white.opacity(0.5) }
    private var headerButtonBg: Color { Color.white.opacity(0.18) }

    private func formatMonth(_ monthKey: String) -> String {
        let parse = DateFormatter()
        parse.dateFormat = "yyyy-MM"
        let display = DateFormatter()
        display.dateFormat = "MMM yyyy"
        if let date = parse.date(from: monthKey) {
            return display.string(from: date)
        }
        return monthKey
    }
}

// MARK: - Budget History View
struct BudgetHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.budgetHistory.sorted { $0.monthKey > $1.monthKey }) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(formatMonth(entry.monthKey))
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Text(entry.monthlyBudget.currencyRS)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                        }
                        Text("Spent \(entry.totalSpent.currencyRS)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                        Text("Needs \(entry.needsSpent.currencyRS) · Wants \(entry.wantsSpent.currencyRS) · Savings \(entry.savingsSpent.currencyRS)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                        Text("Carry-over added: \(entry.carryOverAdded.currencyRS)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                        Text("Savings pool: \(entry.carryOverBalance.currencyRS)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Budget History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formatMonth(_ monthKey: String) -> String {
        let parse = DateFormatter()
        parse.dateFormat = "yyyy-MM"
        let display = DateFormatter()
        display.dateFormat = "MMM yyyy"
        if let date = parse.date(from: monthKey) {
            return display.string(from: date)
        }
        return monthKey
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var transactionsVM: TransactionsViewModel
    @State private var timeFilter = "Month"
    private let timeFilters = ["Week", "Month", "Year"]

    private var filteredExpenses: [Transaction] {
        let expenses = transactionsVM.transactions.filter { $0.type == .expense }
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

    private var accent: Color { appState.plannerTheme.color(for: "analytics") }

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
                        Text("Total Spending")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.75))
                        Text(totalSpent.currencyRS)
                            .font(.system(size:40,weight:.bold,design:.rounded))
                            .foregroundStyle(Color.white)
                    }
                    .frame(maxWidth:.infinity)
                    .padding(24)
                    .background(appState.plannerTheme.gradient(for: "analytics"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(accent.opacity(0.45), lineWidth: 1)
                    )

                    // Weekly bar chart
                    VStack(alignment:.leading, spacing:14) {
                        Text("Spending Trend").font(.system(size: 18, weight: .semibold))
                        Chart(weeklySpending) { day in
                            BarMark(
                                x:.value("Day", day.day),
                                y:.value("Amount", day.amount)
                            )
                            .foregroundStyle(accent)
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

#Preview("Budget") {
    let vm = TransactionsViewModel()
    vm.transactions = MockData.transactions
    return BudgetView()
        .environmentObject(AppState())
        .environmentObject(vm)
}
#Preview("Analytics") {
    let vm = TransactionsViewModel()
    vm.transactions = MockData.transactions
    return NavigationStack { AnalyticsView()
        .environmentObject(AppState())
        .environmentObject(vm)
    }
}
