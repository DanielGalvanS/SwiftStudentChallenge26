//
//  MovementDetector.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

import Vision
import Foundation

struct MovementConfig {
    let threshold: CGFloat  // minimum peak height to count

    enum Axis {
        case vertical
        case horizontal
        case both
    }

    enum Direction {
        case positive
        case negative
        case any
    }

    // How to combine multiple joints into a single value
    enum Aggregation {
        case average  // mean — good when all joints move together
        case maxY     // highest Y — good when joints alternate (e.g. knees while marching)
    }

    let axis: Axis
    let direction: Direction
    let aggregation: Aggregation
}

@MainActor
final class MovementDetector {
    private var history: [BodyPart: [CGFloat]] = [:]
    private let historySize = 3

    // Per-part cooldown — prevents double-detection on the same hit
    private var lastDetection: [BodyPart: Date] = [:]
    private let cooldown: TimeInterval = 0.20  // 200ms minimum between hits

    // Current pose area — updated every frame
    var poseArea: CGFloat = 0.35  // Apple's typical default value

    // Base thresholds — scaled by pose area
    private let baseConfigs: [BodyPart: MovementConfig] = [
        .knees:     MovementConfig(threshold: 0.020, axis: .vertical, direction: .positive, aggregation: .maxY),    // maxY: captures the rising knee, not the average of both
        .leftHand:  MovementConfig(threshold: 0.080, axis: .vertical, direction: .negative, aggregation: .average),
        .rightHand: MovementConfig(threshold: 0.080, axis: .vertical, direction: .negative, aggregation: .average),
        .head:      MovementConfig(threshold: 0.015, axis: .vertical, direction: .negative, aggregation: .average),
    ]

    var onMovement: ((BodyPart) -> Void)?

    // Area-scaled threshold — same approach Apple uses for drawingScale
    private func scaledThreshold(for part: BodyPart) -> CGFloat {
        guard let base = baseConfigs[part] else { return 0.02 }
        let typicalArea: CGFloat = 0.35  // Apple's reference value
        let scale = poseArea / typicalArea
        // Clamp between 0.75x and 1.5x to avoid extreme scaling
        let clampedScale = min(max(scale, 0.75), 1.5)
        return base.threshold * clampedScale
    }

    func update(points: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        let now = Date()

        for part in BodyPart.allCases {
            guard let config = baseConfigs[part] else { continue }

            let currentPositions = part.joints.compactMap { points[$0] }
            guard !currentPositions.isEmpty else { continue }

            let trackingY: CGFloat = switch config.aggregation {
            case .average: average(currentPositions).y
            case .maxY:    currentPositions.map(\.y).max() ?? 0
            }

            // History always updates (even during cooldown)
            var values = history[part] ?? []
            values.append(trackingY)
            if values.count > historySize { values.removeFirst() }
            history[part] = values

            // Active cooldown → skip detection but keep history fresh
            if let last = lastDetection[part], now.timeIntervalSince(last) < cooldown { continue }

            guard values.count == historySize else { continue }

            let prev2 = values[0]
            let prev1 = values[1]
            let curr  = values[2]

            let threshold = scaledThreshold(for: part)
            var detected = false
            var magnitude: CGFloat = 0

            switch config.direction {
            case .positive:
                // Local position maximum: knee at its highest while marching
                let isPeak = prev1 > prev2 && prev1 > curr
                magnitude = prev1 - min(prev2, curr)
                detected = isPeak && magnitude > threshold

            case .negative:
                // Downward velocity peak: detects the MOMENT of impact (not the valley)
                // vel_a = velocity frame 0→1 (positive = hand moving down)
                // vel_b = velocity frame 1→2 (positive = hand moving down)
                // Peak when vel_a > vel_b: hand was accelerating then decelerates = impact
                let vel_a = prev2 - prev1
                let vel_b = prev1 - curr
                magnitude = vel_a
                detected = vel_a > vel_b && vel_a > threshold

            case .any:
                let isPeak    = prev1 > prev2 && prev1 > curr
                let isValley  = prev1 < prev2 && prev1 < curr
                let peakMag   = prev1 - min(prev2, curr)
                let valleyMag = max(prev2, curr) - prev1
                magnitude = max(peakMag, valleyMag)
                detected = (isPeak || isValley) && magnitude > threshold
            }

            if detected {
                lastDetection[part] = now
                onMovement?(part)
                print("🥁 \(part.label) — mag: \(String(format: "%.3f", magnitude)) threshold: \(String(format: "%.3f", threshold))")
            }
        }
    }

    private func average(_ points: [CGPoint]) -> CGPoint {
        let sum = points.reduce(.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }
}
