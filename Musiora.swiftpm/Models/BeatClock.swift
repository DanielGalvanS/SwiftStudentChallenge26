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
    // 90 BPM = 0.667s por beat
    static let bpm: Double = 90
    static let beatDuration: Double = 60.0 / bpm  // 0.667s

    // 8 subdivisions por compás (2 compases de 4/4)
    private(set) var currentBeat: Int = 0  // 0-7
    private(set) var isRunning: Bool = false

    var onBeat: ((Int) -> Void)?

    private var task: Task<Void, Never>?

    func start() {
        isRunning = true
        task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }
                await self.tick()
                try? await Task.sleep(for: .seconds(BeatClock.beatDuration))
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
