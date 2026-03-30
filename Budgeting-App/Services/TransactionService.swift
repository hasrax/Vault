//
//  TransactionService.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-30.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct TransactionService {
    private static var db: Firestore { Firestore.firestore() }

    private static func userCollection() -> CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid).collection("transactions")
    }

    static func addTransaction(_ tx: Transaction, completion: ((Error?) -> Void)? = nil) {
        guard let col = userCollection() else {
            completion?(NSError(domain: "TransactionService", code: 401))
            return
        }
        let data: [String: Any] = [
            "name": tx.name,
            "amount": tx.amount,
            "type": tx.type.rawValue,
            "category": tx.category?.rawValue as Any,
            "incomeSource": tx.incomeSource?.rawValue as Any,
            "budgetCategory": tx.budgetCategory.rawValue,
            "date": Timestamp(date: tx.date),
            "note": tx.note,
            "linkedShiftId": tx.linkedShiftId as Any,
            "linkedSplitBillId": tx.linkedSplitBillId as Any
        ]
        col.document(tx.id.uuidString).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func fetchTransactions(completion: @escaping (Result<[Transaction], Error>) -> Void) {
        guard let col = userCollection() else {
            completion(.failure(NSError(domain: "TransactionService", code: 401)))
            return
        }
        col.order(by: "date", descending: true).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let txs: [Transaction] = snapshot?.documents.compactMap { doc in
                let data = doc.data()
                let name = data["name"] as? String ?? ""
                let amount = data["amount"] as? Double ?? 0
                let typeRaw = data["type"] as? String ?? TransactionType.expense.rawValue
                let type = TransactionType(rawValue: typeRaw) ?? .expense
                let categoryRaw = data["category"] as? String
                let incomeRaw = data["incomeSource"] as? String
                let budgetRaw = data["budgetCategory"] as? String ?? BudgetCategory.wants.rawValue
                let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                let note = data["note"] as? String ?? ""
                let linkedShiftId = data["linkedShiftId"] as? String
                let linkedSplitBillId = data["linkedSplitBillId"] as? String

                return Transaction(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    name: name,
                    amount: amount,
                    type: type,
                    category: categoryRaw.flatMap(ExpenseCategory.init(rawValue:)),
                    incomeSource: incomeRaw.flatMap(IncomeSource.init(rawValue:)),
                    budgetCategory: BudgetCategory(rawValue: budgetRaw) ?? .wants,
                    date: date,
                    note: note,
                    linkedShiftId: linkedShiftId,
                    linkedSplitBillId: linkedSplitBillId
                )
            } ?? []
            completion(.success(txs))
        }
    }

    static func updateTransaction(_ tx: Transaction, completion: ((Error?) -> Void)? = nil) {
        addTransaction(tx, completion: completion)
    }

    static func deleteTransactions(_ ids: [UUID], completion: ((Error?) -> Void)? = nil) {
        guard let col = userCollection() else {
            completion?(NSError(domain: "TransactionService", code: 401))
            return
        }
        let batch = db.batch()
        ids.forEach { id in
            batch.deleteDocument(col.document(id.uuidString))
        }
        batch.commit { error in
            completion?(error)
        }
    }

    static func deleteAllTransactions(completion: ((Error?) -> Void)? = nil) {
        guard let col = userCollection() else {
            completion?(NSError(domain: "TransactionService", code: 401))
            return
        }
        col.getDocuments { snapshot, error in
            if let error = error {
                completion?(error)
                return
            }
            let batch = db.batch()
            snapshot?.documents.forEach { doc in
                batch.deleteDocument(doc.reference)
            }
            batch.commit { err in
                completion?(err)
            }
        }
    }
}
