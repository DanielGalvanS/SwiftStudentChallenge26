//
//  GamePhaseHUD.swift
//  Musiora
//

import SwiftUI

struct GamePhaseHUD: View {
    let phase: GamePhase
    let isPaused: Bool
    
    @State private var bounceScale: CGFloat = 1.0

    var body: some View {
        VStack {
            Spacer()
            if phase != .results && !isPaused {
                Text(phase.instruction)
                    .font(Theme.Typography.titleMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)
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
        }
        .padding(.bottom, 40)
    }
    
    private func triggerBounce() {
        bounceScale = 1.15
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            bounceScale = 1.0
        }
    }
}
