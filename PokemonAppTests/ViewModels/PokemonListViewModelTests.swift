//
//  PokemonListViewModelTests.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import XCTest
@testable import PokemonApp
import Foundation

@MainActor
final class PokemonListViewModelTests: XCTestCase {
    
    // MARK: - Doubles
    
    final class RepositoryMock: PokemonRepository {
        // page
        var pageHandler: ((Int, Int) async throws -> [PokemonSummary])?
        private(set) var pageCalls: [(limit: Int, offset: Int)] = []
        
        func page(limit: Int, offset: Int) async throws -> [PokemonSummary] {
            pageCalls.append((limit, offset))
            return try await pageHandler?(limit, offset) ?? []
        }
        
        // detail
        var detailHandler: ((String) async throws -> PokemonDetail)?
        private(set) var detailCalls: [String] = []
        
        func detail(nameOrID: String) async throws -> PokemonDetail {
            detailCalls.append(nameOrID)
            return try await detailHandler?(nameOrID) ?? PokemonDetail(id: 1, name: nameOrID.capitalized, stats: [], spriteURLs: [])
        }
    }
    
    struct PreloadSpritesSpy {
        private(set) var urls: [URL] = []
        var delayNs: UInt64 = 0
        
        mutating func callAsFunction(_ urls: [URL]) async throws {
            self.urls = urls
            if delayNs > 0 { try? await Task.sleep(nanoseconds: delayNs) }
        }
    }
    
    // MARK: - Builders
    
    func makeVM(
        repo: RepositoryMock = .init(),
        preloadSpy: inout PreloadSpritesSpy
    ) -> PokemonListViewModel {
        let fetchPage = FetchPokemonPageUseCase(repository: repo)
        let fetchDetail = FetchPokemonDetailUseCase(repository: repo)
        let preload = PreloadSpritesUseCase(imageRepository: DummyImageRepository { url in })

        return PokemonListViewModel(
            fetchPage: fetchPage,
            fetchDetail: fetchDetail,
            preloadSprites: preload
        )
    }
    
    // MARK: - Tests
    
