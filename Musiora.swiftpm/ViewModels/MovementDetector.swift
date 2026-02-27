//
//  File.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

import Vision
import Foundation

/// Detecta si una parte del cuerpo se movió comparando frames consecutivos
@MainActor
final class MovementDetector {
    // Posiciones del frame anterior
    private var previousPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]

    // Threshold — distancia mínima normalizada para considerar movimiento
    private let threshold: CGFloat = 0.015

    // Callback cuando se detecta movimiento
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
        let joints = part.joints

        // Calcular posición promedio actual
        let currentPositions = joints.compactMap { current[$0] }
        guard !currentPositions.isEmpty else { return false }
        let currentCenter = average(currentPositions)

        // Calcular posición promedio anterior
        let previousPositions = joints.compactMap { previousPoints[$0] }
        guard !previousPositions.isEmpty else { return false }
        let previousCenter = average(previousPositions)

        // Distancia euclidiana
        let dx = currentCenter.x - previousCenter.x
        let dy = currentCenter.y - previousCenter.y
        let distance = sqrt(dx * dx + dy * dy)

        return distance > threshold
    }

    private func average(_ points: [CGPoint]) -> CGPoint {
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }
}
