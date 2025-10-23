//
//  PokemonSummary.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 19.10.2025.
//

import Foundation

struct PokemonSummary: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let detailURL: URL
}
