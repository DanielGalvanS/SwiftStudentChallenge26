//
//  MovementDetector.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

import Vision
import Foundation

struct MovementConfig {
    let threshold: CGFloat
    let axis: Axis
    let direction: Direction

    enum Axis {
        case vertical
        case horizontal
        case both
    }

    enum Direction {
        case positive  // sube (Y aumenta en Vision)
        case negative  // baja
        case any
    }
}

@MainActor
final class MovementDetector {
    private var previousPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]

    private let configs: [BodyPart: MovementConfig] = [
        .knees:     MovementConfig(threshold: 0.025, axis: .vertical, direction: .positive),
        .leftHand:  MovementConfig(threshold: 0.030, axis: .vertical, direction: .positive),
        .rightHand: MovementConfig(threshold: 0.030, axis: .vertical, direction: .positive),
        .head:      MovementConfig(threshold: 0.018, axis: .vertical, direction: .any),
    ]

    var onMovement: ((BodyPart) -> Void)?

    func update(points: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        for part in BodyPart.allCases {
            if didMove(part: part, in: points) {
                onMovement?(part)
                print("🟢 \(part.label) moved")
            }
        }
        previousPoints = points
    }

    private func didMove(
        part: BodyPart,
        in current: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> Bool {
        guard let config = configs[part] else { return false }

        let currentPositions = part.joints.compactMap { current[$0] }
        guard !currentPositions.isEmpty else { return false }
        let currentCenter = average(currentPositions)

        let previousPositions = part.joints.compactMap { previousPoints[$0] }
        guard !previousPositions.isEmpty else { return false }
        let previousCenter = average(previousPositions)

        let dx = currentCenter.x - previousCenter.x
        let dy = currentCenter.y - previousCenter.y

        let delta: CGFloat
        switch config.axis {
        case .vertical:   delta = dy
        case .horizontal: delta = dx
        case .both:       delta = sqrt(dx*dx + dy*dy)
        }

        switch config.direction {
        case .positive: return delta > config.threshold
        case .negative: return delta < -config.threshold
        case .any:      return abs(delta) > config.threshold
        }
    }

    private func average(_ points: [CGPoint]) -> CGPoint {
        let sum = points.reduce(.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }
}
