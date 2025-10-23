//
//  PhotoLibraryService.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 22.10.2025.
//

import UIKit
import Photos
import Foundation

protocol PhotoLibraryService {
    func requestAuthorizationIfNeeded() async -> Bool
    func save(image: UIImage) async throws
    func save(images: [UIImage]) async throws
}

struct PhotoLibraryServiceImpl: PhotoLibraryService {
    private let client: PhotoLibraryClient
    private let writer: PhotoAssetWriter
    
    init(
        client: PhotoLibraryClient = PhotoLibraryClientImpl(),
        writer: PhotoAssetWriter = PhotoAssetWriterImpl()
    ) {
        self.client = client
        self.writer = writer
    }
    
    func requestAuthorizationIfNeeded() async -> Bool {
        await withCheckedContinuation { continuation in
            switch client.authorizationStatusAddOnly() {
            case .authorized, .limited:
                continuation.resume(returning: true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    continuation.resume(returning: (status == .authorized || status == .limited))
                }
            default:
                continuation.resume(returning: false)
            }
        }
    }
    
    func save(image: UIImage) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            client.performChanges({
                writer.enqueue(image)
            }) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(domain: "photos", code: 1))
                }
            }
        }
    }
    
    func save(images: [UIImage]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            client.performChanges({
                for image in images {
                    writer.enqueue(image)
                }
            }) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(domain: "photos", code: 1))
                }
            }
        }
    }
}
