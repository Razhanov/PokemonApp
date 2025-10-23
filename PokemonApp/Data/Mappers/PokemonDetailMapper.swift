//
//  PokemonDetailMapper.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 21.10.2025.
//

import Foundation

enum PokemonDetailMapper {
    static func toDomain(dto: PokemonDetailDTO, rawJSON: Data) throws -> PokemonDetail {
        let stats: [PokemonDetail.Stat] = dto.stats.map {
            .init(name: $0.stat.name.capitalized, value: $0.base_stat)
        }
        var urls = OrderedURLSet()
        [dto.sprites.front_default, dto.sprites.front_shiny, dto.sprites.back_default, dto.sprites.back_shiny, dto.sprites.other?.official_artwork?.front_default]
            .compactMap { $0 }.compactMap(URL.init(string:)).forEach { urls.insert($0) }
        try collectSpriteURLStrings(fromJSON: rawJSON).compactMap(URL.init(string:)).forEach { urls.insert($0) }
        return .init(id: dto.id, name: dto.name.capitalized, stats: stats, spriteURLs: urls.array)
    }
    
    private static func collectSpriteURLStrings(fromJSON data: Data) throws -> [String] {
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let sprites = (root?["sprites"] as? [String: Any]) else { return [] }
                var acc: [String] = []
                func walk(_ any: Any) {
                    switch any {
                    case let dict as [String: Any]: dict.values.forEach(walk)
                    case let arr as [Any]: arr.forEach(walk)
                    case let str as String:
                        let s = str.lowercased()
                        if s.hasSuffix(".png"), s.contains("http") { acc.append(str) }
                    default: break
                    }
                }
                walk(sprites)
                return acc
    }
}


fileprivate struct OrderedURLSet {
    private var set: Set<URL> = []
    fileprivate(set) var array: [URL] = []
    
    mutating func insert(_ url: URL) {
        if set.insert(url).inserted {
            array.append(url)
        }
    }
}
