//
//  PokemonDetail.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 20.10.2025.
//

import Foundation

struct PokemonDetail: Identifiable, Equatable, Hashable, Sendable {
    struct Stat: Equatable, Hashable, Sendable {
        let name: String
        let value: Int
    }
    let id: Int
    let name: String
    let stats: [Stat]
    let spriteURLs: [URL]
}
