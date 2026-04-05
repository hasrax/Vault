//
//  AICoachViews.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI
import Combine
import PhotosUI
import Vision
import VisionKit
import CoreML
import FirebaseFirestore

// MARK: - AI Coach View
struct AICoachView: View {
    @EnvironmentObject var appState: AppState
    @State private var messages      = MockData.coachMessages
    @State private var inputText     = ""
    @State private var isThinking    = false
    @State private var showAffordSheet = false
    @State private var listener: ListenerRegistration? = nil
    @State private var hasSeededMessages = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                riskDashboard
                Divider()
                chatArea
                inputBar
            }
            .background(Color.clear)
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAffordSheet = true
                    } label: {
                        Label("Can I afford?", systemImage: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showAffordSheet) { CanIAffordSheet() }
            .onAppear { startMessageListener() }
            .onDisappear { stopMessageListener() }
        }
    }

    // MARK: - Risk Dashboard
    private var riskDashboard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                InsightCard(
                    emoji: "⚠️", title: "Needs over budget",
                    message: "Rs.3,000 over limit this month",
                    bgColor: Color.expense.opacity(0.08),
                    borderColor: Color.expense.opacity(0.2)
                ).frame(width: 180)

                InsightCard(
                    emoji: "✅", title: "Wants on track",
                    message: "61% remaining — Rs.6,860 left",
                    bgColor: Color.income.opacity(0.08),
                    borderColor: Color.income.opacity(0.2)
                ).frame(width: 180)

                InsightCard(
                    emoji: "📈", title: "Save more this week",
                    message: "Behind by Rs.1,200",
                    bgColor: Color.warning.opacity(0.08),
                    borderColor: Color.warning.opacity(0.2)
                ).frame(width: 180)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Chat
    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { msg in
                        chatBubble(msg).id(msg.id)
                    }
                    if isThinking {
                        HStack(alignment: .bottom, spacing: 8) {
                            coachAvatar
                            ThinkingDots()
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .background(Color(UIColor.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask your coach anything...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button { send() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(inputText.isEmpty ? Color.secondary : Color.uniBlue)
            }
            .disabled(inputText.isEmpty || isThinking)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Coach Avatar
    private var coachAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.uniBlue.opacity(0.12))
                .frame(width: 32, height: 32)
            Image(systemName: "brain.head.profile")
                .font(.system(size: 14))
                .foregroundStyle(Color.uniBlue)
        }
    }

    // MARK: - Chat Bubble
    @ViewBuilder
    private func chatBubble(_ msg: CoachMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !msg.isFromUser { coachAvatar }

            VStack(alignment: msg.isFromUser ? .trailing : .leading, spacing: 4) {
                if let risk = msg.riskLevel, !msg.isFromUser {
                    HStack(spacing: 4) {
                        Image(systemName: risk.icon).font(.system(size: 11))
                        Text(risk.label).font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(risk.color)
                }

                Text(msg.text)
                    .font(.system(size: 14))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(msg.isFromUser ? Color.uniBlue : Color(UIColor.systemBackground))
                    .foregroundStyle(msg.isFromUser ? Color.white : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .frame(
                maxWidth: UIScreen.main.bounds.width * 0.72,
                alignment: msg.isFromUser ? .trailing : .leading
            )

            if msg.isFromUser { Spacer() }
        }
        .frame(maxWidth: .infinity, alignment: msg.isFromUser ? .trailing : .leading)
    }

    // MARK: - Send
    private func send() {
        let q = inputText
        let userMessage = CoachMessage(text: q, isFromUser: true)
        messages.append(userMessage)
        CoachMessageService.addMessage(userMessage)
        inputText   = ""
        isThinking  = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isThinking = false
            let reply = generateResponse(for: q)
            messages.append(reply)
            CoachMessageService.addMessage(reply)
        }
    }

    private func startMessageListener() {
        guard listener == nil else { return }
        listener = CoachMessageService.listenMessages(limit: 200) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    if items.isEmpty {
                        seedStarterMessagesIfNeeded()
                    } else {
                        messages = items
                    }
                case .failure:
                    break
                }
            }
        }
    }

    private func stopMessageListener() {
        listener?.remove()
        listener = nil
    }

    private func seedStarterMessagesIfNeeded() {
        guard !hasSeededMessages else { return }
        hasSeededMessages = true
        messages = MockData.coachMessages
        MockData.coachMessages.forEach { CoachMessageService.addMessage($0) }
    }

    private func generateResponse(for query: String) -> CoachMessage {
        let q = query.lowercased()
        if q.contains("afford") || q.contains("buy") {
            return affordResponse()
        }
        if q.contains("save") || q.contains("saving") {
            return savingsResponse()
        }

        let features = buildCoachFeatures()
        if let label = predictLabel(features: features) {
            return coachResponse(for: label, features: features)
        }

        return CoachMessage(
            text: "I'm having trouble loading the coach model right now. Try again in a moment.",
            isFromUser: false,
            riskLevel: .caution
        )
    }

    private struct CoachFeatures {
        let needsUtil: Double
        let wantsUtil: Double
        let savingsUtil: Double
        let savingsProgress: Double
        let netBalanceRatio: Double
        let incomeExpenseRatio: Double
        let upcomingBillsCount: Double
        let upcomingShiftsCount: Double
    }

    private func buildCoachFeatures() -> CoachFeatures {
        let monthTx = currentMonthTransactions()
        let expenses = monthTx.filter { $0.type == .expense }
        let income = monthTx.filter { $0.type == .income }

        let needsSpent = expenses.filter { $0.budgetCategory == .needs }.reduce(0) { $0 + $1.amount }
        let wantsSpent = expenses.filter { $0.budgetCategory == .wants }.reduce(0) { $0 + $1.amount }
        let savingsSpent = expenses.filter { $0.budgetCategory == .savings }.reduce(0) { $0 + $1.amount }

        let needsLimit = budgetLimit(for: .needs)
        let wantsLimit = budgetLimit(for: .wants)
        let savingsLimit = budgetLimit(for: .savings)

        let totalIncome = income.reduce(0) { $0 + $1.amount }
        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        let safeBudget = max(appState.monthlyBudget, 1)
        let balance = appState.monthlyBudget + totalIncome - totalExpense

        let savingsProgress = overallSavingsProgress()
        let upcomingBills = upcomingBillsCount()
        let upcomingShifts = upcomingShiftsCount()

        return CoachFeatures(
            needsUtil: needsLimit > 0 ? needsSpent / needsLimit : 0,
            wantsUtil: wantsLimit > 0 ? wantsSpent / wantsLimit : 0,
            savingsUtil: savingsLimit > 0 ? savingsSpent / savingsLimit : 0,
            savingsProgress: savingsProgress,
            netBalanceRatio: balance / safeBudget,
            incomeExpenseRatio: totalIncome / max(totalExpense, 1),
            upcomingBillsCount: Double(upcomingBills),
            upcomingShiftsCount: Double(upcomingShifts)
        )
    }

    private func predictLabel(features: CoachFeatures) -> String? {
        do {
            let model = try CoachModel(configuration: MLModelConfiguration())
            let output = try model.prediction(
                needs_util: features.needsUtil,
                wants_util: features.wantsUtil,
                savings_util: features.savingsUtil,
                savings_progress: features.savingsProgress,
                net_balance_ratio: features.netBalanceRatio,
                income_expense_ratio: features.incomeExpenseRatio,
                upcoming_bills_count: features.upcomingBillsCount,
                upcoming_shifts_count: features.upcomingShiftsCount
            )
            return output.label
        } catch {
            return nil
        }
    }

    private func coachResponse(for label: String, features: CoachFeatures) -> CoachMessage {
        switch label {
        case "needs_over":
            return CoachMessage(
                text: "Needs spending is high this month. You are at \(formatPercent(features.needsUtil)) of your Needs budget.",
                isFromUser: false,
                riskLevel: .danger
            )
        case "reduce_wants":
            return CoachMessage(
                text: "Wants are climbing fast. You have used \(formatPercent(features.wantsUtil)) of your Wants budget.",
                isFromUser: false,
                riskLevel: .caution
            )
        case "savings_low":
            return CoachMessage(
                text: "Savings progress is low at \(formatPercent(features.savingsProgress)). Try setting aside a small amount this week.",
                isFromUser: false,
                riskLevel: .caution
            )
        case "upcoming_bills":
            return CoachMessage(
                text: "You have \(Int(features.upcomingBillsCount)) bills coming up soon. Keep extra buffer in your balance.",
                isFromUser: false,
                riskLevel: .caution
            )
        case "shift_income_tip":
            return CoachMessage(
                text: "Upcoming shifts can help your cash flow. You have \(Int(features.upcomingShiftsCount)) scheduled.",
                isFromUser: false,
                riskLevel: .safe
            )
        default:
            return CoachMessage(
                text: "Your budgets look balanced right now. Keep up the momentum!",
                isFromUser: false,
                riskLevel: .safe
            )
        }
    }

    private func affordResponse() -> CoachMessage {
        let wantsLimit = budgetLimit(for: .wants)
        let wantsSpent = currentMonthTransactions()
            .filter { $0.type == .expense && $0.budgetCategory == .wants }
            .reduce(0) { $0 + $1.amount }
        let remaining = max(wantsLimit - wantsSpent, 0)

        return CoachMessage(
            text: "You have about \(formatAmount(remaining)) left in Wants this month. Under \(formatAmount(remaining * 0.3)) is safest.",
            isFromUser: false,
            riskLevel: remaining <= 0 ? .danger : remaining < wantsLimit * 0.2 ? .caution : .safe
        )
    }

    private func savingsResponse() -> CoachMessage {
        let progress = overallSavingsProgress()
        return CoachMessage(
            text: "Savings progress is \(formatPercent(progress)). Aim to move a little more into Savings this week.",
            isFromUser: false,
            riskLevel: progress < 0.3 ? .caution : .safe
        )
    }

    private func currentMonthTransactions() -> [Transaction] {
        let all = appState.transactions
        let calendar = Calendar.current
        let now = Date()
        let monthTx = all.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        return monthTx.isEmpty ? all : monthTx
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

    private func overallSavingsProgress() -> Double {
        let goals = appState.savingsGoals
        let totalTarget = goals.reduce(0) { $0 + $1.targetAmount }
        let totalCurrent = goals.reduce(0) { $0 + $1.currentAmount }
        guard totalTarget > 0 else { return 0 }
        return min(totalCurrent / totalTarget, 1)
    }

    private func upcomingBillsCount() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let end = calendar.date(byAdding: .day, value: 30, to: now) ?? now
        return appState.importantDates
            .filter { $0.type == .bill && $0.date >= now && $0.date <= end }
            .count
    }

    private func upcomingShiftsCount() -> Int {
        appState.workShifts.filter { $0.status == .upcoming }.count
    }

    private func formatAmount(_ value: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 0
        let num = fmt.string(from: NSNumber(value: value)) ?? "0"
        return "Rs. \(num)"
    }

    private func formatPercent(_ value: Double) -> String {
        let pct = Int((value * 100).rounded())
        return "\(pct)%"
    }
}

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
                                .font(.system(size: 44))
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

