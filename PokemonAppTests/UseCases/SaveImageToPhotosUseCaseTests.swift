//
//  SaveImageToPhotosUseCaseTests.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import XCTest
@testable import PokemonApp

final class SaveImageToPhotosUseCaseTests: XCTestCase {

    // MARK: - Doubles

    final class PhotoLibraryServiceMock: PhotoLibraryService {
        var authorized: Bool = true
        var saveError: Error?

        private(set) var singleSaves: Int = 0
        private(set) var batchSaves: Int = 0
        private(set) var lastBatchCount: Int = 0

        func requestAuthorizationIfNeeded() async -> Bool {
            authorized
        }

        func save(image: UIImage) async throws {
            if let err = saveError { throw err }
            singleSaves += 1
        }

        func save(images: [UIImage]) async throws {
            if let err = saveError { throw err }
            batchSaves += 1
            lastBatchCount = images.count
        }
    }

    // MARK: - Helpers

    private func makeDummyImage(_ color: UIColor = .red, size: CGSize = .init(width: 2, height: 2)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Tests

    func test_save_single_whenAuthorized_callsService() async throws {
        let mock = PhotoLibraryServiceMock()
        mock.authorized = true
        let uc = SaveImageToPhotosUseCase(photoService: mock)

        try await uc(makeDummyImage())

        XCTAssertEqual(mock.singleSaves, 1)
        XCTAssertEqual(mock.batchSaves, 0)
    }

    func test_save_multiple_whenAuthorized_callsServiceWithCount() async throws {
        let mock = PhotoLibraryServiceMock()
        mock.authorized = true
        let uc = SaveImageToPhotosUseCase(photoService: mock)
        let imgs = [makeDummyImage(.red), makeDummyImage(.blue), makeDummyImage(.green)]

        try await uc(imgs)

        XCTAssertEqual(mock.batchSaves, 1)
        XCTAssertEqual(mock.lastBatchCount, imgs.count)
        XCTAssertEqual(mock.singleSaves, 0)
    }

    func test_save_single_whenDenied_throwsPhotosAccessError() async {
        let mock = PhotoLibraryServiceMock()
        mock.authorized = false
        let uc = SaveImageToPhotosUseCase(photoService: mock)

        do {
            try await uc(makeDummyImage())
            XCTFail("Expected PhotosAccessError.denied")
        } catch {
            guard let e = error as? PhotosAccessError else {
                return XCTFail("Wrong error type: \(error)")
            }
            XCTAssertEqual(e, .denied)
            XCTAssertEqual(e.errorDescription, "Photos permission denied")
            XCTAssertEqual(mock.singleSaves, 0)
        }
    }

    func test_save_multiple_whenDenied_throwsPhotosAccessError() async {
        let mock = PhotoLibraryServiceMock()
        mock.authorized = false
        let uc = SaveImageToPhotosUseCase(photoService: mock)

        do {
            try await uc([makeDummyImage()])
            XCTFail("Expected PhotosAccessError.denied")
        } catch {
            XCTAssertTrue(error is PhotosAccessError)
            XCTAssertEqual(mock.batchSaves, 0)
        }
    }

    func test_save_single_propagatesUnderlyingError() async {
        enum TestError: Error { case saveFailed }
        let mock = PhotoLibraryServiceMock()
        mock.authorized = true
        mock.saveError = TestError.saveFailed
        let uc = SaveImageToPhotosUseCase(photoService: mock)

        do {
            try await uc(makeDummyImage())
            XCTFail("Expected underlying error")
        } catch {
            XCTAssertTrue(error is TestError)
            XCTAssertEqual(mock.singleSaves, 0)
        }
    }

    func test_save_multiple_propagatesUnderlyingError() async {
        enum TestError: Error { case saveFailed }
        let mock = PhotoLibraryServiceMock()
        mock.authorized = true
        mock.saveError = TestError.saveFailed
        let uc = SaveImageToPhotosUseCase(photoService: mock)

        do {
            try await uc([makeDummyImage(), makeDummyImage()])
            XCTFail("Expected underlying error")
        } catch {
            XCTAssertTrue(error is TestError)
            XCTAssertEqual(mock.batchSaves, 0)
        }
    }
}
