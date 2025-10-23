//
//  ToastView.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 22.10.2025.
//

import SwiftUI

struct ToastView: View {
    let text: String
    var body: some View {
        Text(text)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 3)
    }
}

struct ToasModifier: ViewModifier {
    @Binding var message: String?
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if let message {
                ToastView(text: message)
                    .padding(.bottom, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToasModifier(message: message))
    }
}

#Preview {
    ToastView(text: "Toast test")
}
