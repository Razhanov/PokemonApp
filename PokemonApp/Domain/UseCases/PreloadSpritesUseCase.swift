//
//  PreloadSpritesUseCase.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 21.10.2025.
//

import Foundation

struct PreloadSpritesUseCase {
    let imageRepository: ImageRepository
    func callAsFunction(_ urls: [URL]) async throws {
        try await imageRepository.preheat(urls)
    }
}
