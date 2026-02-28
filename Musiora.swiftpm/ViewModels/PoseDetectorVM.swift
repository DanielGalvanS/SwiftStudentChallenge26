//
//  PoseDetectorVM.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

@preconcurrency import AVFoundation
import Vision
import SwiftUI

struct PartScore {
    var hits: Int = 0
    var attempts: Int = 0
    var accuracy: Double { attempts > 0 ? Double(hits) / Double(attempts) : 0 }
}

@MainActor
@Observable
final class PoseDetectorVM {
    private(set) var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    private(set) var isCalibrated: Bool = false

    // Cualquier movimiento detectado → flash en etiquetas AR
    private(set) var activeMovements: Set<BodyPart> = []
    // Movimiento correcto (coincide con el patrón en el beat actual) → verde en rhythm guide
    private(set) var correctHits: Set<BodyPart> = []

    private(set) var currentBeat: Int = 0
    private(set) var score: [BodyPart: PartScore] = Dictionary(
        uniqueKeysWithValues: BodyPart.allCases.map { ($0, PartScore()) }
    )

    private let beatClock = BeatClock()
    private let captureService = PoseCaptureService()
    private let movementDetector = MovementDetector()

    // Lookup rápido: part → [Bool] de 8 beats
    private let patterns: [BodyPart: [Bool]] = Dictionary(
        uniqueKeysWithValues: RhythmPattern.all.map { ($0.part, $0.beats) }
    )

    var session: AVCaptureSession { captureService.captureSession }

    func start() async {
        // Movimiento detectado por el peak detector
        movementDetector.onMovement = { [weak self] part in
            self?.handleMovement(part: part)
        }

        // Beat del metrónomo
        beatClock.onBeat = { [weak self] beat in
            self?.handleBeat(beat)
        }
        beatClock.start()

        await captureService.start()
        guard let stream = await captureService.poseStream else { return }

        for await data in stream {
            bodyPoints = data.points
            isCalibrated = data.points.count >= 4
            movementDetector.poseArea = data.area
            movementDetector.update(points: data.points)
        }
    }

    func stop() {
        beatClock.stop()
    }

    // MARK: - Beat handling

    private func handleBeat(_ beat: Int) {
        currentBeat = beat
        // Cada beat que el patrón espera movimiento cuenta como un "intento"
        for part in BodyPart.allCases {
            guard patterns[part]?[beat] == true else { continue }
            score[part]?.attempts += 1
        }
    }

    // MARK: - Movement handling

    private func handleMovement(part: BodyPart) {
        flash(part: part)

        // ¿Coincide con el patrón en este beat?
        guard patterns[part]?[currentBeat] == true else { return }
        score[part]?.hits += 1
        flashCorrect(part: part)
    }

    // Flash en etiquetas AR (cualquier movimiento)
    private func flash(part: BodyPart) {
        activeMovements.insert(part)
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            activeMovements.remove(part)
        }
    }

    // Flash verde en rhythm guide (movimiento correcto)
    private func flashCorrect(part: BodyPart) {
        correctHits.insert(part)
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            correctHits.remove(part)
        }
    }
}
