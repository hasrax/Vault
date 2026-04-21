//
//  PlannerService.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-30.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct PlannerService {
    private static var db: Firestore { Firestore.firestore() }

    private static func userDoc() -> DocumentReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid)
    }

    static func fetchImportantDates(completion: @escaping (Result<[ImportantDate], Error>) -> Void) {
        guard let doc = userDoc() else {
            completion(.failure(NSError(domain: "PlannerService", code: 401)))
            return
        }
        doc.collection("importantDates").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let items: [ImportantDate] = snapshot?.documents.compactMap { d in
                let data = d.data()
                let title = data["title"] as? String ?? ""
                let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                let typeRaw = data["type"] as? String ?? "event"
                let amount = data["amount"] as? Double
                let icon = data["icon"] as? String ?? "📌"
                let type: ImportantDate.DateType
                switch typeRaw {
                case "bill": type = .bill
                case "income": type = .income
                default: type = .event
                }
                return ImportantDate(
                    id: UUID(uuidString: d.documentID) ?? UUID(),
                    title: title,
                    date: date,
                    type: type,
                    amount: amount,
                    icon: icon
                )
            } ?? []
            completion(.success(items))
        }
    }

    static func addImportantDate(_ item: ImportantDate, completion: ((Error?) -> Void)? = nil) {
        guard let doc = userDoc() else {
            completion?(NSError(domain: "PlannerService", code: 401))
            return
        }
        let typeRaw: String = {
            switch item.type {
            case .bill: return "bill"
            case .income: return "income"
            case .event: return "event"
            }
        }()
        let data: [String: Any] = [
            "title": item.title,
            "date": Timestamp(date: item.date),
            "type": typeRaw,
            "amount": item.amount as Any,
            "icon": item.icon
        ]
        doc.collection("importantDates").document(item.id.uuidString).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func updateImportantDate(_ item: ImportantDate, completion: ((Error?) -> Void)? = nil) {
        addImportantDate(item, completion: completion)
    }

    static func deleteImportantDate(_ id: UUID, completion: ((Error?) -> Void)? = nil) {
        guard let doc = userDoc() else {
            completion?(NSError(domain: "PlannerService", code: 401))
            return
        }
        doc.collection("importantDates").document(id.uuidString).delete { error in
            completion?(error)
        }
    }

    static func fetchSemesterGoals(completion: @escaping (Result<[SemesterGoal], Error>) -> Void) {
        guard let doc = userDoc() else {
            completion(.failure(NSError(domain: "PlannerService", code: 401)))
            return
        }
        doc.collection("semesterGoals").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let items: [SemesterGoal] = snapshot?.documents.compactMap { d in
                let data = d.data()
                let title = data["title"] as? String ?? ""
                let completed = data["completed"] as? Bool ?? false
                let progress = data["progress"] as? Int
                return SemesterGoal(
                    id: UUID(uuidString: d.documentID) ?? UUID(),
                    title: title,
                    completed: completed,
                    progress: progress
                )
            } ?? []
            completion(.success(items))
        }
    }

    static func addSemesterGoal(_ goal: SemesterGoal, completion: ((Error?) -> Void)? = nil) {
        guard let doc = userDoc() else {
            completion?(NSError(domain: "PlannerService", code: 401))
            return
        }
        let data: [String: Any] = [
            "title": goal.title,
            "completed": goal.completed,
            "progress": goal.progress as Any
        ]
        doc.collection("semesterGoals").document(goal.id.uuidString).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func updateSemesterGoal(_ goal: SemesterGoal, completion: ((Error?) -> Void)? = nil) {
        guard let doc = userDoc() else {
            completion?(NSError(domain: "PlannerService", code: 401))
            return
        }
        let data: [String: Any] = [
            "title": goal.title,
            "completed": goal.completed,
            "progress": goal.progress as Any
        ]
        doc.collection("semesterGoals").document(goal.id.uuidString).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func deleteSemesterGoal(_ id: UUID, completion: ((Error?) -> Void)? = nil) {
        guard let doc = userDoc() else {
            completion?(NSError(domain: "PlannerService", code: 401))
            return
        }
        doc.collection("semesterGoals").document(id.uuidString).delete { error in
            completion?(error)
        }
    }

    static func fetchWorkShifts(completion: @escaping (Result<[WorkShift], Error>) -> Void) {
        guard let doc = userDoc() else {
            completion(.failure(NSError(domain: "PlannerService", code: 401)))
            return
        }
        doc.collection("workShifts").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let items: [WorkShift] = snapshot?.documents.compactMap { d in
                let data = d.data()
                let day = data["day"] as? String ?? ""
                let date = data["date"] as? String ?? ""
                let role = data["role"] as? String ?? ""
                let start = data["start"] as? String ?? ""
                let end = data["end"] as? String ?? ""
                let hours = data["hours"] as? Int ?? 0
                let pay = data["pay"] as? Double ?? 0
                let statusRaw = data["status"] as? String ?? "upcoming"
                let status = WorkShift.ShiftStatus(rawValue: statusRaw) ?? .upcoming
                return WorkShift(
                    id: UUID(uuidString: d.documentID) ?? UUID(),
                    day: day,
                    date: date,
                    role: role,
                    start: start,
                    end: end,
                    hours: hours,
                    pay: pay,
                    status: status
                )
            } ?? []
            completion(.success(items))
        }
    }

    static func addWorkShift(_ shift: WorkShift, completion: ((Error?) -> Void)? = nil) {
        guard let doc = userDoc() else {
            completion?(NSError(domain: "PlannerService", code: 401))
            return
        }
        let data: [String: Any] = [
            "day": shift.day,
            "date": shift.date,
            "role": shift.role,
            "start": shift.start,
            "end": shift.end,
            "hours": shift.hours,
            "pay": shift.pay,
            "status": shift.status.rawValue
        ]
        doc.collection("workShifts").document(shift.id.uuidString).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func updateWorkShift(_ shift: WorkShift, completion: ((Error?) -> Void)? = nil) {
        addWorkShift(shift, completion: completion)
    }

    static func deleteWorkShift(_ id: UUID, completion: ((Error?) -> Void)? = nil) {
        guard let doc = userDoc() else {
            completion?(NSError(domain: "PlannerService", code: 401))
            return
        }
        doc.collection("workShifts").document(id.uuidString).delete { error in
            completion?(error)
        }
    }

    static func listenImportantDates(onChange: @escaping (Result<[ImportantDate], Error>) -> Void) -> ListenerRegistration? {
        guard let doc = userDoc() else { return nil }
        return doc.collection("importantDates").addSnapshotListener { snapshot, error in
            if let error = error {
                onChange(.failure(error))
                return
            }
            let items: [ImportantDate] = snapshot?.documents.compactMap { d in
                let data = d.data()
                let title = data["title"] as? String ?? ""
                let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                let typeRaw = data["type"] as? String ?? "event"
                let amount = data["amount"] as? Double
                let icon = data["icon"] as? String ?? "📌"
                let type: ImportantDate.DateType
                switch typeRaw {
                case "bill": type = .bill
                case "income": type = .income
                default: type = .event
                }
                return ImportantDate(
                    id: UUID(uuidString: d.documentID) ?? UUID(),
                    title: title,
                    date: date,
                    type: type,
                    amount: amount,
                    icon: icon
                )
            } ?? []
            onChange(.success(items))
        }
    }

    static func listenSemesterGoals(onChange: @escaping (Result<[SemesterGoal], Error>) -> Void) -> ListenerRegistration? {
        guard let doc = userDoc() else { return nil }
        return doc.collection("semesterGoals").addSnapshotListener { snapshot, error in
            if let error = error {
                onChange(.failure(error))
                return
            }
            let items: [SemesterGoal] = snapshot?.documents.compactMap { d in
                let data = d.data()
                let title = data["title"] as? String ?? ""
                let completed = data["completed"] as? Bool ?? false
                let progress = data["progress"] as? Int
                return SemesterGoal(
                    id: UUID(uuidString: d.documentID) ?? UUID(),
                    title: title,
                    completed: completed,
                    progress: progress
                )
            } ?? []
            onChange(.success(items))
        }
    }

    static func listenWorkShifts(onChange: @escaping (Result<[WorkShift], Error>) -> Void) -> ListenerRegistration? {
        guard let doc = userDoc() else { return nil }
        return doc.collection("workShifts").addSnapshotListener { snapshot, error in
            if let error = error {
                onChange(.failure(error))
                return
            }
            let items: [WorkShift] = snapshot?.documents.compactMap { d in
                let data = d.data()
                let day = data["day"] as? String ?? ""
                let date = data["date"] as? String ?? ""
                let role = data["role"] as? String ?? ""
                let start = data["start"] as? String ?? ""
                let end = data["end"] as? String ?? ""
                let hours = data["hours"] as? Int ?? 0
                let pay = data["pay"] as? Double ?? 0
                let statusRaw = data["status"] as? String ?? "upcoming"
                let status = WorkShift.ShiftStatus(rawValue: statusRaw) ?? .upcoming
                return WorkShift(
                    id: UUID(uuidString: d.documentID) ?? UUID(),
                    day: day,
                    date: date,
                    role: role,
                    start: start,
                    end: end,
                    hours: hours,
                    pay: pay,
                    status: status
                )
            } ?? []
            onChange(.success(items))
        }
    }

    // MARK: - Meal Entries
    static func fetchMealEntries(completion: @escaping (Result<[MealEntry], Error>) -> Void) {
        guard let doc = userDoc() else {
            completion(.failure(NSError(domain: "PlannerService", code: 401)))
            return
        }
        doc.collection("mealEntries").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let items: [MealEntry] = snapshot?.documents.compactMap { d in
                let data = d.data()
                let title = data["title"] as? String ?? ""
                let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                let typeRaw = data["type"] as? String ?? MealType.lunch.rawValue
                let type = MealType(rawValue: typeRaw) ?? .lunch
                let amount = data["amount"] as? Double ?? 0
                let location = data["location"] as? String
                let notes = data["notes"] as? String
                return MealEntry(
                    id: UUID(uuidString: d.documentID) ?? UUID(),
                    title: title,
                    date: date,
                    type: type,
                    amount: amount,
                    location: location,
                    notes: notes
                )
            } ?? []
            completion(.success(items))
        }
    }

    static func addMealEntry(_ entry: MealEntry, completion: ((Error?) -> Void)? = nil) {
        guard let doc = userDoc() else {
            completion?(NSError(domain: "PlannerService", code: 401))
            return
        }
        let data: [String: Any] = [
            "title": entry.title,
            "date": Timestamp(date: entry.date),
            "type": entry.type.rawValue,
            "amount": entry.amount,
            "location": entry.location as Any,
            "notes": entry.notes as Any
        ]
        doc.collection("mealEntries").document(entry.id.uuidString).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func updateMealEntry(_ entry: MealEntry, completion: ((Error?) -> Void)? = nil) {
        addMealEntry(entry, completion: completion)
    }

    static func deleteMealEntry(_ id: UUID, completion: ((Error?) -> Void)? = nil) {
        guard let doc = userDoc() else {
            completion?(NSError(domain: "PlannerService", code: 401))
            return
        }
        doc.collection("mealEntries").document(id.uuidString).delete { error in
            completion?(error)
        }
    }

    static func listenMealEntries(onChange: @escaping (Result<[MealEntry], Error>) -> Void) -> ListenerRegistration? {
        guard let doc = userDoc() else { return nil }
        return doc.collection("mealEntries").addSnapshotListener { snapshot, error in
            if let error = error {
                onChange(.failure(error))
                return
            }
            let items: [MealEntry] = snapshot?.documents.compactMap { d in
                let data = d.data()
                let title = data["title"] as? String ?? ""
                let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                let typeRaw = data["type"] as? String ?? MealType.lunch.rawValue
                let type = MealType(rawValue: typeRaw) ?? .lunch
                let amount = data["amount"] as? Double ?? 0
                let location = data["location"] as? String
                let notes = data["notes"] as? String
                return MealEntry(
                    id: UUID(uuidString: d.documentID) ?? UUID(),
                    title: title,
                    date: date,
                    type: type,
                    amount: amount,
                    location: location,
                    notes: notes
                )
            } ?? []
            onChange(.success(items))
        }
    }

    // MARK: - Study Expenses
    static func fetchStudyExpenses(completion: @escaping (Result<[StudyExpense], Error>) -> Void) {
        guard let doc = userDoc() else {
            completion(.failure(NSError(domain: "PlannerService", code: 401)))
            return
        }
        doc.collection("studyExpenses").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let items: [StudyExpense] = snapshot?.documents.compactMap { d in
                let data = d.data()
                let title = data["title"] as? String ?? ""
                let amount = data["amount"] as? Double ?? 0
                let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                let category = data["category"] as? String ?? "Other"
                let notes = data["notes"] as? String
                return StudyExpense(
                    id: UUID(uuidString: d.documentID) ?? UUID(),
                    title: title,
                    amount: amount,
                    date: date,
                    category: category,
                    notes: notes
                )
            } ?? []
            completion(.success(items))
        }
    }

    static func addStudyExpense(_ expense: StudyExpense, completion: ((Error?) -> Void)? = nil) {
        guard let doc = userDoc() else {
            completion?(NSError(domain: "PlannerService", code: 401))
            return
        }
        let data: [String: Any] = [
            "title": expense.title,
            "amount": expense.amount,
            "date": Timestamp(date: expense.date),
            "category": expense.category,
            "notes": expense.notes as Any
        ]
        doc.collection("studyExpenses").document(expense.id.uuidString).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func updateStudyExpense(_ expense: StudyExpense, completion: ((Error?) -> Void)? = nil) {
        addStudyExpense(expense, completion: completion)
    }

    static func deleteStudyExpense(_ id: UUID, completion: ((Error?) -> Void)? = nil) {
        guard let doc = userDoc() else {
            completion?(NSError(domain: "PlannerService", code: 401))
            return
        }
        doc.collection("studyExpenses").document(id.uuidString).delete { error in
            completion?(error)
        }
    }

    static func listenStudyExpenses(onChange: @escaping (Result<[StudyExpense], Error>) -> Void) -> ListenerRegistration? {
        guard let doc = userDoc() else { return nil }
        return doc.collection("studyExpenses").addSnapshotListener { snapshot, error in
            if let error = error {
                onChange(.failure(error))
                return
            }
            let items: [StudyExpense] = snapshot?.documents.compactMap { d in
                let data = d.data()
                let title = data["title"] as? String ?? ""
                let amount = data["amount"] as? Double ?? 0
                let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                let category = data["category"] as? String ?? "Other"
                let notes = data["notes"] as? String
                return StudyExpense(
                    id: UUID(uuidString: d.documentID) ?? UUID(),
                    title: title,
                    amount: amount,
                    date: date,
                    category: category,
                    notes: notes
                )
            } ?? []
            onChange(.success(items))
        }
    }
}
