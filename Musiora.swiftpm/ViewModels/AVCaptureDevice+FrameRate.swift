//
//  File.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

import AVFoundation

extension AVCaptureDevice {
    @discardableResult
    func configureFrameRate(_ frameRate: Double) -> Bool {
        do { try lockForConfiguration() } catch { return false }
        defer { unlockForConfiguration() }

        let sortedRanges = activeFormat.videoSupportedFrameRateRanges
            .sorted { $0.maxFrameRate > $1.maxFrameRate }

        guard let range = sortedRanges.first,
              frameRate >= range.minFrameRate else { return false }

        let duration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
        let inRange = frameRate <= range.maxFrameRate
        activeVideoMinFrameDuration = inRange ? duration : range.minFrameDuration
        activeVideoMaxFrameDuration = range.maxFrameDuration
        return true
    }
}
