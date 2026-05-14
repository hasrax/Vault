//
//  Untitled.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var tokenStore = PushTokenStore.shared
    @State private var showDeleteConfirm = false
    @State private var showSignOutConfirm = false
    @State private var deleteError = ""

    var body: some View {
        NavigationStack {
            ZStack {
                List {

                // ── Avatar ────────────────────────────────────────────────
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            profileAvatar
                                .frame(width: 68, height: 68)
                                .shadow(color: Color.uniBlue.opacity(0.35), radius: 10, y: 4)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            let displayName = appState.currentUser?.name ?? MockData.userName
                            let displayEmail = appState.currentUser?.email ?? MockData.userEmail
                            Text(displayName)
                                .scaledFont(size: 18, weight: .bold)
                            Text(displayEmail)
                                .scaledFont(size: 14)
                                .foregroundStyle(.secondary)
                            Text("Student · LKR")
                                .scaledFont(size: 12, weight: .medium)
                                .foregroundStyle(Color.uniBlue)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.uniBlue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }

                Section {
                    NavigationLink(destination: EditProfileView()) {
                        Label { Text("Edit Profile").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "pencil", color: Color.uniBlue) }
                    }
                }

                // ── Preferences ───────────────────────────────────────────
                Section("Preferences") {
                    Toggle(isOn: $appState.isDarkMode) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dark Mode").scaledFont(size: 15, weight: .medium)
                                Text(appState.isDarkMode ? "Currently on" : "Currently off")
                                    .scaledFont(size: 12).foregroundStyle(.secondary)
                            }
                        } icon: {
                            iconBox(systemName: appState.isDarkMode ? "moon.fill" : "sun.max.fill",
                                    color: appState.isDarkMode ? Color.uniPurple : Color.uniAmber)
                        }
                    }.tint(Color.uniBlue)

                    Toggle(isOn: $appState.isFaceIDEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Face ID").scaledFont(size: 15, weight: .medium)
                                Text("Unlock with Face ID")
                                    .scaledFont(size: 12).foregroundStyle(.secondary)
                            }
                        } icon: { iconBox(systemName: "faceid", color: Color.uniBlue) }
                    }.tint(Color.uniBlue)

                    Toggle(isOn: $appState.notificationsEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Push Notifications").scaledFont(size: 15, weight: .medium)
                                Text("Budget alerts & reminders")
                                    .scaledFont(size: 12).foregroundStyle(.secondary)
                            }
                        } icon: { iconBox(systemName: "bell.fill", color: Color.uniOrange) }
                    }.tint(Color.uniBlue)

                    NavigationLink(destination: AccessibilitySettingsView()) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Accessibility").scaledFont(size: 15, weight: .medium)
                                Text("Text size and contrast")
                                    .scaledFont(size: 12).foregroundStyle(.secondary)
                            }
                        } icon: { iconBox(systemName: "figure.wave", color: Color.uniTeal) }
                    }
                }

                Section("Device Tokens") {
                    if !tokenStore.fcmToken.isEmpty {
                        Text("FCM: \(tokenStore.fcmToken)")
                            .scaledFont(size: 12)
                            .textSelection(.enabled)
                        Button("Copy FCM Token") {
                            UIPasteboard.general.string = tokenStore.fcmToken
                        }
                    } else {
                        Text("FCM token not available yet.")
                            .scaledFont(size: 12)
                            .foregroundStyle(.secondary)
                    }

                    if !tokenStore.apnsToken.isEmpty {
                        Text("APNs: \(tokenStore.apnsToken)")
                            .scaledFont(size: 12)
                            .textSelection(.enabled)
                    }
                }

                // ── Account ───────────────────────────────────────────────
                Section("Account") {
                    NavigationLink(destination: SearchView(showBack: true)) {
                        Label { Text("History").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "clock", color: Color.uniPurple) }
                    }
                    NavigationLink(destination: ApnsSimulatorView()) {
                        Label { Text("APNs Simulator").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "bell.badge", color: Color.uniOrange) }
                    }
                    NavigationLink(destination: SavingsView()) {
                        Label { Text("Savings Goals").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "banknote", color: Color.uniGreen) }
                    }
                    NavigationLink(destination: BudgetView()) {
                        Label { Text("Budget Settings").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "slider.horizontal.3", color: Color.uniBlue) }
                    }
                    NavigationLink(destination: ChangePasswordView()) {
                        Label { Text("Change Password").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "key.fill", color: Color.uniOrange) }
                    }
                }

                // ── Tools ─────────────────────────────────────────────────
                Section("Tools") {
                    NavigationLink(destination: SemesterPlannerView()) {
                        Label { Text("Semester Planner").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "calendar", color: Color.uniPurple) }
                    }
                    NavigationLink(destination: WorkScheduleView()) {
                        Label { Text("Work Schedule").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "briefcase", color: Color.uniTeal) }
                    }
                    NavigationLink(destination: ReceiptScannerView()) {
                        Label { Text("Receipt Scanner").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "camera.viewfinder", color: Color.uniGreen) }
                    }
                    NavigationLink(destination: AnalyticsView()) {
                        Label { Text("Analytics").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "chart.bar.xaxis", color: Color.uniBlue) }
                    }
                    NavigationLink(destination: MoreView()) {
                        Label { Text("More Features").scaledFont(size: 15, weight: .medium)
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

                Section("Support") {
                    NavigationLink(destination: FAQView()) {
                        Label { Text("FAQ").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "questionmark.circle", color: Color.uniTeal) }
                    }
                    NavigationLink(destination: HelpView()) {
                        Label { Text("Help & Support").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "lifepreserver", color: Color.uniBlue) }
                    }
                    NavigationLink(destination: TermsView()) {
                        Label { Text("Terms of Service").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "doc.text", color: Color.uniOrange) }
                    }
                    NavigationLink(destination: PrivacyView()) {
                        Label { Text("Privacy Policy").scaledFont(size: 15, weight: .medium)
                        } icon: { iconBox(systemName: "lock.shield", color: Color.uniPurple) }
                    }
                }

                if !deleteError.isEmpty {
                    Section {
                        Label(deleteError, systemImage: "exclamationmark.circle")
                            .foregroundStyle(Color.expense)
                    }
                }

                // ── Sign out ──────────────────────────────────────────────
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("Sign Out",
                              systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                    }
                    Button(role: .destructive) {
                        withAnimation {
                            appState.signOut()
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

                if showSignOutConfirm {
                    let displayName = appState.currentUser?.name ?? MockData.userName
                    signOutOverlay(
                        accountName: displayName,
                        onConfirm: {
                            showSignOutConfirm = false
                            withAnimation { appState.signOut() }
                        },
                        onCancel: { showSignOutConfirm = false }
                    )
                }

                if showDeleteConfirm {
                    confirmationOverlay(
                        title: "Delete account?",
                        message: "This permanently deletes your account and data.",
                        confirmTitle: "Delete",
                        isDestructive: true,
                        onConfirm: {
                            showDeleteConfirm = false
                            let targetEmail = (appState.currentUser?.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                            appState.deleteAccount { result in
                                DispatchQueue.main.async {
                                    if case let .failure(error) = result {
                                        deleteError = error.localizedDescription
                                    } else if !targetEmail.isEmpty {
                                        KeychainService.removeAccount(email: targetEmail)
                                    }
                                }
                            }
                        },
                        onCancel: { showDeleteConfirm = false }
                    )
                }
            }
        }
        .onChange(of: appState.notificationsEnabled) { _, enabled in
            if enabled {
                NotificationService.requestAuthorization()
            }
        }
        .onAppear {
            if appState.notificationsEnabled {
                NotificationService.requestAuthorization()
            }
        }
    }

    // MARK: - Icon Box Helper
    private func iconBox(systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.12))
                .frame(width: 34, height: 34)
            Image(systemName: systemName)
                .scaledFont(size: 16)
                .foregroundStyle(color)
        }
    }

    private func confirmationOverlay(
        title: String,
        message: String,
        confirmTitle: String,
        isDestructive: Bool,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 12) {
                Text(title)
                    .scaledFont(size: 18, weight: .bold)
                Text(message)
                    .scaledFont(size: 13)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button("Cancel") { onCancel() }
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button(confirmTitle) { onConfirm() }
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(isDestructive ? Color.expense : Color.uniBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18)
            .frame(maxWidth: 300)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
            .padding(.horizontal, 24)
        }
    }

    private var profileAvatar: some View {
        Group {
            if let base64 = appState.currentUser?.photoBase64,
               let data = Data(base64Encoded: base64),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let urlStr = appState.currentUser?.photoURL,
                      let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Circle().fill(LinearGradient.primaryGrad)
                            .overlay(Text(MockData.userAvatar).scaledFont(size: 28))
                    }
                }
            } else {
                Circle().fill(LinearGradient.primaryGrad)
                    .overlay(Text(MockData.userAvatar).scaledFont(size: 28))
            }
        }
        .clipShape(Circle())
    }

    private func signOutOverlay(
        accountName: String,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 12) {
                Text("Sign Out")
                    .scaledFont(size: 17, weight: .semibold)
                    .foregroundStyle(Color.uniBlue)

                VStack(spacing: 4) {
                    Text("Are you sure you want to sign out of")
                        .scaledFont(size: 13)
                        .foregroundStyle(Color.primary)
                    Text("\(accountName)'s account ?")
                        .scaledFont(size: 13)
                        .foregroundStyle(Color.secondary)
                }
                .multilineTextAlignment(.center)

                HStack(spacing: 14) {
                    Button("Sign Out") { onConfirm() }
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundStyle(Color.uniBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.uniBlue, lineWidth: 1)
                        )

                    Button("Cancel") { onCancel() }
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(LinearGradient.ctaGrad)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18)
            .frame(maxWidth: 320)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
            .padding(.horizontal, 24)
        }
    }
}

#Preview { ProfileView().environmentObject(AppState()) }
