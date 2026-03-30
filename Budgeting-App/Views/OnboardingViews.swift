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
        ZStack {
            Circle()
                .fill(LinearGradient.primaryGrad)
                .frame(width: size, height: size)
                .shadow(color: Color.uniBlue.opacity(0.25), radius: 16, y: 6)
            Text("B")
                .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

private struct OnboardingBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#F8FAFF"), Color(hex: "#EEF2FF")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            LinearGradient(colors: [Color.uniBlue.opacity(0.22), Color.clear],
                           startPoint: .topTrailing, endPoint: .bottom)
                .ignoresSafeArea()

            LinearGradient(colors: [Color.clear, Color.uniPurple.opacity(0.18)],
                           startPoint: .top, endPoint: .bottomLeading)
                .ignoresSafeArea()

            LinearGradient(colors: [Color.uniBlue.opacity(0.26), Color.clear],
                           startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
        }
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

                Text("Budgify")
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
                    Capsule().fill(Color.black.opacity(0.08)).frame(width: 40, height: 4)
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

                Text("Welcome to Budgify")
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
                                .background(Color.uniBlue.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.primary)
                                Text(desc).font(.caption1).foregroundStyle(Color.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.05), lineWidth: 1))
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
                            .background(LinearGradient.primaryGrad)
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
        .fullScreenCover(isPresented: $showSignUp)  { SignUpView() }
        .fullScreenCover(isPresented: $showLogin)   { LoginView() }
    }
}

// MARK: - Setup Budget Screen
struct SetupBudgetView: View {
    @EnvironmentObject var appState: AppState
    @State private var budget: Double = 45000
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
                        Text("Set Your Budget")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text("Choose your monthly budget and allocation strategy")
                            .font(.subheadline).foregroundStyle(Color.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 32)

                    // Budget Display
                    VStack(spacing: 4) {
                        Text("Monthly Budget").font(.caption1).foregroundStyle(Color.secondary)
                        Text(budget.currencyRS)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text("per month").font(.caption1).foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05), lineWidth: 1))
                    .padding(.horizontal, 24)

                    // Budget presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(budgetPresets, id: \.self) { preset in
                                Button {
                                    budget = preset
                                } label: {
                                    Text(preset.shortCurrency)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(budget == preset ? .white : Color.primary)
                                        .padding(.horizontal, 16).padding(.vertical, 10)
                                        .background(budget == preset ? Color.uniBlue : Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10)
                                            .stroke(budget == preset ? Color.clear : Color.black.opacity(0.06), lineWidth: 1))
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
                            .foregroundStyle(Color.primary)

                        // Presets
                        HStack(spacing: 10) {
                            ForEach(allocationPresets, id: \.0) { label, n, w, s in
                                let isActive = needsPct == n && wantsPct == w
                                Button {
                                    needsPct = n; wantsPct = w; savingsPct = s
                                } label: {
                                    Text(label)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(isActive ? .white : Color.primary)
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(isActive ? Color.uniBlue : Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10)
                                            .stroke(isActive ? Color.clear : Color.black.opacity(0.06), lineWidth: 1))
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
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Text("\(Int(pct))%")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Color.primary)
                                    Text((budget * pct / 100).currencyRS)
                                        .font(.caption1).foregroundStyle(Color.secondary)
                                        .frame(width: 90, alignment: .trailing)
                                }
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                    // CTA
                    Button {
                        appState.monthlyBudget = budget
                        appState.needsPercent = needsPct
                        appState.wantsPercent = wantsPct
                        appState.savingsPercent = savingsPct
                        appState.hasCompletedSetup = true
                    } label: {
                        Text("Complete Setup")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(LinearGradient.primaryGrad)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

#Preview("Splash")  { SplashView().environmentObject(AppState()) }
#Preview("Welcome") { WelcomeView().environmentObject(AppState()) }
#Preview("Setup")   { SetupBudgetView().environmentObject(AppState()) }
