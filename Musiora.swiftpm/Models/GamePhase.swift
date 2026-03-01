//
//  GamePhase.swift
//  Musiora
//
//  Created by Daniel Galvan on 28/02/26.
//

import Foundation

enum GamePhase: Equatable {
    case pulse          // Phase 1: Knees only with guide
    case silentPulse    // Phase 1B: Dalcroze test — music off, body keeps going alone
    case offbeat        // Phase 2: + left hand
    case melody         // Phase 3: + right hand
    case accent         // Phase 4: All 4 parts simultaneously
    case freePlay       // Phase 5: No guides — real motor independence
    case results        // Final screen with metrics

    /// Body part trained in this phase
    var focusPart: BodyPart? {
        switch self {
        case .pulse, .silentPulse: return .knees
        case .offbeat:             return .leftHand
        case .melody:              return .rightHand
        case .accent:              return .head
        case .freePlay, .results:  return nil
        }
    }

    /// Correct hits needed to advance
    var targetHits: Int {
        switch self {
        case .pulse:               return 6
        case .silentPulse:         return 4
        case .offbeat:             return 6
        case .melody:              return 6
        case .accent:              return 4
        case .freePlay, .results:  return 0
        }
    }

    /// Time limit before auto-advancing (seconds)
    var timeLimit: TimeInterval {
        switch self {
        case .pulse:               return 45
        case .silentPulse:         return 20
        case .offbeat:             return 45
        case .melody:              return 45
        case .accent:              return 30
        case .freePlay:            return 30
        case .results:             return 0
        }
    }

    /// Instruction shown to the user
    var instruction: String {
        switch self {
        case .pulse:       return "Tap your knees like a bass drum 🥁"
        case .silentPulse: return "Keep the bass drum going... without music 🥁"
        case .offbeat:     return "Hit the air with your left hand like a snare 🥁"
        case .melody:      return "Hit the air with your right hand like a cymbal 🥁"
        case .accent:      return "Nod your head to the accent 🧑‍🎤"
        case .freePlay:    return "Play all parts! Motor independence!"
        case .results:     return ""
        }
    }
}
