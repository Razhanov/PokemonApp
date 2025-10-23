//
//  PokemonDetailDTO.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 21.10.2025.
//

import Foundation

struct PokemonDetailDTO: Decodable {
    struct StatEntry: Decodable {
        struct Info: Decodable {
            let name: String
        }
        let base_stat: Int
        let stat: Info
        
    }
    struct Sprites: Decodable {
        let front_default: String?
        let front_shiny: String?
        let back_default: String?
        let back_shiny: String?
        let other: Other?
        
        private enum CodingKeys: String, CodingKey {
            case front_default, front_shiny, back_default, back_shiny, other
        }
        
        struct Other: Decodable {
            let official_artwork: OfficialArtwork?
            
            private enum CodingKeys: String, CodingKey {
                case official_artwork = "official-artwork"
            }
            
            struct OfficialArtwork: Decodable {
                let front_default: String?
            }
        }
    }
    let id: Int
    let name: String
    let stats: [StatEntry]
    let sprites: Sprites
}
