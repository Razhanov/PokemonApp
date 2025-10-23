//
//  PokemonDetailViewModelTests.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import XCTest
import UIKit
@testable import PokemonApp

@MainActor
final class PokemonDetailViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeImage(_ color: UIColor, size: CGSize = .init(width: 2, height: 2)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func dummyDetail(urls: [URL]) -> PokemonDetail {
        PokemonDetail(
            id: 1,
            name: "Bulbasaur",
            stats: [.init(name: "HP", value: 45)],
            spriteURLs: urls
        )
    }

    // Фейковый сервис Фотоплёнки
    final class PhotoLibraryServiceMock: PhotoLibraryService {
        var authorized = true
        var error: Error?
        private(set) var singleSaves = 0
        private(set) var batchSaves = 0
        private(set) var lastBatchCount = 0

        func requestAuthorizationIfNeeded() async -> Bool { authorized }
        func save(image: UIImage) async throws {
            if let e = error { throw e }
            singleSaves += 1
        }
        func save(images: [UIImage]) async throws {
            if let e = error { throw e }
            batchSaves += 1
            lastBatchCount = images.count
        }
    }

    // MARK: - Tests

    func test_loadFromCache_populatesImages_inOriginalOrder() async {
        // given: три URL, а провайдер возвращает картинки в перемешанном времени (имитируем разный отклик)
        let urls = [
            URL(string: "https://s/p/1.png")!,
            URL(string: "https://s/p/2.png")!,
            URL(string: "https://s/p/3.png")!
        ]
        let red = makeImage(.red), green = makeImage(.green), blue = makeImage(.blue)

        // imageProvider с разной задержкой по URL, но важно — order должен сохраниться как в urls
        let provider: (URL) async throws -> UIImage = { url in
            if url.absoluteString.hasSuffix("1.png") { try? await Task.sleep(nanoseconds: 200_000); return red }
            if url.absoluteString.hasSuffix("2.png") { try? await Task.sleep(nanoseconds: 50_000);  return green }
            return blue
        }

        let saveUC = SaveImageToPhotosUseCase(photoService: PhotoLibraryServiceMock())
        let vm = PokemonDetailViewModel(detail: dummyDetail(urls: urls), saveToPhotos: saveUC, imageProvider: provider)

        // when
        await vm.loadFromCache()

        // then
        XCTAssertEqual(vm.images.count, 3)
        // порядок соответствует исходному массиву urls
        XCTAssertTrue(vm.images[0].pngData() == red.pngData())
        XCTAssertTrue(vm.images[1].pngData() == green.pngData())
        XCTAssertTrue(vm.images[2].pngData() == blue.pngData())
        XCTAssertFalse(vm.isLoading)
    }

    func test_save_single_success_setsToast() async {
        let service = PhotoLibraryServiceMock()
        let saveUC = SaveImageToPhotosUseCase(photoService: service)
        let vm = PokemonDetailViewModel(detail: dummyDetail(urls: []), saveToPhotos: saveUC)

        await vm.save(makeImage(.red))

        XCTAssertEqual(service.singleSaves, 1)
        XCTAssertEqual(vm.toast, "Saved to Photos")
    }

    func test_save_single_failure_setsHumanizedToast() async {
        enum TestError: Error { case boom }
        let service = PhotoLibraryServiceMock()
        service.error = TestError.boom
        let saveUC = SaveImageToPhotosUseCase(photoService: service)
        let vm = PokemonDetailViewModel(detail: dummyDetail(urls: []), saveToPhotos: saveUC)

        await vm.save(makeImage(.red))

        XCTAssertEqual(service.singleSaves, 0)
        XCTAssertNotNil(vm.toast) // строка humanized/локал.описания
    }

    func test_saveAll_success_setsToastWithCount() async {
        let service = PhotoLibraryServiceMock()
        let saveUC = SaveImageToPhotosUseCase(photoService: service)
        let vm = PokemonDetailViewModel(detail: dummyDetail(urls: []), saveToPhotos: saveUC)

        vm._injectImagesForTesting([makeImage(.red), makeImage(.green)])
        await vm.saveAll()

        XCTAssertEqual(service.batchSaves, 1)
        XCTAssertEqual(service.lastBatchCount, 2)
        XCTAssertEqual(vm.toast, "Saved 2 images")
    }

    func test_saveAll_failure_setsHumanizedToast() async {
        enum TestError: Error { case nope }
        let service = PhotoLibraryServiceMock()
        service.error = TestError.nope
        let saveUC = SaveImageToPhotosUseCase(photoService: service)
        let vm = PokemonDetailViewModel(detail: dummyDetail(urls: []), saveToPhotos: saveUC)

        vm._injectImagesForTesting([makeImage(.red)])
        await vm.saveAll()

        XCTAssertEqual(service.batchSaves, 0)
        XCTAssertNotNil(vm.toast)
    }

    func test_isLoading_flag_togglesDuringLoad() async {
        // given: provider с задержкой, чтобы успеть увидеть isLoading = true
        let url = URL(string: "https://s/p/1.png")!
        let img = makeImage(.red)
        let provider: (URL) async throws -> UIImage = { _ in
            try? await Task.sleep(nanoseconds: 80_000_000) // 80ms
            return img
        }
        let saveUC = SaveImageToPhotosUseCase(photoService: PhotoLibraryServiceMock())
        let vm = PokemonDetailViewModel(detail: dummyDetail(urls: [url]), saveToPhotos: saveUC, imageProvider: provider)

        // when
        let task = Task { await vm.loadFromCache() }
        // then
        await Task.yield()
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        XCTAssertTrue(vm.isLoading)
        await task.value
        XCTAssertFalse(vm.isLoading)
    }
}
