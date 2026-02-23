// Enumerations.swift
// Gestion Travaux
//
// All domain enumerations used across SwiftData entities.

import Foundation

enum StatutTache: String, Codable, CaseIterable {
    case active
    case terminee
    case archivee

    /// Human-readable French label used across all views.
    var libelle: String {
        switch self {
        case .active:   "Active"
        case .terminee: "Terminée"
        case .archivee: "Archivée"
        }
    }
}

enum AstuceLevel: String, Codable, CaseIterable {
    case critique
    case importante
    case utile
}

enum BlockType: String, Codable {
    case text
    case photo
}
