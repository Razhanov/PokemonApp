//
//  PokemonListScreen.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 19.10.2025.
//

import SwiftUI

struct PokemonListScreen: View {
    @StateObject private var viewModel: PokemonListViewModel
    @State private var path = NavigationPath()
    @Environment(\.di) private var di
    
    init(di: DIContainer) {
        _viewModel = StateObject(wrappedValue: di.makePokemonListViewModel())
    }
    var body: some View {
        NavigationStack(path: $path) {
            List {
                if viewModel.items.isEmpty {
                    EmptyView()
                } else {
                    ForEach(viewModel.items) { item in
                        PokemonRow(
                            title: item.name,
                            isOpening: viewModel.openingId == item.id
                        )
                        .onAppear {
                            Task {
                                await viewModel.loadNextIfNeeded(current: item)
                            }
                        }
                        .onTapGesture {
                            guard viewModel.openingId == nil else { return }
                            Task {
                                await viewModel.openDetail(item)
                            }
                        }
                        .disabled(viewModel.openingId == item.id)
                    }
                }
            }
            .navigationTitle("Pokemon")
            .overlay {
                PokemonListOverlay(
                    isLoading: viewModel.isLoading,
                    isEmpty: viewModel.items.isEmpty,
                    onRefresh: {
                        Task { await viewModel.load(reset: true) }
                    }
                )
            }
            .overlay(alignment: .bottom) {
                if viewModel.isPaging {
                    PagingPokeballHUD()
                        .padding(.bottom, 16)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.15), value: viewModel.isPaging)
                }
            }
            .animation(.default, value: viewModel.openingId)
            .task {
                await viewModel.load(reset: true)
            }
            .refreshable {
                await viewModel.load(reset: true)
            }
            .onChange(of: viewModel.navigationDetail, { _, detail in
                if let d = detail {
                    path.append(d)
                }
            })
            .navigationDestination(for: PokemonDetail.self, destination: { detail in
                let detailViewModel = di.makePokemonDetailViewModel(detail: detail)
                PokemonDetailScreen(viewModel: detailViewModel)
            })
            .alert(
                "Error",
                isPresented: .constant(viewModel.error != nil),
                actions: {
                    Button("OK", role: .cancel) {
                        viewModel.error = nil
                    }
                },
                message: {
                    Text(viewModel.error ?? "")
                })
        }
    }
}

fileprivate struct PokemonRow: View {
    let title: String
    let isOpening: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if isOpening {
                PokeballSpinner(animating: true, size: 16, period: 0.9)
            } else {
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

fileprivate struct PagingPokeballHUD: View {
    var body: some View {
        HStack(spacing: 10) {
            PokeballSpinner(animating: true, size: 22, period: 0.9)
            Text("Loading more…")
                .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(radius: 2)
    }
}

fileprivate struct PokemonListOverlay: View {
    let isLoading: Bool
    let isEmpty: Bool
    let onRefresh: () -> Void
    
    var body: some View {
        ZStack {
            if isEmpty {
                VStack(spacing: 14) {
                    PokeballSpinner(animating: isLoading, size: 64)
                    
                    Text(isLoading ? "Refreshing…" : "No Pokémon yet")
                        .font(.headline)
                    if isLoading {
                        Text(" ")
                            .font(.subheadline)
                            .opacity(0)
                    } else {
                        Text("Tap the button to reload.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    RefreshButton(isLoading: isLoading, action: onRefresh)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(!isLoading)
            }
            
            if !isEmpty && isLoading {
                VStack {
                    Spacer()
                    PokeballSpinner(animating: true, size: 32, period: 0.9)
                }
                .transition(.opacity)
            }
            
        }
        .animation(.none, value: isLoading)
        .animation(.none, value: isEmpty)
    }
}

fileprivate struct EmptyStateView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No Pokémon yet")
                .font(.headline)
            Text("Tap the button below to reload.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onRefresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reload Pokémon list")
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
    }
}


// MARK: - Preview
#Preview("List - mock DI") {
    let di = DIContainer.mock()
    PokemonListScreen(di: di)
        .environment(\.di, di)
}
