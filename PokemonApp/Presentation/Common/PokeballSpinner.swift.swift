//
//  PokeballSpinner.swift.swift
//  PokemonApp
//
//  Created by Karim Razhanov on 23.10.2025.
//

import SwiftUI

struct PokeballSpinner: View {
    var animating: Bool
    var size: CGFloat = 56
    var period: Double = 1.0

    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSince(start)
            let angle = animating
            ? (t / period * 360).truncatingRemainder(dividingBy: 360)
            : 0
            
            PokeballGlyph(size: size)
                .rotationEffect(.degrees(angle))
                .frame(width: size, height: size)
        }
        .onAppear {
            start = Date()
        }
        .onChange(of: animating) { _, on in
            if on {
                start = Date()
            }
        }
    }
}

private struct PokeballGlyph: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            // Верх — красный полукруг
            Circle()
                .trim(from: 0, to: 0.5)
                .rotation(Angle(degrees: 180))
                .fill(Color.red)

            // Низ — белый полукруг
            Circle()
                .trim(from: 0, to: 0.5)
                .fill(Color.white)

            // Чёрная полоса
            Rectangle()
                .fill(Color.black)
                .frame(height: size * 0.12)
                .offset(y: 0)

            // Белая кайма кнопки
            Circle()
                .stroke(Color.white, lineWidth: size * 0.12)
                .frame(width: size * 0.48, height: size * 0.48)

            // Чёрная кнопка
            Circle()
                .fill(Color.black)
                .frame(width: size * 0.32, height: size * 0.32)

            // Белая точка блика
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: size * 0.09, height: size * 0.09)
                .offset(x: size * 0.08, y: -size * 0.08)
        }
        .clipShape(Circle())
        .frame(width: size, height: size)
        .shadow(radius: 2)
    }
}

#Preview {
    PokeballGlyph(size: 50)
        .padding()
    PokeballSpinner(
        animating: true,
        size: 50
    )
}
