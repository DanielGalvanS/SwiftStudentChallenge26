//
//  GlassButtonStyle.swift
//  Musiora
//

import SwiftUI

/// A premium button style that scales down on press and provides haptic feedback.
struct GlassButtonStyle: ButtonStyle {
    var isPrimary: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.titleMedium)
            .foregroundStyle(isPrimary ? Theme.Colors.primaryActionText : Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if isPrimary {
                        Theme.Colors.primaryAction
                    } else {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusMedium))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    HapticManager.shared.playLight()
                }
            }
    }
}

extension View {
    func glassButtonStyle(isPrimary: Bool = true) -> some View {
        self.buttonStyle(GlassButtonStyle(isPrimary: isPrimary))
    }
}
