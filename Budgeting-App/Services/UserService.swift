//
//  UserService.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-30.
//

import Foundation
import FirebaseFirestore

struct UserService {
    private static let usersCollection = Firestore.firestore().collection("users")

    static func createUserProfile(
        uid: String,
        name: String,
        email: String,
        monthlyBudget: Double = 45000,
        needsPercent: Double = 50,
        wantsPercent: Double = 25,
        savingsPercent: Double = 25,
        hasCompletedSetup: Bool = false,
        completion: @escaping (Result<UserProfile, Error>) -> Void
    ) {
        let nameLower = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let emailLower = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let data: [String: Any] = [
            "name": name,
            "email": email,
            "nameLower": nameLower,
            "emailLower": emailLower,
            "createdAt": FieldValue.serverTimestamp(),
            "monthlyBudget": monthlyBudget,
            "needsPercent": needsPercent,
            "wantsPercent": wantsPercent,
            "savingsPercent": savingsPercent,
            "hasCompletedSetup": hasCompletedSetup,
            "photoURL": NSNull(),
            "carryOverBalance": 0,
            "budgetHistory": []
        ]
        usersCollection.document(uid).setData(data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let profile = UserProfile(
                id: uid,
                name: name,
                email: email,
                createdAt: Date(),
                photoURL: nil,
                monthlyBudget: monthlyBudget,
                needsPercent: needsPercent,
                wantsPercent: wantsPercent,
                savingsPercent: savingsPercent,
                hasCompletedSetup: hasCompletedSetup
            )
            completion(.success(profile))
        }
    }

    static func fetchUserProfile(
        uid: String,
        completion: @escaping (Result<UserProfile, Error>) -> Void
    ) {
        usersCollection.document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "UserService", code: 404)))
                return
            }
            let name = data["name"] as? String ?? "User"
            let email = data["email"] as? String ?? ""
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            let photoURL = data["photoURL"] as? String
            let monthlyBudget = data["monthlyBudget"] as? Double
            let needsPercent = data["needsPercent"] as? Double
            let wantsPercent = data["wantsPercent"] as? Double
            let savingsPercent = data["savingsPercent"] as? Double
            let hasCompletedSetup = data["hasCompletedSetup"] as? Bool ?? false
            let profile = UserProfile(
                id: uid,
                name: name,
                email: email,
                createdAt: createdAt,
                photoURL: photoURL,
                monthlyBudget: monthlyBudget,
                needsPercent: needsPercent,
                wantsPercent: wantsPercent,
                savingsPercent: savingsPercent,
                hasCompletedSetup: hasCompletedSetup
            )
            completion(.success(profile))
        }
    }

    static func fetchUserByEmail(
        email: String,
        completion: @escaping (Result<UserProfile, Error>) -> Void
    ) {
        let emailLower = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        usersCollection.whereField("emailLower", isEqualTo: emailLower).limit(to: 1).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let doc = snapshot?.documents.first else {
                completion(.failure(NSError(domain: "UserService", code: 404)))
                return
            }
            let data = doc.data()
            let name = data["name"] as? String ?? "User"
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            let photoURL = data["photoURL"] as? String
            let monthlyBudget = data["monthlyBudget"] as? Double
            let needsPercent = data["needsPercent"] as? Double
            let wantsPercent = data["wantsPercent"] as? Double
            let savingsPercent = data["savingsPercent"] as? Double
            let hasCompletedSetup = data["hasCompletedSetup"] as? Bool ?? false
            let profile = UserProfile(
                id: doc.documentID,
                name: name,
                email: emailLower,
                createdAt: createdAt,
                photoURL: photoURL,
                monthlyBudget: monthlyBudget,
                needsPercent: needsPercent,
                wantsPercent: wantsPercent,
                savingsPercent: savingsPercent,
                hasCompletedSetup: hasCompletedSetup
            )
            completion(.success(profile))
        }
    }

    static func updateProfile(
        uid: String,
        name: String,
        email: String,
        photoURL: String?,
        completion: ((Error?) -> Void)? = nil
    ) {
        let nameLower = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let emailLower = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var data: [String: Any] = [
            "name": name,
            "email": email,
            "nameLower": nameLower,
            "emailLower": emailLower
        ]
        if let photoURL = photoURL {
            data["photoURL"] = photoURL
        }
        usersCollection.document(uid).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func updateSearchFields(
        uid: String,
        name: String,
        email: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        let nameLower = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let emailLower = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let data: [String: Any] = [
            "nameLower": nameLower,
            "emailLower": emailLower
        ]
        usersCollection.document(uid).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func searchUsers(
        query: String,
        limit: Int = 10,
        completion: @escaping (Result<[UserProfile], Error>) -> Void
    ) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            completion(.success([]))
            return
        }

        let group = DispatchGroup()
        var results: [UserProfile] = []
        var errors: [Error] = []

        func parse(_ docs: [QueryDocumentSnapshot], emailFallback: String? = nil) {
            for doc in docs {
                let data = doc.data()
                let name = data["name"] as? String ?? "User"
                let email = (data["email"] as? String) ?? emailFallback ?? ""
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                let photoURL = data["photoURL"] as? String
                let monthlyBudget = data["monthlyBudget"] as? Double
                let needsPercent = data["needsPercent"] as? Double
                let wantsPercent = data["wantsPercent"] as? Double
                let savingsPercent = data["savingsPercent"] as? Double
                let hasCompletedSetup = data["hasCompletedSetup"] as? Bool ?? false
                let profile = UserProfile(
                    id: doc.documentID,
                    name: name,
                    email: email,
                    createdAt: createdAt,
                    photoURL: photoURL,
                    monthlyBudget: monthlyBudget,
                    needsPercent: needsPercent,
                    wantsPercent: wantsPercent,
                    savingsPercent: savingsPercent,
                    hasCompletedSetup: hasCompletedSetup
                )
                if !results.contains(where: { $0.id == profile.id }) {
                    results.append(profile)
                }
            }
        }

        group.enter()
        usersCollection
            .order(by: "nameLower")
            .start(at: [trimmed])
            .end(at: [trimmed + "\u{f8ff}"])
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error { errors.append(error) }
                if let docs = snapshot?.documents { parse(docs) }
                group.leave()
            }

        group.enter()
        usersCollection
            .order(by: "emailLower")
            .start(at: [trimmed])
            .end(at: [trimmed + "\u{f8ff}"])
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error { errors.append(error) }
                if let docs = snapshot?.documents { parse(docs) }
                group.leave()
            }

        group.notify(queue: .main) {
            if let error = errors.first {
                completion(.failure(error))
            } else {
                completion(.success(results))
            }
        }
    }

    static func updateBudget(
        uid: String,
        monthlyBudget: Double,
        needsPercent: Double,
        wantsPercent: Double,
        savingsPercent: Double,
        completion: ((Error?) -> Void)? = nil
    ) {
        let data: [String: Any] = [
            "monthlyBudget": monthlyBudget,
            "needsPercent": needsPercent,
            "wantsPercent": wantsPercent,
            "savingsPercent": savingsPercent,
            "hasCompletedSetup": true
        ]
        usersCollection.document(uid).setData(data, merge: true) { error in
            completion?(error)
        }
    }

    static func deleteUser(uid: String, completion: ((Error?) -> Void)? = nil) {
        usersCollection.document(uid).delete { error in
            completion?(error)
        }
    }
}
