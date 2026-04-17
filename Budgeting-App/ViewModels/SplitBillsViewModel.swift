//
//  SplitBillsViewModel.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-04-02.
//

import Foundation
import Combine
import FirebaseFirestore

final class SplitBillsViewModel: ObservableObject {
    @Published var splitBills: [SplitBill] = []

    private var listener: ListenerRegistration?
    private let userIdProvider: () -> String?
    private let currentUserProvider: () -> UserProfile?
    private let transactionsVM: TransactionsViewModel

    init(
        userIdProvider: @escaping () -> String? = { nil },
        currentUserProvider: @escaping () -> UserProfile? = { nil },
        transactionsVM: TransactionsViewModel
    ) {
        self.userIdProvider = userIdProvider
        self.currentUserProvider = currentUserProvider
        self.transactionsVM = transactionsVM
    }

    func startListener() {
        stopListener()
        listener = SplitBillService.listenSplitBills { result in
            DispatchQueue.main.async {
                if case let .success(items) = result {
                    self.splitBills = items.sorted { $0.createdAt > $1.createdAt }
                }
            }
        }
    }

    func stopListener() {
        listener?.remove()
        listener = nil
    }

    func createSplitBill(
        title: String,
        totalAmount: Double,
        splitMethod: SplitMethod,
        participants: [SplitParticipant]
    ) {
        guard let uid = userIdProvider() else { return }
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
        guard let uid = userIdProvider() else { return }
        guard let participant = bill.participants.first(where: { $0.userId == uid }) else { return }
        if participant.status == .paid { return }
        updateSplitBillParticipant(bill, status: .paid)

        let tx = Transaction(
            name: "Split: \(bill.title)",
            amount: participant.shareAmount,
            type: .expense,
            category: nil,
            incomeSource: nil,
            budgetCategory: .wants,
            date: Date(),
            note: "Split bill payment",
            linkedSplitBillId: bill.id.uuidString
        )
        transactionsVM.addTransaction(tx)
    }

    func settleSplitBill(_ bill: SplitBill) {
        guard let uid = userIdProvider() else { return }
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
            transactionsVM.addTransaction(tx)
        }
    }

    func findUserByEmail(_ email: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            completion(.failure(NSError(domain: "SplitBillsViewModel", code: 400)))
            return
        }
        UserService.fetchUserByEmail(email: trimmed, completion: completion)
    }

    func searchUsers(query: String, completion: @escaping (Result<[UserProfile], Error>) -> Void) {
        UserService.searchUsers(query: query, completion: completion)
    }

    private func updateSplitBillParticipant(_ bill: SplitBill, status: SplitParticipantStatus) {
        guard let uid = userIdProvider() else { return }
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
}
