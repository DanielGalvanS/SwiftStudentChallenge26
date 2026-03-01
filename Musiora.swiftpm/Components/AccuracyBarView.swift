//
//  AccuracyBarView.swift
//  Musiora
//

import SwiftUI

struct AccuracyBarView: View {
    let part: BodyPart
    let score: PartScore
    
    @State private var animatedWidth: CGFloat = 0
    @State private var animatedPercentage: Int = 0
    
    var body: some View {
        HStack(spacing: Theme.Layout.paddingMedium) {
            Text(part.label)
                .font(Theme.Typography.labelSmall)
                .foregroundStyle(part.color)
                .frame(width: 72, alignment: .leading)

            // Accuracy bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.overlayLight)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(part.color)
                        .frame(width: animatedWidth)
                }
                .onAppear {
                    let targetWidth = geo.size.width * CGFloat(score.accuracy)
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                        animatedWidth = targetWidth
                    }
                }
            }
            .frame(height: 8)

            Text("\(animatedPercentage)%")
                .font(Theme.Typography.labelMedium)
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 42, alignment: .trailing)
                .contentTransition(.numericText())
                .onAppear {
                    let targetPercentage = Int(score.accuracy * 100)
                    animatePercentage(to: targetPercentage)
                }
        }
    }
    
    private func animatePercentage(to target: Int) {
        let duration = 0.8
        let steps = target > 0 ? target : 1
        let stepDuration = duration / Double(steps)
        
        Task {
            for i in 0...target {
                try? await Task.sleep(for: .seconds(stepDuration))
                await MainActor.run {
                    withAnimation(.linear(duration: stepDuration)) {
                        animatedPercentage = i
                    }
                }
            }
        }
    }
}
