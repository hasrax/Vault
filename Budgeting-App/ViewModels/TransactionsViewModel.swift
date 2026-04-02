//
//  TransactionsViewModel.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-04-02.
//

import Foundation
import FirebaseFirestore

final class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []

    private var listener: ListenerRegistration?
    private let userIdProvider: () -> String?

    init(userIdProvider: @escaping () -> String? = { nil }) {
        self.userIdProvider = userIdProvider
    }

    func loadCached(uid: String) {
        transactions = CoreDataCache.shared.fetchTransactions(ownerId: uid)
    }

    func loadRemote(uid: String) {
        TransactionService.fetchTransactions { result in
            DispatchQueue.main.async {
                if case let .success(items) = result {
                    self.transactions = items
                    CoreDataCache.shared.replaceTransactions(items, ownerId: uid)
                }
            }
        }
    }

    func startListener(uid: String) {
        stopListener()
        listener = TransactionService.listenTransactions { result in
            DispatchQueue.main.async {
                if case let .success(items) = result {
                    self.transactions = items
                    CoreDataCache.shared.replaceTransactions(items, ownerId: uid)
                }
            }
        }
    }

    func stopListener() {
        listener?.remove()
        listener = nil
    }

    func addTransaction(_ tx: Transaction) {
        transactions.insert(tx, at: 0)
        if let uid = userIdProvider() {
            CoreDataCache.shared.upsertTransaction(tx, ownerId: uid)
        }
        TransactionService.addTransaction(tx) { error in
            if error != nil, let uid = self.userIdProvider() {
                if let data = try? JSONEncoder().encode(tx),
                   let payload = String(data: data, encoding: .utf8) {
                    CoreDataCache.shared.enqueuePendingWrite(ownerId: uid, type: "transaction_upsert", payload: payload)
                }
            }
        }
    }

    func updateTransaction(_ tx: Transaction) {
        addTransaction(tx)
    }

    func deleteTransactions(_ ids: [UUID]) {
        transactions.removeAll { ids.contains($0.id) }
        TransactionService.deleteTransactions(ids)
        if let uid = userIdProvider() {
            CoreDataCache.shared.deleteTransactions(ids, ownerId: uid)
        }
    }
}
