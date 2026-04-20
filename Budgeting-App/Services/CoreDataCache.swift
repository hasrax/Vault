//
//  CoreDataCache.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-04-02.
//

import CoreData

struct PendingWriteItem {
    let id: UUID
    let type: String
    let payload: String
    let createdAt: Date
}

final class CoreDataCache {
    static let shared = CoreDataCache()

    private let context: NSManagedObjectContext

    private init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Transactions
    func fetchTransactions(ownerId: String) -> [Transaction] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedTransaction")
        request.predicate = NSPredicate(format: "ownerId == %@", ownerId)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        guard let results = try? context.fetch(request) else { return [] }
        return results.compactMap { obj in
            guard
                let id = obj.value(forKey: "id") as? UUID,
                let name = obj.value(forKey: "name") as? String,
                let typeRaw = obj.value(forKey: "type") as? String,
                let budgetRaw = obj.value(forKey: "budgetCategory") as? String,
                let date = obj.value(forKey: "date") as? Date
            else { return nil }

            let amount = obj.value(forKey: "amount") as? Double ?? 0
            let note = obj.value(forKey: "note") as? String ?? ""
            let receiptImageUrl = obj.value(forKey: "receiptImageUrl") as? String
            let receiptImageBase64 = obj.value(forKey: "receiptImageBase64") as? String
            let linkedShiftId = obj.value(forKey: "linkedShiftId") as? String
            let linkedSplitBillId = obj.value(forKey: "linkedSplitBillId") as? String

            return Transaction(
                id: id,
                name: name,
                amount: amount,
                type: TransactionType(rawValue: typeRaw) ?? .expense,
                category: nil,
                incomeSource: nil,
                budgetCategory: BudgetCategory(rawValue: budgetRaw) ?? .wants,
                date: date,
                note: note,
                linkedShiftId: linkedShiftId,
                linkedSplitBillId: linkedSplitBillId,
                receiptImageUrl: receiptImageUrl,
                receiptImageBase64: receiptImageBase64
            )
        }
    }

    func replaceTransactions(_ items: [Transaction], ownerId: String) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedTransaction")
        fetch.predicate = NSPredicate(format: "ownerId == %@", ownerId)
        let delete = NSBatchDeleteRequest(fetchRequest: fetch)
        _ = try? context.execute(delete)
        items.forEach { upsertTransaction($0, ownerId: ownerId, save: false) }
        saveContext()
    }

    func upsertTransaction(_ tx: Transaction, ownerId: String, save: Bool = true) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedTransaction")
        request.predicate = NSPredicate(format: "id == %@ AND ownerId == %@", tx.id as CVarArg, ownerId)
        let obj = (try? context.fetch(request))?.first ?? NSManagedObject(entity: entity("CachedTransaction"), insertInto: context)

        obj.setValue(tx.id, forKey: "id")
        obj.setValue(ownerId, forKey: "ownerId")
        obj.setValue(tx.name, forKey: "name")
        obj.setValue(tx.amount, forKey: "amount")
        obj.setValue(tx.type.rawValue, forKey: "type")
        obj.setValue(tx.budgetCategory.rawValue, forKey: "budgetCategory")
        obj.setValue(tx.date, forKey: "date")
        obj.setValue(tx.note, forKey: "note")
        obj.setValue(tx.receiptImageUrl, forKey: "receiptImageUrl")
        obj.setValue(tx.receiptImageBase64, forKey: "receiptImageBase64")
        obj.setValue(tx.linkedShiftId, forKey: "linkedShiftId")
        obj.setValue(tx.linkedSplitBillId, forKey: "linkedSplitBillId")

        if save { saveContext() }
    }

    func deleteTransactions(_ ids: [UUID], ownerId: String) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedTransaction")
        request.predicate = NSPredicate(format: "ownerId == %@ AND id IN %@", ownerId, ids)
        let delete = NSBatchDeleteRequest(fetchRequest: request)
        _ = try? context.execute(delete)
        saveContext()
    }

    // MARK: - Savings Goals
    func fetchSavingsGoals(ownerId: String) -> [SavingsGoal] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedSavingsGoal")
        request.predicate = NSPredicate(format: "ownerId == %@", ownerId)
        guard let results = try? context.fetch(request) else { return [] }
        return results.compactMap { obj in
            guard
                let id = obj.value(forKey: "id") as? UUID,
                let name = obj.value(forKey: "name") as? String,
                let icon = obj.value(forKey: "icon") as? String,
                let colorHex = obj.value(forKey: "colorHex") as? String
            else { return nil }

            let targetAmount = obj.value(forKey: "targetAmount") as? Double ?? 0
            let currentAmount = obj.value(forKey: "currentAmount") as? Double ?? 0
            let deadline = obj.value(forKey: "deadline") as? Date

            return SavingsGoal(
                id: id,
                name: name,
                icon: icon,
                colorHex: colorHex,
                targetAmount: targetAmount,
                currentAmount: currentAmount,
                deadline: deadline
            )
        }
    }

    func replaceSavingsGoals(_ items: [SavingsGoal], ownerId: String) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedSavingsGoal")
        fetch.predicate = NSPredicate(format: "ownerId == %@", ownerId)
        let delete = NSBatchDeleteRequest(fetchRequest: fetch)
        _ = try? context.execute(delete)
        items.forEach { upsertSavingsGoal($0, ownerId: ownerId, save: false) }
        saveContext()
    }

    func upsertSavingsGoal(_ goal: SavingsGoal, ownerId: String, save: Bool = true) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedSavingsGoal")
        request.predicate = NSPredicate(format: "id == %@ AND ownerId == %@", goal.id as CVarArg, ownerId)
        let obj = (try? context.fetch(request))?.first ?? NSManagedObject(entity: entity("CachedSavingsGoal"), insertInto: context)

        obj.setValue(goal.id, forKey: "id")
        obj.setValue(ownerId, forKey: "ownerId")
        obj.setValue(goal.name, forKey: "name")
        obj.setValue(goal.icon, forKey: "icon")
        obj.setValue(goal.colorHex, forKey: "colorHex")
        obj.setValue(goal.targetAmount, forKey: "targetAmount")
        obj.setValue(goal.currentAmount, forKey: "currentAmount")
        obj.setValue(goal.deadline, forKey: "deadline")

        if save { saveContext() }
    }

    func deleteSavingsGoal(_ id: UUID, ownerId: String) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedSavingsGoal")
        request.predicate = NSPredicate(format: "ownerId == %@ AND id == %@", ownerId, id as CVarArg)
        let delete = NSBatchDeleteRequest(fetchRequest: request)
        _ = try? context.execute(delete)
        saveContext()
    }

    // MARK: - User Profile
    func fetchUserProfile(ownerId: String) -> UserProfile? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedUserProfile")
        request.predicate = NSPredicate(format: "ownerId == %@", ownerId)
        guard let obj = try? context.fetch(request).first else { return nil }

        let id = obj.value(forKey: "id") as? String ?? ownerId
        let name = obj.value(forKey: "name") as? String ?? ""
        let email = obj.value(forKey: "email") as? String ?? ""
        let photoURL = obj.value(forKey: "photoURL") as? String
        let monthlyBudget = obj.value(forKey: "monthlyBudget") as? Double
        let needsPercent = obj.value(forKey: "needsPercent") as? Double
        let wantsPercent = obj.value(forKey: "wantsPercent") as? Double
        let savingsPercent = obj.value(forKey: "savingsPercent") as? Double
        let hasCompletedSetup = obj.value(forKey: "hasCompletedSetup") as? Bool ?? false

        return UserProfile(
            id: id,
            name: name,
            email: email,
            createdAt: nil,
            photoURL: photoURL,
            photoBase64: nil,
            monthlyBudget: monthlyBudget,
            needsPercent: needsPercent,
            wantsPercent: wantsPercent,
            savingsPercent: savingsPercent,
            hasCompletedSetup: hasCompletedSetup
        )
    }

    func saveUserProfile(_ profile: UserProfile, ownerId: String) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedUserProfile")
        request.predicate = NSPredicate(format: "ownerId == %@", ownerId)
        let obj = (try? context.fetch(request))?.first ?? NSManagedObject(entity: entity("CachedUserProfile"), insertInto: context)

        obj.setValue(profile.id, forKey: "id")
        obj.setValue(ownerId, forKey: "ownerId")
        obj.setValue(profile.name, forKey: "name")
        obj.setValue(profile.email, forKey: "email")
        obj.setValue(profile.photoURL, forKey: "photoURL")
        obj.setValue(profile.monthlyBudget, forKey: "monthlyBudget")
        obj.setValue(profile.needsPercent, forKey: "needsPercent")
        obj.setValue(profile.wantsPercent, forKey: "wantsPercent")
        obj.setValue(profile.savingsPercent, forKey: "savingsPercent")
        obj.setValue(profile.hasCompletedSetup, forKey: "hasCompletedSetup")

        saveContext()
    }

    // MARK: - Pending Writes
    func enqueuePendingWrite(ownerId: String, type: String, payload: String) {
        let obj = NSManagedObject(entity: entity("PendingWrite"), insertInto: context)
        obj.setValue(UUID(), forKey: "id")
        obj.setValue(ownerId, forKey: "ownerId")
        obj.setValue(type, forKey: "type")
        obj.setValue(payload, forKey: "payload")
        obj.setValue(Date(), forKey: "createdAt")
        saveContext()
    }

    func fetchPendingWrites(ownerId: String) -> [PendingWriteItem] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PendingWrite")
        request.predicate = NSPredicate(format: "ownerId == %@", ownerId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        guard let results = try? context.fetch(request) else { return [] }
        return results.compactMap { obj in
            guard
                let id = obj.value(forKey: "id") as? UUID,
                let type = obj.value(forKey: "type") as? String,
                let payload = obj.value(forKey: "payload") as? String,
                let createdAt = obj.value(forKey: "createdAt") as? Date
            else { return nil }
            return PendingWriteItem(id: id, type: type, payload: payload, createdAt: createdAt)
        }
    }

    func deletePendingWrite(_ id: UUID) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PendingWrite")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let delete = NSBatchDeleteRequest(fetchRequest: request)
        _ = try? context.execute(delete)
        saveContext()
    }

    // MARK: - Helpers
    private func entity(_ name: String) -> NSEntityDescription {
        NSEntityDescription.entity(forEntityName: name, in: context) ?? NSEntityDescription()
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        try? context.save()
    }
}
