//
//  APIClient.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 19.10.2025.
//

import Foundation

struct APIClient: APIClientProtocol {
    func get<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let (data, _) = try await perform(URLRequest(url: endpoint.url))
        do {
            return try JSONDecoder().decode(T.self, from: data)
        }
        catch {
            throw APIError.decoding
        }
    }
    
    func getRaw(_ url: URL) async throws -> (Data, HTTPURLResponse) {
        try await perform(URLRequest(url: url))
    }
    
    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var req = request
        req.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                throw APIError.decoding
            }
            guard (200..<300).contains(http.statusCode) else {
                throw APIError.badStatus(http.statusCode)
            }
            return (data, http)
        } catch is CancellationError {
            throw APIError.cancelled
        } catch {
            throw APIError.transport(error)
        }
    }
}
