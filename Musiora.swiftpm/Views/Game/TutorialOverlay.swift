//
//  TutorialOverlay.swift
//  Musiora
//

import SwiftUI

struct TutorialOverlay: View {
    let phase: GamePhase
    let onReady: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: Theme.Layout.paddingLarge) {
                
                Image(systemName: phase.iconName)
                    .font(.system(size: 80))
                    .foregroundStyle(phase.focusPart?.color ?? Theme.Colors.primaryAction)
                    .symbolEffect(.bounce.up, options: .repeating, value: isAnimating)
                    .padding(.bottom, Theme.Layout.paddingMedium)
                    .onAppear {
                        isAnimating = true
                    }
                
                Text(phase.title)
                    .font(Theme.Typography.titleLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Text(phase.tutorialText)
                    .font(Theme.Typography.titleMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Layout.paddingLarge)
                
                Button(action: {
                    HapticManager.shared.playHeavy()
                    onReady()
                }) {
                    Text("Ready!")
                        .font(Theme.Typography.bodyLarge.weight(.bold))
                        .frame(width: 200, height: 60)
                }
                .glassButtonStyle()
                .padding(.top, Theme.Layout.paddingMedium)
            }
            .padding(Theme.Layout.paddingLarge)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
