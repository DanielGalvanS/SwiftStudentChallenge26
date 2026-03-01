//
//  WelcomeView.swift
//  Musiora
//
//  Created by Daniel Galvan on 28/02/26.
//

import SwiftUI

struct WelcomeView: View {
    let onStart: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 36) {
                Spacer()

                // Título
                VStack(spacing: 10) {
                    Text("Musiora")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Los pianistas tardan años en aprender\na mover cada parte del cuerpo\ncon un ritmo distinto.")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                // Las 4 partes con sus patrones
                VStack(spacing: 16) {
                    ForEach(BodyPart.allCases, id: \.self) { part in
                        HStack(spacing: 14) {
                            Text(part.label)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(part.color)
                                .frame(width: 72, alignment: .trailing)

                            HStack(spacing: 5) {
                                ForEach(0..<8, id: \.self) { beat in
                                    let active = pattern(for: part)[beat]
                                    Circle()
                                        .fill(active ? part.color : part.color.opacity(0.15))
                                        .frame(width: active ? 10 : 7, height: active ? 10 : 7)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 32)

                Text("Tú lo vas a experimentar en 3 minutos.")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)

                Spacer()

                // Botón
                Button(action: onStart) {
                    Text("Empezar")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    private func pattern(for part: BodyPart) -> [Bool] {
        RhythmPattern.all.first { $0.part == part }?.beats ?? Array(repeating: false, count: 8)
    }
}
