//
//  SaveImageToPhotosUseCase.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 22.10.2025.
//

import UIKit

enum PhotosAccessError: LocalizedError {
    case denied
    var errorDescription: String? { "Photos permission denied" }
}

struct SaveImageToPhotosUseCase {
    let photoService: PhotoLibraryService
    func callAsFunction(_ image: UIImage) async throws {
        guard await photoService.requestAuthorizationIfNeeded() else { throw PhotosAccessError.denied }
        try await photoService.save(image: image)
    }
    func callAsFunction(_ images: [UIImage]) async throws {
        guard await photoService.requestAuthorizationIfNeeded() else { throw PhotosAccessError.denied }
        try await photoService.save(images: images)
    }
}
