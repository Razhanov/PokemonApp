//
//  PokemonListMapper.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 20.10.2025.
//

import Foundation

enum PokemonListMapper {
    static func toDomain(_ dto: PokemonListDTO) -> [PokemonSummary] {
        dto.results.map { item in
            let id = Int(item.url.deletingPathExtension().lastPathComponent) ?? 0
            return .init(id: id, name: item.name.capitalized, detailURL: item.url)
        }
    }
}
