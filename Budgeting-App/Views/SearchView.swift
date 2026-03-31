//
//  TransactionsView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Search View
// Full dedicated search screen — navigated to from HomeView "See all" or History header.
// Shows: large title, search bar, filter chips, income/expense summary cards, grouped list.
// Matches React: TransactionsScreen.jsx
struct SearchView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    let showBack: Bool
    @State private var searchText   = ""
    @State private var activeFilter: TxFilter = .all
    @State private var selectedExpenseCategory: ExpenseCategory? = nil
    @State private var selectedIncomeSource: IncomeSource? = nil
    @State private var dateFilter: DateFilter = .all
    @State private var showAdd      = false

    enum TxFilter: String, CaseIterable {
        case all     = "All"
        case income  = "Income"
        case expense = "Expense"
    }

    enum DateFilter: String, CaseIterable {
        case all = "All time"
        case last7 = "Last 7 days"
        case last30 = "Last 30 days"
        case thisMonth = "This month"
        case thisYear = "This year"
    }

    // MARK: - Computed
    private var filtered: [Transaction] {
        appState.transactions.filter { tx in
            let matchesFilter: Bool = {
                switch activeFilter {
                case .all:     return true
                case .income:  return tx.type == .income
                case .expense: return tx.type == .expense
                }
            }()
            let matchesSearch = searchText.isEmpty
                || tx.name.localizedCaseInsensitiveContains(searchText)
                || (tx.category?.rawValue ?? "").localizedCaseInsensitiveContains(searchText)
                || (tx.incomeSource?.rawValue ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesCategory: Bool = {
                switch activeFilter {
                case .expense:
                    if let selected = selectedExpenseCategory { return tx.category == selected }
                    return true
                case .income:
                    if let selected = selectedIncomeSource { return tx.incomeSource == selected }
                    return true
                case .all:
                    return true
                }
            }()
            let matchesDate: Bool = {
                guard let start = dateFilterStart else { return true }
                return tx.date >= start
            }()
            return matchesFilter && matchesSearch
                && matchesCategory && matchesDate
        }
    }

    private var grouped: [(date: String, txs: [Transaction])] {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        let dict = Dictionary(grouping: filtered) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return dict
            .sorted { $0.key > $1.key }
            .map { (fmt.string(from: $0.key), $0.value) }
    }

    private var totalIncome:  Double { appState.transactions.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount } }
    private var totalExpense: Double { appState.transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                if showBack {
                    HStack {
                        BackButton { dismiss() }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                Text("History")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .padding(.horizontal, 20)
                    .padding(.top, showBack ? 16 : 8)
                    .padding(.bottom, 14)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search history...", text: $searchText)
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(TxFilter.allCases, id: \.self) { f in
                            FilterChip(label: f.rawValue, isSelected: activeFilter == f) {
                                withAnimation(.spring(duration: 0.25)) { activeFilter = f }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }

                // Filters row
                HStack(spacing: 10) {
                    Menu {
                        if activeFilter == .income {
                            Button("All sources") { selectedIncomeSource = nil }
                            ForEach(IncomeSource.allCases) { source in
                                Button(source.rawValue) { selectedIncomeSource = source }
                            }
                        } else {
                            Button("All categories") { selectedExpenseCategory = nil }
                            ForEach(ExpenseCategory.allCases) { category in
                                Button(category.rawValue) { selectedExpenseCategory = category }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(categoryLabel)
                                .font(.system(size: 12, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(Capsule())
                    }

                    Menu {
                        ForEach(DateFilter.allCases, id: \.self) { option in
                            Button(option.rawValue) { dateFilter = option }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(dateFilter.rawValue)
                                .font(.system(size: 12, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(Capsule())
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .background(Color(UIColor.systemBackground))

            // ── Summary cards ────────────────────────────────────────────────
            HStack(spacing: 12) {
                summaryCard(label: "Income",   amount: totalIncome,  color: .income)
                summaryCard(label: "Expenses", amount: totalExpense, color: .expense)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))

            Divider()

            // ── Transaction list ─────────────────────────────────────────────
            if filtered.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Text("🔍").font(.system(size: 48))
                    Text("No transactions found")
                        .font(.system(size: 17, weight: .medium))
                    Text("Try adjusting your search or filters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                        ForEach(grouped, id: \.date) { group in
                            Section {
                                VStack(spacing: 0) {
                                    ForEach(Array(group.txs.enumerated()), id: \.element.id) { idx, tx in
                                        TransactionRow(transaction: tx)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 2)
                                        if idx < group.txs.count - 1 {
                                            Divider()
                                                .padding(.leading, 72)
                                                .padding(.trailing, 16)
                                        }
                                    }
                                }
                                .background(Color(UIColor.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            } header: {
                                Text(group.date)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 6)
                                    .background(Color.clear)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Color.clear)
        .navigationTitle("")
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add transaction")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionView()
        }
        .onChange(of: activeFilter) { _, newValue in
            switch newValue {
            case .income:
                selectedExpenseCategory = nil
            case .expense:
                selectedIncomeSource = nil
            case .all:
                selectedExpenseCategory = nil
                selectedIncomeSource = nil
            }
        }
    }

    // MARK: - Summary Card
    private func summaryCard(label: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(amount.currencyRS)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(amount.currencyRS)")
    }

    private var categoryLabel: String {
        switch activeFilter {
        case .income:
            return selectedIncomeSource?.rawValue ?? "All sources"
        case .expense, .all:
            return selectedExpenseCategory?.rawValue ?? "All categories"
        }
    }

    private var dateFilterStart: Date? {
        let calendar = Calendar.current
        let now = Date()
        switch dateFilter {
        case .all:
            return nil
        case .last7:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .last30:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .thisMonth:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        case .thisYear:
            return calendar.date(from: calendar.dateComponents([.year], from: now))
        }
    }
}

#Preview {
    NavigationStack {
        SearchView(showBack: true).environmentObject(AppState())
    }
}
