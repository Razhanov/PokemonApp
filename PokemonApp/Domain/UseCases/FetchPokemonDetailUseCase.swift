//
//  FetchPokemonDetailUseCase.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 21.10.2025.
//

import Foundation

struct FetchPokemonDetailUseCase {
    private let repository: PokemonRepository
    init(repository: PokemonRepository) {
        self.repository = repository
    }
    func callAsFunction(_ nameOrId: String) async throws -> PokemonDetail {
        try await repository.detail(nameOrID: nameOrId)
    }
}
