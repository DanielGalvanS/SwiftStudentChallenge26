//
//  HapticManager.swift
//  Musiora
//

import UIKit

/// Global centralized manager for Haptic feedback
@MainActor
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func playTick() {}
    func playSuccess() {}
    func playLight() {}
    func playHeavy() {}
    func playError() {}
}
