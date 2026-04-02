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
                    .foregroundStyle(Color.white)
                    .padding(.top, 24)
                    .opacity(opacity)

                Text("Smart budgeting for campus life")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .padding(.top, 8)
                    .opacity(opacity)

                Spacer()

                // Loading bar
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12)).frame(width: 40, height: 4)
                    Capsule()
                        .fill(LinearGradient(colors:[Color.uniBlue, Color(hex:"#60A5FA")],
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
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)

                Text("The smart way to manage your student budget")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 10)

                // Feature cards
                VStack(spacing: 12) {
                    ForEach(features, id: \.0) { emoji, title, desc in
                        HStack(spacing: 14) {
                            Text(emoji).font(.system(size: 22))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.white)
                                Text(desc).font(.caption1).foregroundStyle(Color.white.opacity(0.6))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.appSurface2)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appStroke, lineWidth: 1))
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
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .fullScreenCover(isPresented: $showSignUp)  { SignUpView() }
        .fullScreenCover(isPresented: $showLogin)   { LoginView() }
    }
}

// MARK: - Setup Budget Screen
struct SetupBudgetView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    var isEditing: Bool = false
    @State private var budget: Double = 45000
    @State private var budgetInput = ""
    @State private var needsPct: Double = 50
    @State private var wantsPct: Double = 25
    @State private var savingsPct: Double = 25

    private let budgetPresets: [Double] = [25000, 35000, 45000, 60000, 75000]
    private let allocationPresets = [
        ("50/25/25", 50.0, 25.0, 25.0),
        ("60/20/20", 60.0, 20.0, 20.0),
        ("40/40/20", 40.0, 40.0, 20.0),
    ]

    var body: some View {
        ZStack {
            OnboardingBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        if isEditing {
                            BackButton(isDark: true) { dismiss() }
                                .padding(.bottom, 12)
                        }
                        Text("Set Your Budget")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                        Text("Choose your monthly budget and allocation strategy")
                            .font(.subheadline).foregroundStyle(Color.white.opacity(0.6))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 32)

                    // Budget Display
                    VStack(spacing: 4) {
                        Text("Monthly Budget").font(.caption1).foregroundStyle(Color.white.opacity(0.6))
                        Text(budget.currencyRS)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                        Text("per month").font(.caption1).foregroundStyle(Color.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.appSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appStroke, lineWidth: 1))
                    .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter monthly income")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white)
                        TextField("e.g. 45000", text: $budgetInput)
                            .keyboardType(.numberPad)
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(Color.appSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appStroke, lineWidth: 1))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                    // Budget presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(budgetPresets, id: \.self) { preset in
                                Button {
                                    budget = preset
                                    budgetInput = String(Int(preset))
                                } label: {
                                    Text(preset.shortCurrency)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(budget == preset ? .white : Color.white.opacity(0.7))
                                        .padding(.horizontal, 16).padding(.vertical, 10)
                                        .background(budget == preset ? Color.ctaBlue : Color.appSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10)
                                            .stroke(budget == preset ? Color.clear : Color.appStroke, lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 16)

                    // Allocation Strategy
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Allocation Strategy")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.white)

                        // Presets
                        HStack(spacing: 10) {
                            ForEach(allocationPresets, id: \.0) { label, n, w, s in
                                let isActive = needsPct == n && wantsPct == w
                                Button {
                                    needsPct = n; wantsPct = w; savingsPct = s
                                } label: {
                                    Text(label)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(isActive ? .white : Color.white.opacity(0.7))
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(isActive ? Color.ctaBlue : Color.appSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10)
                                            .stroke(isActive ? Color.clear : Color.appStroke, lineWidth: 1))
                                }
                            }
                        }

                        // Breakdown
                        VStack(spacing: 10) {
                            ForEach([
                                (BudgetCategory.needs,   needsPct),
                                (BudgetCategory.wants,   wantsPct),
                                (BudgetCategory.savings, savingsPct),
                            ], id: \.0) { cat, pct in
                                HStack {
                                    Circle().fill(cat.color).frame(width: 10, height: 10)
                                    Text(cat.rawValue)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.white)
                                    Spacer()
                                    Text("\(Int(pct))%")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Color.white)
                                    Text((budget * pct / 100).currencyRS)
                                        .font(.caption1).foregroundStyle(Color.white.opacity(0.6))
                                        .frame(width: 90, alignment: .trailing)
                                }
                                .padding(14)
                                .background(Color.appSurface2)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appStroke, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                    // CTA
                    Button {
                        appState.saveBudget(monthly: budget, needs: needsPct, wants: wantsPct, savings: savingsPct)
                        if isEditing { dismiss() }
                    } label: {
                        Text(isEditing ? "Save Changes" : "Complete Setup")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(hex: "#0B1020"))
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(LinearGradient.ctaGrad)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            budget = appState.monthlyBudget
            needsPct = appState.needsPercent
            wantsPct = appState.wantsPercent
            savingsPct = appState.savingsPercent
            budgetInput = String(Int(appState.monthlyBudget))
        }
        .onChange(of: budgetInput) { _, newValue in
            let filtered = newValue.filter { $0.isNumber }
            if filtered != newValue { budgetInput = filtered }
            if let value = Double(filtered), value > 0 {
                budget = value
            }
        }
    }
}

#Preview("Splash")  { SplashView().environmentObject(AppState()) }
#Preview("Welcome") { WelcomeView().environmentObject(AppState()) }
#Preview("Setup")   { SetupBudgetView().environmentObject(AppState()) }
