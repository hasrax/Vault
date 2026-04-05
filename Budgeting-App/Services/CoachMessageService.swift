//
//  CoachMessageService.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-04-05.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct CoachMessageService {
    private static var db: Firestore { Firestore.firestore() }

    private static func userCollection() -> CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid).collection("coachMessages")
    }

    static func addMessage(_ message: CoachMessage, completion: ((Error?) -> Void)? = nil) {
        guard let col = userCollection() else {
            completion?(NSError(domain: "CoachMessageService", code: 401))
            return
        }
        let data: [String: Any] = [
            "text": message.text,
            "isFromUser": message.isFromUser,
            "riskLevel": message.riskLevel?.rawValue as Any,
            "createdAt": Timestamp(date: message.createdAt)
        ]
        col.document(message.id.uuidString).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func fetchMessages(limit: Int = 200, completion: @escaping (Result<[CoachMessage], Error>) -> Void) {
        guard let col = userCollection() else {
            completion(.failure(NSError(domain: "CoachMessageService", code: 401)))
            return
        }
        col.order(by: "createdAt", descending: true).limit(to: limit).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let items = snapshot?.documents.map(decodeMessage) ?? []
            let sorted = items.sorted { $0.createdAt < $1.createdAt }
            completion(.success(sorted))
        }
    }

    static func listenMessages(limit: Int = 200, completion: @escaping (Result<[CoachMessage], Error>) -> Void) -> ListenerRegistration? {
        guard let col = userCollection() else {
            completion(.failure(NSError(domain: "CoachMessageService", code: 401)))
            return nil
        }
        return col.order(by: "createdAt", descending: true).limit(to: limit).addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let items = snapshot?.documents.map(decodeMessage) ?? []
            let sorted = items.sorted { $0.createdAt < $1.createdAt }
            completion(.success(sorted))
        }
    }

    private static func decodeMessage(_ doc: QueryDocumentSnapshot) -> CoachMessage {
        let data = doc.data()
        let text = data["text"] as? String ?? ""
        let isFromUser = data["isFromUser"] as? Bool ?? false
        let riskRaw = data["riskLevel"] as? String
        let riskLevel = riskRaw.flatMap(CoachMessage.RiskLevel.init(rawValue:))
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return CoachMessage(
            id: UUID(uuidString: doc.documentID) ?? UUID(),
            text: text,
            isFromUser: isFromUser,
            riskLevel: riskLevel,
            createdAt: createdAt
        )
    }
}
