//
//  SplitBillService.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-30.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct SplitBillService {
    private static var db: Firestore { Firestore.firestore() }

    private static func collection() -> CollectionReference {
        db.collection("splitBills")
    }

    static func listenSplitBills(onChange: @escaping (Result<[SplitBill], Error>) -> Void) -> ListenerRegistration? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return collection()
            .whereField("participantIds", arrayContains: uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    onChange(.failure(error))
                    return
                }
                let items: [SplitBill] = snapshot?.documents.compactMap { doc in
                    decodeSplitBill(doc)
                } ?? []
                onChange(.success(items))
            }
    }

    static func addSplitBill(_ bill: SplitBill, completion: ((Error?) -> Void)? = nil) {
        let data = encodeSplitBill(bill)
        collection().document(bill.id.uuidString).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func updateSplitBill(_ bill: SplitBill, completion: ((Error?) -> Void)? = nil) {
        addSplitBill(bill, completion: completion)
    }

    static func deleteSplitBill(_ id: UUID, completion: ((Error?) -> Void)? = nil) {
        collection().document(id.uuidString).delete { error in
            completion?(error)
        }
    }

    private static func encodeSplitBill(_ bill: SplitBill) -> [String: Any] {
        let participants = bill.participants.map { p in
            [
                "userId": p.userId,
                "name": p.name,
                "email": p.email,
                "shareAmount": p.shareAmount,
                "status": p.status.rawValue,
                "isCreator": p.isCreator
            ] as [String: Any]
        }
        return [
            "title": bill.title,
            "totalAmount": bill.totalAmount,
            "createdBy": bill.createdBy,
            "createdAt": Timestamp(date: bill.createdAt),
            "splitMethod": bill.splitMethod.rawValue,
            "status": bill.status.rawValue,
            "participants": participants,
            "participantIds": bill.participantIds
        ]
    }

    private static func decodeSplitBill(_ doc: QueryDocumentSnapshot) -> SplitBill? {
        let data = doc.data()
        let title = data["title"] as? String ?? "Split bill"
        let totalAmount = data["totalAmount"] as? Double ?? 0
        let createdBy = data["createdBy"] as? String ?? ""
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let splitRaw = data["splitMethod"] as? String ?? SplitMethod.equal.rawValue
        let statusRaw = data["status"] as? String ?? SplitBillStatus.open.rawValue
        let splitMethod = SplitMethod(rawValue: splitRaw) ?? .equal
        let status = SplitBillStatus(rawValue: statusRaw) ?? .open
        let participantMaps = data["participants"] as? [[String: Any]] ?? []
        let participants: [SplitParticipant] = participantMaps.compactMap { p in
            let userId = p["userId"] as? String ?? ""
            let name = p["name"] as? String ?? ""
            let email = p["email"] as? String ?? ""
            let shareAmount = p["shareAmount"] as? Double ?? 0
            let statusRaw = p["status"] as? String ?? SplitParticipantStatus.invited.rawValue
            let status = SplitParticipantStatus(rawValue: statusRaw) ?? .invited
            let isCreator = p["isCreator"] as? Bool ?? false
            return SplitParticipant(
                userId: userId,
                name: name,
                email: email,
                shareAmount: shareAmount,
                status: status,
                isCreator: isCreator
            )
        }
        return SplitBill(
            id: UUID(uuidString: doc.documentID) ?? UUID(),
            title: title,
            totalAmount: totalAmount,
            createdBy: createdBy,
            createdAt: createdAt,
            splitMethod: splitMethod,
            status: status,
            participants: participants
        )
    }
}
