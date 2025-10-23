//
//  PokemonRepository.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 20.10.2025.
//

import Foundation

protocol PokemonRepository {
    func page(limit: Int, offset: Int) async throws -> [PokemonSummary]
    func detail(nameOrID: String) async throws -> PokemonDetail
}
