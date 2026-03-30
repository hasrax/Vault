//
//  AICoachViews.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI
import Combine

// MARK: - AI Coach View
struct AICoachView: View {
    @State private var messages      = MockData.coachMessages
    @State private var inputText     = ""
    @State private var isThinking    = false
    @State private var showAffordSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                riskDashboard
                Divider()
                chatArea
                inputBar
            }
            .background(Color(UIColor.systemGroupedBackground))
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
        messages.append(CoachMessage(text: q, isFromUser: true))
        inputText   = ""
        isThinking  = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isThinking = false
            messages.append(generateResponse(for: q))
        }
    }

    private func generateResponse(for query: String) -> CoachMessage {
        let q = query.lowercased()
        if q.contains("afford") || q.contains("buy") {
            return CoachMessage(
                text: "Your Wants budget is 39% used with Rs.6,860 remaining. Under Rs.1,000 is safe — over Rs.3,000 I'd wait until next week.",
                isFromUser: false, riskLevel: .caution
            )
        } else if q.contains("save") || q.contains("saving") {
            return CoachMessage(
                text: "You've saved Rs.5,000 this month — 44% of your savings target. Put aside Rs.1,500 before the weekend to stay on track!",
                isFromUser: false, riskLevel: .safe
            )
        } else {
            return CoachMessage(
                text: "Your Needs category is Rs.3,000 over budget, mainly from rent and groceries. Try reducing dining out this week to compensate.",
                isFromUser: false, riskLevel: .danger
            )
        }
    }
}

// MARK: - Can I Afford Sheet
struct CanIAffordSheet: View {
    @Environment(\.dismiss) var dismiss
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
        guard let limit = MockData.budgetLimits.first(where: { $0.category == category }) else { return }
        if value <= limit.remaining * 0.5      { result = .yes }
        else if value <= limit.remaining       { result = .maybe }
        else                                   { result = .no }
    }
}

// MARK: - Receipt Scanner
struct ReceiptScannerView: View {
    @State private var isScanning      = false
    @State private var scannedAmount: Double? = nil
    @State private var transactions    = MockData.transactions
    @State private var showAdd         = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                cameraFrame
                howItWorksCard
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Receipt Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) {
            AddTransactionView(transactions: $transactions,
                               prefillAmount: scannedAmount)
        }
    }

    // MARK: - Camera Frame
    private var cameraFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#1A1A1A"))
                .frame(height: 300)

            if isScanning {
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
            Label("Point camera at any receipt or bill",               systemImage: "1.circle.fill").font(.subheadline)
            Label("VisionKit reads the total amount automatically",    systemImage: "2.circle.fill").font(.subheadline)
            Label("Transaction is logged straight to your budget",     systemImage: "3.circle.fill").font(.subheadline)
        }
        .padding(16)
        .lightCard()
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if scannedAmount != nil {
                Button { showAdd = true } label: {
                    Label("Log this transaction", systemImage: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(LinearGradient.greenGrad)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            Button { mockScan() } label: {
                Label(scannedAmount == nil ? "Scan Receipt" : "Scan Another",
                      systemImage: "camera.fill")
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

    private func mockScan() {
        isScanning    = true
        scannedAmount = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isScanning    = false
            scannedAmount = (Double.random(in: 500...8000) * 10).rounded() / 10
        }
    }
}

// ProfileView is in Views/Profile/ProfileView.swift

#Preview("AI Coach") { AICoachView() }
#Preview("Scanner")  { NavigationStack { ReceiptScannerView() } }
