//
//  AddTransactionView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Add Transaction View
// Bottom sheet / full-screen modal for logging a new income or expense.
// Used from: HomeView, HistoryView, SearchView, ReceiptScannerView.
struct AddTransactionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    // Form state
    @State private var txType:            TransactionType = .expense
    @State private var amountText:        String = ""
    @State private var selectedCategory:  ExpenseCategory = .dining
    @State private var selectedIncome:    IncomeSource = .parttime
    @State private var name:              String = ""
    @State private var note:              String = ""
    @State private var date:              Date = Date()
    @State private var showValidationMsg  = false
    @State private var showReceiptScanner = false

    // Prefill support — used when coming from ReceiptScannerView
    init(prefillAmount: Double? = nil) {
        if let amt = prefillAmount {
            _amountText = State(initialValue: String(Int(amt)))
        }
    }

    private var amount:  Double { Double(amountText) ?? 0 }
    private var isValid: Bool   { amount > 0 && !name.isEmpty }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        scanReceiptButton
                        typeToggle
                        amountSection
                        categorySection
                        fieldsSection
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showReceiptScanner) {
                ReceiptScannerView()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.headline)
                        .foregroundStyle(isValid ? Color.uniBlue : Color.secondary)
                        .disabled(!isValid)
                }
            }
        }
    }

    private var scanReceiptButton: some View {
        Button { showReceiptScanner = true } label: {
            Label("Scan Receipt", systemImage: "camera.viewfinder")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.uniBlue)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.uniBlue.opacity(0.4), lineWidth: 1)
                )
        }
        .accessibilityLabel("Scan Receipt")
    }

    // MARK: - Type Toggle
    private var typeToggle: some View {
        HStack(spacing: 4) {
            ForEach(TransactionType.allCases, id: \.self) { t in
                Button {
                    withAnimation(.spring(duration: 0.25)) { txType = t }
                } label: {
                    let isSelected = txType == t
                    let isExpense  = t == .expense
                    let color      = isExpense ? Color.expense : Color.income
                    Text(isExpense ? "Expense" : "Income")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(color.opacity(isSelected ? 0.16 : 0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(color.opacity(isSelected ? 0.45 : 0.20), lineWidth: 1)
                        )
                }
                .accessibilityLabel(t == .expense ? "Expense" : "Income")
                .accessibilityAddTraits(txType == t ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Amount
    private var amountSection: some View {
        VStack(spacing: 6) {
            Text("Amount")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary)
            AmountInput(
                text: $amountText,
                accentColor: txType == .expense ? Color.expense : Color.income
            )
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Category chips
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.primary)

            if txType == .expense {
                // Expense subcategories
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 90), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(ExpenseCategory.allCases) { cat in
                        categoryChip(
                            emoji:      cat.icon,
                            label:      cat.rawValue,
                            isSelected: selectedCategory == cat,
                            color:      cat.color
                        ) {
                            selectedCategory = cat
                        }
                    }
                }
            } else {
                // Income sources
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(IncomeSource.allCases) { src in
                        categoryChip(
                            emoji:      src.icon,
                            label:      src.rawValue,
                            isSelected: selectedIncome == src,
                            color:      Color.income
                        ) {
                            selectedIncome = src
                        }
                    }
                }
            }
        }
    }

    private func categoryChip(
        emoji: String,
        label: String,
        isSelected: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(emoji).font(.system(size: 13))
                Text(label).font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color.clear : Color.black.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .animation(.spring(duration: 0.2), value: isSelected)
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Text fields
    private var fieldsSection: some View {
        VStack(spacing: 14) {
            DarkTextField(
                label:       "Description",
                placeholder: "What was this for?",
                text:        $name
            )

            // Date picker styled to match
            VStack(alignment: .leading, spacing: 6) {
                Text("Date")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(14)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
            }

            DarkTextField(
                label:       "Note (optional)",
                placeholder: "Add a note...",
                text:        $note
            )

            // Validation message
            if showValidationMsg {
                Label("Please fill in description and amount", systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(Color.expense)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Save
    private func save() {
        guard isValid else { showValidationMsg = true; return }

        let newTx = Transaction(
            name:           name,
            amount:         amount,
            type:           txType,
            category:       txType == .expense ? selectedCategory : nil,
            incomeSource:   txType == .income  ? selectedIncome   : nil,
            budgetCategory: txType == .expense ? selectedCategory.budgetCategory : .savings,
            date:           date,
            note:           note
        )
        appState.addTransaction(newTx)
        dismiss()
    }
}

#Preview {
    AddTransactionView()
        .environmentObject(AppState())
}
