//
//  File.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

@preconcurrency import AVFoundation
import Vision
import CoreImage

typealias PoseData = (points: [VNHumanBodyPoseObservation.JointName: CGPoint], area: CGFloat)

actor PoseCaptureService {
    nonisolated let captureSession = AVCaptureSession()
    private(set) var poseStream: AsyncStream<PoseData>?
    private var outputDelegate: PoseOutputDelegate?

    private let sessionQueue = DispatchSerialQueue(
        label: "com.musiora.sessionQueue",
        qos: .userInitiated
    )
    private let videoQueue = DispatchQueue(
        label: "com.musiora.videoQueue",
        qos: .userInitiated
    )

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }

    func start() async {
        // Verificar permisos
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else {
            await AVCaptureDevice.requestAccess(for: .video)
            return
        }

        let delegate = PoseOutputDelegate()
        self.outputDelegate = delegate
        self.poseStream = delegate.poseStream

        configureCaptureSession(delegate: delegate)
        captureSession.startRunning()
    }

    private func configureCaptureSession(delegate: PoseOutputDelegate) {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // Limpiar configuración previa
        captureSession.inputs.forEach(captureSession.removeInput)
        captureSession.outputs.forEach(captureSession.removeOutput)

        // Input — cámara frontal
        guard let input = AVCaptureDeviceInput.createCameraInput(position: .front),
              captureSession.canAddInput(input) else { return }
        captureSession.addInput(input)

        // Frame rate óptimo para Vision (30fps es suficiente)
        input.device.configureFrameRate(30)

        // Output — pixel format BGRA igual que Apple
        let output = AVCaptureVideoDataOutput()
        let pixelTypeKey = String(kCVPixelBufferPixelFormatTypeKey)
        output.videoSettings = [pixelTypeKey: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true  // evita lag

        guard captureSession.canAddOutput(output) else { return }
        captureSession.addOutput(output)

        // Configurar connection
        guard let connection = output.connection(with: .video) else { return }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        if connection.isVideoMirroringSupported {
            // Espejo en el preview para cámara frontal
            connection.isVideoMirrored = true
        }

        output.setSampleBufferDelegate(delegate, queue: videoQueue)
    }
}

// MARK: - Delegate
private final class PoseOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    typealias BodyPoints = PoseData

    let poseStream: AsyncStream<BodyPoints>
    private let continuation: AsyncStream<BodyPoints>.Continuation

    // Reusar el request igual que Apple
    nonisolated(unsafe) private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()

    // CIContext reutilizable — igual que Apple, evita allocations por frame
    nonisolated(unsafe) private let ciContext = CIContext(options: nil)

    override init() {
        (poseStream, continuation) = AsyncStream<BodyPoints>.makeStream()
        super.init()
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Convertir a CGImage igual que Apple — sin orientación manual
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }

        // VNImageRequestHandler con CGImage — sin parámetro de orientación
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([bodyPoseRequest])
        } catch { return }

        guard let observation = bodyPoseRequest.results?.max(by: { a, b in
            areaOf(a) < areaOf(b)
        }) else { return }

        let points = extractPoints(from: observation)
        let area = poseArea(from: points)
        continuation.yield((points: points, area: area))
    }
    
    private func areaOf(_ obs: VNHumanBodyPoseObservation) -> CGFloat {
        let points = obs.availableJointNames.compactMap {
            try? obs.recognizedPoint($0)
        }.filter { $0.confidence >= 0.2 }.map { $0.location }

        guard let minX = points.map({ $0.x }).min(),
              let maxX = points.map({ $0.x }).max(),
              let minY = points.map({ $0.y }).min(),
              let maxY = points.map({ $0.y }).max()
        else { return 0 }

        return (maxX - minX) * (maxY - minY)
    }

    private func extractPoints(
        from observation: VNHumanBodyPoseObservation
    ) -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
        var points: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]

        for jointName in observation.availableJointNames {
            guard let point = try? observation.recognizedPoint(jointName),
                  point.confidence >= 0.2  // threshold de Apple
            else { continue }

            points[jointName] = point.location
        }

        return points
    }
    
    private func poseArea(from points: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> CGFloat {
        let locations = Array(points.values)
        guard let minX = locations.map({ $0.x }).min(),
              let maxX = locations.map({ $0.x }).max(),
              let minY = locations.map({ $0.y }).min(),
              let maxY = locations.map({ $0.y }).max()
        else { return 0.35 }
        return (maxX - minX) * (maxY - minY)
    }
}
