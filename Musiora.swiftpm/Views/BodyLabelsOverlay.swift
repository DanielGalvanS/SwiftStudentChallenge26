//
//  File.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

import SwiftUI
import Vision

struct BodyLabel: Identifiable {
    let id = UUID()
    let text: String
    let color: Color
    let part: BodyPart
    let joint: VNHumanBodyPoseObservation.JointName?
    let offset: CGSize
}

struct BodyLabelsOverlay: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let size: CGSize
    let activeMovements: Set<BodyPart>

    private let labels: [BodyLabel] = [
        BodyLabel(text: "ACCENT",       color: .purple, part: .head,      joint: .nose,       offset: CGSize(width: 0, height: -50)),
        BodyLabel(text: "MELODY",      color: .blue,   part: .rightHand, joint: .rightWrist, offset: CGSize(width: 0, height: -30)),
        BodyLabel(text: "OFF-BEAT", color: .orange, part: .leftHand,  joint: .leftWrist,  offset: CGSize(width: 0, height: -30)),
    ]

    var body: some View {
        ZStack {
            ForEach(labels) { label in
                if let joint = label.joint,
                   let point = bodyPoints[joint] {
                    LabelBubble(
                        text: label.text,
                        color: label.color,
                        isActive: activeMovements.contains(label.part)
                    )
                    .position(
                        x: visionToScreen(point, size: size).x + label.offset.width,
                        y: visionToScreen(point, size: size).y + label.offset.height
                    )
                }
            }

            // Rodillas — punto medio
            if let leftKnee = bodyPoints[.leftKnee],
               let rightKnee = bodyPoints[.rightKnee] {
                let mid = midpoint(leftKnee, rightKnee)
                LabelBubble(
                    text: "PULSE",
                    color: .green,
                    isActive: activeMovements.contains(.knees)
                )
                .position(
                    x: visionToScreen(mid, size: size).x,
                    y: visionToScreen(mid, size: size).y - 30
                )
            }
        }
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private func visionToScreen(_ point: CGPoint, size: CGSize) -> CGPoint {
        let videoAspect: CGFloat = 4.0 / 3.0
        let screenAspect: CGFloat = size.height / size.width

        var x = point.x * size.width
        let y = (1 - point.y) * size.height

        if screenAspect > videoAspect {
            let scaledWidth = size.height / videoAspect
            let offset = (scaledWidth - size.width) / 2
            x = point.x * scaledWidth - offset
        }

        return CGPoint(x: x, y: y)
    }
}

struct LabelBubble: View {
    let text: String
    let color: Color
    let isActive: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isActive ? color : color.opacity(0.6))
                    .shadow(color: isActive ? color : .clear, radius: isActive ? 12 : 0)
                    .overlay(
                        Capsule().strokeBorder(
                            isActive ? .white : .white.opacity(0.3),
                            lineWidth: isActive ? 2 : 1
                        )
                    )
            )
            .scaleEffect(isActive ? 1.2 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isActive)
    }
}
