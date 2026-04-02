//
//  ProfileImageService.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-30.
//

import UIKit
import FirebaseStorage

struct ProfileImageService {
    static func uploadProfileImage(uid: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            completion(.failure(NSError(domain: "ProfileImageService", code: 1)))
            return
        }
        let ref = Storage.storage().reference().child("users/\(uid)/profile.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        ref.putData(data, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(url?.absoluteString ?? ""))
            }
        }
    }
}
