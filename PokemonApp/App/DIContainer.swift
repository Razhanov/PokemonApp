//
//  DIContainer.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 18.10.2025.
//

import Foundation

struct DIContainer {
    // Services
    let api: APIClientProtocol
    let imageCache: ImageCache
    let photoService: PhotoLibraryService
    // Repositories
    let pokemonRepository: PokemonRepository
    let imageRepository: ImageRepository
    // Use cases
    let fetchPokemonPage: FetchPokemonPageUseCase
    let fetchPokemonDetail: FetchPokemonDetailUseCase
    let preloadSprites: PreloadSpritesUseCase
    let saveToPhotos: SaveImageToPhotosUseCase
    
    func makePokemonListViewModel() -> PokemonListViewModel {
        PokemonListViewModel(
            fetchPage: fetchPokemonPage,
            fetchDetail: fetchPokemonDetail,
            preloadSprites: preloadSprites
        )
    }
    
    func makePokemonDetailViewModel(detail: PokemonDetail) -> PokemonDetailViewModel {
        PokemonDetailViewModel(
            detail: detail,
            saveToPhotos: saveToPhotos
        )
    }
}

extension DIContainer {
    static func live() -> DIContainer {
        let api = APIClient()
        let cache = ImageCache.shared
        let photo = PhotoLibraryServiceImpl()
        
        let pokemonRepo = PokemonRepositoryImpl(api: api)
        let imageRepo = ImageRepositoryImpl()
        
        let fetchPage = FetchPokemonPageUseCase(
            repository: pokemonRepo
        )
        let fetchDetail = FetchPokemonDetailUseCase(
            repository: pokemonRepo
        )
        let preload = PreloadSpritesUseCase(
            imageRepository: imageRepo
        )
        let saveToPhotos = SaveImageToPhotosUseCase(
            photoService: photo
        )
        
        return DIContainer(
            api: api,
            imageCache: cache,
            photoService: photo,
            pokemonRepository: pokemonRepo,
            imageRepository: imageRepo,
            fetchPokemonPage: fetchPage,
            fetchPokemonDetail: fetchDetail,
            preloadSprites: preload,
            saveToPhotos: saveToPhotos
        )
    }
    
    static func mock(
        api: APIClientProtocol = APIClient(),
        pokemonRepository: PokemonRepository? = nil,
        imageRepository: ImageRepository = ImageRepositoryImpl(),
        photoService: PhotoLibraryService = PhotoLibraryServiceImpl()
    ) -> DIContainer {
        let pokemonRepo = pokemonRepository ?? PokemonRepositoryMock()
        let fetchPage = FetchPokemonPageUseCase(repository: pokemonRepo)
        let fetchDetail = FetchPokemonDetailUseCase(repository: pokemonRepo)
        let preload = PreloadSpritesUseCase(imageRepository: imageRepository)
        let save = SaveImageToPhotosUseCase(photoService: photoService)
        return DIContainer(
            api: api,
            imageCache: .shared,
            photoService: photoService,
            pokemonRepository: pokemonRepo,
            imageRepository: imageRepository,
            fetchPokemonPage: fetchPage,
            fetchPokemonDetail: fetchDetail,
            preloadSprites: preload,
            saveToPhotos: save
        )
    }
}

final class PokemonRepositoryMock: PokemonRepository {
    func page(limit: Int, offset: Int) async throws -> [PokemonSummary] {
        let base = URL(string: "https://pokeapi.co/api/v2/pokemon/")!
        let names: [String] = ["bulbasaur", "ivysaur", "venusaur", "charmander", "charmeleon", "charizard", "squirtle", "wartortle", "blastoise", "caterpie", "metapod", "butterfree", "weedle", "kakuna", "beedrill", "pidgey", "pidgeotto", "pidgeot", "rattata", "raticate"]
        return names.enumerated().map { idx, n in .init(id: idx+1, name: n.capitalized, detailURL: base.appendingPathComponent("\(idx+1)/")) }
    }
    func detail(nameOrID: String) async throws -> PokemonDetail {
        .init(id: 1, name: nameOrID.capitalized, stats: [.init(name: "HP", value: 45)], spriteURLs: [])
    }
}
