//
//  DIEnvironment.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import SwiftUI

private struct DIKey: EnvironmentKey {
    static let defaultValue: DIContainer = .live()
}

extension EnvironmentValues {
    var di: DIContainer {
        get { self[DIKey.self] }
        set { self[DIKey.self] = newValue }
    }
}
