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
        case .silentPulse:         return 6
        case .offbeat:             return 6
        case .melody:              return 6
        case .accent:              return 4
        case .freePlay, .results:  return 0
        }
    }

    /// Time limit before auto-advancing (seconds). 0 means wait for targetHits.
    var timeLimit: TimeInterval {
        switch self {
        case .pulse, .silentPulse, .offbeat, .melody, .accent, .results: 
            return 0 // Must complete required hits
        case .freePlay:            
            return 30
        }
    }

    /// Title shown in the HUD
    var title: String {
        switch self {
        case .pulse:       return "Act 1: The Pulse"
        case .silentPulse: return "Dalcroze Challenge"
        case .offbeat:     return "Act 2: The Snare"
        case .melody:      return "Act 3: The Cymbal"
        case .accent:      return "Act 4: The Accent"
        case .freePlay:    return "Grand Finale"
        case .results:     return "Results"
        }
    }

    /// Instruction shown to the user during gameplay
    var instruction: String {
        switch self {
        case .pulse:       return "Tap your knees like a bass drum 🥁"
        case .silentPulse: return "Keep the bass drum going... without music 🥁"
        case .offbeat:     return "Hit the air with your left hand like a snare 🥁"
        case .melody:      return "Hit the air with your right hand like a cymbal 🥁"
        case .accent:      return "Nod your head to the accent 🧑‍🎤"
        case .freePlay:    return "All four parts — hit them all! 🥁"
        case .results:     return ""
        }
    }

    /// Detailed instruction shown before the phase begins
    var tutorialText: String {
        switch self {
        case .pulse:
            return "The circles at the bottom show the beat. Tap both knees downward — like stomping a bass drum pedal — exactly when the circle lights up. You need 6 correct hits to advance."
        case .silentPulse: 
            return "The music will stop, but the beat continues in your head. Keep tapping your knees to the internal rhythm."
        case .offbeat:
            return "Let's add the snare. Strike downward with your left hand — like hitting a drum pad — exactly when its guide lights up."
        case .melody:
            return "Now the cymbal. Strike downward with your right hand — same motion, like hitting a drum pad — on the new rhythm."
        case .accent:
            return "Finally, the accent. Nod your head downward on beat 1 — a single firm nod, like a drummer marking the top of the bar."
        case .freePlay:
            return "Now all four parts at once — knees, left hand, right hand, and head. Hit each one at the right moment. You have 30 seconds. Go!"
        case .results:     
            return "Well done!"
        }
    }

    /// The SF Symbol icon used to teach the movement
    var iconName: String {
        switch self {
        case .pulse:       return "arrow.down.app.fill"
        case .silentPulse: return "speaker.slash.fill"
        case .offbeat:     return "hand.point.up.left.fill"
        case .melody:      return "hand.point.up.right.fill"
        case .accent:      return "person.fill"
        case .freePlay:    return "music.quarternote.3"
        case .results:     return "star.fill"
        }
    }
}
