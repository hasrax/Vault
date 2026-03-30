//
//  HistoryView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - History View
// Tab 2 — grouped transaction list with filter chips and swipe-to-delete.
struct HistoryView: View {
    @State private var transactions = MockData.transactions
    @State private var activeFilter: TxFilter = .all
    @State private var searchText = ""
    @State private var showAdd    = false
    @State private var showSearch = false

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

    private var totalIncome:  Double { filtered.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount } }
    private var totalExpense: Double { filtered.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    private var net:          Double { totalIncome - totalExpense }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                summaryBar
                filterRow
                Divider()
                transactionList
            }
            .background(Color.clear)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search transactions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("Search all transactions")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add transaction")
                }
            }
            .navigationDestination(isPresented: $showSearch) {
                SearchView()
            }
            .sheet(isPresented: $showAdd) {
                AddTransactionView(transactions: $transactions)
            }
        }
    }

    // MARK: - Summary Bar
    private var summaryBar: some View {
        HStack(spacing: 0) {
            summaryCell(label: "Income",  amount: totalIncome,  color: Color.income)
            Divider()
            summaryCell(label: "Expense", amount: totalExpense, color: Color.expense)
            Divider()
            summaryCell(label: "Net",     amount: net,          color: net >= 0 ? Color.uniBlue : Color.expense)
        }
        .frame(height: 60)
        .background(Color(UIColor.systemBackground))
    }

    private func summaryCell(label: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.secondary)
            Text(amount.shortCurrency)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(amount.currencyRS)")
    }

    // MARK: - Filter Chips
    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TxFilter.allCases, id: \.self) { f in
                    FilterChip(label: f.rawValue, isSelected: activeFilter == f) {
                        withAnimation(.spring(duration: 0.25)) { activeFilter = f }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - List
    @ViewBuilder
    private var transactionList: some View {
        if filtered.isEmpty {
            ContentUnavailableView(
                "No transactions",
                systemImage: "doc.text.magnifyingglass",
                description: Text(searchText.isEmpty
                    ? "Add your first transaction with the + button"
                    : "No results for \"\(searchText)\"")
            )
        } else {
            List {
                ForEach(grouped, id: \.date) { group in
                    Section(group.date) {
                        ForEach(group.txs) { tx in
                            TransactionRow(transaction: tx)
                                .listRowBackground(Color(UIColor.systemBackground))
                                .listRowInsets(
                                    EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
                                )
                        }
                        .onDelete { offsets in
                            deleteItems(in: group.txs, at: offsets)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Delete
    private func deleteItems(in group: [Transaction], at offsets: IndexSet) {
        let idsToDelete = offsets.map { group[$0].id }
        transactions.removeAll { idsToDelete.contains($0.id) }
    }
}

#Preview {
    HistoryView()
}
