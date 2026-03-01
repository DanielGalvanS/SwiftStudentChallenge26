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

            VStack(spacing: Theme.Layout.paddingXLarge) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("Musiora")
                        .font(Theme.Typography.displayMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Pianists spend years learning\nto move each body part\nwith a different rhythm.")
                        .font(Theme.Typography.bodyLarge)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                // The 4 parts with their patterns
                GlassPanel {
                    VStack(spacing: Theme.Layout.paddingMedium) {
                        ForEach(BodyPart.allCases, id: \.self) { part in
                            HStack(spacing: 14) {
                                Text(part.label)
                                    .font(Theme.Typography.labelSmall)
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
                }
                .padding(.horizontal, Theme.Layout.paddingXLarge)

                Text("You'll experience it in 3 minutes.")
                    .font(Theme.Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .multilineTextAlignment(.center)

                Spacer()

                // Button
                Button(action: {
                    HapticManager.shared.playHeavy()
                    onStart()
                }) {
                    Text("Experience It")
                }
                .glassButtonStyle()
                .padding(.horizontal, Theme.Layout.paddingXLarge)
                .padding(.bottom, 48)
            }
        }
    }

    private func pattern(for part: BodyPart) -> [Bool] {
        RhythmPattern.all.first { $0.part == part }?.beats ?? Array(repeating: false, count: 8)
    }
}
