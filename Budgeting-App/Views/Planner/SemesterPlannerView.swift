//
//  SemesterPlannerView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Semester Planner
struct SemesterPlannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var plannerVM: PlannerViewModel
    @State private var activeTab = "overview"
    @State private var showAddGoal = false
    @State private var newGoalTitle = ""
    @State private var newGoalProgress = ""
    @State private var showAddDate = false
    @State private var dateTitle = ""
    @State private var dateType: ImportantDate.DateType = .event
    @State private var dateAmount = ""
    @State private var dateIcon = "📌"
    @State private var selectedDate = Date()
    @State private var editGoal: SemesterGoal?
    @State private var editDate: ImportantDate?

    private let semesterBudget = 4000.0
    private let spent = 1650.0
    private let totalWeeks = 16
    private let currentWeek = 9

    private var remaining: Double { semesterBudget - spent }
    private var weeksLeft: Int   { totalWeeks - currentWeek }
    private var weeklyBudget: Double { weeksLeft > 0 ? remaining / Double(weeksLeft) : remaining }
    private var budgetProgress: Double { spent / semesterBudget }
    private var weekProgress: Double   { Double(currentWeek) / Double(totalWeeks) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Tab switcher
                HStack(spacing: 4) {
                    ForEach([("overview","📊 Overview"),("calendar","📅 Dates"),("goals","🎯 Goals")], id:\.0) { id, label in
                        Button {
                            withAnimation(.spring(duration: 0.3)) { activeTab = id }
                        } label: {
                            Text(label)
                                .font(.system(size:13,weight:.semibold))
                                .foregroundStyle(activeTab == id ? Color.white : Color.secondary)
                                .frame(maxWidth:.infinity).frame(height:40)
                                .background(activeTab == id ? Color.uniBlue : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius:10))
                        }
                    }
                }
                .padding(4)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius:14))
                .padding(.horizontal,16).padding(.top,16)

                if activeTab == "overview"  { overviewTab }
                else if activeTab == "calendar" { calendarTab }
                else { goalsTab }
            }
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Semester Planner")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
        .sheet(isPresented: $showAddGoal) {
            NavigationStack {
                Form {
                    Section("Goal") {
                        TextField("Goal title", text: $newGoalTitle)
                    }
                    Section("Progress (optional)") {
                        TextField("0 - 100", text: $newGoalProgress)
                            .keyboardType(.numberPad)
                    }
                }
                .navigationTitle("New Goal")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { showAddGoal = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add") {
                            let trimmed = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            let progress = Int(newGoalProgress)
                            plannerVM.addSemesterGoal(title: trimmed, progress: progress)
                            newGoalTitle = ""
                            newGoalProgress = ""
                            showAddGoal = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddDate) {
            NavigationStack {
                Form {
                    Section("Title") {
                        TextField("e.g. Tuition Due", text: $dateTitle)
                    }
                    Section("Date") {
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                    Section("Type") {
                        Picker("Type", selection: $dateType) {
                            Text("Bill").tag(ImportantDate.DateType.bill)
                            Text("Income").tag(ImportantDate.DateType.income)
                            Text("Event").tag(ImportantDate.DateType.event)
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Amount (optional)") {
                        TextField("e.g. 2500", text: $dateAmount)
                            .keyboardType(.numberPad)
                    }
                    Section("Icon") {
                        TextField("Emoji", text: $dateIcon)
                    }
                }
                .navigationTitle("New Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { showAddDate = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add") {
                            let title = dateTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !title.isEmpty else { return }
                            let amount = Double(dateAmount)
                            let icon = dateIcon.isEmpty ? "📌" : dateIcon
                            plannerVM.addImportantDate(title: title, date: selectedDate, type: dateType, amount: amount, icon: icon)
                            dateTitle = ""
                            dateAmount = ""
                            dateIcon = "📌"
                            selectedDate = Date()
                            showAddDate = false
                        }
                    }
                }
            }
        }
        .sheet(item: $editGoal) { goal in
            NavigationStack {
                Form {
                    Section("Goal") {
                        TextField("Goal title", text: $newGoalTitle)
                    }
                    Section("Progress (optional)") {
                        TextField("0 - 100", text: $newGoalProgress)
                            .keyboardType(.numberPad)
                    }
                }
                .navigationTitle("Edit Goal")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { editGoal = nil }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            let title = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !title.isEmpty else { return }
                            let progress = Int(newGoalProgress)
                            let updated = SemesterGoal(id: goal.id, title: title, completed: goal.completed, progress: progress)
                            plannerVM.updateSemesterGoal(updated)
                            editGoal = nil
                        }
                    }
                }
                .onAppear {
                    newGoalTitle = goal.title
                    newGoalProgress = goal.progress.map(String.init) ?? ""
                }
            }
        }
        .sheet(item: $editDate) { item in
            NavigationStack {
                Form {
                    Section("Title") {
                        TextField("e.g. Tuition Due", text: $dateTitle)
                    }
                    Section("Date") {
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                    Section("Type") {
                        Picker("Type", selection: $dateType) {
                            Text("Bill").tag(ImportantDate.DateType.bill)
                            Text("Income").tag(ImportantDate.DateType.income)
                            Text("Event").tag(ImportantDate.DateType.event)
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Amount (optional)") {
                        TextField("e.g. 2500", text: $dateAmount)
                            .keyboardType(.numberPad)
                    }
                    Section("Icon") {
                        TextField("Emoji", text: $dateIcon)
                    }
                }
                .navigationTitle("Edit Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { editDate = nil }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            let title = dateTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !title.isEmpty else { return }
                            let amount = Double(dateAmount)
                            let icon = dateIcon.isEmpty ? "📌" : dateIcon
                            let updated = ImportantDate(id: item.id, title: title, date: selectedDate, type: dateType, amount: amount, icon: icon)
                            plannerVM.updateImportantDate(updated)
                            editDate = nil
                        }
                    }
                }
                .onAppear {
                    dateTitle = item.title
                    dateType = item.type
                    dateAmount = item.amount.map { String(Int($0)) } ?? ""
                    dateIcon = item.icon
                    selectedDate = item.date
                }
            }
        }
    }

    private var overviewTab: some View {
        VStack(spacing: 16) {
            // Main card
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment:.leading,spacing:4) {
                        Text("Semester Budget").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.8))
                        Text(semesterBudget.currencyRS).font(.system(size:28,weight:.bold,design:.rounded)).foregroundStyle(Color.white)
                    }
                    Spacer()
                    VStack(alignment:.trailing,spacing:4) {
                        Text("Remaining").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.8))
                        Text(remaining.currencyRS).font(.system(size:20,weight:.semibold)).foregroundStyle(Color.white)
                    }
                }
                VStack(spacing:8) {
                    HStack {
                        Text("Budget used").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.8))
                        Spacer()
                        Text("\(Int(budgetProgress*100))%").font(.system(size: 12, weight: .bold)).foregroundStyle(Color.white)
                    }
                    UniProgressBar(progress:budgetProgress, color:budgetProgress > weekProgress ? Color.warning : Color.white, height:8)
                    HStack {
                        Text("Semester progress").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.8))
                        Spacer()
                        Text("Week \(currentWeek) of \(totalWeeks)").font(.system(size: 12, weight: .bold)).foregroundStyle(Color.white)
                    }
                    UniProgressBar(progress:weekProgress, color:.white, height:8)
                }
            }
            .padding(24)
            .background(LinearGradient.primaryGrad)
            .clipShape(RoundedRectangle(cornerRadius:20))

            // Weekly budget suggestion
            HStack(spacing:14) {
                Text("💡").font(.system(size:28))
                VStack(alignment:.leading,spacing:4) {
                    Text("Recommended weekly budget").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    Text(weeklyBudget.currencyRS)
                        .font(.system(size:24,weight:.bold,design:.rounded)).foregroundStyle(Color.income)
                    Text("To stay on track for \(weeksLeft) remaining weeks")
                        .font(.system(size: 11)).foregroundStyle(Color.secondary)
                }
            }
            .padding(18)
            .frame(maxWidth:.infinity,alignment:.leading)
            .background(Color.income.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius:14))
            .overlay(RoundedRectangle(cornerRadius:14).stroke(Color.income.opacity(0.2),lineWidth:1))

            // Monthly breakdown
            VStack(alignment:.leading,spacing:14) {
                Text("Monthly Plan").font(.system(size: 18, weight: .semibold))
                VStack(spacing:0) {
                    ForEach([
                        ("January",800.0,780.0,"completed"),
                        ("February",1000.0,870.0,"completed"),
                        ("March",1000.0,420.0,"current"),
                        ("April",700.0,0.0,"upcoming"),
                        ("May",500.0,0.0,"upcoming"),
                    ],id:\.0) { month, budget, mSpent, status in
                        monthRow(month:month,budget:budget,spent:mSpent,status:status)
                    }
                }
            }
            .padding(.horizontal,16).padding(.vertical,20)
            .lightCard()
        }
        .padding(.horizontal,16).padding(.top,16)
    }

    private func monthRow(month:String,budget:Double,spent:Double,status:String) -> some View {
        VStack(spacing:0) {
            HStack {
                Text(month).font(.system(size:15,weight:.semibold))
                if status == "current" {
                    Text("Current").font(.system(size:10,weight:.bold)).foregroundStyle(Color.uniBlue)
                        .padding(.horizontal,7).padding(.vertical,3).background(Color.uniBlue.opacity(0.12)).clipShape(Capsule())
                } else if status == "completed" {
                    Text("✓ Done").font(.system(size:10,weight:.bold)).foregroundStyle(Color.income)
                        .padding(.horizontal,7).padding(.vertical,3).background(Color.income.opacity(0.12)).clipShape(Capsule())
                }
                Spacer()
                Text("\(spent.currencyRS) / \(budget.currencyRS)")
                    .font(.system(size:13,weight:.semibold))
                    .foregroundStyle(spent > budget ? Color.expense : Color.primary)
            }
            .padding(.vertical,14)
            UniProgressBar(progress:budget > 0 ? min(spent/budget,1) : 0,
                           color:status == "upcoming" ? Color(UIColor.tertiarySystemFill)
                            : spent > budget ? Color.expense : Color.uniBlue, height:6)
                .padding(.bottom,14)
            Divider()
        }
        .padding(.horizontal,16)
    }

    private var calendarTab: some View {
        VStack(spacing:14) {
            ForEach(plannerVM.importantDates.sorted { $0.date < $1.date }) { (item: ImportantDate) in
                HStack(spacing:14) {
                    ZStack {
                        RoundedRectangle(cornerRadius:12)
                            .fill(item.color.opacity(0.1))
                            .frame(width:48,height:48)
                        Text(item.icon).font(.system(size:22))
                    }
                    VStack(alignment:.leading,spacing:3) {
                        Text(item.title).font(.system(size:15,weight:.semibold))
                        Text("\(item.date, style:.date) · \(daysUntil(item.date))")
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        if let amt = item.amount {
                            Text("\(item.type == .income ? "+" : "−")\(amt.currencyRS)")
                                .font(.system(size:14,weight:.semibold))
                                .foregroundStyle(item.color)
                        }
                        Button {
                            editDate = item
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundStyle(Color.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit date")
                    }
                }
                .padding(16)
                .lightCard()
                .contextMenu {
                    Button {
                        editDate = item
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        plannerVM.deleteImportantDate(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            Button("+ Add Important Date") { showAddDate = true }
                .font(.system(size:15,weight:.semibold)).foregroundStyle(Color.white)
                .frame(maxWidth:.infinity).frame(height:48)
                .background(LinearGradient.ctaGrad)
                .clipShape(RoundedRectangle(cornerRadius:12))
                .padding(.top,4)
        }
        .padding(.horizontal,16).padding(.top,16)
    }

    private var goalsTab: some View {
        VStack(spacing:12) {
            ForEach(plannerVM.semesterGoals) { (goal: SemesterGoal) in
                HStack(alignment:.top,spacing:14) {
                    Button {
                        plannerVM.toggleSemesterGoal(goal)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(goal.completed ? Color.income : Color(UIColor.tertiarySystemFill))
                                .frame(width:28,height:28)
                            if goal.completed {
                                Image(systemName:"checkmark").font(.system(size:12,weight:.bold)).foregroundStyle(Color.white)
                            }
                        }
                        .padding(.top,2)
                    }
                    .buttonStyle(.plain)
                    VStack(alignment:.leading,spacing:8) {
                        Text(goal.title)
                            .font(.system(size:15,weight:.medium))
                            .foregroundStyle(goal.completed ? Color.secondary : Color.primary)
                            .strikethrough(goal.completed)
                        if let p = goal.progress, !goal.completed {
                            VStack(alignment:.leading,spacing:4) {
                                HStack {
                                    Text("Progress").font(.system(size: 11)).foregroundStyle(Color.secondary)
                                    Spacer()
                                    Text("\(p)%").font(.system(size:11,weight:.bold)).foregroundStyle(Color.uniBlue)
                                }
                                UniProgressBar(progress:Double(p)/100,color:Color.uniBlue,height:6)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        if !goal.completed { editGoal = goal }
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(goal.completed)
                    .accessibilityLabel("Edit goal")
                }
                .padding(16)
                .lightCard()
                .contextMenu {
                    Button {
                        if !goal.completed { editGoal = goal }
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .disabled(goal.completed)
                    Button(role: .destructive) {
                        plannerVM.deleteSemesterGoal(goal)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            Button("+ Add New Goal") { showAddGoal = true }
                .font(.system(size:15,weight:.semibold)).foregroundStyle(Color.white)
                .frame(maxWidth:.infinity).frame(height:48)
                .background(Color.ctaBlue)
                .clipShape(RoundedRectangle(cornerRadius:12))
                .padding(.top,4)

            HStack(spacing:14) {
                Text("🏆").font(.system(size:28))
                VStack(alignment:.leading,spacing:4) {
                    Text("You're doing great!").font(.system(size: 15, weight: .semibold))
                    Text("2 of 4 goals completed. Keep going — you've got this!")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                }
            }
            .padding(16)
            .background(Color.warning.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius:14))
            .overlay(RoundedRectangle(cornerRadius:14).stroke(Color.warning.opacity(0.2),lineWidth:1))
        }
        .padding(.horizontal,16).padding(.top,16)
    }

    private func daysUntil(_ d: Date) -> String {
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
        if diff == 0 { return "Today" }
        if diff == 1 { return "Tomorrow" }
        if diff < 0  { return "Passed" }
        return "\(diff) days"
    }
}

#Preview("Semester")  {
    let vm = PlannerViewModel(transactionsVM: TransactionsViewModel())
    vm.importantDates = MockData.importantDates
    vm.semesterGoals = MockData.semesterGoals
    return NavigationStack { SemesterPlannerView().environmentObject(vm) }
}
