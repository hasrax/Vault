//
//  SavingsView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Savings
struct SavingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var savingsVM: SavingsGoalsViewModel
    @State private var showAddGoal = false
    @State private var addMoneyGoal: SavingsGoal? = nil
    private var goals: [SavingsGoal] { savingsVM.goals }
    private var totalSaved:  Double { goals.reduce(0){$0+$1.currentAmount} }
    private var totalTarget: Double { goals.reduce(0){$0+$1.targetAmount} }
    private var totalProgress: Double { totalTarget > 0 ? totalSaved / totalTarget : 0 }
    private var accent: Color { appState.plannerTheme.color(for: "savings") }
    private var grad: LinearGradient { appState.plannerTheme.gradient(for: "savings") }

    var body: some View {
        ScrollView {
            VStack(spacing:16) {
                // Total card
                VStack(spacing:12) {
                    Text("Total Saved").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    Text(totalSaved.currencyRS)
                        .font(.system(size:36,weight:.bold,design:.rounded)).foregroundStyle(Color.primary)
                    Text("of \(totalTarget.currencyRS) goal").font(.subheadline).foregroundStyle(Color.secondary)
                    UniProgressBar(progress: totalProgress, color: accent, height: 10)
                }
                .padding(24)
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius:20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(accent.opacity(0.25), lineWidth: 1)
                )

                // Goals
                ForEach(goals) { goal in
                    GoalCard(goal:goal) {
                        addMoneyGoal = goal
                    }
                }

                // Motivation
                HStack(spacing:14) {
                    Text("🚀").font(.system(size:32))
                    VStack(alignment:.leading,spacing:4) {
                        Text("Keep going!").font(.system(size:15,weight:.semibold))
                        Text("You've saved \(totalSaved.currencyRS). Just \((totalTarget-totalSaved).currencyRS) more to reach all goals!")
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    }
                }
                .padding(16)
                .background(accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius:14))
                .overlay(RoundedRectangle(cornerRadius:14).stroke(accent.opacity(0.15),lineWidth:1))
            }
            .padding(.horizontal,16).padding(.top,16).padding(.bottom,40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Savings Goals")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
            ToolbarItem(placement:.topBarTrailing) {
                Button { showAddGoal = true } label: { Image(systemName:"plus") }
            }
        }
        .sheet(isPresented: $showAddGoal) {
            AddSavingsGoalView { input in
                savingsVM.addSavingsGoal(
                    name: input.name,
                    icon: input.icon,
                    colorHex: input.colorHex,
                    targetAmount: input.targetAmount,
                    currentAmount: input.currentAmount,
                    deadline: input.deadline
                )
                showAddGoal = false
            }
        }
        .sheet(item: $addMoneyGoal) { goal in
            AddMoneyView(goal: goal) { amount in
                savingsVM.addMoney(to: goal, amount: amount)
                addMoneyGoal = nil
            }
        }
    }
}

private struct AddSavingsGoalView: View {
    struct Input {
        var name: String
        var icon: String
        var colorHex: String
        var targetAmount: Double
        var currentAmount: Double
        var deadline: Date?
    }

    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var icon = "🎯"
    @State private var colorHex = "#3B82F6"
    @State private var targetText = ""
    @State private var currentText = ""
    @State private var hasDeadline = false
    @State private var deadline = Date()
    let onSave: (Input) -> Void

    private var targetAmount: Double { Double(targetText) ?? 0 }
    private var currentAmount: Double { Double(currentText) ?? 0 }
    private var isValid: Bool { !name.isEmpty && targetAmount > 0 }

    private let colors: [(String, String)] = [
        ("Blue", "#3B82F6"),
        ("Green", "#22C55E"),
        ("Purple", "#8B5CF6"),
        ("Orange", "#F97316"),
        ("Teal", "#14B8A6"),
        ("Pink", "#EC4899")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Name", text: $name)
                    TextField("Icon (emoji)", text: $icon)
                }

                Section("Amounts") {
                    TextField("Target amount", text: $targetText)
                        .keyboardType(.decimalPad)
                    TextField("Already saved (optional)", text: $currentText)
                        .keyboardType(.decimalPad)
                }

                Section("Color") {
                    Picker("Theme", selection: $colorHex) {
                        ForEach(colors, id: \.1) { item in
                            Text(item.0).tag(item.1)
                        }
                    }
                }

                Section("Deadline") {
                    Toggle("Set deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("", selection: $deadline, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let input = Input(
                            name: name,
                            icon: icon.isEmpty ? "🎯" : icon,
                            colorHex: colorHex,
                            targetAmount: targetAmount,
                            currentAmount: currentAmount,
                            deadline: hasDeadline ? deadline : nil
                        )
                        onSave(input)
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

private struct AddMoneyView: View {
    @Environment(\.dismiss) var dismiss
    let goal: SavingsGoal
    let onSave: (Double) -> Void
    @State private var amountText = ""

    private var amount: Double { Double(amountText) ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Add to \(goal.name)") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(amount)
                        dismiss()
                    }
                    .disabled(amount <= 0)
                }
            }
        }
    }
}

#Preview("Savings") {
    let vm = SavingsGoalsViewModel()
    vm.goals = MockData.savingsGoals
    return NavigationStack { SavingsView().environmentObject(vm).environmentObject(AppState()) }
}
