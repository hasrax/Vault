import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import UIKit

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
    @Published var importantDates: [ImportantDate] = MockData.importantDates
    @Published var semesterGoals: [SemesterGoal] = MockData.semesterGoals
    @Published var workShifts: [WorkShift] = MockData.shifts

    private var importantDatesListener: ListenerRegistration?
    private var semesterGoalsListener: ListenerRegistration?
    private var workShiftsListener: ListenerRegistration?
    
        func restoreSession() {
            guard let user = Auth.auth().currentUser else { return }
            loadUserProfile(uid: user.uid, fallbackEmail: user.email) {
                self.isAuthenticated = true
            }
            loadTransactions()
            startPlannerListeners()
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
                            self.transactions = []
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
            stopPlannerListeners()
        }

        func changePassword(newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let user = Auth.auth().currentUser else {
                completion(.failure(NSError(domain: "AppState", code: 401)))
                return
            }
            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }

        func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
            guard let user = Auth.auth().currentUser else {
                completion(.failure(NSError(domain: "AppState", code: 401)))
                return
            }
            let uid = user.uid
            TransactionService.deleteAllTransactions { txError in
                if let txError = txError {
                    completion(.failure(txError))
                    return
                }
                UserService.deleteUser(uid: uid) { userDocError in
                    if let userDocError = userDocError {
                        completion(.failure(userDocError))
                        return
                    }
                    user.delete { authError in
                        if let authError = authError {
                            completion(.failure(authError))
                            return
                        }
                        DispatchQueue.main.async {
                            self.signOut()
                            completion(.success(()))
                        }
                    }
                }
            }
        }

        func updateProfile(name: String, email: String, photo: UIImage?, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let uid = Auth.auth().currentUser?.uid else {
                completion(.failure(NSError(domain: "AppState", code: 401)))
                return
            }
            let applyUpdate: (String?) -> Void = { photoURL in
                UserService.updateProfile(uid: uid, name: name, email: email, photoURL: photoURL) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        var updated = self.currentUser ?? UserProfile(
                            id: uid,
                            name: name,
                            email: email,
                            createdAt: nil,
                            photoURL: photoURL,
                            monthlyBudget: self.monthlyBudget,
                            needsPercent: self.needsPercent,
                            wantsPercent: self.wantsPercent,
                            savingsPercent: self.savingsPercent,
                            hasCompletedSetup: self.hasCompletedSetup
                        )
                        updated.name = name
                        updated.email = email
                        if let photoURL = photoURL { updated.photoURL = photoURL }
                        self.currentUser = updated
                        completion(.success(()))
                    }
                }
            }

            if let photo = photo {
                ProfileImageService.uploadProfileImage(uid: uid, image: photo) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let url): applyUpdate(url)
                        case .failure(let error): completion(.failure(error))
                        }
                    }
                }
            } else {
                applyUpdate(nil)
            }
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

        func loadPlannerData() {
            PlannerService.fetchImportantDates { result in
                DispatchQueue.main.async {
                    if case let .success(items) = result, !items.isEmpty {
                        self.importantDates = items
                    }
                }
            }
            PlannerService.fetchSemesterGoals { result in
                DispatchQueue.main.async {
                    if case let .success(items) = result, !items.isEmpty {
                        self.semesterGoals = items
                    }
                }
            }
            PlannerService.fetchWorkShifts { result in
                DispatchQueue.main.async {
                    if case let .success(items) = result, !items.isEmpty {
                        self.workShifts = items
                    }
                }
            }
        }

        func startPlannerListeners() {
            stopPlannerListeners()
            importantDatesListener = PlannerService.listenImportantDates { result in
                DispatchQueue.main.async {
                    if case let .success(items) = result { self.importantDates = items }
                }
            }
            semesterGoalsListener = PlannerService.listenSemesterGoals { result in
                DispatchQueue.main.async {
                    if case let .success(items) = result { self.semesterGoals = items }
                }
            }
            workShiftsListener = PlannerService.listenWorkShifts { result in
                DispatchQueue.main.async {
                    if case let .success(items) = result { self.workShifts = items }
                }
            }
        }

        func stopPlannerListeners() {
            importantDatesListener?.remove()
            semesterGoalsListener?.remove()
            workShiftsListener?.remove()
            importantDatesListener = nil
            semesterGoalsListener = nil
            workShiftsListener = nil
        }

        func addSemesterGoal(title: String, progress: Int?) {
            let goal = SemesterGoal(title: title, completed: false, progress: progress)
            semesterGoals.insert(goal, at: 0)
            PlannerService.addSemesterGoal(goal)
        }

        func toggleSemesterGoal(_ goal: SemesterGoal) {
            guard let idx = semesterGoals.firstIndex(where: { $0.id == goal.id }) else { return }
            var updated = goal
            updated.completed.toggle()
            if updated.completed { updated.progress = nil }
            semesterGoals[idx] = updated
            PlannerService.updateSemesterGoal(updated)
        }

        func updateSemesterGoal(_ goal: SemesterGoal) {
            guard let idx = semesterGoals.firstIndex(where: { $0.id == goal.id }) else { return }
            semesterGoals[idx] = goal
            PlannerService.updateSemesterGoal(goal)
        }

        func deleteSemesterGoal(_ goal: SemesterGoal) {
            semesterGoals.removeAll { $0.id == goal.id }
            PlannerService.deleteSemesterGoal(goal.id)
        }

        func addImportantDate(title: String, date: Date, type: ImportantDate.DateType, amount: Double?, icon: String) {
            let item = ImportantDate(title: title, date: date, type: type, amount: amount, icon: icon)
            importantDates.append(item)
            PlannerService.addImportantDate(item)
        }

        func updateImportantDate(_ item: ImportantDate) {
            guard let idx = importantDates.firstIndex(where: { $0.id == item.id }) else { return }
            importantDates[idx] = item
            PlannerService.updateImportantDate(item)
        }

        func deleteImportantDate(_ item: ImportantDate) {
            importantDates.removeAll { $0.id == item.id }
            PlannerService.deleteImportantDate(item.id)
        }

        func addWorkShift(day: String, date: String, role: String, start: String, end: String, hours: Int, pay: Double, status: WorkShift.ShiftStatus) {
            let shift = WorkShift(day: day, date: date, role: role, start: start, end: end, hours: hours, pay: pay, status: status)
            workShifts.append(shift)
            PlannerService.addWorkShift(shift)

            if pay > 0 {
                let txDate = parseShiftDate(date) ?? Date()
                let tx = Transaction(
                    name: "Work: \(role)",
                    amount: pay,
                    type: .income,
                    incomeSource: .parttime,
                    budgetCategory: .savings,
                    date: txDate,
                    note: "Shift income",
                    linkedShiftId: shift.id.uuidString
                )
                addTransaction(tx)
            }
        }

        func updateWorkShift(_ shift: WorkShift) {
            guard let idx = workShifts.firstIndex(where: { $0.id == shift.id }) else { return }
            workShifts[idx] = shift
            PlannerService.updateWorkShift(shift)

            if let txIdx = transactions.firstIndex(where: { $0.linkedShiftId == shift.id.uuidString }) {
                var tx = transactions[txIdx]
                tx.name = "Work: \(shift.role)"
                tx.amount = shift.pay
                tx.date = parseShiftDate(shift.date) ?? Date()
                transactions[txIdx] = tx
                TransactionService.updateTransaction(tx)
            } else if shift.pay > 0 {
                let tx = Transaction(
                    name: "Work: \(shift.role)",
                    amount: shift.pay,
                    type: .income,
                    incomeSource: .parttime,
                    budgetCategory: .savings,
                    date: parseShiftDate(shift.date) ?? Date(),
                    note: "Shift income",
                    linkedShiftId: shift.id.uuidString
                )
                addTransaction(tx)
            }
        }

        func addMonthlyShifts(
            startDate: Date,
            months: Int,
            role: String,
            start: String,
            end: String,
            hours: Int,
            monthlyPay: Double,
            status: WorkShift.ShiftStatus
        ) {
            let calendar = Calendar.current
            let dateFmt = DateFormatter()
            dateFmt.dateFormat = "MMM yyyy"

            for offset in 0..<months {
                guard let date = calendar.date(byAdding: .month, value: offset, to: startDate) else { continue }
                let day = "Monthly"
                let dateStr = dateFmt.string(from: date)
                addWorkShift(
                    day: day,
                    date: dateStr,
                    role: role,
                    start: start,
                    end: end,
                    hours: hours,
                    pay: monthlyPay,
                    status: status
                )
            }
        }

        func addWeeklyShifts(
            startDate: Date,
            weeks: Int,
            role: String,
            start: String,
            end: String,
            hours: Int,
            pay: Double,
            status: WorkShift.ShiftStatus
        ) {
            let calendar = Calendar.current
            let dayFmt = DateFormatter()
            dayFmt.dateFormat = "EEE"
            let dateFmt = DateFormatter()
            dateFmt.dateFormat = "MMM d"

            for offset in 0..<weeks {
                guard let date = calendar.date(byAdding: .day, value: offset * 7, to: startDate) else { continue }
                let day = dayFmt.string(from: date)
                let dateStr = dateFmt.string(from: date)
                addWorkShift(
                    day: day,
                    date: dateStr,
                    role: role,
                    start: start,
                    end: end,
                    hours: hours,
                    pay: pay,
                    status: status
                )
            }
        }

        func deleteWorkShift(_ shift: WorkShift) {
            workShifts.removeAll { $0.id == shift.id }
            PlannerService.deleteWorkShift(shift.id)
            if let tx = transactions.first(where: { $0.linkedShiftId == shift.id.uuidString }) {
                deleteTransactions([tx.id])
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
    
        private func loadUserProfile(uid: String, fallbackEmail: String?, completion: (() -> Void)? = nil) {
            UserService.fetchUserProfile(uid: uid) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profile):
                        var updated = profile
                        let email = fallbackEmail ?? profile.email
                        if (updated.name.isEmpty || updated.name == "User"), !email.isEmpty {
                            let base = email.split(separator: "@").first.map(String.init) ?? "User"
                            updated.name = base
                            UserService.updateProfile(uid: uid, name: updated.name, email: email, photoURL: updated.photoURL)
                        }
                        self.applyProfile(updated)
                    case .failure:
                        let email = fallbackEmail ?? ""
                        let base = email.split(separator: "@").first.map(String.init) ?? "User"
                        UserService.createUserProfile(uid: uid, name: base, email: email) { serviceResult in
                            DispatchQueue.main.async {
                                switch serviceResult {
                                case .success(let profile):
                                    self.applyProfile(profile)
                                case .failure:
                                    let profile = UserProfile(
                                        id: uid,
                                        name: base,
                                        email: email,
                                        createdAt: nil,
                                        photoURL: nil,
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
                    completion?()
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

        private func parseShiftDate(_ dateString: String) -> Date? {
            let fmt1 = DateFormatter()
            fmt1.dateFormat = "MMM d"
            let fmt2 = DateFormatter()
            fmt2.dateFormat = "MMM yyyy"
            return fmt1.date(from: dateString) ?? fmt2.date(from: dateString)
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
                    } else if !appState.isAuthenticated {
                        WelcomeView()
                    } else if !appState.hasCompletedSetup {
                        SetupBudgetView()
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
