import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
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
    @Published var savingsGoals: [SavingsGoal] = []
    @Published var sessionTimeoutSeconds: TimeInterval = 30
    @Published var splitBills: [SplitBill] = []
    @Published var plannerTheme: PlannerTheme = PlannerTheme()

    private var importantDatesListener: ListenerRegistration?
    private var semesterGoalsListener: ListenerRegistration?
    private var workShiftsListener: ListenerRegistration?
    private var splitBillsListener: ListenerRegistration?
    private var transactionsListener: ListenerRegistration?
    private var savingsGoalsListener: ListenerRegistration?
    
        func restoreSession() {
            guard let user = Auth.auth().currentUser else { return }
            loadCachedData(uid: user.uid)
            loadUserProfile(uid: user.uid, fallbackEmail: user.email) {
                self.isAuthenticated = true
            }
            loadTransactions()
            startTransactionListener()
            startSavingsGoalsListener()
            loadPlannerTheme()                  // ← restore per-user theme
            flushPendingWrites(uid: user.uid)
        }

        // MARK: - Planner Theme persistence
        func savePlannerTheme() {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let data: [String: Any] = ["plannerTheme": plannerTheme.firestoreData]
            Firestore.firestore().collection("users").document(uid)
                .setData(data, merge: true) { _ in }
        }

        func loadPlannerTheme() {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            Firestore.firestore().collection("users").document(uid)
                .getDocument { [weak self] snapshot, _ in
                    guard let self,
                          let dict = snapshot?.data()?["plannerTheme"] as? [String: Any],
                          let theme = PlannerTheme(from: dict) else { return }
                    DispatchQueue.main.async { self.plannerTheme = theme }
                }
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
            splitBills = []
            savingsGoals = []
            plannerTheme = PlannerTheme()   // reset to defaults on logout
            stopTransactionListener()
            stopSavingsGoalsListener()
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
                        CoreDataCache.shared.saveUserProfile(updated, ownerId: uid)
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

            if var profile = currentUser {
                profile.monthlyBudget = monthly
                profile.needsPercent = needs
                profile.wantsPercent = wants
                profile.savingsPercent = savings
                profile.hasCompletedSetup = true
                currentUser = profile
                CoreDataCache.shared.saveUserProfile(profile, ownerId: uid)
            }
        }
    
        func loadTransactions() {
            TransactionService.fetchTransactions { result in
                DispatchQueue.main.async {
                    if case let .success(items) = result {
                        self.transactions = items
                        if let uid = Auth.auth().currentUser?.uid {
                            CoreDataCache.shared.replaceTransactions(items, ownerId: uid)
                        }
                    }
                }
            }
        }

        func startTransactionListener() {
            stopTransactionListener()
            transactionsListener = TransactionService.listenTransactions { result in
                DispatchQueue.main.async {
                    if case let .success(items) = result {
                        self.transactions = items
                        if let uid = Auth.auth().currentUser?.uid {
                            CoreDataCache.shared.replaceTransactions(items, ownerId: uid)
                        }
                    }
                }
            }
        }

        func stopTransactionListener() {
            transactionsListener?.remove()
            transactionsListener = nil
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

        func startSplitBillListeners() {
            stopSplitBillListeners()
            splitBillsListener = SplitBillService.listenSplitBills { result in
                DispatchQueue.main.async {
                    if case let .success(items) = result {
                        self.splitBills = items.sorted { $0.createdAt > $1.createdAt }
                    }
                }
            }
        }

        func stopSplitBillListeners() {
            splitBillsListener?.remove()
            splitBillsListener = nil
        }

        func startSavingsGoalsListener() {
            stopSavingsGoalsListener()
            savingsGoalsListener = SavingsGoalService.listenGoals { result in
                DispatchQueue.main.async {
                    if case let .success(items) = result {
                        self.savingsGoals = items
                        if let uid = Auth.auth().currentUser?.uid {
                            CoreDataCache.shared.replaceSavingsGoals(items, ownerId: uid)
                        }
                    }
                }
            }
        }

        func stopSavingsGoalsListener() {
            savingsGoalsListener?.remove()
            savingsGoalsListener = nil
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

        func findUserByEmail(_ email: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
            let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !trimmed.isEmpty else {
                completion(.failure(NSError(domain: "AppState", code: 400)))
                return
            }
            UserService.fetchUserByEmail(email: trimmed, completion: completion)
        }

        func searchUsers(query: String, completion: @escaping (Result<[UserProfile], Error>) -> Void) {
            UserService.searchUsers(query: query, completion: completion)
        }

        func createSplitBill(
            title: String,
            totalAmount: Double,
            splitMethod: SplitMethod,
            participants: [SplitParticipant]
        ) {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let bill = SplitBill(
                title: title,
                totalAmount: totalAmount,
                createdBy: uid,
                createdAt: Date(),
                splitMethod: splitMethod,
                status: .open,
                participants: participants
            )
            splitBills.insert(bill, at: 0)
            SplitBillService.addSplitBill(bill)
        }

        func updateSplitBill(_ bill: SplitBill) {
            if let idx = splitBills.firstIndex(where: { $0.id == bill.id }) {
                splitBills[idx] = bill
            }
            SplitBillService.updateSplitBill(bill)
        }

        func acceptSplitBill(_ bill: SplitBill) {
            updateSplitBillParticipant(bill, status: .accepted)
        }

        func declineSplitBill(_ bill: SplitBill) {
            updateSplitBillParticipant(bill, status: .declined)
        }

        func markSplitBillPaid(_ bill: SplitBill) {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            guard let participant = bill.participants.first(where: { $0.userId == uid }) else { return }
            if participant.status == .paid { return }
            updateSplitBillParticipant(bill, status: .paid)

            let tx = Transaction(
                name: "Split: \(bill.title)",
                amount: participant.shareAmount,
                type: .expense,
                category: .other,
                budgetCategory: .wants,
                date: Date(),
                note: "Split bill payment",
                linkedSplitBillId: bill.id.uuidString
            )
            addTransaction(tx)
        }

        func settleSplitBill(_ bill: SplitBill) {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            guard bill.createdBy == uid else { return }
            if bill.status == .settled { return }

            let totalCollected = bill.participants
                .filter { !$0.isCreator && $0.status == .paid }
                .reduce(0.0) { $0 + $1.shareAmount }

            var updated = bill
            updated.status = .settled
            updateSplitBill(updated)

            if totalCollected > 0 {
                let tx = Transaction(
                    name: "Split settled: \(bill.title)",
                    amount: totalCollected,
                    type: .income,
                    incomeSource: .other,
                    budgetCategory: .savings,
                    date: Date(),
                    note: "Split bill settled",
                    linkedSplitBillId: bill.id.uuidString
                )
                addTransaction(tx)
            }
        }

        private func updateSplitBillParticipant(_ bill: SplitBill, status: SplitParticipantStatus) {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            var updated = bill
            updated.participants = bill.participants.map { p in
                if p.userId == uid {
                    var copy = p
                    copy.status = status
                    return copy
                }
                return p
            }
            updateSplitBill(updated)
        }
    
        func addTransaction(_ tx: Transaction) {
            transactions.insert(tx, at: 0)
            if let uid = Auth.auth().currentUser?.uid {
                CoreDataCache.shared.upsertTransaction(tx, ownerId: uid)
            }
            TransactionService.addTransaction(tx) { error in
                if error != nil, let uid = Auth.auth().currentUser?.uid {
                    if let data = try? JSONEncoder().encode(tx),
                       let payload = String(data: data, encoding: .utf8) {
                        CoreDataCache.shared.enqueuePendingWrite(ownerId: uid, type: "transaction_upsert", payload: payload)
                    }
                }
            }
        }

        func addSavingsGoal(
            name: String,
            icon: String,
            colorHex: String,
            targetAmount: Double,
            currentAmount: Double,
            deadline: Date?
        ) {
            let goal = SavingsGoal(
                name: name,
                icon: icon,
                colorHex: colorHex,
                targetAmount: targetAmount,
                currentAmount: currentAmount,
                deadline: deadline
            )
            savingsGoals.insert(goal, at: 0)
            if let uid = Auth.auth().currentUser?.uid {
                CoreDataCache.shared.upsertSavingsGoal(goal, ownerId: uid)
            }
            SavingsGoalService.addGoal(goal) { error in
                if error != nil, let uid = Auth.auth().currentUser?.uid {
                    if let data = try? JSONEncoder().encode(goal),
                       let payload = String(data: data, encoding: .utf8) {
                        CoreDataCache.shared.enqueuePendingWrite(ownerId: uid, type: "savings_goal_upsert", payload: payload)
                    }
                }
            }

            if currentAmount > 0 {
                let tx = Transaction(
                    name: "Savings: \(goal.name)",
                    amount: currentAmount,
                    type: .expense,
                    category: nil,
                    incomeSource: nil,
                    budgetCategory: .savings,
                    date: Date(),
                    note: "Initial savings"
                )
                addTransaction(tx)
            }
        }

        func updateSavingsGoal(_ goal: SavingsGoal) {
            if let idx = savingsGoals.firstIndex(where: { $0.id == goal.id }) {
                savingsGoals[idx] = goal
            }
            if let uid = Auth.auth().currentUser?.uid {
                CoreDataCache.shared.upsertSavingsGoal(goal, ownerId: uid)
            }
            SavingsGoalService.updateGoal(goal) { error in
                if error != nil, let uid = Auth.auth().currentUser?.uid {
                    if let data = try? JSONEncoder().encode(goal),
                       let payload = String(data: data, encoding: .utf8) {
                        CoreDataCache.shared.enqueuePendingWrite(ownerId: uid, type: "savings_goal_upsert", payload: payload)
                    }
                }
            }
        }

        func deleteSavingsGoal(_ goal: SavingsGoal) {
            savingsGoals.removeAll { $0.id == goal.id }
            SavingsGoalService.deleteGoal(goal.id)
            if let uid = Auth.auth().currentUser?.uid {
                CoreDataCache.shared.deleteSavingsGoal(goal.id, ownerId: uid)
            }
        }

        func addMoney(to goal: SavingsGoal, amount: Double) {
            guard amount > 0 else { return }
            var updated = goal
            updated.currentAmount += amount
            updateSavingsGoal(updated)

            let tx = Transaction(
                name: "Savings: \(goal.name)",
                amount: amount,
                type: .expense,
                category: nil,
                incomeSource: nil,
                budgetCategory: .savings,
                date: Date(),
                note: "Savings goal contribution"
            )
            addTransaction(tx)
        }
    
        func deleteTransactions(_ ids: [UUID]) {
            transactions.removeAll { ids.contains($0.id) }
            TransactionService.deleteTransactions(ids)
            if let uid = Auth.auth().currentUser?.uid {
                CoreDataCache.shared.deleteTransactions(ids, ownerId: uid)
            }
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
                        CoreDataCache.shared.saveUserProfile(updated, ownerId: uid)
                        UserService.updateSearchFields(uid: uid, name: updated.name, email: email)
                    case .failure:
                        let email = fallbackEmail ?? ""
                        let base = email.split(separator: "@").first.map(String.init) ?? "User"
                        UserService.createUserProfile(uid: uid, name: base, email: email) { serviceResult in
                            DispatchQueue.main.async {
                                switch serviceResult {
                                case .success(let profile):
                                    self.applyProfile(profile)
                                    CoreDataCache.shared.saveUserProfile(profile, ownerId: uid)
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
                                    CoreDataCache.shared.saveUserProfile(profile, ownerId: uid)
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

        private func loadCachedData(uid: String) {
            transactions = CoreDataCache.shared.fetchTransactions(ownerId: uid)
            savingsGoals = CoreDataCache.shared.fetchSavingsGoals(ownerId: uid)
            if let cached = CoreDataCache.shared.fetchUserProfile(ownerId: uid) {
                applyProfile(cached)
            }
        }

        private func flushPendingWrites(uid: String) {
            let pending = CoreDataCache.shared.fetchPendingWrites(ownerId: uid)
            guard !pending.isEmpty else { return }

            for item in pending {
                switch item.type {
                case "transaction_upsert":
                    if let data = item.payload.data(using: .utf8),
                       let tx = try? JSONDecoder().decode(Transaction.self, from: data) {
                        TransactionService.addTransaction(tx) { error in
                            if error == nil {
                                CoreDataCache.shared.deletePendingWrite(item.id)
                            }
                        }
                    }
                case "savings_goal_upsert":
                    if let data = item.payload.data(using: .utf8),
                       let goal = try? JSONDecoder().decode(SavingsGoal.self, from: data) {
                        SavingsGoalService.updateGoal(goal) { error in
                            if error == nil {
                                CoreDataCache.shared.deletePendingWrite(item.id)
                            }
                        }
                    }
                default:
                    break
                }
            }
        }
}

// MARK: - App Entry Point
@main
struct Budgeting_App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState: AppState
    @StateObject private var authVM: AuthViewModel
    @StateObject private var transactionsVM: TransactionsViewModel
    @StateObject private var savingsVM: SavingsGoalsViewModel
    @StateObject private var plannerVM: PlannerViewModel
    @StateObject private var splitBillsVM: SplitBillsViewModel

    init() {
            FirebaseApp.configure()
            if let clientID = FirebaseApp.app()?.options.clientID {
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            }
            let state = AppState()
            _appState = StateObject(wrappedValue: state)
            _authVM = StateObject(wrappedValue: AuthViewModel(appState: state))

            let txVM = TransactionsViewModel(userIdProvider: { Auth.auth().currentUser?.uid })
            _transactionsVM = StateObject(wrappedValue: txVM)
            _savingsVM = StateObject(
                wrappedValue: SavingsGoalsViewModel(
                    userIdProvider: { Auth.auth().currentUser?.uid },
                    addTransaction: { tx in
                        txVM.addTransaction(tx)
                    }
                )
            )
            _plannerVM = StateObject(wrappedValue: PlannerViewModel(transactionsVM: txVM))
            _splitBillsVM = StateObject(
                wrappedValue: SplitBillsViewModel(
                    userIdProvider: { Auth.auth().currentUser?.uid },
                    currentUserProvider: { state.currentUser },
                    transactionsVM: txVM
                )
            )
        }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authVM)
                .environmentObject(transactionsVM)
                .environmentObject(savingsVM)
                .environmentObject(plannerVM)
                .environmentObject(splitBillsVM)
                .tint(Color.uniBlue)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}

// MARK: - Root Router
// Decides which screen to show based on app state.
// Splash → Setup → Welcome/Login → Main app
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var transactionsVM: TransactionsViewModel
    @EnvironmentObject var savingsVM: SavingsGoalsViewModel
    @EnvironmentObject var plannerVM: PlannerViewModel
    @EnvironmentObject var splitBillsVM: SplitBillsViewModel
    @Environment(\.scenePhase) var scenePhase
    @State private var lastBackgroundAt: Date?
    private let lastBackgroundKey = "lastBackgroundAt"

    var body: some View {
        rootBase
            .modifier(
                RootLifecycleModifier(
                    authVM: authVM,
                    transactionsVM: transactionsVM,
                    savingsVM: savingsVM,
                    plannerVM: plannerVM,
                    splitBillsVM: splitBillsVM,
                    scenePhase: scenePhase,
                    lastBackgroundKey: lastBackgroundKey,
                    lastBackgroundAt: $lastBackgroundAt,
                    onAuthChange: handleAuthChange,
                    onBudgetChange: sendBudgetNotifications,
                    onShiftChange: sendShiftNotifications,
                    onSplitBillChange: sendSplitBillNotifications,
                    onSavingsChange: sendSavingsNotifications
                )
            )
            .modifier(
                WidgetBudgetUpdateModifier(
                    appState: appState,
                    onUpdate: updateWidgetSnapshot
                )
            )
            .modifier(
                WidgetDataUpdateModifier(
                    transactionsVM: transactionsVM,
                    plannerVM: plannerVM,
                    onUpdate: updateWidgetSnapshot
                )
            )
    }

    @ViewBuilder
    private var rootContent: some View {
        if !authVM.hasCompletedOnboarding {
            SplashView()
        } else if !authVM.isAuthenticated {
            WelcomeView()
        } else if !authVM.hasCompletedSetup {
            SetupBudgetView()
        } else {
            MainTabView()
                .id(authVM.isAuthenticated)
        }
    }

    private var rootBase: some View {
        ZStack {
            AppBackground()
            rootContent
        }
    }

    private func handleAuthChange(_ isAuthed: Bool) {
        if isAuthed, let uid = Auth.auth().currentUser?.uid {
            transactionsVM.loadCached(uid: uid)
            transactionsVM.loadRemote(uid: uid)
            transactionsVM.startListener(uid: uid)
            savingsVM.loadCached(uid: uid)
            savingsVM.loadRemote(uid: uid)
            savingsVM.startListener(uid: uid)
            plannerVM.loadRemote()
            plannerVM.startListeners()
            splitBillsVM.startListener()
        } else {
            transactionsVM.stopListener()
            transactionsVM.transactions = []
            savingsVM.stopListener()
            savingsVM.goals = []
            plannerVM.stopListeners()
            plannerVM.importantDates = []
            plannerVM.semesterGoals = []
            plannerVM.workShifts = []
            splitBillsVM.stopListener()
            splitBillsVM.splitBills = []
        }
    }

    private func sendBudgetNotifications() {
        guard authVM.notificationsEnabled else { return }
        let budget = authVM.monthlyBudget
        guard budget > 0 else { return }

        for cat in BudgetCategory.allCases {
            let percent: Double
            switch cat {
            case .needs:   percent = authVM.needsPercent
            case .wants:   percent = authVM.wantsPercent
            case .savings: percent = authVM.savingsPercent
            }
            let limit = budget * (percent / 100)
            if limit <= 0 { continue }

            let spent = transactionsVM.transactions
                .filter { $0.type == .expense && $0.budgetCategory == cat }
                .reduce(0) { $0 + $1.amount }

            if spent >= limit {
                NotificationService.sendLocalNotificationIfNeeded(
                    key: "budget_exceeded_\(cat.rawValue)",
                    title: "Budget exceeded",
                    body: "Your \(cat.rawValue) budget is over the limit.",
                    type: .budget
                )
            } else if spent >= limit * 0.75 {
                NotificationService.sendLocalNotificationIfNeeded(
                    key: "budget_near_\(cat.rawValue)",
                    title: "Budget nearly used",
                    body: "You have used most of your \(cat.rawValue) budget.",
                    type: .budget
                )
            }
        }
    }

    private func sendShiftNotifications() {
        guard authVM.notificationsEnabled else { return }
        let now = Date()
        for shift in plannerVM.workShifts where shift.status == .upcoming {
            guard let shiftDate = parseShiftDate(shift.date) else { continue }
            let interval = shiftDate.timeIntervalSince(now)
            if interval > 0 && interval <= 24 * 3600 {
                NotificationService.sendLocalNotificationIfNeeded(
                    key: "shift_upcoming_\(shift.id)",
                    title: "Upcoming shift",
                    body: "\(shift.role) on \(shift.date)",
                    type: .work
                )
            }
        }
    }

    private func sendSplitBillNotifications() {
        guard authVM.notificationsEnabled else { return }
        guard let uid = authVM.currentUser?.id else { return }

        for bill in splitBillsVM.splitBills {
            if let me = bill.participants.first(where: { $0.userId == uid }), me.status == .invited {
                NotificationService.sendLocalNotificationIfNeeded(
                    key: "split_invited_\(bill.id)",
                    title: "Split bill request",
                    body: "You were invited to split \(bill.title).",
                    type: .planner
                )
            }

            if bill.createdBy == uid {
                let anyPaid = bill.participants.contains { !$0.isCreator && $0.status == .paid }
                if anyPaid {
                    NotificationService.sendLocalNotificationIfNeeded(
                        key: "split_paid_\(bill.id)",
                        title: "Split bill paid",
                        body: "Someone paid their share for \(bill.title).",
                        type: .planner
                    )
                }
            }
        }
    }

    private func sendSavingsNotifications() {
        guard authVM.notificationsEnabled else { return }
        for goal in savingsVM.goals {
            let progress = goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0
            if progress >= 1.0 {
                NotificationService.sendLocalNotificationIfNeeded(
                    key: "goal_complete_\(goal.id)",
                    title: "Goal completed",
                    body: "You reached \(goal.name).",
                    type: .budget
                )
            } else if progress >= 0.75 {
                NotificationService.sendLocalNotificationIfNeeded(
                    key: "goal_near_\(goal.id)",
                    title: "Goal almost there",
                    body: "You are close to \(goal.name).",
                    type: .budget
                )
            }
        }
    }

    private func parseShiftDate(_ dateString: String) -> Date? {
        let cal = Calendar.current
        let fmt1 = DateFormatter()
        fmt1.dateFormat = "MMM d"
        if let d = fmt1.date(from: dateString) {
            let comps = cal.dateComponents([.month, .day], from: d)
            let year = cal.component(.year, from: Date())
            return cal.date(from: DateComponents(year: year, month: comps.month, day: comps.day))
        }
        let fmt2 = DateFormatter()
        fmt2.dateFormat = "MMM yyyy"
        return fmt2.date(from: dateString)
    }

    private func updateWidgetSnapshot() {
        let income = transactionsVM.transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = transactionsVM.transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let balance = appState.monthlyBudget + income - expense

        let needsLimit = appState.monthlyBudget * (appState.needsPercent / 100)
        let wantsLimit = appState.monthlyBudget * (appState.wantsPercent / 100)
        let savingsLimit = appState.monthlyBudget * (appState.savingsPercent / 100)

        let needsSpent = transactionsVM.transactions
            .filter { $0.type == .expense && $0.budgetCategory == .needs }
            .reduce(0) { $0 + $1.amount }
        let wantsSpent = transactionsVM.transactions
            .filter { $0.type == .expense && $0.budgetCategory == .wants }
            .reduce(0) { $0 + $1.amount }
        let savingsSpent = transactionsVM.transactions
            .filter { $0.type == .expense && $0.budgetCategory == .savings }
            .reduce(0) { $0 + $1.amount }

        let needsProgress = needsLimit > 0 ? min(needsSpent / needsLimit, 1.0) : 0
        let wantsProgress = wantsLimit > 0 ? min(wantsSpent / wantsLimit, 1.0) : 0
        let savingsProgress = savingsLimit > 0 ? min(savingsSpent / savingsLimit, 1.0) : 0

        let nextItem = upcomingItem()

        let summary = WidgetSummary(
            monthlyBudget: appState.monthlyBudget,
            balance: balance,
            needsProgress: needsProgress,
            wantsProgress: wantsProgress,
            savingsProgress: savingsProgress,
            nextTitle: nextItem.title,
            nextDateText: nextItem.subtitle,
            updatedAt: Date()
        )
        WidgetDataStore.save(summary)
    }

    private func upcomingItem() -> (title: String, subtitle: String) {
        let upcomingShift = plannerVM.workShifts
            .filter { $0.status == .upcoming }
            .compactMap { shift -> (date: Date, text: String, role: String)? in
                guard let d = parseShiftDate(shift.date) else { return nil }
                let text = "\(shift.date) · \(shift.role)"
                return (d, text, shift.role)
            }
            .sorted { $0.date < $1.date }
            .first

        if let shift = upcomingShift {
            return ("Upcoming shift", shift.text)
        }

        let upcomingDate = plannerVM.importantDates
            .filter { $0.date >= Date() }
            .sorted { $0.date < $1.date }
            .first

        if let item = upcomingDate {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            let dateText = fmt.string(from: item.date)
            return ("Important date", "\(dateText) · \(item.title)")
        }

        return ("No upcoming", "Check planner")
    }
}

private struct RootLifecycleModifier: ViewModifier {
    let authVM: AuthViewModel
    let transactionsVM: TransactionsViewModel
    let savingsVM: SavingsGoalsViewModel
    let plannerVM: PlannerViewModel
    let splitBillsVM: SplitBillsViewModel
    let scenePhase: ScenePhase
    let lastBackgroundKey: String
    @Binding var lastBackgroundAt: Date?
    let onAuthChange: (Bool) -> Void
    let onBudgetChange: () -> Void
    let onShiftChange: () -> Void
    let onSplitBillChange: () -> Void
    let onSavingsChange: () -> Void

    func body(content: Content) -> some View {
        content
            .modifier(RootAnimationModifier(authVM: authVM))
            .modifier(
                RootSessionModifier(
                    authVM: authVM,
                    scenePhase: scenePhase,
                    lastBackgroundKey: lastBackgroundKey,
                    lastBackgroundAt: $lastBackgroundAt
                )
            )
            .modifier(
                RootNotificationTriggersModifier(
                    authVM: authVM,
                    transactionsVM: transactionsVM,
                    savingsVM: savingsVM,
                    plannerVM: plannerVM,
                    splitBillsVM: splitBillsVM,
                    onAuthChange: onAuthChange,
                    onBudgetChange: onBudgetChange,
                    onShiftChange: onShiftChange,
                    onSplitBillChange: onSplitBillChange,
                    onSavingsChange: onSavingsChange
                )
            )
    }
}

private struct RootAnimationModifier: ViewModifier {
    let authVM: AuthViewModel

    func body(content: Content) -> some View {
        content
            .animation(.easeInOut(duration: 0.35), value: authVM.isAuthenticated)
            .animation(.easeInOut(duration: 0.35), value: authVM.hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.35), value: authVM.hasCompletedSetup)
    }
}

private struct RootSessionModifier: ViewModifier {
    let authVM: AuthViewModel
    let scenePhase: ScenePhase
    let lastBackgroundKey: String
    @Binding var lastBackgroundAt: Date?

    func body(content: Content) -> some View {
        content
            .onAppear {
                if authVM.hasCompletedOnboarding {
                    authVM.signOut()
                }
                if let ts = UserDefaults.standard.object(forKey: lastBackgroundKey) as? TimeInterval {
                    let last = Date(timeIntervalSince1970: ts)
                    let elapsed = Date().timeIntervalSince(last)
                    if elapsed >= authVM.sessionTimeoutSeconds {
                        authVM.signOut()
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background:
                    lastBackgroundAt = Date()
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastBackgroundKey)
                case .active:
                    if authVM.isAuthenticated, let last = lastBackgroundAt {
                        let elapsed = Date().timeIntervalSince(last)
                        if elapsed >= authVM.sessionTimeoutSeconds {
                            authVM.signOut()
                        }
                    }
                    lastBackgroundAt = nil
                default:
                    break
                }
            }
    }
}

private struct RootNotificationTriggersModifier: ViewModifier {
    let authVM: AuthViewModel
    let transactionsVM: TransactionsViewModel
    let savingsVM: SavingsGoalsViewModel
    let plannerVM: PlannerViewModel
    let splitBillsVM: SplitBillsViewModel
    let onAuthChange: (Bool) -> Void
    let onBudgetChange: () -> Void
    let onShiftChange: () -> Void
    let onSplitBillChange: () -> Void
    let onSavingsChange: () -> Void

    func body(content: Content) -> some View {
        content
            .modifier(
                AuthChangeModifier(
                    authVM: authVM,
                    onAuthChange: onAuthChange
                )
            )
            .modifier(
                BudgetChangeModifier(
                    authVM: authVM,
                    transactionsVM: transactionsVM,
                    onBudgetChange: onBudgetChange
                )
            )
            .modifier(
                PlannerChangeModifier(
                    authVM: authVM,
                    plannerVM: plannerVM,
                    onShiftChange: onShiftChange
                )
            )
            .modifier(
                SplitBillChangeModifier(
                    authVM: authVM,
                    splitBillsVM: splitBillsVM,
                    onSplitBillChange: onSplitBillChange
                )
            )
            .modifier(
                SavingsChangeModifier(
                    authVM: authVM,
                    savingsVM: savingsVM,
                    onSavingsChange: onSavingsChange
                )
            )
    }
}

private struct WidgetBudgetUpdateModifier: ViewModifier {
    let appState: AppState
    let onUpdate: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                onUpdate()
            }
            .onChange(of: appState.monthlyBudget) { _, _ in onUpdate() }
            .onChange(of: appState.needsPercent) { _, _ in onUpdate() }
            .onChange(of: appState.wantsPercent) { _, _ in onUpdate() }
            .onChange(of: appState.savingsPercent) { _, _ in onUpdate() }
    }
}

