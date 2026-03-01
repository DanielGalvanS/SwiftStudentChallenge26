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
    let scores: [BodyPart: PartScore]

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
                        isActive: activeMovements.contains(label.part),
                        hitCount: scores[label.part]?.hits ?? 0
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
                    isActive: activeMovements.contains(.knees),
                    hitCount: scores[.knees]?.hits ?? 0
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
    let hitCount: Int
    
    @State private var floats: [UUID] = []

    var body: some View {
        ZStack {
            // Drum pad outer ring
            Circle()
                .strokeBorder(
                    isActive ? Theme.Colors.textPrimary : color.opacity(0.8),
                    lineWidth: isActive ? 4 : 2
                )
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(isActive ? color.opacity(0.8) : color.opacity(0.3))
                )
                .shadow(color: isActive ? color : .clear, radius: isActive ? 15 : 0)

            // Label text inside the pad
            Text(text)
                .font(Theme.Typography.labelSmall)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            // Floating +1 container
            ZStack {
                ForEach(floats, id: \.self) { id in
                    FloatingPlusOne(color: color)
                }
            }
        }
        .scaleEffect(isActive ? 1.3 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isActive)
        .onChange(of: hitCount) { _ in
            let floatID = UUID()
            floats.append(floatID)
            
            // Cleanup memory after animation finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                floats.removeAll { $0 == floatID }
            }
        }
    }
}

struct FloatingPlusOne: View {
    let color: Color
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Text("+1")
            .font(Theme.Typography.titleMedium.weight(.black))
            .foregroundStyle(color)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    offset = -80 // Float upwards
                    opacity = 0   // Fade out
                }
            }
    }
}
