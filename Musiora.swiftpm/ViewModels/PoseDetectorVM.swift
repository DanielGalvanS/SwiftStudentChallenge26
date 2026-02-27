//
//  File.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

import SwiftUI
import Vision
@preconcurrency import AVFoundation

// MARK: - ViewModel (MainActor)
@MainActor
@Observable
final class PoseDetectorVM {
    private(set) var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    private(set) var isCalibrated: Bool = false
    
    private let captureService = PoseCaptureService()
    var session: AVCaptureSession { captureService.captureSession }
    
    func start() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await startListening()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted { await startListening() }
        default:
            print("❌ Permiso de cámara denegado")
        }
    }
    
    private func startListening() async {
        await captureService.start()
        
        Task {
            guard let stream = await captureService.poseStream else { return }
            for await points in stream {
                self.bodyPoints = points
                self.isCalibrated = points.count >= 4
            }
        }
    }
}

// MARK: - Actor (AVFoundation + Vision)
actor PoseCaptureService {
    nonisolated let captureSession = AVCaptureSession()
    private let outputDelegate = PoseOutputDelegate()
    private(set) var poseStream: AsyncStream<[VNHumanBodyPoseObservation.JointName: CGPoint]>?
    
    private let sessionQueue = DispatchSerialQueue(label: "sessionQueue")
    private let videoQueue = DispatchQueue(label: "videoQueue")
    
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }
    
    func start() {
        poseStream = outputDelegate.poseStream
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .medium
        
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ),
        let input = try? AVCaptureDeviceInput(device: device),
        captureSession.canAddInput(input) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(outputDelegate, queue: videoQueue)
        
        guard captureSession.canAddOutput(output) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(output)
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
    
    // MARK: - Delegate privado dentro del actor
    private final class PoseOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let poseStream: AsyncStream<[VNHumanBodyPoseObservation.JointName: CGPoint]>
        private let continuation: AsyncStream<[VNHumanBodyPoseObservation.JointName: CGPoint]>.Continuation
        
        nonisolated(unsafe) private let bodyRequest = VNDetectHumanBodyPoseRequest()
        
        override init() {
            let (stream, continuation) = AsyncStream.makeStream(
                of: [VNHumanBodyPoseObservation.JointName: CGPoint].self
            )
            self.poseStream = stream
            self.continuation = continuation
        }
        
        func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let handler = VNImageRequestHandler(
                cvPixelBuffer: imageBuffer,
                orientation: .leftMirrored,
                options: [:]
            )
            
            guard (try? handler.perform([bodyRequest])) != nil,
                  let observation = bodyRequest.results?.first else { return }
            
            let points = Self.extractPoints(from: observation)
            continuation.yield(points)
        }
        
        private static func extractPoints(
            from observation: VNHumanBodyPoseObservation
        ) -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
            var points: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
            
            let joints: [VNHumanBodyPoseObservation.JointName] = [
                .nose,
                .leftShoulder, .rightShoulder,
                .leftElbow, .rightElbow,
                .leftWrist, .rightWrist,
                .leftKnee, .rightKnee,
                .leftAnkle, .rightAnkle,
                .root
            ]
            
            for joint in joints {
                if let p = try? observation.recognizedPoint(joint), p.confidence > 0.5 {
                    points[joint] = CGPoint(x: p.x, y: 1 - p.y)
                }
            }
            
            return points
        }
    }
}
