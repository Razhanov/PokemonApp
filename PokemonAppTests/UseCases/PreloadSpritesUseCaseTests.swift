//
//  PreloadSpritesUseCaseTests.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import XCTest
@testable import PokemonApp

final class PreloadSpritesUseCaseTests: XCTestCase {

    // MARK: - Doubles
    final class ImageRepositoryMock: ImageRepository {
        
        var receivedURLs: [URL] = []
        var shouldThrow = false

        func preheat(_ urls: [URL]) async throws {
            receivedURLs = urls
            if shouldThrow { throw TestError.failed }
        }
        
        func image(_ url: URL) async throws -> UIImage { return UIImage() }

        enum TestError: Error { case failed }
    }

    // MARK: - Tests

    func test_preloadSprites_callsRepositoryWithURLs() async throws {
        // given
        let mock = ImageRepositoryMock()
        let useCase = PreloadSpritesUseCase(imageRepository: mock)
        let urls = [
            URL(string: "https://pokeapi.co/api/v2/pokemon/1.png")!,
            URL(string: "https://pokeapi.co/api/v2/pokemon/2.png")!
        ]

        // when
        try await useCase(urls)

        // then
        XCTAssertEqual(mock.receivedURLs, urls)
    }

    func test_preloadSprites_propagatesError() async {
        // given
        let mock = ImageRepositoryMock()
        mock.shouldThrow = true
        let useCase = PreloadSpritesUseCase(imageRepository: mock)
        let urls = [URL(string: "https://pokeapi.co/api/v2/pokemon/1.png")!]

        // when / then
        do {
            try await useCase(urls)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is ImageRepositoryMock.TestError)
        }
    }
}
