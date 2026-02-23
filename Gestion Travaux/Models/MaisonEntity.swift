// MaisonEntity.swift
// Gestion Travaux
//
// Singleton entity representing the user's home. Created once on first launch.

import Foundation
import SwiftData

@Model
final class MaisonEntity {
    var nom: String

    @Relationship(deleteRule: .cascade, inverse: \PieceEntity.maison)
    var pieces: [PieceEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \NoteSaisonEntity.maison)
    var notesSaison: [NoteSaisonEntity] = []

    init(nom: String) {
        self.nom = nom
    }
}
