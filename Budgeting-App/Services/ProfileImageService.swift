//
//  ProfileImageService.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-30.
//

import UIKit
import FirebaseStorage

struct ProfileImageService {
    static func encodeProfileImage(image: UIImage, maxDimension: CGFloat = 512, quality: CGFloat = 0.7) -> String? {
        guard let resized = image.scaledDown(maxDimension: maxDimension),
              let data = resized.jpegData(compressionQuality: quality) else { return nil }
        return data.base64EncodedString()
    }

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

private extension UIImage {
    func scaledDown(maxDimension: CGFloat) -> UIImage? {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
