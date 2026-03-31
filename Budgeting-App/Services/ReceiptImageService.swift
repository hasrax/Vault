//
//  ReceiptImageService.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-31.
//

import UIKit
import FirebaseAuth
import FirebaseStorage

struct ReceiptImageService {
    static func encodeReceiptImage(image: UIImage, maxDimension: CGFloat = 640, quality: CGFloat = 0.55) -> String? {
        guard let resized = image.scaledDown(maxDimension: maxDimension),
              let data = resized.jpegData(compressionQuality: quality) else { return nil }
        return data.base64EncodedString()
    }

    static func uploadReceiptImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "ReceiptImageService", code: 401)))
            return
        }
        guard let resized = image.scaledDown(maxDimension: 1600),
              let data = resized.jpegData(compressionQuality: 0.65) else {
            completion(.failure(NSError(domain: "ReceiptImageService", code: 1)))
            return
        }

        let id = UUID().uuidString
        let ref = Storage.storage().reference().child("users/\(uid)/receipts/\(id).jpg")
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
