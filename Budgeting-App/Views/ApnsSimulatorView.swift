import SwiftUI
import UIKit

struct ApnsSimulatorView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var transactionsVM: TransactionsViewModel
    @EnvironmentObject var savingsVM: SavingsGoalsViewModel
    @EnvironmentObject var plannerVM: PlannerViewModel
    @EnvironmentObject var splitBillsVM: SplitBillsViewModel

    @State private var apnsFilePath = ""
    @State private var apnsCommand = ""
    @State private var apnsError = ""
    @State private var apnsTitle = ""
    @State private var apnsBody = ""
    @State private var apnsLink = ""

    var body: some View {
        List {
            Section("Custom") {
                TextField("Custom title", text: $apnsTitle)
                TextField("Custom body", text: $apnsBody)
                TextField("Custom link (optional)", text: $apnsLink)
                Button("Generate Custom APNs") {
                    generateApnsPayload(
                        title: apnsTitle.isEmpty ? "Custom notification" : apnsTitle,
                        body: apnsBody.isEmpty ? "Custom body" : apnsBody,
                        link: apnsLink,
                        type: nil,
                        filePrefix: "custom"
                    )
                }
            }

            Section("Presets") {
                Button("Generate Budget APNs") {
                    let template = budgetTemplate(isOverOnly: false)
                    generateApnsPayload(
                        title: template.title,
                        body: template.body,
                        type: "budget",
                        filePrefix: template.filePrefix
                    )
                }
                Button("Generate Budget Exceeded APNs") {
                    let template = budgetTemplate(isOverOnly: true)
                    generateApnsPayload(
                        title: template.title,
                        body: template.body,
                        type: "budget",
                        filePrefix: template.filePrefix
                    )
                }
                Button("Generate Latest Expense APNs") {
                    let template = transactionTemplate(type: .expense, limitTo: nil)
                    generateApnsPayload(
                        title: template.title,
                        body: template.body,
                        type: "budget",
                        filePrefix: template.filePrefix
                    )
                }
                Button("Generate Latest Income APNs") {
                    let template = transactionTemplate(type: .income, limitTo: nil)
                    generateApnsPayload(
                        title: template.title,
                        body: template.body,
                        type: "budget",
                        filePrefix: template.filePrefix
                    )
                }
                Button("Generate Needs Update APNs") {
                    let template = transactionTemplate(type: .expense, limitTo: .needs)
                    generateApnsPayload(
                        title: template.title,
                        body: template.body,
                        type: "budget",
                        filePrefix: template.filePrefix
                    )
                }
                Button("Generate Shift APNs") {
                    let template = shiftTemplate()
                    generateApnsPayload(
                        title: template.title,
                        body: template.body,
                        type: "work",
                        filePrefix: template.filePrefix
                    )
                }
                Button("Generate Split Bill APNs") {
                    let template = splitTemplate(kind: .request)
                    generateApnsPayload(
                        title: template.title,
                        body: template.body,
                        type: "planner",
                        filePrefix: template.filePrefix
                    )
                }
                Button("Generate Split Accepted APNs") {
                    let template = splitTemplate(kind: .accepted)
                    generateApnsPayload(
                        title: template.title,
                        body: template.body,
                        type: "planner",
                        filePrefix: template.filePrefix
                    )
                }
                Button("Generate Split Paid APNs") {
                    let template = splitTemplate(kind: .paid)
                    generateApnsPayload(
                        title: template.title,
                        body: template.body,
                        type: "planner",
                        filePrefix: template.filePrefix
                    )
                }
                Button("Generate Savings APNs") {
                    let template = savingsTemplate(isReached: false)
                    generateApnsPayload(
                        title: template.title,
                        body: template.body,
                        type: "budget",
                        filePrefix: template.filePrefix
                    )
                }
                Button("Generate Savings Reached APNs") {
                    let template = savingsTemplate(isReached: true)
                    generateApnsPayload(
                        title: template.title,
                        body: template.body,
                        type: "budget",
                        filePrefix: template.filePrefix
                    )
                }
            }

            if !apnsFilePath.isEmpty {
                Section("Output") {
                    Text("File: \(apnsFilePath)")
                        .font(.system(size: 12))
                        .textSelection(.enabled)
                    Button("Copy File Path") {
                        UIPasteboard.general.string = apnsFilePath
                    }

                    if !apnsCommand.isEmpty {
                        Text("Command: \(apnsCommand)")
                            .font(.system(size: 12))
                            .textSelection(.enabled)
                        Button("Copy simctl Command") {
                            UIPasteboard.general.string = apnsCommand
                        }
                    }
                }
            }

            if !apnsError.isEmpty {
                Section {
                    Text(apnsError)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.warning)
                }
            }
        }
        .navigationTitle("APNs Simulator")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func generateApnsPayload(
        title: String,
        body: String,
        link: String? = nil,
        type: String? = nil,
        filePrefix: String
    ) {
        apnsError = ""
        let bundleId = Bundle.main.bundleIdentifier ?? "com.example.app"
        do {
            let url = try ApnsPayloadBuilder.writePayload(
                title: title,
                body: body,
                bundleId: bundleId,
                link: link,
                type: type,
                filePrefix: filePrefix
            )
            apnsFilePath = url.path
            apnsCommand = "xcrun simctl push booted \(bundleId) \(url.path)"
        } catch {
            apnsError = "Failed to create APNs file."
        }
    }

    private func budgetTemplate(isOverOnly: Bool) -> (title: String, body: String, filePrefix: String) {
        let snapshots = BudgetCategory.allCases.map { category -> BudgetSnapshot in
            let limit = budgetLimit(for: category)
            let spent = spentAmount(for: category)
            let progress = limit > 0 ? spent / limit : 0
            return BudgetSnapshot(category: category, limit: limit, spent: spent, progress: progress)
        }

        let ordered = snapshots.sorted { a, b in
            if a.isOver != b.isOver { return a.isOver && !b.isOver }
            return a.progress > b.progress
        }

        if let pick = ordered.first(where: { !isOverOnly || $0.isOver }) {
            let title = pick.isOver ? "Budget exceeded" : "Budget nearly used"
            let percent = Int((pick.progress * 100).rounded())
            let body = "You have used \(percent)% of your \(pick.category.rawValue) budget (\(formatAmount(pick.spent)) / \(formatAmount(pick.limit)))."
            let filePrefix = pick.isOver ? "budget_exceeded" : "budget"
            return (title, body, filePrefix)
        }

        return (
            "Budget update",
            "No recent budget activity found.",
            isOverOnly ? "budget_exceeded" : "budget"
        )
    }

    private func shiftTemplate() -> (title: String, body: String, filePrefix: String) {
        let upcoming = plannerVM.workShifts
            .filter { $0.status == .upcoming }
            .sorted { (parseShiftDate($0.date) ?? Date.distantFuture) < (parseShiftDate($1.date) ?? Date.distantFuture) }
            .first

        if let shift = upcoming {
            let body = "\(shift.role) on \(shift.date) (\(shift.start) - \(shift.end))."
            return ("Upcoming shift", body, "shift")
        }

        return ("Upcoming shift", "No upcoming shifts found.", "shift")
    }

    private enum SplitTemplateKind { case request, accepted, paid }

    private func splitTemplate(kind: SplitTemplateKind) -> (title: String, body: String, filePrefix: String) {
        let bill = splitBillsVM.splitBills.first
        let billTitle = bill?.title ?? "Split bill"
        let amountText = bill != nil ? formatAmount(bill?.totalAmount ?? 0) : "Rs. 0"

        switch kind {
        case .request:
            let body = "You were invited to split \(billTitle) for \(amountText)."
            return ("Split bill request", body, "split")
        case .accepted:
            let participant = bill?.participants.first { $0.status == .accepted && !$0.isCreator }
            let name = participant?.name ?? "A roommate"
            let body = "\(name) accepted the \(billTitle) split."
            return ("Split accepted", body, "split_accepted")
        case .paid:
            let participant = bill?.participants.first { $0.status == .paid && !$0.isCreator }
            let name = participant?.name ?? "A roommate"
            let body = "\(name) marked \(billTitle) as paid."
            return ("Split paid", body, "split_paid")
        }
    }

    private func savingsTemplate(isReached: Bool) -> (title: String, body: String, filePrefix: String) {
        let goals = savingsVM.goals
        let pick = goals.sorted { $0.progress > $1.progress }.first

        if let goal = pick {
            if isReached, goal.isComplete {
                let body = "You reached your \(goal.name) goal (\(formatAmount(goal.currentAmount)))."
                return ("Goal reached", body, "savings_reached")
            }

            let percent = Int((goal.progress * 100).rounded())
            let body = "You saved \(formatAmount(goal.currentAmount)) toward \(goal.name) (\(percent)%)."
            return ("Goal progress", body, "savings")
        }

        return (
            isReached ? "Goal reached" : "Goal progress",
            "No savings goals found.",
            isReached ? "savings_reached" : "savings"
        )
    }

    private func transactionTemplate(type: TransactionType, limitTo: BudgetCategory?) -> (title: String, body: String, filePrefix: String) {
        let filtered = transactionsVM.transactions
            .filter { $0.type == type }
            .filter { limitTo == nil || $0.budgetCategory == limitTo }
            .sorted { $0.date > $1.date }

        guard let tx = filtered.first else {
            let title = type == .income ? "Income update" : "Expense update"
            let body = "No recent \(type == .income ? "income" : "expense") found."
            let prefix = limitTo == .needs ? "needs_update" : (type == .income ? "income" : "expense")
            return (title, body, prefix)
        }

        let amountText = formatAmount(tx.amount)
        let budgetName = tx.budgetCategory.rawValue
        let name = tx.name.isEmpty ? "Transaction" : tx.name
        let title: String
        let body: String
        let prefix: String

        if type == .income {
            title = "Income received"
            body = "\(name): \(amountText) added to \(budgetName)."
            prefix = "income"
        } else if limitTo == .needs {
            title = "Needs updated"
            body = "\(name): \(amountText) spent in Needs."
            prefix = "needs_update"
        } else {
            title = "Expense added"
            body = "\(name): \(amountText) spent in \(budgetName)."
            prefix = "expense"
        }

        return (title, body, prefix)
    }

    private struct BudgetSnapshot {
        let category: BudgetCategory
        let limit: Double
        let spent: Double
        let progress: Double

        var isOver: Bool { spent > limit && limit > 0 }
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

    private func spentAmount(for category: BudgetCategory) -> Double {
        transactionsVM.transactions
            .filter { $0.type == .expense && $0.budgetCategory == category }
            .reduce(0) { $0 + $1.amount }
    }

    private func parseShiftDate(_ dateString: String) -> Date? {
        let fmt1 = DateFormatter()
        fmt1.dateFormat = "MMM d"
        let fmt2 = DateFormatter()
        fmt2.dateFormat = "MMM yyyy"
        return fmt1.date(from: dateString) ?? fmt2.date(from: dateString)
    }

    private func formatAmount(_ value: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 0
        let num = fmt.string(from: NSNumber(value: value)) ?? "0"
        return "Rs. \(num)"
    }
}

#Preview {
    let appState = AppState()
    let txVM = TransactionsViewModel()
    txVM.transactions = MockData.transactions
    let savingsVM = SavingsGoalsViewModel()
    savingsVM.goals = MockData.savingsGoals
    let plannerVM = PlannerViewModel(transactionsVM: txVM)
    plannerVM.workShifts = MockData.shifts
    let splitVM = SplitBillsViewModel(userIdProvider: { "demo" }, currentUserProvider: { nil }, transactionsVM: txVM)
    splitVM.splitBills = [
        SplitBill(
            title: "Dinner",
            totalAmount: 3600,
            createdBy: "demo",
            splitMethod: .equal,
            participants: [
                SplitParticipant(userId: "demo", name: "You", email: "you@example.com", shareAmount: 1800, status: .accepted, isCreator: true),
                SplitParticipant(userId: "u2", name: "Sam", email: "sam@example.com", shareAmount: 1800, status: .paid, isCreator: false)
            ]
        )
    ]
    return NavigationStack {
        ApnsSimulatorView()
            .environmentObject(appState)
            .environmentObject(txVM)
            .environmentObject(savingsVM)
            .environmentObject(plannerVM)
            .environmentObject(splitVM)
    }
}
