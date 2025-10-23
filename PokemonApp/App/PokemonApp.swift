//
//  PokemonApp.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 17.10.2025.
//

import SwiftUI

@main
struct PokemonApp: App {
    private let di = DIContainer.live()
    var body: some Scene {
        WindowGroup {
            PokemonListScreen(di: di)
                .environment(\.di, di)
        }
    }
}
