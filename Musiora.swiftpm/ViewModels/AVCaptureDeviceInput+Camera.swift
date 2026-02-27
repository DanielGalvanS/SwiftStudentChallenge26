//
//  File.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

import AVFoundation

extension AVCaptureDeviceInput {
    static func createCameraInput(position: AVCaptureDevice.Position) -> AVCaptureDeviceInput? {
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: position
        ) else { return nil }

        return try? AVCaptureDeviceInput(device: camera)
    }
}
