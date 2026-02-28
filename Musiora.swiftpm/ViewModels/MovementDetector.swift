//
//  MovementDetector.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

import Vision
import Foundation

struct MovementConfig {
    let threshold: CGFloat  // altura mínima del pico para contar
    
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
    
    let axis: Axis
    let direction: Direction
}

@MainActor
final class MovementDetector {
    private var history: [BodyPart: [CGFloat]] = [:]
    private let historySize = 3

    // Cooldown por parte — evita doble detección en el mismo golpe
    private var lastDetection: [BodyPart: Date] = [:]
    private let cooldown: TimeInterval = 0.20  // 200ms mínimo entre golpes

    // Área actual del pose — se actualiza cada frame
    var poseArea: CGFloat = 0.35  // valor típico de Apple como default

    // Thresholds base — se escalan con el área
    private let baseConfigs: [BodyPart: MovementConfig] = [
        .knees:     MovementConfig(threshold: 0.020, axis: .vertical, direction: .positive),  // marchar = rodilla sube
        .leftHand:  MovementConfig(threshold: 0.025, axis: .vertical, direction: .negative),  // golpear = muñeca baja
        .rightHand: MovementConfig(threshold: 0.025, axis: .vertical, direction: .negative),  // golpear = muñeca baja
        .head:      MovementConfig(threshold: 0.015, axis: .vertical, direction: .negative),  // asentir = cabeza baja
    ]

    var onMovement: ((BodyPart) -> Void)?

    // Threshold escalado por área — igual que Apple escala drawingScale
    private func scaledThreshold(for part: BodyPart) -> CGFloat {
        guard let base = baseConfigs[part] else { return 0.02 }
        let typicalArea: CGFloat = 0.35  // valor de Apple
        let scale = poseArea / typicalArea
        // Clamp entre 0.5x y 2x para no volverse loco
        let clampedScale = min(max(scale, 0.5), 2.0)
        return base.threshold * clampedScale
    }

    func update(points: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        let now = Date()

        for part in BodyPart.allCases {
            guard let config = baseConfigs[part] else { continue }

            let currentPositions = part.joints.compactMap { points[$0] }
            guard !currentPositions.isEmpty else { continue }
            let currentCenter = average(currentPositions)

            // History se actualiza siempre (incluso durante cooldown)
            var values = history[part] ?? []
            values.append(currentCenter.y)
            if values.count > historySize { values.removeFirst() }
            history[part] = values

            // Cooldown activo → skip detección pero mantener history fresco
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
                // Máximo local en posición: rodilla en lo más alto al marchar
                let isPeak = prev1 > prev2 && prev1 > curr
                magnitude = prev1 - min(prev2, curr)
                detected = isPeak && magnitude > threshold

            case .negative:
                // Pico de velocidad descendente: detecta el MOMENTO del golpe (no el valle)
                // vel_a = velocidad frame 0→1 (positivo = mano bajando)
                // vel_b = velocidad frame 1→2 (positivo = mano bajando)
                // Pico cuando vel_a > vel_b: la mano estaba acelerando y ahora desacelera = impacto
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
