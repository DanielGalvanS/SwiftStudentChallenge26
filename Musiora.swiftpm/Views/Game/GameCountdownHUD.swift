//
//  GameCountdownHUD.swift
//  Musiora
//

import SwiftUI

struct GameCountdownHUD: View {
    let countdown: Int

    var body: some View {
        Text(countdown > 0 ? "\(countdown)" : "Go!")
            .font(Theme.Typography.displayLarge)
            .foregroundStyle(Theme.Colors.textPrimary)
            .shadow(color: .white.opacity(0.4), radius: 20)
            .id(countdown)
            .transition(.scale(scale: 1.4).combined(with: .opacity))
            .animation(.easeOut(duration: 0.25), value: countdown)
    }
}
