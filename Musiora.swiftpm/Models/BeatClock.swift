//
//  File.swift
//  Musiora
//
//  Created by Daniel Galvan on 28/02/26.
//

import Foundation

@MainActor
@Observable
final class BeatClock {
    // 90 BPM = 0.667s per beat
    static let bpm: Double = 90
    static let beatDuration: Double = 60.0 / bpm  // 0.667s

    // 8 subdivisions per bar (2 bars of 4/4)
    private(set) var currentBeat: Int = 0  // 0-7
    private(set) var isRunning: Bool = false

    var onBeat: ((Int) -> Void)?

    private var task: Task<Void, Never>?

    func start() {
        isRunning = true
        let startTime = Date()
        task = Task { [weak self] in
            var beatIndex = 0
            while !Task.isCancelled {
                guard let self else { break }
                self.tick()
                beatIndex += 1
                // Calculates when the NEXT beat should fire from the absolute start time
                // → auto-corrects any accumulated drift from previous beats
                let nextBeatTime = startTime.addingTimeInterval(Double(beatIndex) * BeatClock.beatDuration)
                let delay = nextBeatTime.timeIntervalSinceNow
                if delay > 0 {
                    try? await Task.sleep(for: .seconds(delay))
                }
            }
        }
    }

    func stop() {
        isRunning = false
        task?.cancel()
        task = nil
        currentBeat = 0
    }

    private func tick() {
        onBeat?(currentBeat)
        currentBeat = (currentBeat + 1) % 8
    }
}
