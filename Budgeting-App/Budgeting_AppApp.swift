import SwiftUI
import Combine

// MARK: - Global App State
class AppState: ObservableObject {
    @Published var isAuthenticated        = false
    @Published var hasCompletedOnboarding = false
    @Published var hasCompletedSetup      = false
    @Published var isDarkMode             = false
    @Published var isFaceIDEnabled        = true
    @Published var notificationsEnabled   = true
    @Published var monthlyBudget: Double  = 45000
    @Published var needsPercent: Double   = 50
    @Published var wantsPercent: Double   = 25
    @Published var savingsPercent: Double = 25
}

// MARK: - App Entry Point
@main
struct Budgeting_App: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}

// MARK: - Root Router
// Decides which screen to show based on app state.
// Splash → Setup → Welcome/Login → Main app
struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                SplashView()
            } else if !appState.hasCompletedSetup {
                SetupBudgetView()
            } else if !appState.isAuthenticated {
                WelcomeView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedSetup)
    }
}
