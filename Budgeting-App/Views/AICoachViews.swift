//
//  AICoachViews.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI
import UIKit
import FirebaseFirestore

// MARK: - AI Coach View
struct AICoachView: View {
    @EnvironmentObject var appState: AppState
    @State private var messages = MockData.coachMessages
    @State private var inputText = ""
    @State private var isThinking = false
    @State private var showAffordSheet = false
    @State private var listener: ListenerRegistration? = nil
    @State private var hasSeededMessages = false
    @State private var activeUserId: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topHeader
                riskDashboard
                Divider()
                chatArea
                inputBar
            }
            .background(Color.clear)
            // Hide the NavigationStack bar so it doesn't add invisible
            // height that pushes the custom header content out of place
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAffordSheet) { CanIAffordSheet() }
            .onAppear { syncUserListener() }
            .onDisappear { stopMessageListener() }
        }
        .appStatusBarStyle(.lightContent)
        .onChange(of: appState.currentUser?.id) { _, _ in
            syncUserListener()
        }
    }

    // MARK: - Header
    private var topHeader: some View {
        let topInset: CGFloat = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 47

        return ZStack(alignment: .bottom) {
            HomeHeaderBackground()
                .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))

            HStack(alignment: .center) {
                Text("AI Coach")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                Spacer()
                Button {
                    showAffordSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 42, height: 42)
                        Image(systemName: "questionmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.uniBlue)
                    }
                }
                .accessibilityLabel("Can I afford?")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(height: topInset + 140)
        .ignoresSafeArea(edges: .top)
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
                )
                .frame(width: 180)

                InsightCard(
                    emoji: "✅", title: "Wants on track",
                    message: "61% remaining — Rs.6,860 left",
                    bgColor: Color.income.opacity(0.08),
                    borderColor: Color.income.opacity(0.2)
                )
                .frame(width: 180)

                InsightCard(
                    emoji: "📈", title: "Save more this week",
                    message: "Behind by Rs.1,200",
                    bgColor: Color.warning.opacity(0.08),
                    borderColor: Color.warning.opacity(0.2)
                )
                .frame(width: 180)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemBackground))
        .padding(.top, -40)
        .padding(.bottom, 10)
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
                        HStack {
                            ThinkingDots()
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .id("thinking")
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isThinking) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func chatBubble(_ message: CoachMessage) -> some View {
        HStack(alignment: .bottom) {
            if message.isFromUser { Spacer() }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 6) {
                Text(message.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(message.isFromUser ? .white : Color.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(message.isFromUser ? Color.uniBlue : Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                if !message.isFromUser, let risk = message.riskLevel {
                    HStack(spacing: 6) {
                        Image(systemName: risk.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(risk.label)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(risk.color)
                }
            }

            if !message.isFromUser { Spacer() }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about your budget...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .lineLimit(1...4)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.uniBlue)
                    .clipShape(Circle())
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
        .overlay(Divider(), alignment: .top)
    }

    // MARK: - Messaging Logic
    private func sendMessage() {
        guard appState.currentUser?.id != nil else { return }
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = CoachMessage(text: trimmed, isFromUser: true)
        inputText = ""
        messages.append(userMessage)
        CoachMessageService.addMessage(userMessage)

        isThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            let reply = generateReply(for: trimmed)
            let replyMessage = CoachMessage(text: reply.text, isFromUser: false, riskLevel: reply.riskLevel)
            messages.append(replyMessage)
            CoachMessageService.addMessage(replyMessage)
            isThinking = false
        }
    }

    private func generateReply(for input: String) -> (text: String, riskLevel: CoachMessage.RiskLevel?) {
        let lower = input.lowercased()
        if lower.contains("afford") || lower.contains("can i") {
            return ("Try the Can I afford checker on the top right — it uses your budget limits.", nil)
        }

        if lower.contains("save") || lower.contains("savings") {
            let target = appState.monthlyBudget * (appState.savingsPercent / 100)
            return ("Your savings target this month is Rs.\(Int(target)). Want me to suggest a weekly plan?", .safe)
        }

        if lower.contains("spend") || lower.contains("spent") || lower.contains("budget") || lower.contains("limit") {
            let spent = expensesThisMonth()
            let limit = appState.monthlyBudget
            let percent = limit > 0 ? spent / limit : 0
            let risk = riskLevel(for: percent)
            let message = "You’ve spent Rs.\(Int(spent)) of your Rs.\(Int(limit)) budget this month (\(Int(percent * 100))%)."
            return (message, risk)
        }

        return ("I’m tracking your budgets and recent activity. Ask about spending, savings, or limits.", nil)
    }

    private func riskLevel(for percent: Double) -> CoachMessage.RiskLevel {
        if percent >= 1.0 { return .danger }
        if percent >= 0.75 { return .caution }
        return .safe
    }

    private func expensesThisMonth() -> Double {
        let now = Date()
        let cal = Calendar.current
        return appState.transactions
            .filter { $0.type == .expense && cal.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    private func startMessageListener() {
        if listener != nil { return }
        listener = CoachMessageService.listenMessages { result in
            switch result {
            case .success(let items):
                if items.isEmpty && !hasSeededMessages {
                    hasSeededMessages = true
                    MockData.coachMessages.forEach { CoachMessageService.addMessage($0) }
                } else {
                    messages = items
                }
            case .failure:
                break
            }
        }
    }

    private func stopMessageListener() {
        listener?.remove()
        listener = nil
    }

    private func syncUserListener() {
        let currentId = appState.currentUser?.id
        guard currentId != activeUserId else { return }

        activeUserId = currentId
        stopMessageListener()
        hasSeededMessages = false
        messages = []

        guard currentId != nil else { return }
        startMessageListener()
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let last = messages.last?.id {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(last, anchor: .bottom)
            }
        } else if isThinking {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("thinking", anchor: .bottom)
            }
        }
    }
}

#Preview("AI Coach") { AICoachView().environmentObject(AppState()) }
