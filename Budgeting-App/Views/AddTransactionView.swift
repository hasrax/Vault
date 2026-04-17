//
//  AddTransactionView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Add Transaction View
// Bottom sheet / full-screen modal for logging a new income or expense.
// Used from: HomeView, SearchView, ReceiptScannerView.
struct AddTransactionView: View {
    @EnvironmentObject var transactionsVM: TransactionsViewModel
    @Environment(\.dismiss) var dismiss

    // Form state
    @State private var txType:            TransactionType = .expense
    @State private var amountText:        String = ""
    @State private var selectedBudget:    BudgetCategory = .needs
    @State private var name:              String = ""
    @State private var note:              String = ""
    @State private var date:              Date = Date()
    @State private var showValidationMsg  = false
    @State private var showReceiptScanner = false
    @State private var receiptImageUrl: String? = nil
    @State private var receiptImageBase64: String? = nil

    // Prefill support — used when coming from ReceiptScannerView
    init(
        prefillType: TransactionType? = nil,
        prefillAmount: Double? = nil,
        prefillReceiptUrl: String? = nil,
        prefillReceiptBase64: String? = nil
    ) {
        if let type = prefillType {
            _txType = State(initialValue: type)
        }
        if let amt = prefillAmount {
            _amountText = State(initialValue: String(Int(amt)))
        }
        if let url = prefillReceiptUrl {
            _receiptImageUrl = State(initialValue: url)
        }
        if let base64 = prefillReceiptBase64 {
            _receiptImageBase64 = State(initialValue: base64)
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
            Text("Budget Bucket")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.primary)

            // Needs / Wants / Savings buckets (for expense and income)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 90), spacing: 8)],
                spacing: 8
            ) {
                ForEach(BudgetCategory.allCases) { cat in
                    categoryChip(
                        emoji:      cat.emoji,
                        label:      cat.rawValue,
                        isSelected: selectedBudget == cat,
                        color:      cat.color
                    ) {
                        selectedBudget = cat
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

            if receiptImageUrl != nil || receiptImageBase64 != nil {
                HStack {
                    Image(systemName: "paperclip")
                        .foregroundStyle(Color.uniBlue)
                    Text("Receipt attached")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                }
            }

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
            category:       nil,
            incomeSource:   nil,
            budgetCategory: selectedBudget,
            date:           date,
            note:           note,
            receiptImageUrl: receiptImageUrl,
            receiptImageBase64: receiptImageBase64
        )
        transactionsVM.addTransaction(newTx)
        dismiss()
    }
}

#Preview {
    let vm = TransactionsViewModel()
    vm.transactions = MockData.transactions
    return AddTransactionView()
        .environmentObject(vm)
}
