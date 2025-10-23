//
//  PokemonListViewModel.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 19.10.2025.
//

import Foundation
internal import Combine

@MainActor final class PokemonListViewModel: ObservableObject {
    @Published private(set) var items: [PokemonSummary] = []
    @Published var isLoading: Bool = false
    @Published var isRefreshing = false
    @Published var isPaging = false
    @Published var error: String?
    @Published var navigationDetail: PokemonDetail?
    @Published var openingId: Int? = nil
    
    
    private let fetchPage: FetchPokemonPageUseCase
    private let fetchDetail: FetchPokemonDetailUseCase
    private let preloadSprites: PreloadSpritesUseCase
    
    private let pageSize = 20
    private var page = 0
    private var endReached = false
    private var isLoadingGate = false
    
    init(
        fetchPage: FetchPokemonPageUseCase,
        fetchDetail: FetchPokemonDetailUseCase,
        preloadSprites: PreloadSpritesUseCase
    ) {
        self.fetchPage = fetchPage
        self.fetchDetail = fetchDetail
        self.preloadSprites = preloadSprites
    }
    
    func load(reset: Bool = false) async {
        guard !isLoadingGate else { return }
        isLoadingGate = true
        defer { isLoadingGate = false }
        
        if reset {
            page = 0
            endReached = false
            items = []
            isLoading = true
        } else {
            isPaging = true
        }
        defer {
            isLoading = false
            isPaging = false
        }
        
        do {
            let new = try await fetchPage(limit: pageSize, offset: page * pageSize)
            items += new
            endReached = new.count < pageSize
            page += 1
        } catch {
            self.error = error.humanized
        }
    }
    
    func loadNextIfNeeded(current item: PokemonSummary) async {
        guard !endReached, let idx = items.firstIndex(of: item) else { return }
        if idx >= items.count - 5 {
            await load()
        }
    }
    
    func openDetail(_ item: PokemonSummary) async {
        guard openingId == nil else { return }
        openingId = item.id
        defer { openingId = nil }
        
        do {
            let detail = try await fetchDetail(item.name)
            try await preloadSprites(detail.spriteURLs)
            self.navigationDetail = detail
        } catch {
            self.error = error.humanized
        }
    }
    
    func userRefresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await load(reset: true)
    }
}
