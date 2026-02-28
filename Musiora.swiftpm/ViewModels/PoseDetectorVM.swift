//
//  File.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

@preconcurrency import AVFoundation
import Vision
import SwiftUI

@MainActor
@Observable
final class PoseDetectorVM {
    private(set) var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    private(set) var isCalibrated: Bool = false
    private(set) var activeMovements: Set<BodyPart> = []
    
    private let beatClock = BeatClock()
    private(set) var currentBeat: Int = 0
    private let captureService = PoseCaptureService()
    private let movementDetector = MovementDetector()

    var session: AVCaptureSession { captureService.captureSession }

    func start() async {
        beatClock.onBeat = { [weak self] beat in
                self?.currentBeat = beat
            }
            beatClock.start()
        movementDetector.onMovement = { [weak self] part in
            self?.flash(part: part)
        }

        await captureService.start()
        guard let stream = await captureService.poseStream else { return }

        for await points in stream {
            self.bodyPoints = points
            self.isCalibrated = points.count >= 4
            movementDetector.update(points: points)
        }
    }

    // Flash visual — la parte se "activa" por 0.15s
    private func flash(part: BodyPart) {
        activeMovements.insert(part)
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            activeMovements.remove(part)
        }
    }
}
