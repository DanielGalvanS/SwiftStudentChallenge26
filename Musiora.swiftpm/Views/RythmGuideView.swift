//
//  RhythmGuideView.swift
//  Musiora
//
//  Created by Daniel Galvan on 28/02/26.
//

import SwiftUI

extension Theme.Colors {
    static let error = Color.red
}

struct RhythmGuideView: View {
    let pattern: RhythmPattern
    let currentBeat: Int
    let userHit: Bool
    let missedHit: Bool
    let wrongHit: Bool

    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 6) {
            Text(pattern.part.label)
                .font(Theme.Typography.labelSmall)
                .foregroundStyle(pattern.part.color)
                .frame(width: 80, alignment: .trailing)

            ForEach(0..<8, id: \.self) { beat in
                ZStack {
                    Circle()
                        .fill(circleColor(beat: beat))
                        .shadow(color: circleGlow(beat: beat), radius: 6)
                        .frame(width: circleSize(beat: beat), height: circleSize(beat: beat))
                        .offset(x: (beat == currentBeat && (missedHit || wrongHit)) ? shakeOffset : 0)
                        .animation(.spring(response: 0.15, dampingFraction: 0.5), value: currentBeat)
                }
                .frame(width: 18, height: 18)
            }
        }
        .onChange(of: userHit) { hit in
            if hit {
                HapticManager.shared.playTick()
            }
        }
        .onChange(of: missedHit) { missed in
            if missed {
                triggerShake()
            }
        }
        .onChange(of: wrongHit) { wrong in
            if wrong {
                triggerShake()
            }
        }
    }

    private func triggerShake() {
        withAnimation(.default.speed(4).repeatCount(3, autoreverses: true)) {
            shakeOffset = 4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shakeOffset = 0
        }
    }

    private func circleColor(beat: Int) -> Color {
        let isActive = beat == currentBeat
        let shouldMove = pattern.beats[beat]

        if isActive && shouldMove {
            if userHit { return Theme.Colors.success }
            if missedHit { return Theme.Colors.error }
            return pattern.part.color
        } else if isActive && !shouldMove {
            if wrongHit { return Theme.Colors.error }
            return .white.opacity(0.3)
        } else if shouldMove {
            return pattern.part.color.opacity(0.4)
        } else {
            return .white.opacity(0.1)
        }
    }
    
    private func circleGlow(beat: Int) -> Color {
        let isActive = beat == currentBeat
        let shouldMove = pattern.beats[beat]
        
        if isActive && shouldMove && userHit {
            return Theme.Colors.success.opacity(0.5)
        }
        if isActive && (missedHit || wrongHit) {
            return Theme.Colors.error.opacity(0.6)
        }
        return .clear
    }

    private func circleSize(beat: Int) -> CGFloat {
        beat == currentBeat && pattern.beats[beat] ? 18 : 12
    }
}

struct RhythmGuidePanel: View {
    let currentBeat: Int
    let correctHits: Set<BodyPart>
    let missedHits: Set<BodyPart>
    let wrongHits: Set<BodyPart>
    let guidesVisible: Set<BodyPart>

    var body: some View {
        let visiblePatterns = RhythmPattern.all.filter { guidesVisible.contains($0.part) }
        if !visiblePatterns.isEmpty {
            VStack(alignment: .trailing, spacing: 10) {
                ForEach(visiblePatterns, id: \.part) { pattern in
                    RhythmGuideView(
                        pattern: pattern,
                        currentBeat: currentBeat,
                        userHit: correctHits.contains(pattern.part),
                        missedHit: missedHits.contains(pattern.part),
                        wrongHit: wrongHits.contains(pattern.part)
                    )
                }
            }
            .padding(Theme.Layout.paddingMedium)
            .background(.regularMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusMedium))
            .shadow(color: .black.opacity(0.2), radius: 10)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}
