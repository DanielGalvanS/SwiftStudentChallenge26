//
//  AudioEngine.swift
//  Musiora
//
//  Created by Daniel Galvan on 28/02/26.
//

@preconcurrency import AVFoundation

@MainActor
final class AudioEngine {
    private let engine  = AVAudioEngine()
    private var players: [BodyPart: AVAudioPlayerNode] = [:]
    private var buffers: [BodyPart: AVAudioPCMBuffer] = [:]
    private var savedVolumes: [BodyPart: Float] = [:]
    private(set) var isReady = false

    // Exact loop duration: 16 beats at 90 BPM = 10.6667s
    private static let bpm: Double   = 90
    private static let beats: Double = 16
    private static let loopDuration  = beats * 60.0 / bpm  // 10.6667s

    // MARK: - Setup

    func prepare() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ AVAudioSession: \(error)")
        }

        let tracks: [(BodyPart, String)] = [
            (.knees,     "pulse"),
            (.leftHand,  "offbeat"),
            (.rightHand, "melody"),
            (.head,      "accent"),
        ]

        for (part, name) in tracks {
            guard
                let url    = Bundle.main.url(forResource: name, withExtension: "aif"),
                let file   = try? AVAudioFile(forReading: url),
                let raw    = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                              frameCapacity: AVAudioFrameCount(file.length)),
                (try? file.read(into: raw)) != nil
            else {
                print("⚠️ AudioEngine: could not load \(name).aif")
                continue
            }

            // Trim to exact musical length → removes trailing silence
            let buffer = trimmed(raw)

            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
            player.volume = 0
            players[part] = player
            buffers[part] = buffer
        }

        guard !players.isEmpty else {
            print("⚠️ AudioEngine: no tracks loaded")
            return
        }

        do {
            try engine.start()
            isReady = true
            print("✅ AudioEngine ready — \(players.count)/4 tracks")
        } catch {
            print("⚠️ AudioEngine error: \(error)")
        }
    }

    // MARK: - Playback

    func startLoops() {
        guard isReady else { return }
        players.values.forEach { $0.play() }
    }

    /// Stop all players, re-schedule their buffers from the top, then play them together.
    /// Call this at the exact same moment as BeatClock.start() to guarantee sync.
    func syncAndPlay() {
        guard isReady else { return }
        for (part, player) in players {
            guard let buffer = buffers[part] else { continue }
            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: .loops)
        }
        players.values.forEach { $0.play() }
    }

    func stop() {
        players.values.forEach { $0.stop() }
        engine.stop()
        isReady = false
    }

    // MARK: - Volume

    func unlock(_ part: BodyPart) {
        fade(part: part, to: 1.0, duration: 0.6)
    }

    func silenceAll(duration: TimeInterval = 0.4) {
        for (part, player) in players {
            savedVolumes[part] = player.volume
        }
        for part in BodyPart.allCases {
            fade(part: part, to: 0, duration: duration)
        }
    }

    func unsilenceAll(duration: TimeInterval = 0.5) {
        for (part, saved) in savedVolumes {
            fade(part: part, to: saved, duration: duration)
        }
        savedVolumes = [:]
    }

    func setVolume(_ volume: Float, for part: BodyPart) {
        players[part]?.volume = volume
    }

    // MARK: - Trim buffer to exact musical length

    private func trimmed(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer {
        let sampleRate   = buffer.format.sampleRate
        let targetFrames = AVAudioFrameCount(sampleRate * Self.loopDuration)
        let frames       = min(targetFrames, buffer.frameLength)

        // If already shorter than target, return as-is
        guard frames < buffer.frameLength,
              let out = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: frames),
              let src = buffer.floatChannelData,
              let dst = out.floatChannelData
        else { return buffer }

        out.frameLength = frames
        for ch in 0..<Int(buffer.format.channelCount) {
            dst[ch].update(from: src[ch], count: Int(frames))
        }
        return out
    }

    // MARK: - Fade

    private func fade(part: BodyPart, to target: Float, duration: TimeInterval) {
        guard let player = players[part] else { return }
        // Snap the volume instantly to prevent async races overlapping with Game State changes
        player.volume = target
    }
}
