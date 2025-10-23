//
//  PhotoLibraryClient.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import Photos

protocol PhotoLibraryClient {
    func authorizationStatusAddOnly() -> PHAuthorizationStatus
    func requestAuthorizationAddOnly(_ block: @escaping (PHAuthorizationStatus) -> Void)
    func performChanges(_ changes: @escaping () -> Void,
                        completion: @escaping (Bool, Error?) -> Void)
}

struct PhotoLibraryClientImpl: PhotoLibraryClient {
    func authorizationStatusAddOnly() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
    func requestAuthorizationAddOnly(_ block: @escaping (PHAuthorizationStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: block)
    }
    func performChanges(_ changes: @escaping () -> Void,
                        completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges(changes, completionHandler: completion)
    }
}
