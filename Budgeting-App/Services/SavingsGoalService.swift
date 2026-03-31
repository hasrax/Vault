//
//  SavingsGoalService.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-31.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct SavingsGoalService {
    private static var db: Firestore { Firestore.firestore() }

    private static func userCollection() -> CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid).collection("savingsGoals")
    }

    static func addGoal(_ goal: SavingsGoal, completion: ((Error?) -> Void)? = nil) {
        guard let col = userCollection() else {
            completion?(NSError(domain: "SavingsGoalService", code: 401))
            return
        }
        let data: [String: Any] = [
            "name": goal.name,
            "icon": goal.icon,
            "colorHex": goal.colorHex,
            "targetAmount": goal.targetAmount,
            "currentAmount": goal.currentAmount,
            "deadline": goal.deadline.map { Timestamp(date: $0) } as Any
        ]
        col.document(goal.id.uuidString).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func updateGoal(_ goal: SavingsGoal, completion: ((Error?) -> Void)? = nil) {
        addGoal(goal, completion: completion)
    }

    static func deleteGoal(_ id: UUID, completion: ((Error?) -> Void)? = nil) {
        guard let col = userCollection() else {
            completion?(NSError(domain: "SavingsGoalService", code: 401))
            return
        }
        col.document(id.uuidString).delete { error in
            completion?(error)
        }
    }

    static func listenGoals(completion: @escaping (Result<[SavingsGoal], Error>) -> Void) -> ListenerRegistration? {
        guard let col = userCollection() else {
            completion(.failure(NSError(domain: "SavingsGoalService", code: 401)))
            return nil
        }
        return col.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let goals: [SavingsGoal] = snapshot?.documents.compactMap { doc in
                let data = doc.data()
                let name = data["name"] as? String ?? ""
                let icon = data["icon"] as? String ?? "🎯"
                let colorHex = data["colorHex"] as? String ?? "#22C55E"
                let targetAmount = data["targetAmount"] as? Double ?? 0
                let currentAmount = data["currentAmount"] as? Double ?? 0
                let deadline = (data["deadline"] as? Timestamp)?.dateValue()

                return SavingsGoal(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    name: name,
                    icon: icon,
                    colorHex: colorHex,
                    targetAmount: targetAmount,
                    currentAmount: currentAmount,
                    deadline: deadline
                )
            } ?? []
            completion(.success(goals))
        }
    }
}
