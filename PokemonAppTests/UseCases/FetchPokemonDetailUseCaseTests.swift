//
//  FetchPokemonDetailUseCaseTests.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import XCTest
@testable import PokemonApp

final class FetchPokemonDetailUseCaseTests: XCTestCase {

    // MARK: - Doubles
    final class RepositoryMock: PokemonRepository {
        var receivedNameOrId: String?
        var detailResult: Result<PokemonDetail, Error> = .failure(NSError(domain: "uninitialized", code: 0))

        func page(limit: Int, offset: Int) async throws -> [PokemonSummary] {
            []
        }

        func detail(nameOrID: String) async throws -> PokemonDetail {
            receivedNameOrId = nameOrID
            return try detailResult.get()
        }
    }

    // MARK: - Tests

    func test_fetchDetail_returnsData_fromRepository() async throws {
        // given
        let expected = PokemonDetail(
            id: 1,
            name: "Bulbasaur",
            stats: [.init(name: "HP", value: 45)],
            spriteURLs: [URL(string: "https://pokeapi.co/api/v2/pokemon/1.png")!]
        )

        let repo = RepositoryMock()
        repo.detailResult = .success(expected)
        let useCase = await FetchPokemonDetailUseCase(repository: repo)

        // when
        let result = try await useCase("bulbasaur")

        // then
        XCTAssertEqual(repo.receivedNameOrId, "bulbasaur")
        XCTAssertEqual(result.id, expected.id)
        XCTAssertEqual(result.name, "Bulbasaur")
        XCTAssertEqual(result.stats.first?.name, "HP")
    }

    func test_fetchDetail_propagatesError_fromRepository() async {
        // given
        enum TestError: Error { case failure }
        let repo = RepositoryMock()
        repo.detailResult = .failure(TestError.failure)
        let useCase = FetchPokemonDetailUseCase(repository: repo)

        // when / then
        do {
            _ = try await useCase("ivysaur")
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }
}
