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

            VStack(spacing: Theme.Layout.paddingXLarge) {
                Spacer()

                // Título
                VStack(spacing: 8) {
                    Text("Motor\nIndependence")
                        .font(Theme.Typography.displaySmall)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("This is how musicians train at conservatories.")
                        .font(Theme.Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                // Accuracy per part
                GlassPanel {
                    VStack(spacing: 14) {
                        ForEach(BodyPart.allCases, id: \.self) { part in
                            if let s = score[part] {
                                AccuracyBarView(part: part, score: s)
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)

                // Mensaje final
                Text("This is what pianists\ndedicate years to.\n\nYou just experienced it\nin 3 minutes.")
                    .font(Theme.Typography.bodyLarge)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Spacer()

                // Restart button
                Button(action: {
                    HapticManager.shared.playLight()
                    onRestart()
                }) {
                    Text("Try Again")
                }
                .glassButtonStyle()
                .padding(.horizontal, Theme.Layout.paddingXLarge)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            HapticManager.shared.playSuccess()
        }
    }
}
