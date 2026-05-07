//
//  MealPlanView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Meal Plan
struct MealPlanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var plannerVM: PlannerViewModel
    @State private var activeTab = "meals"
    @State private var showAddMeal = false
    @State private var showAddExpense = false
    @State private var editMeal: MealEntry? = nil
    @State private var editExpense: StudyExpense? = nil
    private var grad: LinearGradient { appState.plannerTheme.gradient(for: "mealPlan") }
    private var accent: Color { appState.plannerTheme.color(for: "mealPlan") }

    private var mealEntries: [MealEntry] {
        plannerVM.mealEntries.sorted { $0.date > $1.date }
    }

    private var studyExpenses: [StudyExpense] {
        plannerVM.studyExpenses.sorted { $0.date > $1.date }
    }

    private var studyTotal: Double {
        studyExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Tab switcher
                HStack(spacing: 4) {
                    ForEach([("meals","Meal Plan"),("study","Study Costs")],id:\.0) { id,label in
                        Button {
                            withAnimation(.spring(duration: 0.25)) { activeTab = id }
                        } label: {
                            Text(label)
                                .scaledFont(size: 14, weight: .semibold, relativeTo: .headline)
                                .foregroundStyle(activeTab == id ? Color.white : Color.secondary)
                                .frame(maxWidth:.infinity).frame(height:44)
                                .background(activeTab == id ? Color.uniBlue : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius:10))
                        }
                    }
                }
                .padding(4)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius:14))

                if activeTab == "meals" { mealsTab }
                else { studyTab }
            }
            .padding(.horizontal,16).padding(.top,16).padding(.bottom,40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Campus Life")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
        .sheet(isPresented: $showAddMeal) {
            MealEntryEditorView { input in
                plannerVM.addMealEntry(
                    title: input.title,
                    date: input.date,
                    type: input.type,
                    amount: input.amount,
                    location: input.location,
                    notes: input.notes
                )
                showAddMeal = false
            }
        }
        .sheet(isPresented: $showAddExpense) {
            StudyExpenseEditorView { input in
                plannerVM.addStudyExpense(
                    title: input.title,
                    amount: input.amount,
                    date: input.date,
                    category: input.category,
                    notes: input.notes
                )
                showAddExpense = false
            }
        }
        .sheet(item: $editMeal) { entry in
            MealEntryEditorView(entry: entry) { input in
                let updated = MealEntry(
                    id: entry.id,
                    title: input.title,
                    date: input.date,
                    type: input.type,
                    amount: input.amount,
                    location: input.location,
                    notes: input.notes
                )
                plannerVM.updateMealEntry(updated)
                editMeal = nil
            }
        }
        .sheet(item: $editExpense) { expense in
            StudyExpenseEditorView(expense: expense) { input in
                let updated = StudyExpense(
                    id: expense.id,
                    title: input.title,
                    amount: input.amount,
                    date: input.date,
                    category: input.category,
                    notes: input.notes
                )
                plannerVM.updateStudyExpense(updated)
                editExpense = nil
            }
        }
        .appStatusBarStyle(.darkContent)
    }

    private var mealsTab: some View {
        VStack(spacing:14) {
            // Plan info
            HStack(spacing:12) {
                Text("🎓").scaledFont(size: 28, relativeTo: .largeTitle)
                VStack(alignment:.leading,spacing:3) {
                    Text("Gold Meal Plan").scaledFont(size: 15, weight: .semibold, relativeTo: .headline)
                    Text("58 days left in semester").scaledFont(size: 12, weight: .medium, relativeTo: .caption).foregroundStyle(Color.secondary)
                }
                Spacer()
                Text("58d").scaledFont(size: 12, weight: .bold, relativeTo: .caption).foregroundStyle(Color.uniBlue)
                    .padding(.horizontal,8).padding(.vertical,4).background(Color.uniBlue.opacity(0.1)).clipShape(Capsule())
            }
            .padding(16).plannerModuleCard(accent: accent)

            // Swipes card
            VStack(spacing:14) {
                HStack {
                    VStack(alignment:.leading,spacing:4) {
                        Text("Meal Swipes").scaledFont(size: 13, relativeTo: .caption).foregroundStyle(Color.secondary)
                        Text("63").scaledFont(size: 40, weight: .bold, relativeTo: .largeTitle).foregroundStyle(Color.primary)
                        Text("remaining").scaledFont(size: 12, weight: .medium, relativeTo: .caption).foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    VStack(alignment:.trailing,spacing:4) {
                        Text("This Week").scaledFont(size: 12, relativeTo: .caption).foregroundStyle(Color.secondary)
                        Text("9/14").scaledFont(size: 22, weight: .semibold, relativeTo: .title3).foregroundStyle(Color.primary)
                    }
                }
                UniProgressBar(progress:0.42, color:accent, height:8)
                Text("💡 Use ~1.8 swipes/day to last the semester")
                    .scaledFont(size: 12, weight: .medium, relativeTo: .caption).foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius:18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(accent.opacity(0.25), lineWidth: 1)
            )

            // Dining dollars + flex
            HStack(spacing:12) {
                VStack(alignment:.leading,spacing:8) {
                    Text("Dining Dollars").scaledFont(size: 12, weight: .medium, relativeTo: .caption).foregroundStyle(Color.secondary)
                    Text("Rs.2,655").scaledFont(size: 20, weight: .bold, relativeTo: .title3).foregroundStyle(Color.income)
                    UniProgressBar(progress:0.47,color:Color.income,height:6)
                }
                .padding(16).frame(maxWidth:.infinity).plannerModuleCard(accent: accent)
                VStack(alignment:.leading,spacing:8) {
                    Text("Flex Points").scaledFont(size: 12, weight: .medium, relativeTo: .caption).foregroundStyle(Color.secondary)
                    Text("Rs.1,217").scaledFont(size: 20, weight: .bold, relativeTo: .title3).foregroundStyle(Color.uniBlue)
                    UniProgressBar(progress:0.39,color:Color.uniBlue,height:6)
                }
                .padding(16).frame(maxWidth:.infinity).plannerModuleCard(accent: accent)
            }

            InsightCard(emoji:"⚠️",title:"Low Swipes Alert",
                        message:"Running low on meal swipes. Consider using dining dollars.",
                        bgColor:Color.expense.opacity(0.08),borderColor:Color.expense.opacity(0.2))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Meals").scaledFont(size: 16, weight: .semibold, relativeTo: .headline)
                    Spacer()
                    Button("Add Meal") { showAddMeal = true }
                        .scaledFont(size: 13, weight: .semibold, relativeTo: .caption)
                        .foregroundStyle(accent)
                }

                if mealEntries.isEmpty {
                    Text("No meals added yet.")
                        .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
                        .foregroundStyle(Color.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(mealEntries) { entry in
                        mealRow(entry)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    editMeal = entry
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    plannerVM.deleteMealEntry(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.2), lineWidth: 1))
        }
    }

    private var studyTab: some View {
        VStack(spacing:14) {
            VStack(spacing:8) {
                Text("Study Expenses This Month").scaledFont(size: 12, weight: .medium, relativeTo: .caption).foregroundStyle(Color.secondary)
                Text(studyTotal.currencyRS).scaledFont(size: 36, weight: .bold, relativeTo: .largeTitle).foregroundStyle(Color.primary)
                Text("\(studyExpenses.count) transactions").scaledFont(size: 12, weight: .medium, relativeTo: .caption).foregroundStyle(Color.secondary)
            }
            .frame(maxWidth:.infinity).padding(24)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius:18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(accent.opacity(0.25), lineWidth: 1)
            )

            LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:4),spacing:10) {
                ForEach([("🖨️","Printing"),("📚","Books"),("👨‍🏫","Tutoring"),("📝","Supplies")],id:\.0) { emoji,label in
                    VStack(spacing:6) {
                        Text(emoji).scaledFont(size: 22, relativeTo: .title2)
                        Text(label).scaledFont(size: 11, weight: .medium, relativeTo: .caption2).foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth:.infinity).padding(.vertical,14)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius:12))
                }
            }

            InsightCard(emoji:"💡",title:"Save on Textbooks",
                        message:"Check the library reserve or rent from Chegg before buying new textbooks!",
                        bgColor:Color.income.opacity(0.08),borderColor:Color.income.opacity(0.2))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Study Expenses").scaledFont(size: 16, weight: .semibold, relativeTo: .headline)
                    Spacer()
                    Button("Add Expense") { showAddExpense = true }
                        .scaledFont(size: 13, weight: .semibold, relativeTo: .caption)
                        .foregroundStyle(accent)
                }

                if studyExpenses.isEmpty {
                    Text("No study expenses yet.")
                        .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
                        .foregroundStyle(Color.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(studyExpenses) { expense in
                        studyExpenseRow(expense)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    editExpense = expense
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    plannerVM.deleteStudyExpense(expense)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.2), lineWidth: 1))
        }
    }

    private func mealRow(_ entry: MealEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accent.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text(entry.type.emoji).scaledFont(size: 18, relativeTo: .body)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .scaledFont(size: 14, weight: .semibold, relativeTo: .headline)
                Text("\(entry.type.label) · \(entry.date, style: .date)")
                    .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
                    .foregroundStyle(Color.secondary)
                if let location = entry.location, !location.isEmpty {
                    Text(location)
                        .scaledFont(size: 11, weight: .medium, relativeTo: .caption2)
                        .foregroundStyle(Color.secondary)
                }
            }
            Spacer()
            if entry.amount > 0 {
                Text(entry.amount.currencyRS)
                    .scaledFont(size: 12, weight: .semibold, relativeTo: .caption)
                    .foregroundStyle(Color.expense)
            }
        }
    }

    private func studyExpenseRow(_ expense: StudyExpense) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accent.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text("📘").scaledFont(size: 18, relativeTo: .body)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .scaledFont(size: 14, weight: .semibold, relativeTo: .headline)
                Text("\(expense.category) · \(expense.date, style: .date)")
                    .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
            Text(expense.amount.currencyRS)
                .scaledFont(size: 13, weight: .semibold, relativeTo: .caption)
                .foregroundStyle(Color.expense)
        }
    }
}

