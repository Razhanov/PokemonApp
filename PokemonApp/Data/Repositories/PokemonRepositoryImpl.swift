//
//  PokemonRepositoryImpl.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 20.10.2025.
//

import Foundation

struct PokemonRepositoryImpl: PokemonRepository {
    let api: APIClientProtocol
    
    func page(limit: Int, offset: Int) async throws -> [PokemonSummary] {
        let dto: PokemonListDTO = try await api.get(.init(path: .pokemonList(limit: limit, offset: offset)))
//        try await Task.sleep(for: .seconds(2)) // To test refresh
//        return Bool.random() ? [] : PokemonListMapper.toDomain(dto)
        return PokemonListMapper.toDomain(dto)
    }
    
    func detail(nameOrID: String) async throws -> PokemonDetail {
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(nameOrID.lowercased())")
        let (data, _) = try await api.getRaw(url!)
        let dto = try JSONDecoder().decode(PokemonDetailDTO.self, from: data)
        return try PokemonDetailMapper.toDomain(dto: dto, rawJSON: data)
    }
}
