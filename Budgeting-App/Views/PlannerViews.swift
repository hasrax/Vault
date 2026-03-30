//
//  PlannerViews.swift
// Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Planner Hub
struct PlannerView: View {
    @State private var path = NavigationPath()
    private let modules = MockData.plannerModules

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    // Dark header
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient.headerGrad
                            .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Campus toolkit")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.4))
                                .textCase(.uppercase)
                            Text("My Planner")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white)
                            Text("Everything for budgeting, classes, and campus life.")
                                .font(.subheadline).foregroundStyle(Color.white.opacity(0.5))
                        }
                        .padding(24)
                        .padding(.top, 44)
                        .padding(.bottom, 24)
                    }

                    // Horizontal carousel
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Swipeable summaries")
                                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary).textCase(.uppercase)
                            Text("Slide through the toolkit").font(.system(size: 18, weight: .semibold))
                        }
                        .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(modules) { mod in
                                    NavigationLink(value: mod.destination) {
                                        plannerCarouselCard(mod)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 24)

                    // Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(modules) { mod in
                            NavigationLink(value: mod.destination) {
                                plannerGridCard(mod)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    // Info card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What happens in each area?").font(.system(size: 15, weight: .semibold))
                        ForEach([
                            ("📅","Semester planning","Sync tuition, exam weeks, and assignment reminders"),
                            ("💼","Work shifts","Compare hours versus targets and export the rota"),
                            ("🍽️","Meal & study","Balance swipes, dining rupees, and academic supplies"),
                            ("🎯","Savings","Route rupees toward books, rent, and emergency buffer"),
                            ("🔔","Smart notifications","Keep helpful nudges and snooze the rest"),
                            ("🤝","Split bill","Invite roommates, log each share, send a settle-up link"),
                        ], id:\.0) { emoji, title, desc in
                            HStack(alignment:.top, spacing:10) {
                                Text(emoji).font(.system(size:16))
                                VStack(alignment:.leading,spacing:2) {
                                    Text(title).font(.system(size:13,weight:.semibold))
                                    Text(desc).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .lightCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { dest in
                switch dest {
                case "semesterPlanner": SemesterPlannerView()
                case "workSchedule":    WorkScheduleView()
                case "mealPlan":        MealPlanView()
                case "savings":         SavingsView()
                case "splitBill":       SplitBillView()
                case "analytics":       AnalyticsView()
                default:                Text(dest)
                }
            }
        }
    }

    private func plannerCarouselCard(_ mod: PlannerModule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(mod.pill)
                .font(.system(size:11,weight:.bold)).textCase(.uppercase)
                .foregroundStyle(Color.white.opacity(0.7))
                .padding(.horizontal,10).padding(.vertical,4)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            Spacer()
            Text(mod.title)
                .font(.system(size:17,weight:.bold))
                .foregroundStyle(Color.white)
            Text(mod.description)
                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.7))
                .lineLimit(3)
            Text("Open →")
                .font(.system(size:13,weight:.semibold)).foregroundStyle(Color.white)
                .padding(.top,4)
        }
        .padding(18)
        .frame(width:200,height:180)
        .background(mod.gradient)
        .clipShape(RoundedRectangle(cornerRadius:18))
    }

    private func plannerGridCard(_ mod: PlannerModule) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(mod.pill)
                .font(.system(size:10,weight:.bold)).textCase(.uppercase)
                .foregroundStyle(Color.white)
                .padding(.horizontal,8).padding(.vertical,3)
                .background(mod.gradient)
                .clipShape(Capsule())
            Text(mod.title).font(.system(size:14,weight:.semibold)).foregroundStyle(Color.primary).lineLimit(1)
            Text(mod.description).font(.system(size: 11)).foregroundStyle(Color.secondary).lineLimit(2)
            HStack {
                Spacer()
                Image(systemName:"chevron.right").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth:.infinity, alignment:.leading)
        .lightCard()
    }
}

