//
//  FetchPokemonPageUseCaseTests.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import XCTest
@testable import PokemonApp

final class FetchPokemonPageUseCaseTests: XCTestCase {

    // MARK: - Doubles
    final class RepositoryMock: PokemonRepository {
        var receivedLimit: Int?
        var receivedOffset: Int?
        var result: Result<[PokemonSummary], Error> = .success([])

        func page(limit: Int, offset: Int) async throws -> [PokemonSummary] {
            receivedLimit = limit
            receivedOffset = offset
            return try result.get()
        }

        func detail(nameOrID: String) async throws -> PokemonDetail {
            throw NSError(domain: "not implemented", code: 0)
        }
    }

    // MARK: - Tests

    func test_fetchPage_returnsData_fromRepository() async throws {
        // given
        let expected = [
            PokemonSummary(id: 1, name: "Bulbasaur", detailURL: URL(string: "https://pokeapi.co/api/v2/pokemon/1")!),
            PokemonSummary(id: 2, name: "Ivysaur", detailURL: URL(string: "https://pokeapi.co/api/v2/pokemon/2")!)
        ]
        let repo = RepositoryMock()
        repo.result = .success(expected)
        let useCase = FetchPokemonPageUseCase(repository: repo)

        // when
        let result = try await useCase(limit: 20, offset: 0)

        // then
        XCTAssertEqual(result.count, expected.count)
        XCTAssertEqual(repo.receivedLimit, 20)
        XCTAssertEqual(repo.receivedOffset, 0)
        XCTAssertEqual(result.first?.name, "Bulbasaur")
    }

    func test_fetchPage_propagatesError_fromRepository() async {
        // given
        enum TestError: Error { case failed }
        let repo = RepositoryMock()
        repo.result = .failure(TestError.failed)
        let useCase = FetchPokemonPageUseCase(repository: repo)

        // when/then
        do {
            _ = try await useCase(limit: 20, offset: 0)
            XCTFail("Expected to throw")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }
}
