//
//  PokemonDetailScreen.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 20.10.2025.
//

import SwiftUI

struct PokemonDetailScreen: View {
    @StateObject private var viewModel: PokemonDetailViewModel
    @State var toastMessage: String?
    
    init(viewModel: PokemonDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 16
            ) {
                DetailHelpText()
                SpriteGrid(
                    images: viewModel.images,
                    onSave: {
                        img in Task {
                            await viewModel.save(img)
                        }
                    }
                )
                if !viewModel.detail.stats.isEmpty {
                    StatsSection(stats: viewModel.detail.stats)
                }
            }.padding()
        }
        .navigationTitle(viewModel.detail.name)
        .task {
            await viewModel.loadFromCache()
        }
        .toast($toastMessage)
        .onChange(of: viewModel.toast) { _, newValue in
            if let newValue {
                showToast(newValue)
            }
        }
        .toolbar {
            if !viewModel.images.isEmpty {
                SaveAllButton {
                    Task {
                        await viewModel.saveAll()
                    }
                }
            }
        }
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                toastMessage = nil
                viewModel.toast = nil
            }
        }
    }
}

fileprivate struct DetailHelpText: View {
    var body: some View {
        Text("Длительно нажмите на изображение, чтобы сохранить его в Фото")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 4)
    }
}

fileprivate struct SaveAllButton: ToolbarContent {
    let action: () -> Void
    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Save all", action: action)
        }
    }
}

fileprivate struct StatsSection: View {
    let stats: [PokemonDetail.Stat]
    var body: some View {
        SectionCard(title: "Stats") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(stats, id: \.name) { stat in
                    HStack {
                        Text(stat.name)
                        Spacer()
                        Text("\(stat.value)")
                            .monospacedDigit()
                    }
                }
            }
        }
    }
}

fileprivate struct SpriteGrid: View {
    let images: [UIImage]
    var onSave: (UIImage) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 84), spacing: 10)
    ]

    var body: some View {
        Group {
            if images.isEmpty {
                GridPlaceholder()
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(images.indices, id: \.self) { i in
                        SpriteCell(image: images[i]) { onSave(images[i]) }
                    }
                }
            }
        }
    }
}

fileprivate struct SpriteCell: View {
    let image: UIImage
    var onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
                .resizable().scaledToFit()
                .frame(height: 84)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contextMenu {
                    Button(action: onSave) {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }
                }
        }
        .contentShape(Rectangle())
    }
}

fileprivate struct GridPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemFill))
                            .frame(width: 84, height: 84)
                            .redacted(reason: .placeholder)
                    }
                }
            }
            ProgressView("Loading images…")
        }
        .frame(maxWidth: .infinity)
    }
}

fileprivate struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title3.bold())
            content
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview("Detail - Mock DI") {
    let di = DIContainer.mock()
    let detail = PokemonDetail(
        id: 0,
        name: "Bulbasaur",
        stats: [.init(name: "HP", value: 45)],
        spriteURLs: []
    )
    let detailViewModel = di.makePokemonDetailViewModel(detail: detail)
    PokemonDetailScreen(viewModel: detailViewModel)
        .environment(\.di, di)
}
