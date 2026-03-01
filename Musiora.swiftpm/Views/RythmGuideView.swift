//
//  File.swift
//  Musiora
//
//  Created by Daniel Galvan on 28/02/26.
//

import SwiftUI

struct RhythmGuideView: View {
    let pattern: RhythmPattern
    let currentBeat: Int
    let userHit: Bool  // el usuario movió esta parte en este beat

    var body: some View {
        HStack(spacing: 6) {
            Text(pattern.part.label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(pattern.part.color)
                .frame(width: 80, alignment: .trailing)

            ForEach(0..<8, id: \.self) { beat in
                ZStack {
                    Circle()
                        .fill(circleColor(beat: beat))
                        .frame(width: circleSize(beat: beat), height: circleSize(beat: beat))
                        .animation(.spring(response: 0.15, dampingFraction: 0.5), value: currentBeat)
                }
                .frame(width: 18, height: 18)  // ← este frame fijo evita que el HStack se mueva
            }
        }
    }

    private func circleColor(beat: Int) -> Color {
        let isActive = beat == currentBeat
        let shouldMove = pattern.beats[beat]

        if isActive && shouldMove {
            return userHit ? .green : pattern.part.color
        } else if isActive {
            return .white.opacity(0.3)
        } else if shouldMove {
            return pattern.part.color.opacity(0.4)
        } else {
            return .white.opacity(0.1)
        }
    }

    private func circleSize(beat: Int) -> CGFloat {
        beat == currentBeat && pattern.beats[beat] ? 18 : 12
    }
}

struct RhythmGuidePanel: View {
    let currentBeat: Int
    let correctHits: Set<BodyPart>
    let guidesVisible: Set<BodyPart>

    var body: some View {
        let visiblePatterns = RhythmPattern.all.filter { guidesVisible.contains($0.part) }
        if !visiblePatterns.isEmpty {
            VStack(alignment: .trailing, spacing: 10) {
                ForEach(visiblePatterns, id: \.part) { pattern in
                    RhythmGuideView(
                        pattern: pattern,
                        currentBeat: currentBeat,
                        userHit: correctHits.contains(pattern.part)
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black.opacity(0.6))
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}
