//
//  OnboardingViews.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Shared Onboarding Branding
private struct AppLogoMark: View {
    var size: CGFloat = 80

    var body: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: Color.uniBlue.opacity(0.25), radius: 12, y: 4)
            .accessibilityLabel("Vault logo")
    }
}

private struct OnboardingBackground: View {
    var body: some View {
        AuthBackground()
    }
}

// MARK: - Splash Screen
struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @State private var scale: CGFloat = 0.6
    @State private var opacity = 0.0
    @State private var barOffset: CGFloat = -40

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                AppLogoMark(size: 100)
                .scaleEffect(scale)
                .opacity(opacity)

                Text("Vault")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .padding(.top, 24)
                    .opacity(opacity)

                Text("Smart budgeting for campus life")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 8)
                    .opacity(opacity)

                Spacer()

                // Loading bar
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.12)).frame(width: 40, height: 4)
                    Capsule()
                        .fill(LinearGradient(colors:[Color.uniBlue, Color(hex:"#3B82F6")],
                                             startPoint:.leading, endPoint:.trailing))
                        .frame(width: 20, height: 4)
                        .offset(x: barOffset)
                }
                .padding(.bottom, 60)
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(0.5)) {
                barOffset = 20
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation { appState.hasCompletedOnboarding = true }
            }
        }
    }
}

// MARK: - Welcome Screen
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSignUp = false
    @State private var showLogin = false

    private let features = [
        ("📊", "Smart Budget Tracking",  "50/30/20 auto-allocation"),
        ("🔔", "Spending Alerts",        "Never overspend again"),
        ("🎯", "Savings Goals",          "Plan for what matters"),
    ]

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                AppLogoMark(size: 80)

                Text("Welcome to Vault")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)

                Text("The smart way to manage your student budget")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 10)

                // Feature cards
                VStack(spacing: 12) {
                    ForEach(features, id: \.0) { emoji, title, desc in
                        HStack(spacing: 14) {
                            Text(emoji).font(.system(size: 22))
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.primary)
                                Text(desc).font(.caption1).foregroundStyle(Color.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.08), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    Button {
                        showSignUp = true
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(LinearGradient.ctaGrad)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        showLogin = true
                    } label: {
                        Text("I already have an account")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .fullScreenCover(isPresented: $showSignUp)  {
            SignUpView(onSignInTap: {
                showSignUp = false
                DispatchQueue.main.async { showLogin = true }
            })
        }
        .fullScreenCover(isPresented: $showLogin)   { LoginView() }
    }
}

// MARK: - Setup Budget Screen (Set Your Budget / Edit Your Budget)
struct SetupBudgetView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    var isEditing: Bool = false

    @State private var budget: Double      = 45000
    @State private var budgetInput         = ""
    @State private var needsPct: Double    = 50
    @State private var wantsPct: Double    = 25
    @State private var savingsPct: Double  = 25

    private let budgetPresets: [Double]    = [25000, 35000, 45000, 55000, 65000]
    private let allocationPresets          = [
        ("50/25/25", 50.0, 25.0, 25.0),
        ("60/20/20", 60.0, 20.0, 20.0),
        ("40/40/20", 40.0, 40.0, 20.0),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Title block ──────────────────────────────────────
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isEditing ? "Edit Your Budget" : "Set Your Budget")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text("Choose your monthly budget and allocation strategy")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)

                    // ── Monthly Budget card ───────────────────────────────
                    VStack(spacing: 6) {
                        Text("Monthly Budget")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.secondary)
                        Text(budget.currencyRS)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)

                    // ── Budget preset chips (horizontal scroll) ───────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(budgetPresets, id: \.self) { preset in
                                Button {
                                    budget     = preset
                                    budgetInput = String(Int(preset))
                                } label: {
                                    Text(preset.shortCurrency)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(budget == preset ? Color.uniBlue : Color.primary)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 10)
                                        .background(Color(UIColor.systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    budget == preset ? Color.uniBlue : Color(UIColor.separator),
                                                    lineWidth: budget == preset ? 1.5 : 1
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    // ── Allocation Strategy ───────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Allocation Strategy")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.primary)

                        // Segmented selector
                        HStack(spacing: 0) {
                            ForEach(allocationPresets, id: \.0) { label, n, w, s in
                                let isActive = needsPct == n && wantsPct == w
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        needsPct = n; wantsPct = w; savingsPct = s
                                    }
                                } label: {
                                    Text(label)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(isActive ? .white : Color.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(isActive ? Color.uniBlue : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(4)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Breakdown rows
                        VStack(spacing: 0) {
                            ForEach([
                                (BudgetCategory.needs,   needsPct),
                                (BudgetCategory.wants,   wantsPct),
                                (BudgetCategory.savings, savingsPct),
                            ], id: \.0) { cat, pct in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(cat.color)
                                        .frame(width: 10, height: 10)
                                    Text(cat.rawValue)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Text("\(Int(pct))%")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color.primary)
                                    Text((budget * pct / 100).currencyRS)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.secondary)
                                        .frame(width: 95, alignment: .trailing)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                if cat != .savings {
                                    Divider().padding(.leading, 38)
                                }
                            }
                        }
                        .background(Color(UIColor.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                    }

                    // ── Confirm button (onboarding only) ─────────────────
                    if !isEditing {
                        Button {
                            appState.saveBudget(
                                monthly: budget,
                                needs:   needsPct,
                                wants:   wantsPct,
                                savings: savingsPct
                            )
                        } label: {
                            Text("Confirm")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.uniBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                if isEditing {
                    // Edit mode: Cancel (left) + Save (right)
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.uniBlue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            appState.saveBudget(
                                monthly: budget,
                                needs:   needsPct,
                                wants:   wantsPct,
                                savings: savingsPct
                            )
                            dismiss()
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.uniBlue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(Capsule())
                    }
                } else {
                    // Onboarding mode: back chevron (left)
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.primary)
                                .frame(width: 36, height: 36)
                                .background(Color(UIColor.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
                        }
                    }
                }
            }
        }
        .onAppear {
            budget      = appState.monthlyBudget
            needsPct    = appState.needsPercent
            wantsPct    = appState.wantsPercent
            savingsPct  = appState.savingsPercent
            budgetInput = String(Int(appState.monthlyBudget))
        }
        .onChange(of: budgetInput) { _, newValue in
            let filtered = newValue.filter { $0.isNumber }
            if filtered != newValue { budgetInput = filtered }
            if let value = Double(filtered), value > 0 { budget = value }
        }
    }
}

#Preview("Splash")  { SplashView().environmentObject(AppState()) }
#Preview("Welcome") { WelcomeView().environmentObject(AppState()) }
#Preview("Setup")   { SetupBudgetView().environmentObject(AppState()) }
#Preview("Edit Budget") { SetupBudgetView(isEditing: true).environmentObject(AppState()) }
