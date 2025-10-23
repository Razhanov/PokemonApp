//
//  Endpoint.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 19.10.2025.
//

import Foundation

struct Endpoint {
    enum Path {
        case pokemonList(limit: Int, offset: Int)
    }
    let path: Path
    var url: URL {
        switch path {
        case let .pokemonList(limit, offset):
            var c = URLComponents(string: "https://pokeapi.co/api/v2/pokemon")!
            c.queryItems = [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset))
            ]
            return c.url!
        }
    }
}
