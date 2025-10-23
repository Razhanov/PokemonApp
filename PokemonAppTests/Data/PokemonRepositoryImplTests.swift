//
//  PokemonRepositoryImplTests.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import XCTest
@testable import PokemonApp

// MARK: - APIClient mock

final class APIClientMock: APIClientProtocol {
    
    struct RecordedEndpoint: Equatable {
        let url: URL
    }

    // get<T>
    var getResultProvider: ((Endpoint) async throws -> Any)?
    private(set) var lastEndpoint: Endpoint?

    func get<T>(_ endpoint: Endpoint) async throws -> T where T : Decodable {
        lastEndpoint = endpoint
        guard let provider = getResultProvider else {
            fatalError("getResultProvider not set")
        }
        let any = try await provider(endpoint)
        guard let typed = any as? T else {
            fatalError("APIClientMock: mismatched type \(T.self)")
        }
        return typed
    }

    // getRaw(URL)
    var getRawResultProvider: ((URL) async throws -> (Data, URLResponse))?
    private(set) var lastRawURL: URL?
    
    func getRaw(_ url: URL) async throws -> (Data, HTTPURLResponse) {
        lastRawURL = url
        guard let provider = getRawResultProvider else {
            fatalError("getRawResultProvider not set")
        }
        let (data, response) = try await provider(url)
        guard let httpResponse = response as? HTTPURLResponse else {
            fatalError("APIClientMock: expected HTTPURLResponse, got \(type(of: response))")
        }
        return (data, httpResponse)
    }
}

// MARK: - Tests

final class PokemonRepositoryImplTests: XCTestCase {

    // MARK: page(limit:offset:)

    func test_page_returnsMappedSummaries() async throws {
        // given
        let api = APIClientMock()
        api.getResultProvider = { endpoint in
            // Проверим, что лимит/оффсет зашиты в URL
            let url = await endpoint.url.absoluteString
            XCTAssertTrue(url.contains("limit=20"))
            XCTAssertTrue(url.contains("offset=40"))
            // Вернём минимальный DTO
            return PokemonListDTO(
                count: 1302,
                next: nil,
                previous: nil,
                results: [
                    .init(name: "bulbasaur", url: URL(string: "https://pokeapi.co/api/v2/pokemon/1/")!),
                    .init(name: "ivysaur",   url: URL(string: "https://pokeapi.co/api/v2/pokemon/2/")!)
                ]
            )
        }

        let sut = PokemonRepositoryImpl(api: api)

        // when
        let items = try await sut.page(limit: 20, offset: 40)

        // then
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].id, 1)
        XCTAssertEqual(items[0].name, "Bulbasaur")  // маппер капитализует
        XCTAssertEqual(items[1].id, 2)
        XCTAssertEqual(items[1].name, "Ivysaur")
    }

    func test_page_propagatesError() async {
        enum TestError: Error { case failed }
        let api = APIClientMock()
        api.getResultProvider = { _ in throw TestError.failed }

        let sut = PokemonRepositoryImpl(api: api)

        do {
            _ = try await sut.page(limit: 20, offset: 0)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    // MARK: detail(nameOrID:)

    func test_detail_buildsLowercasedURL_andMapsDetail() async throws {
        // given
        let api = APIClientMock()
        api.getRawResultProvider = { url in
            XCTAssertTrue(url.absoluteString.hasSuffix("/pokemon/ivysaur"))
            // Минимально валидный JSON для PokemonDetailDTO
            let json = """
            {
              "id": 2,
              "name": "ivysaur",
              "stats": [
                { "base_stat": 60, "stat": { "name": "hp" } },
                { "base_stat": 62, "stat": { "name": "attack" } }
              ],
              "sprites": {
                "front_default": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/2.png",
                "back_default":  "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/back/2.png",
                "other": {
                  "official-artwork": {
                    "front_default": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/2.png"
                  }
                }
              }
            }
            """.data(using: .utf8)!
            let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (json, resp)
        }

        let sut = PokemonRepositoryImpl(api: api)

        // when
        let detail = try await sut.detail(nameOrID: "Ivysaur")

        // then
        XCTAssertEqual(api.lastRawURL?.absoluteString.hasSuffix("/pokemon/ivysaur"), true)
        XCTAssertEqual(detail.id, 2)
        XCTAssertEqual(detail.name, "Ivysaur") // капитализация в маппере
        XCTAssertEqual(detail.stats.first?.name, "Hp")
        XCTAssertEqual(detail.stats.first?.value, 60)
        XCTAssertFalse(detail.spriteURLs.isEmpty)
    }

    func test_detail_propagatesDecodingError_onInvalidJSON() async {
        let api = APIClientMock()
        api.getRawResultProvider = { url in
            let bad = Data("{\"id\":2,\"name\":true}".utf8) // неправильные типы
            let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (bad, resp)
        }
        let sut = PokemonRepositoryImpl(api: api)

        do {
            _ = try await sut.detail(nameOrID: "bulbasaur")
            XCTFail("Expected DecodingError")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }

    func test_detail_propagatesUnderlyingTransportError() async {
        enum TestError: Error { case noNetwork }
        let api = APIClientMock()
        api.getRawResultProvider = { _ in throw TestError.noNetwork }
        let sut = PokemonRepositoryImpl(api: api)

        do {
            _ = try await sut.detail(nameOrID: "bulbasaur")
            XCTFail("Expected transport error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }
}

