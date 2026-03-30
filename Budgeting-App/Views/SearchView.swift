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
    @State private var transactions = MockData.transactions
    @State private var searchText   = ""
    @State private var activeFilter: TxFilter = .all
    @State private var showAdd      = false

    enum TxFilter: String, CaseIterable {
        case all     = "All"
        case income  = "Income"
        case expense = "Expense"
    }

    // MARK: - Computed
    private var filtered: [Transaction] {
        transactions.filter { tx in
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
            return matchesFilter && matchesSearch
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

    private var totalIncome:  Double { transactions.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount } }
    private var totalExpense: Double { transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    BackButton { dismiss() }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Text("Transactions")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 14)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search transactions...", text: $searchText)
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
            AddTransactionView(transactions: $transactions)
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
}

#Preview {
    NavigationStack {
        SearchView()
    }
}
