//
//  File.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

import SwiftUI
import Vision

struct BodyLabel {
    let text: String
    let color: Color
    let joint: VNHumanBodyPoseObservation.JointName?
    let offset: CGSize
}

struct BodyLabelsOverlay: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let size: CGSize

    private let labels: [BodyLabel] = [
        BodyLabel(text: "ACCENT",       color: .purple, joint: .nose,       offset: CGSize(width: 0, height: -50)),
        BodyLabel(text: "MELODY",      color: .blue,   joint: .rightWrist, offset: CGSize(width: 0, height: -30)),
        BodyLabel(text: "OFF-BEAT", color: .orange, joint: .leftWrist,  offset: CGSize(width: 0, height: -30)),
    ]

    var body: some View {
        ZStack {
            // Labels individuales por joint
            ForEach(labels, id: \.text) { label in
                if let joint = label.joint,
                   let point = bodyPoints[joint] {
                    LabelBubble(text: label.text, color: label.color)
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
                LabelBubble(text: "PULSE", color: .green)
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

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.85))
                    .overlay(
                        Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 1)
                    )
            )
    }
}