// MARK: - Semester Planner
struct SemesterPlannerView: View {
    @State private var activeTab = "overview"

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
            ForEach(MockData.importantDates.sorted { $0.date < $1.date }) { (item: ImportantDate) in
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
                    if let amt = item.amount {
                        Text("\(item.type == .income ? "+" : "−")\(amt.currencyRS)")
                            .font(.system(size:14,weight:.semibold))
                            .foregroundStyle(item.color)
                    }
                }
                .padding(16)
                .lightCard()
            }
            Button("+ Add Important Date") {}
                .font(.system(size:15,weight:.semibold)).foregroundStyle(Color.uniBlue)
                .frame(maxWidth:.infinity).frame(height:48)
                .background(Color.uniBlue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius:12))
                .padding(.top,4)
        }
        .padding(.horizontal,16).padding(.top,16)
    }

    private var goalsTab: some View {
        VStack(spacing:12) {
            ForEach(MockData.semesterGoals) { (goal: SemesterGoal) in
                HStack(alignment:.top,spacing:14) {
                    ZStack {
                        Circle()
                            .fill(goal.completed ? Color.income : Color(UIColor.tertiarySystemFill))
                            .frame(width:28,height:28)
                        if goal.completed {
                            Image(systemName:"checkmark").font(.system(size:12,weight:.bold)).foregroundStyle(Color.white)
                        }
                    }
                    .padding(.top,2)
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
                }
                .padding(16)
                .lightCard()
            }
            Button("+ Add New Goal") {}
                .font(.system(size:15,weight:.semibold)).foregroundStyle(Color.uniBlue)
                .frame(maxWidth:.infinity).frame(height:48)
                .background(LinearGradient.primaryGrad)
                .clipShape(RoundedRectangle(cornerRadius:12))
                .foregroundStyle(Color.white)
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

// MARK: - Work Schedule
struct WorkScheduleView: View {
    @State private var activeTab = "week"
    @State private var viewMode = "hours"
    private let shifts = MockData.shifts
    private var shiftDays: Set<String> { Set(shifts.map(\.day)) }
    private var completed: [WorkShift] { shifts.filter{$0.status == .completed} }
    private var upcoming: [WorkShift]  { shifts.filter{$0.status == .upcoming} }
    private var totalEarned:     Double { completed.reduce(0){$0+$1.pay} }
    private var projectedEarnings: Double { shifts.reduce(0){$0+$1.pay} }
    private var totalHours:      Int { completed.reduce(0){$0+$1.hours} }

    private var displayedShifts: [WorkShift] {
        switch activeTab {
        case "upcoming":  return upcoming
        case "completed": return completed
        default:          return shifts
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Dark header
                ZStack(alignment: .bottom) {
                    LinearGradient.headerGrad
                        .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft,.bottomRight]))
                    VStack(spacing: 20) {
                        HStack(spacing:12) {
                            GlassStatCard(label:"Earned",    value:totalEarned.shortCurrency,       sub:"\(totalHours)h worked", valueColor:Color.income)
                            GlassStatCard(label:"Projected", value:projectedEarnings.shortCurrency, sub:"this month",            valueColor:Color.uniBlue)
                            GlassStatCard(label:"Upcoming",  value:"\(upcoming.count)",             sub:"shifts left",           valueColor:Color.warning)
                        }
                        WeekDayStrip(shiftDays: shiftDays)
                    }
                    .padding(.horizontal,16)
                    .padding(.vertical,24)
                }

                // View mode toggle
                HStack(spacing:10) {
                    ForEach([("hours","2-hour view"),("monthly","Monthly view")],id:\.0) { id,label in
                        FilterChip(label:label, isSelected:viewMode == id) { viewMode = id }
                    }
                    Spacer()
                }
                .padding(.horizontal,16).padding(.top,16)

                // Info card
                VStack(alignment:.leading,spacing:4) {
                    Text(viewMode == "hours" ? "Recommended block" : "Monthly pacing")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    Text(viewMode == "hours" ? "2h × 3 sessions" : "5 blocks · 20h")
                        .font(.system(size:22,weight:.bold,design:.rounded))
                    Text(viewMode == "hours"
                         ? "Split your shifts into smaller two-hour bursts when classes are tight."
                         : "Average pay per hour \(Double(totalEarned / max(Double(totalHours),1)).currencyRS)")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                }
                .padding(16)
                .frame(maxWidth:.infinity,alignment:.leading)
                .lightCard()
                .padding(.horizontal,16).padding(.top,12)

                // Tab filter
                HStack(spacing:10) {
                    ForEach([("week","Week"),("upcoming","Upcoming"),("completed","Completed")],id:\.0) { id,label in
                        FilterChip(label:label,isSelected:activeTab == id) { activeTab = id }
                    }
                    Spacer()
                }
                .padding(.horizontal,16).padding(.top,16)

                // Shifts
                VStack(spacing:10) {
                    ForEach(displayedShifts) { shift in ShiftCard(shift:shift) }
                }
                .padding(.horizontal,16).padding(.top,12)

                // Add shift
                Button {
                } label: {
                    Label("Add Shift",systemImage:"plus")
                        .font(.system(size:15,weight:.semibold)).foregroundStyle(Color.white)
                        .frame(maxWidth:.infinity).frame(height:50)
                        .background(LinearGradient.primaryGrad)
                        .clipShape(RoundedRectangle(cornerRadius:14))
                }
                .padding(.horizontal,16).padding(.top,20).padding(.bottom,40)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Work Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Meal Plan
struct MealPlanView: View {
    @State private var activeTab = "meals"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Tab switcher
                HStack(spacing: 4) {
                    ForEach([("meals","🍽️ Meal Plan"),("study","📚 Study Costs")],id:\.0) { id,label in
                        Button {
                            withAnimation(.spring(duration: 0.25)) { activeTab = id }
                        } label: {
                            Text(label)
                                .font(.system(size:14,weight:.semibold))
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
    }

    private var mealsTab: some View {
        VStack(spacing:14) {
            // Plan info
            HStack(spacing:12) {
                Text("🎓").font(.system(size:28))
                VStack(alignment:.leading,spacing:3) {
                    Text("Gold Meal Plan").font(.system(size:15,weight:.semibold))
                    Text("58 days left in semester").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                }
                Spacer()
                Text("58d").font(.system(size:12,weight:.bold)).foregroundStyle(Color.uniBlue)
                    .padding(.horizontal,8).padding(.vertical,4).background(Color.uniBlue.opacity(0.1)).clipShape(Capsule())
            }
            .padding(16).lightCard()

            // Swipes card
            VStack(spacing:14) {
                HStack {
                    VStack(alignment:.leading,spacing:4) {
                        Text("Meal Swipes").font(.system(size:13)).foregroundStyle(Color.white.opacity(0.9))
                        Text("63").font(.system(size:40,weight:.bold)).foregroundStyle(Color.white)
                        Text("remaining").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.8))
                    }
                    Spacer()
                    VStack(alignment:.trailing,spacing:4) {
                        Text("This Week").font(.system(size:12)).foregroundStyle(Color.white.opacity(0.9))
                        Text("9/14").font(.system(size:22,weight:.semibold)).foregroundStyle(Color.white)
                    }
                }
                UniProgressBar(progress:0.42, color:.white, height:8)
                Text("💡 Use ~1.8 swipes/day to last the semester")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(LinearGradient.amberGrad)
            .clipShape(RoundedRectangle(cornerRadius:18))

            // Dining dollars + flex
            HStack(spacing:12) {
                VStack(alignment:.leading,spacing:8) {
                    Text("Dining Dollars").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    Text("Rs.2,655").font(.system(size:20,weight:.bold)).foregroundStyle(Color.income)
                    UniProgressBar(progress:0.47,color:Color.income,height:6)
                }
                .padding(16).frame(maxWidth:.infinity).lightCard()
                VStack(alignment:.leading,spacing:8) {
                    Text("Flex Points").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    Text("Rs.1,217").font(.system(size:20,weight:.bold)).foregroundStyle(Color.uniBlue)
                    UniProgressBar(progress:0.39,color:Color.uniBlue,height:6)
                }
                .padding(16).frame(maxWidth:.infinity).lightCard()
            }

            InsightCard(emoji:"⚠️",title:"Low Swipes Alert",
                        message:"Running low on meal swipes. Consider using dining dollars.",
                        bgColor:Color.expense.opacity(0.08),borderColor:Color.expense.opacity(0.2))
        }
    }

    private var studyTab: some View {
        VStack(spacing:14) {
            VStack(spacing:8) {
                Text("Study Expenses This Month").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.9))
                Text("Rs.4,965").font(.system(size:36,weight:.bold)).foregroundStyle(Color.white)
                Text("5 transactions").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.8))
            }
            .frame(maxWidth:.infinity).padding(24)
            .background(LinearGradient.purpleGrad)
            .clipShape(RoundedRectangle(cornerRadius:18))

            LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:4),spacing:10) {
                ForEach([("🖨️","Printing"),("📚","Books"),("👨‍🏫","Tutoring"),("📝","Supplies")],id:\.0) { emoji,label in
                    VStack(spacing:6) {
                        Text(emoji).font(.system(size:22))
                        Text(label).font(.system(size:11,weight:.medium)).foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth:.infinity).padding(.vertical,14)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius:12))
                }
            }

            InsightCard(emoji:"💡",title:"Save on Textbooks",
                        message:"Check the library reserve or rent from Chegg before buying new textbooks!",
                        bgColor:Color.income.opacity(0.08),borderColor:Color.income.opacity(0.2))
        }
    }
}

