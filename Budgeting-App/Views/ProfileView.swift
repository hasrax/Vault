//
//  Untitled.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI
import Combine

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            List {

                // ── Avatar ────────────────────────────────────────────────
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.primaryGrad)
                                .frame(width: 68, height: 68)
                                .shadow(color: Color.uniBlue.opacity(0.35), radius: 10, y: 4)
                            Text(MockData.userAvatar).font(.system(size: 28))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            let displayName = appState.currentUser?.name ?? MockData.userName
                            let displayEmail = appState.currentUser?.email ?? MockData.userEmail
                            Text(displayName)
                                .font(.system(size: 18, weight: .bold))
                            Text(displayEmail)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Text("Student · LKR")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.uniBlue)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.uniBlue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }

                // ── Preferences ───────────────────────────────────────────
                Section("Preferences") {
                    Toggle(isOn: $appState.isDarkMode) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dark Mode").font(.system(size: 15, weight: .medium))
                                Text(appState.isDarkMode ? "Currently on" : "Currently off")
                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                        } icon: {
                            iconBox(systemName: appState.isDarkMode ? "moon.fill" : "sun.max.fill",
                                    color: appState.isDarkMode ? Color.uniPurple : Color.uniAmber)
                        }
                    }.tint(Color.uniBlue)

                    Toggle(isOn: $appState.isFaceIDEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Face ID").font(.system(size: 15, weight: .medium))
                                Text("Unlock with Face ID")
                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                        } icon: { iconBox(systemName: "faceid", color: Color.uniBlue) }
                    }.tint(Color.uniBlue)

                    Toggle(isOn: $appState.notificationsEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Push Notifications").font(.system(size: 15, weight: .medium))
                                Text("Budget alerts & reminders")
                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                        } icon: { iconBox(systemName: "bell.fill", color: Color.uniOrange) }
                    }.tint(Color.uniBlue)
                }

                // ── Account ───────────────────────────────────────────────
                Section("Account") {
                    NavigationLink(destination: HistoryView()) {
                        Label { Text("Transaction History").font(.system(size: 15, weight: .medium))
                        } icon: { iconBox(systemName: "clock", color: Color.uniPurple) }
                    }
                    NavigationLink(destination: SavingsView()) {
                        Label { Text("Savings Goals").font(.system(size: 15, weight: .medium))
                        } icon: { iconBox(systemName: "banknote", color: Color.uniGreen) }
                    }
                    NavigationLink(destination: BudgetView()) {
                        Label { Text("Budget Settings").font(.system(size: 15, weight: .medium))
                        } icon: { iconBox(systemName: "slider.horizontal.3", color: Color.uniBlue) }
                    }
                }

                // ── Tools ─────────────────────────────────────────────────
                Section("Tools") {
                    NavigationLink(destination: SemesterPlannerView()) {
                        Label { Text("Semester Planner").font(.system(size: 15, weight: .medium))
                        } icon: { iconBox(systemName: "calendar", color: Color.uniPurple) }
                    }
                    NavigationLink(destination: WorkScheduleView()) {
                        Label { Text("Work Schedule").font(.system(size: 15, weight: .medium))
                        } icon: { iconBox(systemName: "briefcase", color: Color.uniTeal) }
                    }
                    NavigationLink(destination: ReceiptScannerView()) {
                        Label { Text("Receipt Scanner").font(.system(size: 15, weight: .medium))
                        } icon: { iconBox(systemName: "camera.viewfinder", color: Color.uniGreen) }
                    }
                    NavigationLink(destination: AnalyticsView()) {
                        Label { Text("Analytics").font(.system(size: 15, weight: .medium))
                        } icon: { iconBox(systemName: "chart.bar.xaxis", color: Color.uniBlue) }
                    }
                    NavigationLink(destination: MoreView()) {
                        Label { Text("More Features").font(.system(size: 15, weight: .medium))
                        } icon: { iconBox(systemName: "square.grid.2x2.fill", color: Color.uniOrange) }
                    }
                }

                // ── About ─────────────────────────────────────────────────
                Section("About") {
                    LabeledContent("Version",    value: "1.0.0")
                    LabeledContent("Build",      value: "Phase 1 — Frontend")
                    LabeledContent("iOS target", value: "iOS 17+")
                    LabeledContent("Framework",  value: "SwiftUI + MVVM")
                }

                // ── Sign out ──────────────────────────────────────────────
                Section {
                    Button(role: .destructive) {
                        withAnimation { appState.isAuthenticated = false }
                    } label: {
                        Label("Sign Out",
                              systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    Button(role: .destructive) {
                        withAnimation {
                            appState.isAuthenticated        = false
                            appState.hasCompletedOnboarding = false
                            appState.hasCompletedSetup      = false
                        }
                    } label: {
                        Label("Reset App (dev only)", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Icon Box Helper
    private func iconBox(systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.12))
                .frame(width: 34, height: 34)
            Image(systemName: systemName)
                .font(.system(size: 16))
                .foregroundStyle(color)
        }
    }
}

#Preview { ProfileView().environmentObject(AppState()) }
