//
//  RefreshButton.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import SwiftUI

struct RefreshButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    @State private var width: CGFloat = 0
    private let height: CGFloat = 44
    
    var body: some View {
        ZStack {
            Button(action: {
                if !isLoading { action() }
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        GeometryReader { geo in
                            Color.accentColor
                                .onAppear {
                                    width = geo.size.width
                                }
                        }
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .opacity(isLoading ? 0 : 1)
            .allowsHitTesting(!isLoading)
            
            if isLoading {
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: width == 0 ? nil : width, height: height)
                    .overlay(ProgressView().tint(.white))
            }
        }
        .frame(height: height)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }
}

#Preview {
    RefreshButton(
        isLoading: true,
        action: {}
    )
}
