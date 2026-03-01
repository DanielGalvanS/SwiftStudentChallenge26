//
//  GameStartHUD.swift
//  Musiora
//

import SwiftUI

struct GameStartHUD: View {
    let progress: Double
    let isCalibrated: Bool

    var body: some View {
        Group {
            if isCalibrated {
                VStack(spacing: Theme.Layout.paddingMedium) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.overlayLight)
                            .frame(width: 110, height: 110)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Theme.Colors.primaryAction, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .frame(width: 110, height: 110)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.05), value: progress)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Theme.Colors.primaryAction)
                    }

                    Text("Bring a hand close to start")
                        .font(Theme.Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            } else {
                Text("Step in front of the camera")
                    .font(Theme.Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(.horizontal, Theme.Layout.paddingMedium)
                    .padding(.vertical, Theme.Layout.paddingSmall)
                    .background(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 10)
            }
        }
    }
}