private struct MealEntryEditorView: View {
    struct Input {
        var title: String
        var date: Date
        var type: MealType
        var amount: Double
        var location: String?
        var notes: String?
    }

    @Environment(\.dismiss) var dismiss
    var entry: MealEntry? = nil
    let onSave: (Input) -> Void

    @State private var title = ""
    @State private var date = Date()
    @State private var type: MealType = .lunch
    @State private var amountText = ""
    @State private var location = ""
    @State private var notes = ""

    private var amount: Double { Double(amountText) ?? 0 }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(MealType.allCases) { item in
                            Text(item.label).tag(item)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Cost") {
                    TextField("Amount (optional)", text: $amountText)
                        .keyboardType(.decimalPad)
                }
                Section("Details") {
                    TextField("Location (optional)", text: $location)
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle(entry == nil ? "Add Meal" : "Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let input = Input(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            date: date,
                            type: type,
                            amount: amount,
                            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onSave(input)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let entry {
                    title = entry.title
                    date = entry.date
                    type = entry.type
                    amountText = entry.amount > 0 ? String(entry.amount) : ""
                    location = entry.location ?? ""
                    notes = entry.notes ?? ""
                }
            }
        }
    }
}

private struct StudyExpenseEditorView: View {
    struct Input {
        var title: String
        var amount: Double
        var date: Date
        var category: String
        var notes: String?
    }

    @Environment(\.dismiss) var dismiss
    var expense: StudyExpense? = nil
    let onSave: (Input) -> Void

    @State private var title = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var category = "Books"
    @State private var notes = ""

    private let categories = ["Books", "Printing", "Tutoring", "Supplies", "Other"]
    private var amount: Double { Double(amountText) ?? 0 }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense") {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle(expense == nil ? "Add Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let input = Input(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            amount: amount,
                            date: date,
                            category: category,
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onSave(input)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let expense {
                    title = expense.title
                    amountText = String(expense.amount)
                    date = expense.date
                    category = expense.category
                    notes = expense.notes ?? ""
                }
            }
        }
    }
}

#Preview("Meal Plan") {
    NavigationStack {
        MealPlanView()
            .environmentObject(AppState())
            .environmentObject(PlannerViewModel(transactionsVM: TransactionsViewModel()))
    }
}