// MARK: - Receipt Scanner
struct ReceiptScannerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isScanning      = false
    @State private var scannedAmount: Double? = nil
    @State private var amountCandidates: [Double] = []
    @State private var selectedCandidate: Double? = nil
    @State private var showAdd         = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var receiptImageUrl: String?
    @State private var receiptImageBase64: String?
    @State private var isUploading = false
    @State private var uploadError = ""
    @State private var saveReceiptImage = true
    @State private var useLiveScanner = false
    @State private var liveScanText = ""
    @State private var showFullScreenScanner = false
    @State private var showImagePreview = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    Text("Scan mode")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Picker("Scan mode", selection: $useLiveScanner) {
                        Text("Gallery").tag(false)
                        Text("Live Camera").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
                .padding(.horizontal, 4)

                cameraFrame
                howItWorksCard
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color.clear)
        .navigationTitle("Receipt Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionView(
                prefillAmount: scannedAmount,
                prefillReceiptUrl: receiptImageUrl,
                prefillReceiptBase64: receiptImageBase64
            )
        }
        .fullScreenCover(isPresented: $showImagePreview) {
            ReceiptImagePreviewView(
                image: receiptImage,
                onCancel: {
                    showImagePreview = false
                },
                onScan: {
                    if let image = receiptImage {
                        recognizeText(in: image)
                    }
                    showImagePreview = false
                }
            )
        }
        .fullScreenCover(isPresented: $showFullScreenScanner) {
            LiveScannerFullScreenView(
                text: $liveScanText,
                onCancel: { showFullScreenScanner = false },
                onUseText: {
                    scanLiveText()
                    showFullScreenScanner = false
                }
            )
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            loadPhoto(item: newItem)
        }
    }

    // MARK: - Camera Frame
    private var cameraFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#1A1A1A"))
                .frame(height: 300)

            if let img = receiptImage {
                Button {
                    showImagePreview = true
                } label: {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            if useLiveScanner {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerView(text: $liveScanText)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "camera.badge.exclamationmark")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.white.opacity(0.7))
                        Text("Live scan not available")
                            .foregroundStyle(Color.white.opacity(0.7))
                            .font(.subheadline)
                    }
                }
            } else if isScanning {
                VStack(spacing: 16) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Scanning receipt...")
                        .foregroundStyle(Color.white.opacity(0.7))
                        .font(.subheadline)
                }
            } else if let amount = scannedAmount {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.income)
                    Text("Receipt scanned!")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(amount.currencyRS)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.income)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.white.opacity(0.4))
                    Text("Point camera at receipt")
                        .foregroundStyle(Color.white.opacity(0.6))
                        .font(.subheadline)
                    scanCorners
                }
            }
        }
    }

    private var scanCorners: some View {
        ZStack {
            let s: CGFloat = 20
            let t: CGFloat = 3
            let w: CGFloat = 180
            let h: CGFloat = 100
            Path { p in
                p.move(to: CGPoint(x: 0,   y: s)); p.addLine(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: s, y: 0))
            }.stroke(Color.white, lineWidth: t)
            Path { p in
                p.move(to: CGPoint(x: w,   y: s)); p.addLine(to: CGPoint(x: w, y: 0))
                p.addLine(to: CGPoint(x: w-s, y: 0))
            }.stroke(Color.white, lineWidth: t)
            Path { p in
                p.move(to: CGPoint(x: 0,   y: h-s)); p.addLine(to: CGPoint(x: 0, y: h))
                p.addLine(to: CGPoint(x: s, y: h))
            }.stroke(Color.white, lineWidth: t)
            Path { p in
                p.move(to: CGPoint(x: w,   y: h-s)); p.addLine(to: CGPoint(x: w, y: h))
                p.addLine(to: CGPoint(x: w-s, y: h))
            }.stroke(Color.white, lineWidth: t)
        }
        .frame(width: 180, height: 100)
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How it works").font(.system(size: 18, weight: .semibold))
            Label("Pick a receipt photo or use live scan",             systemImage: "1.circle.fill").font(.subheadline)
            Label("Vision reads the total amount automatically",       systemImage: "2.circle.fill").font(.subheadline)
            Label("Transaction is logged straight to your budget",     systemImage: "3.circle.fill").font(.subheadline)
        }
        .padding(16)
        .lightCard()
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Toggle("Save receipt image (compressed)", isOn: $saveReceiptImage)
                .font(.system(size: 13, weight: .medium))

            if isUploading {
                HStack(spacing: 10) {
                    ProgressView().tint(Color.uniBlue)
                    Text("Uploading receipt...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
            } else if !uploadError.isEmpty {
                Text(uploadError)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.expense)
            }

            if scannedAmount != nil {
                Button { prepareToAddTransaction() } label: {
                    Label("Log this transaction", systemImage: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(LinearGradient.greenGrad)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            if scannedAmount == nil, !amountCandidates.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Detected totals")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    ForEach(amountCandidates, id: \.self) { value in
                        Button {
                            selectedCandidate = value
                        } label: {
                            HStack {
                                Text(value.currencyRS)
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                                if selectedCandidate == value {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.uniBlue)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }

                    Button("Confirm Amount") {
                        if let selectedCandidate {
                            scannedAmount = selectedCandidate
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(LinearGradient.primaryGrad)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(selectedCandidate == nil)
                }
            }

            if useLiveScanner {
                Button { scanLiveText() } label: {
                    Label("Scan from Live View", systemImage: "text.viewfinder")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(isScanning
                                    ? LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient.primaryGrad)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isScanning)

                Button { showFullScreenScanner = true } label: {
                    Label("Open Full Screen Scanner", systemImage: "viewfinder")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(LinearGradient.primaryGrad)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!(DataScannerViewController.isSupported && DataScannerViewController.isAvailable))
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(scannedAmount == nil ? "Choose Receipt Photo" : "Choose Another",
                          systemImage: "photo.on.rectangle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(isScanning
                                    ? LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient.primaryGrad)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isScanning)
            }
        }
    }

    private func loadPhoto(item: PhotosPickerItem) {
        isScanning = true
        scannedAmount = nil
        amountCandidates = []
        selectedCandidate = nil
        uploadError = ""
        receiptImageUrl = nil
        receiptImageBase64 = nil

        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    guard let data, let image = UIImage(data: data) else {
                        isScanning = false
                        uploadError = "Unable to load image."
                        return
                    }
                    receiptImage = image
                    isScanning = false
                    showImagePreview = true
                case .failure:
                    isScanning = false
                    uploadError = "Failed to read image."
                }
            }
        }
    }

    private func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else {
            isScanning = false
            uploadError = "Invalid image."
            return
        }
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                self.isScanning = false
                if let _ = error {
                    self.uploadError = "Text scan failed."
                    return
                }
                let strings = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string } ?? []
                let amounts = extractAmounts(from: strings)
                self.amountCandidates = amounts
                self.selectedCandidate = amounts.first
                if amounts.isEmpty {
                    self.uploadError = "Could not find a total amount."
                }
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    private func extractAmounts(from lines: [String]) -> [Double] {
        let lower = lines.map { $0.lowercased() }
        let keywords = ["total", "amount", "subtotal", "balance", "due", "payable", "grand", "net"]
        let prioritized = lower.filter { line in
            keywords.contains { line.contains($0) }
        }

        let sourceLines = prioritized.isEmpty ? lower : prioritized
        let candidates = sourceLines.flatMap { extractNumbers(from: $0) }
        if !candidates.isEmpty {
            return normalizeCandidates(candidates)
        }

        let fallbackCandidates = lower.flatMap { extractNumbers(from: $0) }
        return normalizeCandidates(fallbackCandidates)
    }

    private func extractNumbers(from text: String) -> [Double] {
        let pattern = "([0-9]{1,3}(?:[\\.,][0-9]{3})*(?:[\\.,][0-9]{2})?|[0-9]+(?:[\\.,][0-9]{2})?)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, options: [], range: range).compactMap { match in
            guard let r = Range(match.range(at: 1), in: text) else { return nil }
            let raw = String(text[r])
            let normalized = normalizeNumberString(raw)
            return Double(normalized)
        }
    }

    private func normalizeNumberString(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains(",") && trimmed.contains(".") {
            return trimmed.replacingOccurrences(of: ",", with: "")
        }

        if trimmed.contains(",") {
            let parts = trimmed.split(separator: ",")
            if let last = parts.last, last.count == 2 {
                let intPart = parts.dropLast().joined()
                return intPart + "." + last
            }
            return trimmed.replacingOccurrences(of: ",", with: "")
        }

        return trimmed
    }

    private func normalizeCandidates(_ values: [Double]) -> [Double] {
        let unique = Array(Set(values))
        let sorted = unique.sorted(by: >)
        return Array(sorted.prefix(5))
    }

    private func prepareToAddTransaction() {
        guard saveReceiptImage, let image = receiptImage else {
            showAdd = true
            return
        }
        uploadError = ""
        if let encoded = ReceiptImageService.encodeReceiptImage(image: image, maxDimension: 640, quality: 0.55) {
            receiptImageBase64 = encoded
            showAdd = true
        } else {
            uploadError = "Unable to save receipt image."
        }
    }

    private func scanLiveText() {
        let lines = liveScanText
            .split(separator: "\n")
            .map { String($0) }
        let amounts = extractAmounts(from: lines)
        amountCandidates = amounts
        selectedCandidate = amounts.first
        if amounts.isEmpty {
            uploadError = "Could not find a total amount."
        }
    }
}

