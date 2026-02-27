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

    private let captureService = PoseCaptureService()

    var session: AVCaptureSession { captureService.captureSession }

    func start() async {
        await captureService.start()

        guard let stream = await captureService.poseStream else { return }

        for await points in stream {
            self.bodyPoints = points
            self.isCalibrated = points.count >= 4
        }
    }
}
