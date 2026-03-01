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

    @State private var strictMode = false
    @State private var animatedOverall: Int = 0

    private var overallAccuracy: Double {
        let values = BodyPart.allCases.compactMap { score[$0] }
        guard !values.isEmpty else { return 0 }
        let sum = values.reduce(0.0) { $0 + (strictMode ? $1.accuracyStrict : $1.accuracy) }
        return sum / Double(values.count)
    }

    private var overallColor: Color {
        overallAccuracy >= 0.7 ? .green : overallAccuracy >= 0.4 ? .orange : Theme.Colors.textPrimary
    }

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

                // Overall accuracy
                VStack(spacing: 4) {
                    Text("\(animatedOverall)%")
                        .font(.system(size: 72, weight: .black, design: .monospaced))
                        .foregroundStyle(overallColor)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4), value: animatedOverall)

                    Text("overall accuracy")
                        .font(Theme.Typography.labelSmall)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                // Accuracy per part
                GlassPanel {
                    VStack(spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Strict mode")
                                    .font(Theme.Typography.labelSmall)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                Text(strictMode ? "Also penalizes missed beats" : "Only counts hits you attempted")
                                    .font(Theme.Typography.labelSmall)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                            Spacer()
                            Toggle("", isOn: $strictMode)
                                .labelsHidden()
                                .tint(Theme.Colors.textPrimary)
                        }

                        Divider().opacity(0.2)

                        ForEach(BodyPart.allCases, id: \.self) { part in
                            if let s = score[part] {
                                AccuracyBarView(part: part, score: s, strict: strictMode)
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)

                // Closing
                Text("What you just trained is called\n**motor independence** —\nthe skill that separates a beginner\nfrom a professional musician.\n\nConservatory students spend years on this.\nYou just experienced it.")
                    .font(Theme.Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)

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
            animateOverall(to: Int(overallAccuracy * 100))
        }
        .onChange(of: strictMode) { _, _ in
            withAnimation(.spring(response: 0.4)) {
                animatedOverall = Int(overallAccuracy * 100)
            }
        }
    }

    private func animateOverall(to target: Int) {
        let steps = max(target, 1)
        let stepDuration = 0.8 / Double(steps)
        Task {
            for i in 0...target {
                try? await Task.sleep(for: .seconds(stepDuration))
                await MainActor.run {
                    withAnimation(.linear(duration: stepDuration)) {
                        animatedOverall = i
                    }
                }
            }
        }
    }
}
