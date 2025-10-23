//
//  FetchPokemonPageUseCase.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 19.10.2025.
//

struct FetchPokemonPageUseCase {
    let repository: PokemonRepository
    func callAsFunction(limit: Int, offset: Int) async throws -> [PokemonSummary] {
        try await repository.page(limit: limit, offset: offset)
    }
}
