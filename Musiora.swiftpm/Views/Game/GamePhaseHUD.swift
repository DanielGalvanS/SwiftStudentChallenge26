//
//  GamePhaseHUD.swift
//  Musiora
//

import SwiftUI

struct GamePhaseHUD: View {
    let phase: GamePhase
    let isPaused: Bool
    let phaseHits: Int
    
    @State private var bounceScale: CGFloat = 1.0

    var body: some View {
        VStack {
            if phase != .results && !isPaused {
                VStack(spacing: Theme.Layout.paddingSmall) {
                    Text(phase.title.uppercased())
                        .font(Theme.Typography.labelMedium)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .kerning(1.5)
                        
                    HStack(spacing: Theme.Layout.paddingSmall) {
                        Text(phase.instruction)
                            .font(Theme.Typography.titleMedium)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    
                    if phase.targetHits > 0 {
                        Text("\(phaseHits) / \(phase.targetHits) 🔥")
                            .font(Theme.Typography.titleMedium.weight(.bold))
                            .foregroundStyle(Theme.Colors.primaryAction)
                    }
                    }
                }
                .padding(.horizontal, Theme.Layout.paddingLarge)
                .padding(.vertical, Theme.Layout.paddingMedium)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.3), radius: 10)
                .scaleEffect(bounceScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: bounceScale)
                .onChange(of: phase) { _ in
                    triggerBounce()
                }
                .onAppear { triggerBounce() }
            }
            Spacer()
        }
        .padding(.top, 60)
    }
    
    private func triggerBounce() {
        bounceScale = 1.15
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            bounceScale = 1.0
        }
    }
}
