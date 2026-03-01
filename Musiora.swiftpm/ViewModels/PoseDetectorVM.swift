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

    // MARK: - Pose

    private(set) var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    private(set) var isCalibrated: Bool = false

    // Any detected movement → flash on AR labels
    private(set) var activeMovements: Set<BodyPart> = []
    // Correct movement on the beat → green on rhythm guide
    private(set) var correctHits: Set<BodyPart> = []

    // MARK: - Rhythm

    private(set) var currentBeat: Int = 0
    private(set) var score: [BodyPart: PartScore] = Dictionary(
        uniqueKeysWithValues: BodyPart.allCases.map { ($0, PartScore()) }
    )

    // MARK: - Game

    private(set) var phase: GamePhase = .pulse
    private(set) var guidesVisible: Set<BodyPart> = [.knees]
    private(set) var gameActive: Bool = false   // true once the game starts
    private(set) var isPaused: Bool = false     // true when body is lost during the game
    private var uncalibratedFrames: Int = 0
    private let pauseThreshold: Int = 15        // ~0.5s a 30fps antes de pausar
    private var phaseHits: Int = 0
    private var isTransitioning: Bool = false
    private var autoAdvanceTask: Task<Void, Never>?

    // MARK: - AR Start button
    private(set) var startProgress: Double = 0   // 0→1, anillo de progreso
    private(set) var countdown: Int = 0          // 3, 2, 1, 0 (Go!)
    private(set) var isCountingDown: Bool = false

    // MARK: - Services

    private let beatClock      = BeatClock()
    private let captureService = PoseCaptureService()
    private let movementDetector = MovementDetector()
    private let audioEngine    = AudioEngine()

    private let patterns: [BodyPart: [Bool]] = Dictionary(
        uniqueKeysWithValues: RhythmPattern.all.map { ($0.part, $0.beats) }
    )

    var session: AVCaptureSession { captureService.captureSession }

    // MARK: - Start

    func start() async {
        movementDetector.onMovement = { [weak self] part in
            self?.handleMovement(part: part)
        }

        // Prepare audio in advance (loads files, no sound yet)
        audioEngine.prepare()

        // Start camera
        await captureService.start()
        guard let stream = await captureService.poseStream else { return }

        for await data in stream {
            bodyPoints = data.points
            let requiredJoints: [VNHumanBodyPoseObservation.JointName] = [
                .nose, .leftWrist, .rightWrist, .leftKnee, .rightKnee
            ]
            isCalibrated = requiredJoints.allSatisfy { data.points[$0] != nil }
            movementDetector.poseArea = data.area
            movementDetector.update(points: data.points)

            // AR button: accumulate/decay progress while body is ready
            if isCalibrated && !gameActive && !isCountingDown {
                if isHandNearButton(points: data.points) {
                    startProgress = min(startProgress + (1.0 / 45.0), 1.0)  // ~1.5s a 30fps
                    if startProgress >= 1.0 { triggerCountdown() }
                } else {
                    startProgress = max(startProgress - (1.0 / 15.0), 0.0)  // decae rápido
                }
            }

            // Pause/resume if body is lost during the game
            if gameActive && phase != .results {
                if isCalibrated {
                    uncalibratedFrames = 0
                    if isPaused { resumeGame() }
                } else {
                    uncalibratedFrames += 1
                    if uncalibratedFrames >= pauseThreshold && !isPaused {
                        pauseGame()
                    }
                }
            }
        }
    }

    private func beginGame() {
        beatClock.onBeat = { [weak self] beat in
            self?.handleBeat(beat)
        }
        beatClock.start()
        audioEngine.startLoops()
        startAutoAdvance()
    }

    func stop() {
        beatClock.stop()
        audioEngine.stop()
        autoAdvanceTask?.cancel()
    }

    private func pauseGame() {
        isPaused = true
        beatClock.stop()
        audioEngine.silenceAll(duration: 0.2)
        autoAdvanceTask?.cancel()
    }

    private func resumeGame() {
        isPaused = false
        uncalibratedFrames = 0
        beatClock.start()
        audioEngine.unsilenceAll(duration: 0.3)
        startAutoAdvance()
    }

    // MARK: - AR Start button

    private func isHandNearButton(points: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> Bool {
        let center = CGPoint(x: 0.5, y: 0.5)
        let radius: CGFloat = 0.15
        for joint in [VNHumanBodyPoseObservation.JointName.leftWrist, .rightWrist] {
            if let p = points[joint] {
                let dx = p.x - center.x
                let dy = p.y - center.y
                if (dx * dx + dy * dy) < (radius * radius) { return true }
            }
        }
        return false
    }

    private func triggerCountdown() {
        isCountingDown = true
        startProgress = 0
        Task {
            for n in [3, 2, 1] {
                countdown = n
                try? await Task.sleep(for: .seconds(1))
            }
            countdown = 0   // ¡Ya!
            try? await Task.sleep(for: .milliseconds(500))
            gameActive = true
            beginGame()
            isCountingDown = false
        }
    }

    // MARK: - Beat

    private func handleBeat(_ beat: Int) {
        currentBeat = beat
        for part in BodyPart.allCases {
            guard patterns[part]?[beat] == true else { continue }
            score[part]?.attempts += 1
        }
    }

    // MARK: - Movement

    private func handleMovement(part: BodyPart) {
        flash(part: part)

        guard patterns[part]?[currentBeat] == true else { return }
        score[part]?.hits += 1
        flashCorrect(part: part)
        checkPhaseProgress(for: part)
    }

    private func flash(part: BodyPart) {
        activeMovements.insert(part)
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            activeMovements.remove(part)
        }
    }

    private func flashCorrect(part: BodyPart) {
        correctHits.insert(part)
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            correctHits.remove(part)
        }
    }

    // MARK: - Phase progress

    private func checkPhaseProgress(for part: BodyPart) {
        guard let focus = phase.focusPart, part == focus else { return }
        phaseHits += 1
        if phaseHits >= phase.targetHits {
            moveToNextPhase()
        }
    }

    // MARK: - Phase transitions

    private func moveToNextPhase() {
        guard !isTransitioning else { return }
        isTransitioning = true
        phaseHits = 0
        autoAdvanceTask?.cancel()

        switch phase {

        case .pulse:
            // Guide disappears → Dalcroze test
            guidesVisible.remove(.knees)
            phase = .silentPulse
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                self.audioEngine.silenceAll(duration: 0.6)
            }
            isTransitioning = false
            startAutoAdvance()

        case .silentPulse:
            // Music returns → add left hand
            phase = .offbeat
            guidesVisible.insert(.leftHand)
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                self.audioEngine.unsilenceAll(duration: 0.5)
                self.audioEngine.unlock(.leftHand)
            }
            isTransitioning = false
            startAutoAdvance()

        case .offbeat:
            guidesVisible.remove(.leftHand)
            phase = .melody
            guidesVisible.insert(.rightHand)
            audioEngine.unlock(.rightHand)
            isTransitioning = false
            startAutoAdvance()

        case .melody:
            guidesVisible.remove(.rightHand)
            phase = .accent
            guidesVisible.insert(.head)
            audioEngine.unlock(.head)
            isTransitioning = false
            startAutoAdvance()

        case .accent:
            guidesVisible.removeAll()
            phase = .freePlay
            isTransitioning = false
            startAutoAdvance()

        case .freePlay:
            phase = .results
            audioEngine.stop()
            beatClock.stop()
            isTransitioning = false

        case .results:
            isTransitioning = false
        }
    }

    private func startAutoAdvance() {
        let limit = phase.timeLimit
        guard limit > 0 else { return }
        autoAdvanceTask = Task {
            try? await Task.sleep(for: .seconds(limit))
            guard !Task.isCancelled else { return }
            self.moveToNextPhase()
        }
    }
}
