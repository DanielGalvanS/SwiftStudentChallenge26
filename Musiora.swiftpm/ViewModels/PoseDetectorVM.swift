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
    // Incorrect movement off the beat → red on rhythm guide
    private(set) var wrongHits: Set<BodyPart> = []
    // Missed a required beat → red on rhythm guide
    private(set) var missedHits: Set<BodyPart> = []

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
    private(set) var isShowingTutorial: Bool = false
    private var uncalibratedFrames: Int = 0
    private let pauseThreshold: Int = 15        // ~0.5s a 30fps antes de pausar
    private(set) var phaseHits: Int = 0
    private var isTransitioning: Bool = false
    private var autoAdvanceTask: Task<Void, Never>?

    // MARK: - AR Start button
    private(set) var startProgress: Double = 0   // 0→1, anillo de progreso
    private(set) var countdown: Int = 0          // 3, 2, 1, 0 (Go!)
    private(set) var isCountingDown: Bool = false
    private(set) var hasStarted: Bool = false

    // MARK: - Services

    private let beatClock      = BeatClock()
    private let captureService = PoseCaptureService()
    private let movementDetector = MovementDetector()
    private let audioEngine    = AudioEngine()

    private let patterns: [BodyPart: [Bool]] = Dictionary(
        uniqueKeysWithValues: RhythmPattern.all.map { ($0.part, $0.beats) }
    )

    var session: AVCaptureSession { captureService.captureSession }

    /// Parts shown in the rhythm guide panel — all unlocked parts at once.
    /// Grows cumulatively as phases progress.
    var guidesShown: Set<BodyPart> { guidesVisible }

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
            if isCalibrated && !gameActive && !isCountingDown && !isShowingTutorial {
                if isHandNearButton(points: data.points) {
                    startProgress = min(startProgress + (1.0 / 45.0), 1.0)  // ~1.5s a 30fps
                    if startProgress >= 1.0 { beginGame() }
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
        
        // Stop any background clock and flush hit cache
        beatClock.stop()
        clearHitHistory()
        
        // Show tutorial immediately
        isShowingTutorial = true
    }
    
    func dismissTutorial() {
        isShowingTutorial = false

        // First tutorial ever: go through the countdown before starting the game.
        if !hasStarted {
            triggerCountdown()
            return
        }

        clearHitHistory()

        // If the game is paused (body out of frame), don't start the clock or audio yet —
        // resumeGame() will do that when the user re-enters the frame.
        guard !isPaused else { return }

        for part in guidesVisible {
            audioEngine.unlock(part)
        }
        audioEngine.syncAndPlay()
        beatClock.start()
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
        clearHitHistory()
    }

    private func resumeGame() {
        isPaused = false
        uncalibratedFrames = 0
        // If a tutorial is still showing, the clock and audio aren't running yet —
        // dismissTutorial() will start them when the user taps Ready.
        guard !isShowingTutorial else { return }
        // Restore audio directly from guidesVisible — avoids stale savedVolumes
        // that can be corrupted when silenceAll() is called twice (transition + pause).
        for part in guidesVisible {
            audioEngine.unlock(part)
        }
        audioEngine.syncAndPlay()
        beatClock.start()
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
            isCountingDown = false
            hasStarted = true
            gameActive = true
            
            // Kick off audio from beat 0, in sync with the clock
            audioEngine.unlock(.knees)
            audioEngine.syncAndPlay()

            clearHitHistory()
            beatClock.start()
            startAutoAdvance()
        }
    }

    // MARK: - Beat

    private func handleBeat(_ beat: Int) {

        // Check for missed beats from the PREVIOUS beat BEFORE clearing correctHits,
        // otherwise the check always fires (correctHits would be empty after clearing).
        if gameActive && !isCountingDown && !isShowingTutorial {
            let prevBeat = (beat - 1 < 0) ? 7 : (beat - 1)
            for part in BodyPart.allCases {
                guard guidesVisible.contains(part) else { continue }
                if patterns[part]?[prevBeat] == true && !correctHits.contains(part) {
                    flashMissed(part: part)
                }
            }
        }

        // Now safe to clear — missed check already ran against the old state
        correctHits.removeAll()
        wrongHits.removeAll()
        missedHits.removeAll()
        currentBeat = beat
    }

    // MARK: - Movement

    private func handleMovement(part: BodyPart) {
        guard !isShowingTutorial else { return }
        guard gameActive && !isCountingDown else { return }

        // ALWAYS provide visual feedback (drum pad expansion)
        flash(part: part)
        
        // Only grade if the part is actively visible/playing for the current phase
        guard guidesVisible.contains(part) else { return }

        score[part]?.attempts += 1
        if patterns[part]?[currentBeat] == true {
            score[part]?.hits += 1
            flashCorrect(part: part)
            checkPhaseProgress(for: part)
        } else {
            flashWrong(part: part)
        }
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
        // correctHits is cleared on the next beat manually
    }
    
    private func flashWrong(part: BodyPart) {
        wrongHits.insert(part)
        HapticManager.shared.playError()
        // Clear on next beat (~667ms), consistent with correctHits and missedHits
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            wrongHits.remove(part)
        }
    }
    
    private func flashMissed(part: BodyPart) {
        missedHits.insert(part)
        HapticManager.shared.playError()
        // Missed hits clear automatically on the next beat
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
        
        // Completely stop the clock and clear ghosts
        beatClock.stop()
        clearHitHistory()

        switch phase {
        case .pulse:
            // Add left hand on top — knees stay visible and graded
            phase = .offbeat
            guidesVisible.insert(.leftHand)
            audioEngine.silenceAll(duration: 0.4)
            isShowingTutorial = true
            isTransitioning = false

        case .silentPulse:
            // Reserved for future alternate mode
            phase = .offbeat
            guidesVisible.insert(.leftHand)
            isShowingTutorial = true
            isTransitioning = false

        case .offbeat:
            // Add right hand on top — knees + leftHand stay
            phase = .melody
            guidesVisible.insert(.rightHand)
            audioEngine.silenceAll(duration: 0.4)
            isShowingTutorial = true
            isTransitioning = false

        case .melody:
            // Add head on top — all previous parts stay
            phase = .accent
            guidesVisible.insert(.head)
            audioEngine.silenceAll(duration: 0.4)
            isShowingTutorial = true
            isTransitioning = false

        case .accent:
            phase = .results
            audioEngine.stop()
            beatClock.stop()
            isTransitioning = false

        case .freePlay, .results:
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
    
    // MARK: - Helpers
    
    private func clearHitHistory() {
        correctHits.removeAll()
        wrongHits.removeAll()
        missedHits.removeAll()
        activeMovements.removeAll()
    }
}
