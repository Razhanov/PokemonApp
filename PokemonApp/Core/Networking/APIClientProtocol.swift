//
//  APIClientProtocol.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 19.10.2025.
//

import Foundation

protocol APIClientProtocol {
    func get<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func getRaw(_ url: URL) async throws -> (Data, HTTPURLResponse)
}
