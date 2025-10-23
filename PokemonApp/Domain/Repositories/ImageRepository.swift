//
//  ImageRepository.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 22.10.2025.
//

import Foundation
import UIKit

protocol ImageRepository {
    func image(_ url: URL) async throws -> UIImage
    func preheat(_ urls: [URL]) async throws
}
