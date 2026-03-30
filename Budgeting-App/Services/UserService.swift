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
        let data: [String: Any] = [
            "name": name,
            "email": email,
            "createdAt": FieldValue.serverTimestamp(),
            "monthlyBudget": monthlyBudget,
            "needsPercent": needsPercent,
            "wantsPercent": wantsPercent,
            "savingsPercent": savingsPercent,
            "hasCompletedSetup": hasCompletedSetup,
            "photoURL": NSNull()
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
        usersCollection.whereField("email", isEqualTo: email).limit(to: 1).getDocuments { snapshot, error in
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

    static func updateProfile(
        uid: String,
        name: String,
        email: String,
        photoURL: String?,
        completion: ((Error?) -> Void)? = nil
    ) {
        var data: [String: Any] = [
            "name": name,
            "email": email
        ]
        if let photoURL = photoURL {
            data["photoURL"] = photoURL
        }
        usersCollection.document(uid).setData(data, merge: true) { error in
            completion?(error)
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