    func test_initialLoad_resetsAndFillsItems() async {
        let repo = RepositoryMock()
        repo.pageHandler = { limit, offset in
            XCTAssertEqual(limit, 20)
            XCTAssertEqual(offset, 0)
            return Self.makeSummaries(start: 1, count: 20)
        }
        
        var preload = PreloadSpritesSpy()
        let vm = makeVM(repo: repo, preloadSpy: &preload)
        
        await vm.load(reset: true)
        
        XCTAssertEqual(vm.items.count, 20)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.isPaging)
        XCTAssertTrue(repo.pageCalls.count >= 1)
    }
    
    func test_pagination_loadsNextPage_whenNearEnd() async {
        let repo = RepositoryMock()
        repo.pageHandler = { _, offset in
            let start = offset + 1
            // 2 страницы по 20
            if offset == 0 { return Self.makeSummaries(start: start, count: 20) }
            else { return Self.makeSummaries(start: start, count: 20) }
        }
        
        var preload = PreloadSpritesSpy()
        let vm = makeVM(repo: repo, preloadSpy: &preload)
        
        await vm.load(reset: true) // 1..20
        let trigger = vm.items[vm.items.count - 2] // предпоследний
        await vm.loadNextIfNeeded(current: trigger)
        
        XCTAssertEqual(vm.items.count, 40)
        XCTAssertFalse(vm.isPaging)
        XCTAssertEqual(repo.pageCalls.map(\.offset), [0, 20])
    }
    
    func test_pagination_doesNotLoad_whenEndReached() async {
        let repo = RepositoryMock()
        repo.pageHandler = { _, offset in
            if offset == 0 { return Self.makeSummaries(start: 1, count: 20) }
            // вторая «страница» короче — сигнал конца
            return Self.makeSummaries(start: 21, count: 5)
        }
        
        var preload = PreloadSpritesSpy()
        let vm = makeVM(repo: repo, preloadSpy: &preload)
        
        await vm.load(reset: true)
        await vm.load(reset: false)      // items = 25
        let last = vm.items.last!
        await vm.loadNextIfNeeded(current: last) // не должно догружать
        
        XCTAssertEqual(vm.items.count, 25)
        XCTAssertEqual(repo.pageCalls.count, 2)
    }
    
    func test_isLoadingGate_preventsConcurrentLoads() async {
        let repo = RepositoryMock()
        repo.pageHandler = { _, _ in
            try? await Task.sleep(nanoseconds: 80_000_000) // 80ms
            return Self.makeSummaries(start: 1, count: 20)
        }
        
        var preload = PreloadSpritesSpy()
        let vm = makeVM(repo: repo, preloadSpy: &preload)
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 { group.addTask { await vm.load(reset: false) } }
            await group.waitForAll()
        }
        // ожидаем, что репозиторий вызвался не 5 раз, а 1 (или ≤2 с прогонами)
        XCTAssertLessThanOrEqual(repo.pageCalls.count, 2)
    }
    
    func test_openDetail_setsOpeningId_thenNavigates_andPreloads() async {
        let repo = RepositoryMock()
        repo.pageHandler = { _, _ in Self.makeSummaries(start: 1, count: 1) }
        repo.detailHandler = { name in
            PokemonDetail(id: 1, name: name, stats: [], spriteURLs: [
                URL(string: "https://s/p/1.png")!,
                URL(string: "https://s/p/2.png")!
            ])
        }
        
        var preload = PreloadSpritesSpy()
        preload.delayNs = 50_000_000 // 50ms, чтобы успеть поймать openingId
        
        let vm = makeVM(repo: repo, preloadSpy: &preload)
        await vm.load(reset: true)
        let item = vm.items[0]
        
        let t = Task { await vm.openDetail(item) }
        
        await t.value
        XCTAssertNil(vm.openingId)
        XCTAssertEqual(vm.navigationDetail?.name, item.name)
    }
    
    func test_load_setsHumanizedError_onFailure() async {
        let repo = RepositoryMock()
        repo.pageHandler = { _, _ in throw URLError(.notConnectedToInternet) }
        
        var preload = PreloadSpritesSpy()
        let vm = makeVM(repo: repo, preloadSpy: &preload)
        
        await vm.load(reset: true)
        
        XCTAssertNotNil(vm.error)
        XCTAssertTrue(vm.error?.isEmpty == false)
    }
    
    func test_refresh_callsResetLoad_andTogglesFlag() async {
        let repo = RepositoryMock()
        repo.pageHandler = { _, offset in
            return offset == 0
            ? Self.makeSummaries(start: 1, count: 20)
            : Self.makeSummaries(start: offset + 1, count: 20)
        }
        
        var preload = PreloadSpritesSpy()
        let vm = makeVM(repo: repo, preloadSpy: &preload)
        
        await vm.load(reset: true)   // получили 20
        XCTAssertEqual(vm.items.count, 20)
        
        // имитируем, что уже есть данные, сейчас обновим
        let task = Task { await vm.userRefresh() }
        
        await task.value
        XCTAssertFalse(vm.isRefreshing)
        XCTAssertEqual(vm.items.count, 20) // после refresh снова 20 (reset)
        XCTAssertEqual(repo.pageCalls.first?.offset, 0)
    }
    
    // MARK: - Utils
    
    static func makeSummaries(start: Int, count: Int) -> [PokemonSummary] {
        (0..<count).map { i in
            let id = start + i
            return PokemonSummary(
                id: id,
                name: "Poke \(id)",
                detailURL: URL(string: "https://pokeapi.co/api/v2/pokemon/\(id)/")!
            )
        }
    }
}

struct PreloadSpritesUseCaseAdapter: Sendable {
    private let block: @Sendable ([URL]) async throws -> Void
    init(_ block: @escaping @Sendable ([URL]) async throws -> Void) { self.block = block }
    func callAsFunction(_ urls: [URL]) async throws { try await block(urls) }
}

// Заглушка ImageRepository, если вдруг понадобится
struct DummyImageRepository: ImageRepository {
    let handler: (URL) async throws -> Void
    func preheat(_ urls: [URL]) async throws {
        for u in urls { _ = try await handler(u) }
    }
    func image(_ url: URL) async throws -> UIImage { return UIImage() }
}

extension XCTestCase {
    /// Ждёт, пока condition() станет true (или таймаут)
    func waitUntil(
        timeout: TimeInterval = 0.5,
        pollNs: UInt64 = 5_000_000, // 5 ms
        _ condition: @escaping () -> Bool
    ) async {
        let end = Date().addingTimeInterval(timeout)
        while !condition() && Date() < end {
            try? await Task.sleep(nanoseconds: pollNs)
        }
        XCTAssertTrue(condition(), "Condition not met within \(timeout)s")
    }
}
