import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth

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
    @Published var currentUser: UserProfile?
    @Published var transactions: [Transaction] = MockData.transactions
    
        func restoreSession() {
            guard let user = Auth.auth().currentUser else { return }
            isAuthenticated = true
            loadUserProfile(uid: user.uid, fallbackEmail: user.email)
            loadTransactions()
        }
    
        func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
            Auth.auth().signIn(withEmail: email, password: password) { _, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                self.restoreSession()
                completion(.success(()))
            }
        }
    
        func signUp(name: String, email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let user = result?.user else {
                    completion(.success(()))
                    return
                }
                UserService.createUserProfile(uid: user.uid, name: name, email: email) { serviceResult in
                    switch serviceResult {
                    case .success(let profile):
                        DispatchQueue.main.async {
                            self.applyProfile(profile)
                            self.isAuthenticated = true
                        }
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    
        func signOut() {
            try? Auth.auth().signOut()
            isAuthenticated = false
            currentUser = nil
            transactions = []
        }
    
        func saveBudget(monthly: Double, needs: Double, wants: Double, savings: Double) {
            monthlyBudget = monthly
            needsPercent = needs
            wantsPercent = wants
            savingsPercent = savings
            hasCompletedSetup = true
        
            guard let uid = Auth.auth().currentUser?.uid else { return }
            UserService.updateBudget(
                uid: uid,
                monthlyBudget: monthly,
                needsPercent: needs,
                wantsPercent: wants,
                savingsPercent: savings
            ) { _ in }
        }
    
        func loadTransactions() {
            TransactionService.fetchTransactions { result in
                DispatchQueue.main.async {
                    if case let .success(items) = result {
                        self.transactions = items
                    }
                }
            }
        }
    
        func addTransaction(_ tx: Transaction) {
            transactions.insert(tx, at: 0)
            TransactionService.addTransaction(tx)
        }
    
        func deleteTransactions(_ ids: [UUID]) {
            transactions.removeAll { ids.contains($0.id) }
            TransactionService.deleteTransactions(ids)
        }
    
        private func loadUserProfile(uid: String, fallbackEmail: String?) {
            UserService.fetchUserProfile(uid: uid) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profile):
                        self.applyProfile(profile)
                    case .failure:
                        let profile = UserProfile(
                            id: uid,
                            name: "User",
                            email: fallbackEmail ?? "",
                            createdAt: nil,
                            monthlyBudget: nil,
                            needsPercent: nil,
                            wantsPercent: nil,
                            savingsPercent: nil,
                            hasCompletedSetup: false
                        )
                        self.applyProfile(profile)
                    }
                }
            }
        }
    
        private func applyProfile(_ profile: UserProfile) {
            currentUser = profile
            if let monthly = profile.monthlyBudget { monthlyBudget = monthly }
            if let needs = profile.needsPercent { needsPercent = needs }
            if let wants = profile.wantsPercent { wantsPercent = wants }
            if let savings = profile.savingsPercent { savingsPercent = savings }
            hasCompletedSetup = profile.hasCompletedSetup
        }
}

// MARK: - App Entry Point
@main
struct Budgeting_App: App {
    @StateObject private var appState = AppState()

    init() {
            FirebaseApp.configure()
        }
    
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
            ZStack {
                AppBackground()
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
            }
        .animation(.easeInOut(duration: 0.35), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedSetup)
        .onAppear {
                appState.restoreSession()
        }
    }
}
