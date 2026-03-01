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
    private var savedVolumes: [BodyPart: Float] = [:]
    private(set) var isReady = false

    // Duración exacta del loop: 16 beats a 90 BPM = 10.6667s
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
                print("⚠️ AudioEngine: no se pudo cargar \(name).aif")
                continue
            }

            // Recortar al largo musical exacto → elimina el silencio del final
            let buffer = trimmed(raw)

            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.volume = 0
            players[part] = player
        }

        guard !players.isEmpty else {
            print("⚠️ AudioEngine: ningún track cargado")
            return
        }

        do {
            try engine.start()
            isReady = true
            print("✅ AudioEngine listo — \(players.count)/4 tracks")
        } catch {
            print("⚠️ AudioEngine error: \(error)")
        }
    }

    // MARK: - Playback

    func startLoops() {
        guard isReady else { return }
        // Sincronizar todos los tracks al mismo AVAudioTime exacto
        if let renderTime = engine.outputNode.lastRenderTime,
           renderTime.isSampleTimeValid {
            let startSample = renderTime.sampleTime + AVAudioFramePosition(renderTime.sampleRate * 0.1)
            let startTime   = AVAudioTime(sampleTime: startSample, atRate: renderTime.sampleRate)
            players.values.forEach { $0.play(at: startTime) }
        } else {
            players.values.forEach { $0.play() }
        }
        setVolume(1.0, for: .knees)
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

    // MARK: - Trim buffer al largo musical exacto

    private func trimmed(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer {
        let sampleRate   = buffer.format.sampleRate
        let targetFrames = AVAudioFrameCount(sampleRate * Self.loopDuration)
        let frames       = min(targetFrames, buffer.frameLength)

        // Si ya es más corto que el target, devolver tal cual
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
        let start    = player.volume
        let steps    = 12
        let delta    = (target - start) / Float(steps)
        let stepTime = duration / Double(steps)

        for i in 1...steps {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(stepTime * Double(i)))
                player.volume = start + delta * Float(i)
            }
        }
    }
}
