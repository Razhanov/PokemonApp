//
//  PokemonDetailViewModel.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import Foundation
import UIKit
internal import Combine

@MainActor final class PokemonDetailViewModel: ObservableObject {
    @Published private(set) var images: [UIImage] = []
    @Published var isLoading = false
    @Published var toast: String?
    
    let detail: PokemonDetail
    private let saveToPhotos: SaveImageToPhotosUseCase
    private let imageProvider: (URL) async throws -> UIImage
    
    init (
        detail: PokemonDetail,
        saveToPhotos: SaveImageToPhotosUseCase,
        imageProvider: @escaping (URL) async throws -> UIImage = { url in
            try await ImageCache.shared.image(for: url)
        }
    ) {
        self.detail = detail
        self.saveToPhotos = saveToPhotos
        self.imageProvider = imageProvider
    }
    
    func loadFromCache() async {
        guard images.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        await withTaskGroup(of: (Int, UIImage)?.self) { group in
            for (idx, url) in detail.spriteURLs.enumerated() {
                group.addTask {
                    if let img = try? await self.imageProvider(url) {
                        return (idx, img)
                    }
                    return nil
                }
            }
            var tmp = Array(repeating: UIImage(), count: detail.spriteURLs.count)
            var filled = 0
            for await res in group {
                if let (i, img) = res {
                    tmp[i] = img
                    filled += 1
                }
            }
            images = Array(tmp.prefix(filled))
        }
    }
    
    func save(_ image: UIImage) async {
        do {
            try await saveToPhotos(image)
            toast = "Saved to Photos"
        } catch {
            toast = error.humanized
        }
    }
    
    func saveAll() async {
        do {
            try await saveToPhotos(images)
            toast = "Saved \(images.count) images"
        } catch {
            toast = error.humanized
        }
    }
}

#if DEBUG
extension PokemonDetailViewModel {
    func _injectImagesForTesting(_ imgs: [UIImage]) {
        self.images = imgs
    }
}
#endif
