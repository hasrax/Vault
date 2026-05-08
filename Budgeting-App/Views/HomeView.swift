//
//  HomeView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var transactionsVM: TransactionsViewModel
    @State private var activeCategory: BudgetCategory = .needs
    @State private var showAddTransaction = false
    @State private var showNotifications  = false
    @State private var addTransactionType: TransactionType = .expense

    // Navigation destinations
    @State private var showSearch         = false
    @State private var showBudget         = false
    @State private var showPlanner        = false
    @State private var showWorkSchedule   = false
    @State private var showSplitBill      = false
    @State private var showMealPlan       = false
    @State private var showSavings        = false
    @State private var showSemesterPlanner = false
    @State private var showAnalytics      = false
    @State private var showProfile        = false

    private var currentMonthTransactions: [Transaction] {
        let cal = Calendar.current
        return transactionsVM.transactions.filter {
            cal.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
    }

    private var totalExpense: Double {
        currentMonthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    private var totalIncome:  Double {
        currentMonthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    private var balance:      Double { appState.monthlyBudget + totalIncome - totalExpense }

    private var currentLimit: BudgetLimit? {
        budgetLimits.first { $0.category == activeCategory }
    }

    private var budgetLimits: [BudgetLimit] {
        let needsLimit = appState.monthlyBudget * (appState.needsPercent / 100)
        let wantsLimit = appState.monthlyBudget * (appState.wantsPercent / 100)
        let savingsLimit = appState.monthlyBudget * (appState.savingsPercent / 100)
        return [
            BudgetLimit(category: .needs,   limit: needsLimit,   spent: spent(for: .needs)),
            BudgetLimit(category: .wants,   limit: wantsLimit,   spent: spent(for: .wants)),
            BudgetLimit(category: .savings, limit: savingsLimit, spent: spent(for: .savings))
        ]
    }

    private func spent(for category: BudgetCategory) -> Double {
        currentMonthTransactions
            .filter { $0.type == .expense && $0.budgetCategory == category }
            .reduce(0) { $0 + $1.amount }
    }

    private func allocationAmount(for category: BudgetCategory) -> Double {
        let percent: Double
        switch category {
        case .needs:   percent = appState.needsPercent
        case .wants:   percent = appState.wantsPercent
        case .savings: percent = appState.savingsPercent
        }
        return appState.monthlyBudget * (percent / 100)
    }

    private func receivedText(at date: Date) -> String {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
        let end = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? date
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let received = fmt.string(from: start)
        let daysLeft = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: end).day ?? 0
        let leftText = "\(daysLeft) days left"
        return "Received \(received) · \(leftText)"
    }

    private var homeSummary: String {
        let name = appState.currentUser?.name ?? MockData.userName
        var summary = "Hi \(name). Your monthly budget balance is \(balance.currencyRS). "
        summary += "This month you have received \(totalIncome.currencyRS) and spent \(totalExpense.currencyRS). "
        if let limit = currentLimit {
            summary += "Your \(activeCategory.rawValue) budget is \(Int(limit.progress * 100)) percent used, with \(limit.remaining.currencyRS) remaining."
        }
        return summary
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 0) {
                        darkHeader
                        glassOverlapCard
                        contentSection
                    }
                }
                .ignoresSafeArea(edges: .top)
                .background(Color(UIColor.systemGroupedBackground))
                // Sheets
                .sheet(isPresented: $showAddTransaction) {
                    AddTransactionView(prefillType: addTransactionType)
                }
                .sheet(isPresented: $showNotifications) {
                    NotificationsView()
                }
                // Navigation destinations
                .navigationDestination(isPresented: $showSearch) {
                    SearchView(showBack: true)
                }
                .navigationDestination(isPresented: $showBudget) {
                    BudgetView()
                }
                .navigationDestination(isPresented: $showPlanner) {
                    PlannerView()
                }
                .navigationDestination(isPresented: $showSemesterPlanner) {
                    SemesterPlannerView()
                }
                .navigationDestination(isPresented: $showWorkSchedule) {
                    WorkScheduleView()
                }
                .navigationDestination(isPresented: $showSplitBill) {
                    SplitBillView()
                }
                .navigationDestination(isPresented: $showMealPlan) {
                    MealPlanView()
                }
                .navigationDestination(isPresented: $showSavings) {
                    SavingsView()
                }
                .navigationDestination(isPresented: $showAnalytics) {
                    AnalyticsView()
                }
                .navigationDestination(isPresented: $showProfile) {
                    ProfileView()
                }
            }
            
            FloatingSpeakButton(textToSpeak: homeSummary)
        }
    }

    // MARK: - Dark Header
    private var darkHeader: some View {
        ZStack(alignment: .bottom) {
            HomeHeaderBackground()
                .frame(minHeight: 380)
                .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    HStack(spacing: 10) {
                        Button {
                            showProfile = true
                        } label: {
                            profileAvatar
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Profile settings")
                        
                        let displayName = appState.currentUser?.name ?? MockData.userName
                        Text("Hi, \(displayName)!")
                            .scaledFont(size: 15, weight: .semibold)
                            .foregroundStyle(Color.white)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Hi, \(appState.currentUser?.name ?? MockData.userName). Profile settings")
                    Spacer()
                    Button { showNotifications = true } label: {
                        Image(systemName: "bell.fill")
                            .scaledFont(size: 16)
                            .foregroundStyle(Color.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Notifications")
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                // Balance
                VStack(spacing: 6) {
                    Text("Monthly Budget")
                        .scaledFont(size: 12, weight: .medium)
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text(balance.currencyRS)
                        .scaledFont(size: 40, weight: .bold, design: .rounded)
                        .foregroundStyle(Color.white)
                    TimelineView(.periodic(from: Date(), by: 60)) { context in
                        Text(receivedText(at: context.date))
                            .scaledFont(size: 12)
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                }
                .padding(.top, 24)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Monthly Budget Balance: \(balance.currencyRS). \(receivedText(at: Date()))")

                // Income / Expense row
                HStack(spacing: 32) {
                    VStack(spacing: 3) {
                        Text("Income")
                            .scaledFont(size: 11)
                            .foregroundStyle(Color.white.opacity(0.7))
                        Text(totalIncome.currencyRS)
                            .scaledFont(size: 14, weight: .semibold)
                            .foregroundStyle(Color.income)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Total Income: \(totalIncome.currencyRS)")
                    Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 32)
                    VStack(spacing: 3) {
                        Text("Spent")
                            .scaledFont(size: 11)
                            .foregroundStyle(Color.white.opacity(0.7))
                        Text(totalExpense.currencyRS)
                            .scaledFont(size: 14, weight: .semibold)
                            .foregroundStyle(Color.expense)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Total Spent: \(totalExpense.currencyRS)")
                }
                .padding(.top, 16)

                // Donut chart + legend
                Text("Budget Allocation")
                    .scaledFont(size: 12, weight: .medium)
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.top, 24)

                HStack(spacing: 24) {
                    Button { showBudget = true } label: {
                        DonutChart(
                            needs:      appState.needsPercent,
                            wants:      appState.wantsPercent,
                            savings:    appState.savingsPercent,
                            centerText: balance.shortCurrency,
                            centerSub:  "Monthly"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open Budget Settings")
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(BudgetCategory.allCases) { cat in
                            HStack(spacing: 8) {
                                Circle().fill(cat.color).frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(cat.rawValue)
                                        .scaledFont(size: 11)
                                        .foregroundStyle(Color.white.opacity(0.5))
                                    Text(allocationAmount(for: cat).shortCurrency)
                                        .scaledFont(size: 12, weight: .bold)
                                        .foregroundStyle(Color.white)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(cat.rawValue) allocation: \(allocationAmount(for: cat).shortCurrency)")
                        }
                    }
                }
                .padding(.top, 12)

                // Category tabs
                HStack(spacing: 8) {
                    ForEach(BudgetCategory.allCases) { cat in
                        Button {
                            withAnimation(.spring(duration: 0.3)) { activeCategory = cat }
                        } label: {
                            Text(cat.rawValue)
                                .scaledFont(size: 14, weight: activeCategory == cat ? .semibold : .regular)
                                .foregroundStyle(activeCategory == cat ? Color.white : Color.white.opacity(0.4))
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(activeCategory == cat ? cat.color : Color.clear)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(
                                        Color.white.opacity(activeCategory == cat ? 0 : 0.12)
                                    )
                                )
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
    }

    private var profileAvatar: some View {
        Group {
            if let base64 = appState.currentUser?.photoBase64,
               let data = Data(base64Encoded: base64),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let urlStr = appState.currentUser?.photoURL,
                      let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Color.white.opacity(0.12)
                    }
                }
            } else {
                ZStack {
                    Color.white.opacity(0.12)
                    Text(MockData.userAvatar)
                        .scaledFont(size: 22)
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }

    // MARK: - Glass Overlap Card
    private var glassOverlapCard: some View {
        VStack(spacing: 12) {
            if let limit = currentLimit {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(activeCategory.color.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Text(activeCategory.emoji).scaledFont(size: 18)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activeCategory.rawValue)
                            .scaledFont(size: 15, weight: .semibold)
                        Text(activeCategory.subtitle)
                            .scaledFont(size: 12)
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    Text(limit.limit.currencyRS)
                        .scaledFont(size: 17, weight: .bold)
                }
                UniProgressBar(progress: limit.progress, color: limit.progressColor)
                HStack {
                    Text("\(limit.remaining.currencyRS) left")
                        .scaledFont(size: 12)
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text("\(Int(limit.progress * 100))% used")
                        .scaledFont(size: 11, weight: .bold)
                        .foregroundStyle(limit.progressColor)
                }
            }
        }
        .padding(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(currentLimit != nil ? "\(activeCategory.rawValue) budget: \(currentLimit!.limit.currencyRS). \(currentLimit!.remaining.currencyRS) left. \(Int(currentLimit!.progress * 100)) percent used." : "")
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.10), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .offset(y: -28)
    }

    // MARK: - Content Section
    private var contentSection: some View {
        VStack(spacing: 20) {

            // Add Transaction card
            addTransactionCard

            // Quick Actions — all wired up
            quickActionsGrid

            // Planner highlights — all wired up
            plannerHighlights

            // Recent Transactions — See all wired
            recentTransactions
        }
        .padding(.horizontal, 16)
        .padding(.top, -8)
        .padding(.bottom, 100)
    }

    // MARK: - Add Transaction Card
    private var addTransactionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add transaction")
                    .scaledFont(size: 12, weight: .medium)
                    .foregroundStyle(Color.secondary)
                    .textCase(.uppercase)
                Text("Log expense or income")
                    .scaledFont(size: 18, weight: .bold)
                Text("Capture rupees right away so budgets stay accurate.")
                    .scaledFont(size: 13)
                    .foregroundStyle(Color.secondary)
            }
            HStack(spacing: 12) {
                Button {
                    addTransactionType = .expense
                    showAddTransaction = true
                } label: {
                    Label("Expense", systemImage: "minus.circle.fill")
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundStyle(Color.expense)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Color.expense.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.expense.opacity(0.45), lineWidth: 1)
                        )
                }
                Button {
                    addTransactionType = .income
                    showAddTransaction = true
                } label: {
                    Label("Income", systemImage: "plus.circle.fill")
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundStyle(Color.income)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Color.income.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.income.opacity(0.45), lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .lightCard()
    }

    // MARK: - Quick Actions Grid (all wired)
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Actions")
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                spacing: 10
            ) {
                QuickActionButton(emoji: "📅", label: "Semester", accent: appState.plannerTheme.color(for: "semesterPlanner")) {
                    showSemesterPlanner = true
                }
                QuickActionButton(emoji: "💼", label: "Shifts",   accent: appState.plannerTheme.color(for: "workSchedule")) {
                    showWorkSchedule = true
                }
                QuickActionButton(emoji: "🍽️", label: "Meals",    accent: appState.plannerTheme.color(for: "mealPlan")) {
                    showMealPlan = true
                }
                QuickActionButton(emoji: "🎯", label: "Savings",  accent: appState.plannerTheme.color(for: "savings")) {
                    showSavings = true
                }
                QuickActionButton(emoji: "🤝", label: "Split",    accent: appState.plannerTheme.color(for: "splitBill")) {
                    showSplitBill = true
                }
                QuickActionButton(emoji: "📊", label: "Analytics", accent: appState.plannerTheme.color(for: "analytics")) {
                    showAnalytics = true
                }
            }
        }
        .padding(16)
        .lightCard()
    }

    // MARK: - Planner Highlights (all wired)
    private var plannerHighlights: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Planner highlights", actionLabel: "All six") {
                showPlanner = true
            }
            VStack(spacing: 8) {
                PlannerHighlightCard(
                    title: "Semester Planner",
                    detail: "Recent activity: upcoming deadlines",
                    accent: appState.plannerTheme.color(for: "semesterPlanner")
                ) { showSemesterPlanner = true }

                PlannerHighlightCard(
                    title: "Work Schedule",
                    detail: "Recent activity: shifts this week",
                    accent: appState.plannerTheme.color(for: "workSchedule")
                ) { showWorkSchedule = true }

                PlannerHighlightCard(
                    title: "Meal Plan",
                    detail: "Recent activity: dining balance",
                    accent: appState.plannerTheme.color(for: "mealPlan")
                ) { showMealPlan = true }

                PlannerHighlightCard(
                    title: "Savings",
                    detail: "Recent activity: goal progress",
                    accent: appState.plannerTheme.color(for: "savings")
                ) { showSavings = true }

                PlannerHighlightCard(
                    title: "Split Bill",
                    detail: "Recent activity: open balances",
                    accent: appState.plannerTheme.color(for: "splitBill")
                ) { showSplitBill = true }

                PlannerHighlightCard(
                    title: "Analytics",
                    detail: "Recent activity: spending trends",
                    accent: appState.plannerTheme.color(for: "analytics")
                ) { showAnalytics = true }
            }
        }
        .padding(16)
        .lightCard()
    }

    // MARK: - Recent Transactions (See all wired)
    private var recentTransactions: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Recent Transactions", actionLabel: "See all") {
                showSearch = true
            }
            ForEach(Array(transactionsVM.transactions.prefix(4).enumerated()), id: \.element.id) { idx, tx in
                TransactionRow(transaction: tx)
                if idx < 3 {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .padding(16)
        .lightCard()
    }
}

// RoundedCorner is defined in DesignSystem.swift

#Preview {
    let vm = TransactionsViewModel()
    vm.transactions = MockData.transactions
    return HomeView()
        .environmentObject(AppState())
        .environmentObject(vm)
}
