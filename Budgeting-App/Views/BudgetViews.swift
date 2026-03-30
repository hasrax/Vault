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
    @State private var timeFilter = "Month"
    private let timeFilters = ["Week", "Month", "Year"]

    private var topCategories: [(ExpenseCategory, Double, Double)] {
        let total = MockData.spendingByCategory.reduce(0) { $0 + $1.spent }
        return MockData.spendingByCategory
            .sorted { $0.spent > $1.spent }
            .prefix(5)
            .map { ($0.category, $0.spent, total > 0 ? $0.spent / total : 0) }
    }
    private var totalSpent: Double { MockData.spendingByCategory.reduce(0){$0+$1.spent} }
    private var maxWeekly: Double   { MockData.weeklySpending.map(\.amount).max() ?? 1 }

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

                // Total spending card
                VStack(spacing: 12) {
                    Text("Total Spending").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    Text(totalSpent.currencyRS)
                        .font(.system(size:40,weight:.bold,design:.rounded))
                    HStack(spacing:6) {
                        Image(systemName:"arrow.down").font(.system(size: 12))
                        Text("12% less than last month").font(.system(size:13,weight:.medium))
                    }
                    .foregroundStyle(Color.income)
                    .padding(.horizontal,12).padding(.vertical,6)
                    .background(Color.income.opacity(0.1))
                    .clipShape(Capsule())
                }
                .frame(maxWidth:.infinity)
                .padding(24)
                .lightCard()

                // Weekly bar chart
                VStack(alignment:.leading, spacing:14) {
                    Text("Weekly Spending").font(.system(size: 18, weight: .semibold))
                    Chart(MockData.weeklySpending) { day in
                        BarMark(
                            x:.value("Day", day.day),
                            y:.value("Amount", day.amount)
                        )
                        .foregroundStyle(day.day == "Fri"
                            ? LinearGradient.primaryGrad
                            : LinearGradient(colors:[Color.uniBlue.opacity(0.25)],startPoint:.top,endPoint:.bottom))
                        .cornerRadius(6)
                        .annotation(position:.top) {
                            Text(day.amount.shortCurrency)
                                .font(.system(size:9,weight:.semibold))
                                .foregroundStyle(Color.secondary)
                        }
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
                                        Text(cat.icon).font(.system(size:20))
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

                // Insights
                VStack(alignment:.leading, spacing:12) {
                    Text("Insights").font(.system(size: 18, weight: .semibold))
                    InsightCard(emoji:"🎯", title:"Great job on groceries!",
                                message:"You spent 20% less than last month",
                                bgColor:Color.income.opacity(0.08),
                                borderColor:Color.income.opacity(0.2))
                    InsightCard(emoji:"☕", title:"Coffee spending alert",
                                message:"Making coffee at home could save you Rs 12,000 each month",
                                bgColor:Color.warning.opacity(0.08),
                                borderColor:Color.warning.opacity(0.2))
                }
                .padding(.bottom, 20)
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
