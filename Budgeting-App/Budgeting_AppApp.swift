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
    @Published var savingsGoals: [SavingsGoal] = []
    @Published var sessionTimeoutSeconds: TimeInterval = 30
    @Published var splitBills: [SplitBill] = []

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
            startSplitBillListeners()
            startTransactionListener()
            startSavingsGoalsListener()
            flushPendingWrites(uid: user.uid)
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
            stopTransactionListener()
            stopSplitBillListeners()
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
    @StateObject private var appState = AppState()
    @StateObject private var transactionsVM: TransactionsViewModel
    @StateObject private var savingsVM: SavingsGoalsViewModel
    @StateObject private var plannerVM: PlannerViewModel

    init() {
            FirebaseApp.configure()
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
        }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(transactionsVM)
                .environmentObject(savingsVM)
                .environmentObject(plannerVM)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}

// MARK: - Root Router
// Decides which screen to show based on app state.
// Splash → Setup → Welcome/Login → Main app
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var transactionsVM: TransactionsViewModel
    @EnvironmentObject var savingsVM: SavingsGoalsViewModel
    @EnvironmentObject var plannerVM: PlannerViewModel
    @Environment(\.scenePhase) var scenePhase
    @State private var lastBackgroundAt: Date?
    private let lastBackgroundKey = "lastBackgroundAt"

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
                            .id(appState.isAuthenticated)
                    }
                }
            }
        .animation(.easeInOut(duration: 0.35), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedSetup)
        .onAppear {
            if appState.hasCompletedOnboarding {
                appState.signOut()
            }
            if let ts = UserDefaults.standard.object(forKey: lastBackgroundKey) as? TimeInterval {
                let last = Date(timeIntervalSince1970: ts)
                let elapsed = Date().timeIntervalSince(last)
                if elapsed >= appState.sessionTimeoutSeconds {
                    appState.signOut()
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                lastBackgroundAt = Date()
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastBackgroundKey)
            case .active:
                if appState.isAuthenticated, let last = lastBackgroundAt {
                    let elapsed = Date().timeIntervalSince(last)
                    if elapsed >= appState.sessionTimeoutSeconds {
                        appState.signOut()
                    }
                }
                lastBackgroundAt = nil
            default:
                break
            }
        }
        .onChange(of: appState.isAuthenticated) { _, isAuthed in
            if isAuthed, let uid = Auth.auth().currentUser?.uid {
                transactionsVM.loadCached(uid: uid)
                transactionsVM.loadRemote(uid: uid)
                transactionsVM.startListener(uid: uid)
                savingsVM.loadCached(uid: uid)
                savingsVM.loadRemote(uid: uid)
                savingsVM.startListener(uid: uid)
                plannerVM.loadRemote()
                plannerVM.startListeners()
            } else {
                transactionsVM.stopListener()
                transactionsVM.transactions = []
                savingsVM.stopListener()
                savingsVM.goals = []
                plannerVM.stopListeners()
                plannerVM.importantDates = []
                plannerVM.semesterGoals = []
                plannerVM.workShifts = []
            }
        }
    }
}
