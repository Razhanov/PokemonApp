//
//  ImageRepositoryImplTests.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import XCTest
import UIKit
@testable import PokemonApp

final class ImageRepositoryImplTests: XCTestCase {

    func test_image_returnsSeededImage_fromCacheActor() async throws {
        // given
        let cache = ImageCache()
        let sut = await ImageRepositoryImpl(cache: cache)
        let url = URL(string: "https://cdn/p/1.png")!
        let img = ImageCache.testImage(.blue)

        await cache.seed(image: img, for: url)

        // when
        let result = try await sut.image(url)

        // then
        XCTAssertEqual(result.pngData(), img.pngData())
    }

    func test_preheat_then_image_hitsCache_withoutNetwork() async throws {
        // given
        let cache = ImageCache()
        let sut = await ImageRepositoryImpl(cache: cache)
        let urls = [
            URL(string: "https://cdn/p/1.png")!,
            URL(string: "https://cdn/p/2.png")!
        ]

        // seed сразу обоими, имитируя то, что preheat бы сделал загрузку
        let img1 = ImageCache.testImage(.red)
        let img2 = ImageCache.testImage(.green)
        await cache.seed(image: img1, for: urls[0])
        await cache.seed(image: img2, for: urls[1])

        // when
        try await sut.preheat(urls)              // в тесте «пустой» — но мы проверяем проводку вызова
        let r1 = try await sut.image(urls[0])
        let r2 = try await sut.image(urls[1])

        // then
        XCTAssertEqual(r1.pngData(), img1.pngData())
        XCTAssertEqual(r2.pngData(), img2.pngData())
    }
}