private struct WidgetDataUpdateModifier: ViewModifier {
    let transactionsVM: TransactionsViewModel
    let plannerVM: PlannerViewModel
    let onUpdate: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: transactionsVM.transactions) { _, _ in onUpdate() }
            .onChange(of: plannerVM.workShifts) { _, _ in onUpdate() }
            .onChange(of: plannerVM.importantDates) { _, _ in onUpdate() }
    }
}

private struct AuthChangeModifier: ViewModifier {
    let authVM: AuthViewModel
    let onAuthChange: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: authVM.isAuthenticated) { _, isAuthed in
                onAuthChange(isAuthed)
            }
            .onChange(of: authVM.notificationsEnabled) { _, enabled in
                if enabled {
                    NotificationService.requestAuthorization()
                }
            }
    }
}

private struct BudgetChangeModifier: ViewModifier {
    let authVM: AuthViewModel
    let transactionsVM: TransactionsViewModel
    let onBudgetChange: () -> Void
    @State private var didHandle = false

    func body(content: Content) -> some View {
        content
            .onChange(of: authVM.isAuthenticated) { _, _ in
                didHandle = false
            }
            .onChange(of: transactionsVM.transactions) { _, _ in
                if !didHandle {
                    didHandle = true
                    return
                }
                if authVM.notificationsEnabled {
                    onBudgetChange()
                }
            }
    }
}

