//
//  File.swift
//  Musiora
//
//  Created by Daniel Galvan on 28/02/26.
//

import SwiftUI

struct RhythmPattern {
    let part: BodyPart
    // 8 beats — true = debe moverse en ese beat
    let beats: [Bool]

    static let all: [RhythmPattern] = [
        RhythmPattern(part: .knees,     beats: [true, true, true, true, true, true, true, true]),
        RhythmPattern(part: .leftHand,  beats: [false, true, false, true, false, true, false, true]),
        RhythmPattern(part: .rightHand, beats: [true, true, false, true, true, true, true, true]),
        RhythmPattern(part: .head,      beats: [true, false, false, false, false, false, false, false]),
    ]
}