// MARK: - Savings
struct SavingsView: View {
    @State private var goals = MockData.savingsGoals
    private var totalSaved:  Double { goals.reduce(0){$0+$1.currentAmount} }
    private var totalTarget: Double { goals.reduce(0){$0+$1.targetAmount} }

    var body: some View {
        ScrollView {
            VStack(spacing:16) {
                // Total card
                VStack(spacing:12) {
                    Text("Total Saved").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.9))
                    Text(totalSaved.currencyRS)
                        .font(.system(size:36,weight:.bold,design:.rounded)).foregroundStyle(Color.white)
                    Text("of \(totalTarget.currencyRS) goal").font(.subheadline).foregroundStyle(Color.white.opacity(0.8))
                    UniProgressBar(progress:totalSaved/totalTarget,color:.white,height:10)
                }
                .padding(24)
                .background(LinearGradient.savingsGoldGrad)
                .clipShape(RoundedRectangle(cornerRadius:20))

                // Goals
                ForEach(goals) { goal in
                    GoalCard(goal:goal) {}
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
                .background(Color.uniBlue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius:14))
                .overlay(RoundedRectangle(cornerRadius:14).stroke(Color.uniBlue.opacity(0.15),lineWidth:1))
            }
            .padding(.horizontal,16).padding(.top,16).padding(.bottom,40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Savings Goals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement:.topBarTrailing) {
                Button { } label: { Image(systemName:"plus") }
            }
        }
    }
}