private struct PlannerChangeModifier: ViewModifier {
    let authVM: AuthViewModel
    let plannerVM: PlannerViewModel
    let onShiftChange: () -> Void
    @State private var didHandle = false

    func body(content: Content) -> some View {
        content
            .onChange(of: authVM.isAuthenticated) { _, _ in
                didHandle = false
            }
            .onChange(of: plannerVM.workShifts) { _, _ in
                if !didHandle {
                    didHandle = true
                    return
                }
                onShiftChange()
            }
    }
}

private struct SplitBillChangeModifier: ViewModifier {
    let authVM: AuthViewModel
    let splitBillsVM: SplitBillsViewModel
    let onSplitBillChange: () -> Void
    @State private var didHandle = false

    func body(content: Content) -> some View {
        content
            .onChange(of: authVM.isAuthenticated) { _, _ in
                didHandle = false
            }
            .onChange(of: splitBillsVM.splitBills) { _, _ in
                if !didHandle {
                    didHandle = true
                    return
                }
                onSplitBillChange()
            }
    }
}

private struct SavingsChangeModifier: ViewModifier {
    let authVM: AuthViewModel
    let savingsVM: SavingsGoalsViewModel
    let onSavingsChange: () -> Void
    @State private var didHandle = false

    func body(content: Content) -> some View {
        content
            .onChange(of: authVM.isAuthenticated) { _, _ in
                didHandle = false
            }
            .onChange(of: savingsVM.goals) { _, _ in
                if !didHandle {
                    didHandle = true
                    return
                }
                onSavingsChange()
            }
    }
}
