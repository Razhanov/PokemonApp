//
//  PokemonListDTO.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 20.10.2025.
//

import Foundation

struct PokemonListDTO: Decodable {
    struct Item: Decodable {
        let name: String
        let url: URL
    }
    let count: Int
    let next: URL?
    let previous: URL?
    let results: [Item]
}
