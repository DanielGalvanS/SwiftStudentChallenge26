//
//  GamePhase.swift
//  Musiora
//
//  Created by Daniel Galvan on 28/02/26.
//

import Foundation

enum GamePhase: Equatable {
    case pulse          // Fase 1: Solo rodillas con guía
    case silentPulse    // Fase 1B: Test Dalcroze — música off, cuerpo sigue solo
    case offbeat        // Fase 2: + mano izquierda
    case melody         // Fase 3: + mano derecha
    case accent         // Fase 4: Las 4 partes simultáneas
    case freePlay       // Fase 5: Sin guías — independencia motriz real
    case results        // Pantalla final con métricas

    /// Parte del cuerpo que se entrena en esta fase
    var focusPart: BodyPart? {
        switch self {
        case .pulse, .silentPulse: return .knees
        case .offbeat:             return .leftHand
        case .melody:              return .rightHand
        case .accent:              return .head
        case .freePlay, .results:  return nil
        }
    }

    /// Hits correctos necesarios para avanzar
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

    /// Tiempo límite antes de avanzar automáticamente (segundos)
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

    /// Instrucción visible para el usuario
    var instruction: String {
        switch self {
        case .pulse:       return "Marcha al ritmo con las rodillas"
        case .silentPulse: return "Sigue marchando... sin música"
        case .offbeat:     return "Agrega la mano izquierda"
        case .melody:      return "Agrega la mano derecha"
        case .accent:      return "Asiente con la cabeza en el beat 1"
        case .freePlay:    return "¡Independencia motriz!"
        case .results:     return ""
        }
    }
}
