//
//  PhotoSaverError.swift
//  Core Video Fudementals
//
//  Created by Adi Mizrahi on 31/08/2025.
//

import Foundation
import Photos

enum PhotoSaverError: Error, LocalizedError {
    case authorizationDenied
    case creationFailed
    var errorDescription: String? {
        switch self {
        case .authorizationDenied: return "Photos access was denied."
        case .creationFailed: return "Could not create photo library asset."
        }
    }
}

enum PhotoSaver {
    /// Saves a video file URL to the user's Photos library with full error handling.
    /// Works on device; on Simulator the Photos app must exist to view results.
    static func saveVideoToPhotos(url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        // On iOS 14+, use .addOnly; earlier falls back to global request.
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    completion(.failure(PhotoSaverError.authorizationDenied))
                    return
                }
                createAsset(url: url, completion: completion)
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    completion(.failure(PhotoSaverError.authorizationDenied))
                    return
                }
                createAsset(url: url, completion: completion)
            }
        }
    }

    private static func createAsset(url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }, completionHandler: { success, error in
            if let error = error {
                completion(.failure(error))
            } else if success {
                completion(.success(()))
            } else {
                completion(.failure(PhotoSaverError.creationFailed))
            }
        })
    }
}