// MARK: - Split Bill
struct SplitBillView: View {
    @State private var amountText = ""
    @State private var description = ""
    @State private var splitMethod = "equal"
    @State private var includeSelf = true
    @State private var selectedPeople: Set<UUID> = []
    private let roommates = MockData.roommates

    private var amount: Double { Double(amountText) ?? 0 }
    private var totalPeople: Int { selectedPeople.count + (includeSelf ? 1 : 0) }
    private var splitAmount: Double { totalPeople > 0 ? amount / Double(totalPeople) : 0 }

    private var amountInputSection: some View {
        VStack(spacing: 8) {
            Text("Total Amount")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
            AmountInput(text: $amountText, accentColor: Color.uniPurple)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing:24) {
            // Amount input
            amountInputSection

                // Description
                VStack(alignment:.leading,spacing:8) {
                    Text("What's this for?").font(.system(size:14,weight:.medium)).foregroundStyle(Color.white)
                    TextField("e.g. Dinner, Rent, Utilities",text:$description)
                        .foregroundStyle(Color.white)
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius:12))
                        .overlay(RoundedRectangle(cornerRadius:12).stroke(Color.white.opacity(0.1),lineWidth:1))
                }

                // Split method
                VStack(alignment:.leading,spacing:10) {
                    Text("Split Method").font(.system(size:14,weight:.medium)).foregroundStyle(Color.white)
                    HStack(spacing:10) {
                        ForEach([("equal","⚖️","Equal"),("custom","✏️","Custom"),("percentage","📊","Percent")],id:\.0) { id,emoji,label in
                            Button {
                                splitMethod = id
                            } label: {
                                VStack(spacing:6) {
                                    Text(emoji).font(.system(size:22))
                                    Text(label).font(.system(size:11,weight:.medium)).foregroundStyle(splitMethod==id ? Color.uniPurple : Color.secondary)
                                }
                                .frame(maxWidth:.infinity).padding(.vertical,14)
                                .background(splitMethod == id ? Color.uniPurple.opacity(0.15) : Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius:12))
                                .overlay(RoundedRectangle(cornerRadius:12)
                                    .stroke(splitMethod==id ? Color.uniPurple : Color.clear,lineWidth:1.5))
                            }
                        }
                    }
                }

                // People selection
                VStack(alignment:.leading,spacing:10) {
                    Text("Split with").font(.system(size:14,weight:.medium)).foregroundStyle(Color.white)

                    // Self
                    personRow(avatar:"🎓",name:"You",color:Color.uniBlue,isSelected:includeSelf) {
                        includeSelf.toggle()
                    }

                    ForEach(roommates) { r in
                        let sel = selectedPeople.contains(r.id)
                        personRow(avatar:r.avatar,name:r.name,color:r.color,isSelected:sel) {
                            if sel { selectedPeople.remove(r.id) }
                            else   { selectedPeople.insert(r.id) }
                        }
                    }
                }

                // Preview
                if amount > 0 && totalPeople > 0 {
                    VStack(spacing:8) {
                        Text("Each person pays").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                        Text(splitAmount.currencyRS)
                            .font(.system(size:32,weight:.bold,design:.rounded)).foregroundStyle(Color.uniPurple)
                        Text("Split between \(totalPeople) people")
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth:.infinity).padding(20)
                    .background(Color.uniPurple.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius:16))
                    .overlay(RoundedRectangle(cornerRadius:16).stroke(Color.uniPurple.opacity(0.2),lineWidth:1))
                }

                Button {
                } label: {
                    Text("Create Split")
                        .font(.system(size:16,weight:.semibold)).foregroundStyle(Color.white)
                        .frame(maxWidth:.infinity).frame(height:52)
                        .background(amount > 0 && totalPeople > 0 ? LinearGradient.purpleGrad : LinearGradient(colors:[Color.white.opacity(0.1)],startPoint:.leading,endPoint:.trailing))
                        .clipShape(RoundedRectangle(cornerRadius:14))
                }
                .disabled(amount == 0 || totalPeople == 0)
            }
            .padding(20).padding(.bottom,40)
        }
        .background(LinearGradient(colors:[Color(hex:"#0D0D0D"),Color(hex:"#1A1A1A")],startPoint:.top,endPoint:.bottom))
        .ignoresSafeArea()
        .navigationTitle("Split Bill")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex:"#0D0D0D"),for:.navigationBar)
        .toolbarColorScheme(.dark,for:.navigationBar)
    }

    private func personRow(avatar:String,name:String,color:Color,isSelected:Bool,toggle:@escaping()->Void) -> some View {
        Button(action:toggle) {
            HStack(spacing:14) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width:44,height:44)
                    Text(avatar).font(.system(size:20))
                }
                VStack(alignment:.leading,spacing:2) {
                    Text(name).font(.system(size:15,weight:.medium)).foregroundStyle(Color.white)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.uniPurple : Color.white.opacity(0.1))
                        .frame(width:24,height:24)
                    if isSelected {
                        Image(systemName:"checkmark").font(.system(size:11,weight:.bold)).foregroundStyle(Color.white)
                    }
                }
            }
            .padding(14)
            .background(isSelected ? Color.uniPurple.opacity(0.1) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius:14))
            .overlay(RoundedRectangle(cornerRadius:14)
                .stroke(isSelected ? Color.uniPurple : Color.white.opacity(0.08),lineWidth:isSelected ? 1.5 : 1))
        }
    }
}

#Preview("Planner")   { PlannerView().environmentObject(AppState()) }
#Preview("Semester")  { NavigationStack { SemesterPlannerView() } }
#Preview("Work")      { NavigationStack { WorkScheduleView() } }
#Preview("Meal Plan") { NavigationStack { MealPlanView() } }
#Preview("Savings")   { NavigationStack { SavingsView() } }
#Preview("Split")     { NavigationStack { SplitBillView() } }
