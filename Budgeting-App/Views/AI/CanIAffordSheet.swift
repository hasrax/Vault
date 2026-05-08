//
//  CanIAffordSheet.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Can I Afford Sheet
struct CanIAffordSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var amount   = ""
    @State private var category: BudgetCategory = .wants
    @State private var result: AffordResult? = nil

    enum AffordResult {
        case yes, maybe, no
        var color:   Color  { self == .yes ? Color.income : self == .maybe ? Color.warning : Color.expense }
        var icon:    String { self == .yes ? "checkmark.circle.fill" : self == .maybe ? "exclamationmark.triangle.fill" : "xmark.circle.fill" }
        var message: String {
            switch self {
            case .yes:   return "Yes, you can afford this — it fits within your budget."
            case .maybe: return "Be careful — this brings you close to your limit."
            case .no:    return "Not recommended — you're already at or over your limit."
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("How much do you want to spend?") {
                    HStack {
                        Text("Rs.")
                        TextField("Amount", text: $amount)
                            .keyboardType(.numberPad)
                    }
                }
                Section("Which category?") {
                    Picker("Category", selection: $category) {
                        ForEach(BudgetCategory.allCases) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Button("Check") { checkAfford() }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(Color.uniBlue)
                        .fontWeight(.semibold)
                }
                if let r = result {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: r.icon)
                                .scaledFont(size: 44, relativeTo: .body)
                                .foregroundStyle(r.color)
                            Text(r.message)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Can I afford this?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func checkAfford() {
        guard let value = Double(amount) else { return }
        let limit = budgetLimit(for: category)
        let remaining = max(limit - spent(for: category), 0)
        if value <= remaining * 0.5 { result = .yes }
        else if value <= remaining  { result = .maybe }
        else                        { result = .no }
    }

    private func budgetLimit(for category: BudgetCategory) -> Double {
        let percent: Double
        switch category {
        case .needs:   percent = appState.needsPercent
        case .wants:   percent = appState.wantsPercent
        case .savings: percent = appState.savingsPercent
        }
        return appState.monthlyBudget * (percent / 100)
    }

    private func spent(for category: BudgetCategory) -> Double {
        appState.transactions
            .filter { $0.type == .expense && $0.budgetCategory == category }
            .reduce(0) { $0 + $1.amount }
    }
}
