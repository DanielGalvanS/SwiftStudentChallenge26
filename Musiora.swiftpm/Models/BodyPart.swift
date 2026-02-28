//
//  File.swift
//  Musiora
//
//  Created by Daniel Galvan on 27/02/26.
//

import Vision
import SwiftUI

enum BodyPart: String, CaseIterable, Hashable {
    case head
    case leftHand
    case rightHand
    case knees

    var label: String {
        switch self {
        case .head:      return "ACCENT"
        case .leftHand:  return "OFF-BEAT"
        case .rightHand: return "MELODY"
        case .knees:     return "PULSE"
        }
    }

    var color: Color {
        switch self {
        case .head:      return .purple
        case .leftHand:  return .orange
        case .rightHand: return .blue
        case .knees:     return .green
        }
    }

    /// Joints que representan esta parte
    var joints: [VNHumanBodyPoseObservation.JointName] {
        switch self {
        case .head:      return [.nose]
        case .leftHand:  return [.leftWrist]
        case .rightHand: return [.rightWrist]
        case .knees:     return [.leftKnee, .rightKnee]
        }
    }
}
