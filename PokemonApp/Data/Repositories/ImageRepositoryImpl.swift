//
//  ImageRepositoryImpl.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 22.10.2025.
//

import Foundation
import UIKit


struct ImageRepositoryImpl: ImageRepository {
    private let cache: ImageCache
    
    init(cache: ImageCache = .shared) {
        self.cache = cache
    }
    
    func image(_ url: URL) async throws -> UIImage {
        try await cache.image(for: url)
    }
    func preheat(_ urls: [URL]) async throws {
        try await cache.preheat(urls)
    }
}