@available(iOS 16.0, *)
private struct DataScannerView: UIViewControllerRepresentable {
    @Binding var text: String

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd items: [RecognizedItem], allItems: [RecognizedItem]) {
            updateText(items: allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate items: [RecognizedItem], allItems: [RecognizedItem]) {
            updateText(items: allItems)
        }

        private func updateText(items: [RecognizedItem]) {
            let lines = items.compactMap { item -> String? in
                if case let .text(textItem) = item { return textItem.transcript }
                return nil
            }
            text.wrappedValue = lines.joined(separator: "\n")
        }
    }
}

private struct LiveScannerFullScreenView: View {
    @Binding var text: String
    var onCancel: () -> Void
    var onUseText: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                DataScannerView(text: $text)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.badge.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Text("Live scan not available")
                        .foregroundStyle(Color.white.opacity(0.8))
                        .font(.subheadline)
                    Button("Close") { onCancel() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            VStack {
                HStack {
                    Button { onCancel() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)

                Spacer()

                VStack(spacing: 10) {
                    Text("Fill the screen with the receipt")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Button { onUseText() } label: {
                        Label("Use Detected Text", systemImage: "text.viewfinder")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient.primaryGrad)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct ReceiptImagePreviewView: View {
    let image: UIImage?
    var onCancel: () -> Void
    var onScan: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                ZoomableImageView(image: image)
                    .ignoresSafeArea()
            } else {
                Text("No image")
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            VStack {
                HStack {
                    Button { onCancel() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)

                Spacer()

                VStack(spacing: 10) {
                    Text("Pinch to zoom, then scan")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Button { onScan() } label: {
                        Label("Scan This Image", systemImage: "text.viewfinder")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient.primaryGrad)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .black
        scrollView.delegate = context.coordinator

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = image
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }
    }
}

// ProfileView is in Views/Profile/ProfileView.swift

#Preview("AI Coach") { AICoachView().environmentObject(AppState()) }
#Preview("Scanner")  { NavigationStack { ReceiptScannerView() }.environmentObject(AppState()) }
