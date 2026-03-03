// Enumerations.swift
// Gestion Travaux
//
// All domain enumerations used across SwiftData entities.

import Foundation

enum StatutTache: String, Codable, CaseIterable {
    case active
    case terminee

    /// Human-readable French label used across all views.
    var libelle: String {
        switch self {
        case .active:   "Active"
        case .terminee: "Terminée"
        }
    }
}

enum AstuceLevel: String, Codable, CaseIterable {
    case critique
    case importante
    case utile

    /// Human-readable French label used in RecapitulatifView.
    var libelle: String {
        switch self {
        case .critique:    "Critique"
        case .importante:  "Importante"
        case .utile:       "Utile"
        }
    }
}

enum BlockType: String, Codable {
    case text
    case photo
}

// Classification direction detected by the swipe gesture.
enum SwipeDirection: Equatable {
    case left   // ALERTE
    case right  // ASTUCE (shows criticité sheet)
    case up     // NOTE
    case down   // ACHAT
}

// Final classification type sent to the ViewModel after optional sheet interaction.
enum ClassificationType {
    case alerte
    case astuce(AstuceLevel)
    case note
    case achat
}
