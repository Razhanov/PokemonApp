//
//  Errors.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 20.10.2025.
//

import Foundation

enum APIError: Error, CustomStringConvertible {
    case badStatus(Int),
    decoding,
    transport(Error),
    cancelled
    
    var description: String {
        switch self {
        case .badStatus(let code):
            return "Bad status code: \(code)"
        case .decoding:
            return "Decoding error"
        case .transport(let error):
            return "Network error: \(error.localizedDescription)"
        case .cancelled:
            return "Request cancelled"
        }
    }
}

enum ErrorHumanizer {
    static func humanize(_ error: Error) -> String {
        // MARK: - Swift Concurrency
        if error is CancellationError {
            return "Operation was cancelled"
        }
        
        // MARK: - APIError (твой enum)
        if let apiError = error as? APIError {
            return apiError.description
        }
        
        // MARK: - DecodingError (детальное описание)
        if let e = error as? DecodingError {
            switch e {
            case .dataCorrupted(let ctx):
                return "Decoding failed: \(ctx.debugDescription) at \(ctx.codingPath.map(\.stringValue).joined(separator: "."))"
            case .keyNotFound(let key, let ctx):
                return "Missing key '\(key.stringValue)' at \(ctx.codingPath.map(\.stringValue).joined(separator: "."))"
            case .typeMismatch(_, let ctx):
                return "Type mismatch at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")): \(ctx.debugDescription)"
            case .valueNotFound(_, let ctx):
                return "Value not found at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")): \(ctx.debugDescription)"
            @unknown default:
                return "Unknown decoding error"
            }
        }
        
        // MARK: - URL / Transport
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No Internet connection"
            case .timedOut:
                return "The request timed out"
            case .cannotFindHost, .cannotConnectToHost:
                return "Cannot connect to server"
            case .networkConnectionLost:
                return "Network connection lost"
            case .badServerResponse:
                return "Server returned bad response"
            default:
                return urlError.localizedDescription
            }
        }
        
        // MARK: - NSError generic
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return "Network error (\(nsError.code)): \(nsError.localizedDescription)"
        }
        
        // MARK: - Fallback
        return error.localizedDescription
    }
}

extension Error {
    var humanized: String { ErrorHumanizer.humanize(self) }
}
