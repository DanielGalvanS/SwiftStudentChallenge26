//
//  ResultsView.swift
//  Musiora
//
//  Created by Daniel Galvan on 28/02/26.
//

import SwiftUI

struct ResultsView: View {
    let score: [BodyPart: PartScore]
    let onRestart: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Título
                VStack(spacing: 8) {
                    Text("Independencia\nMotriz")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Así se entrena en los conservatorios.")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Precisión por parte
                VStack(spacing: 14) {
                    ForEach(BodyPart.allCases, id: \.self) { part in
                        if let s = score[part] {
                            HStack(spacing: 12) {
                                Text(part.label)
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(part.color)
                                    .frame(width: 72, alignment: .leading)

                                // Barra de precisión
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.white.opacity(0.1))
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(part.color)
                                            .frame(width: geo.size.width * CGFloat(s.accuracy))
                                    }
                                }
                                .frame(height: 8)

                                Text("\(Int(s.accuracy * 100))%")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .frame(width: 42, alignment: .trailing)
                            }
                        }
                    }
                }
                .padding(.vertical, 22)
                .padding(.horizontal, 20)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 28)

                // Mensaje final
                Text("Eso es lo que los pianistas\nentregan por años.\n\nLo acabas de experimentar\nen 3 minutos.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Spacer()

                // Botón reiniciar
                Button(action: onRestart) {
                    Text("Intentar de nuevo")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
