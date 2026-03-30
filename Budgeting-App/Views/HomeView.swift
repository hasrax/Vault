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
    @State private var activeCategory: BudgetCategory = .needs
    @State private var showAddTransaction = false
    @State private var showNotifications  = false
    @State private var transactions       = MockData.transactions
    @State private var budgetLimits       = MockData.budgetLimits

    // Navigation destinations
    @State private var showSearch         = false
    @State private var showBudget         = false
    @State private var showPlanner        = false
    @State private var showWorkSchedule   = false
    @State private var showSplitBill      = false
    @State private var showMealPlan       = false
    @State private var showSavings        = false

    private var totalExpense: Double { transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    private var totalIncome:  Double { transactions.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount } }
    private var balance:      Double { appState.monthlyBudget + totalIncome - totalExpense }

    private var currentLimit: BudgetLimit? {
        budgetLimits.first { $0.category == activeCategory }
    }

    var body: some View {
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
                AddTransactionView(transactions: $transactions)
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
            }
            // Navigation destinations
            .navigationDestination(isPresented: $showSearch) {
                SearchView()
            }
            .navigationDestination(isPresented: $showBudget) {
                BudgetView()
            }
            .navigationDestination(isPresented: $showPlanner) {
                PlannerView()
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
        }
    }

    // MARK: - Dark Header
    private var darkHeader: some View {
        ZStack(alignment: .bottom) {
            AuthBackground()
                .frame(minHeight: 380)
                .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    HStack(spacing: 10) {
                        Text(MockData.userAvatar)
                            .font(.system(size: 22))
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                        Text("Hi, \(MockData.userName)!")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.white)
                    }
                    Spacer()
                    Button { showNotifications = true } label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16))
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
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text(balance.currencyRS)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                    Text("Received Mar 1 · 27 days left")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .padding(.top, 24)

                // Income / Expense row
                HStack(spacing: 32) {
                    VStack(spacing: 3) {
                        Text("Income")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.7))
                        Text(totalIncome.currencyRS)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.income)
                    }
                    Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 32)
                    VStack(spacing: 3) {
                        Text("Spent")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.7))
                        Text(totalExpense.currencyRS)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.expense)
                    }
                }
                .padding(.top, 16)

                // Donut chart + legend
                Text("Budget Allocation")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.top, 24)

                HStack(spacing: 24) {
                    DonutChart(
                        needs:      appState.needsPercent,
                        wants:      appState.wantsPercent,
                        savings:    appState.savingsPercent,
                        centerText: balance.shortCurrency,
                        centerSub:  "Monthly"
                    )
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(BudgetCategory.allCases) { cat in
                            HStack(spacing: 8) {
                                Circle().fill(cat.color).frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(cat.rawValue)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.white.opacity(0.5))
                                    Text((appState.monthlyBudget * cat.percentage).shortCurrency)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color.white)
                                }
                            }
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
                                .font(.system(size: 14, weight: activeCategory == cat ? .semibold : .regular))
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

    // MARK: - Glass Overlap Card
    private var glassOverlapCard: some View {
        VStack(spacing: 12) {
            if let limit = currentLimit {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(activeCategory.color.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Text(activeCategory.emoji).font(.system(size: 18))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activeCategory.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                        Text(activeCategory.subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    Text(limit.limit.currencyRS)
                        .font(.system(size: 17, weight: .bold))
                }
                UniProgressBar(progress: limit.progress, color: limit.progressColor)
                HStack {
                    Text("\(limit.remaining.currencyRS) left")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text("\(Int(limit.progress * 100))% used")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(limit.progressColor)
                }
            }
        }
        .padding(16)
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .textCase(.uppercase)
                Text("Log expense or income")
                    .font(.system(size: 18, weight: .bold))
                Text("Capture rupees right away so budgets stay accurate.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
            }
            HStack(spacing: 12) {
                Button { showAddTransaction = true } label: {
                    Label("Expense", systemImage: "minus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.expense)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Color.expense.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.expense.opacity(0.45), lineWidth: 1)
                        )
                }
                Button { showAddTransaction = true } label: {
                    Label("Income", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
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
                QuickActionButton(emoji: "📊", label: "Budget",  gradient: .primaryGrad) {
                    showBudget = true
                }
                QuickActionButton(emoji: "📅", label: "Planner", gradient: .purpleGrad) {
                    showPlanner = true
                }
                QuickActionButton(emoji: "💼", label: "Jobs",    gradient: .greenGrad) {
                    showWorkSchedule = true
                }
                QuickActionButton(emoji: "🍕", label: "Split",   gradient: .orangeGrad) {
                    showSplitBill = true
                }
                QuickActionButton(emoji: "🛒", label: "Meals",   gradient: .tealGrad) {
                    showMealPlan = true
                }
                QuickActionButton(emoji: "🐷", label: "Savings", gradient: .pinkGrad) {
                    showSavings = true
                }
            }
        }
        .padding(16)
        .lightCard()
    }

    // MARK: - Planner Highlights (all wired)
    private var plannerHighlights: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Planner highlights", actionLabel: "Go to planner") {
                showPlanner = true
            }
            VStack(spacing: 8) {
                PlannerHighlightCard(
                    title: "Semester Planner",
                    detail: "9 weeks remaining"
                ) { showPlanner = true }

                PlannerHighlightCard(
                    title: "Work Schedule",
                    detail: "2 shifts this week"
                ) { showWorkSchedule = true }

                PlannerHighlightCard(
                    title: "Split Bill",
                    detail: "Settle dinner with Hasini & co."
                ) { showSplitBill = true }
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
            ForEach(Array(transactions.prefix(4).enumerated()), id: \.element.id) { idx, tx in
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

#Preview { HomeView().environmentObject(AppState()) }
