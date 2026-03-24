// Enumerations.swift
// Gestion Travaux
//
// All domain enumerations used across SwiftData entities.

import Foundation
import SwiftUI

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
    case up     // TO DO (shows priorité sheet)
    case down   // ACHAT
}

// Final classification type sent to the ViewModel after optional sheet interaction.
enum ClassificationType {
    case alerte
    case astuce(AstuceLevel)
    case toDo(PrioriteToDo)
    case achat
}

// MARK: - ToDo enumerations (Story 6.1)

enum PrioriteToDo: String, Codable, CaseIterable {
    case urgent
    case bientot
    case unJour

    var libelle: String {
        switch self {
        case .urgent:  return "Urgent"
        case .bientot: return "Bientôt"
        case .unJour:  return "Un jour"
        }
    }

    var couleur: Color {
        switch self {
        case .urgent:  return Color(hex: "#FF3B30")
        case .bientot: return Color(hex: "#FF9500")
        case .unJour:  return Color(hex: "#6C6C70")
        }
    }

    /// Sort order: lower = higher priority (used for in-memory list sorting).
    var ordre: Int {
        switch self {
        case .urgent:  return 0
        case .bientot: return 1
        case .unJour:  return 2
        }
    }
}

enum SourceToDo: String, Codable {
    case manuel
    case swipeGame
    case checkout
}
