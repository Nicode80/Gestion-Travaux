// PieceEntity.swift
// Gestion Travaux
//
// A room inside the home (e.g. "Salon", "Cuisine").

import Foundation
import SwiftData

@Model
final class PieceEntity {
    var nom: String
    var createdAt: Date = Date()

    var maison: MaisonEntity?

    @Relationship(deleteRule: .cascade, inverse: \TacheEntity.piece)
    var taches: [TacheEntity] = []

    init(nom: String) {
        self.nom = nom
    }
}
