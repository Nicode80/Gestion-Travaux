// ActiviteEntity.swift
// Gestion Travaux
//
// A work category / trade (e.g. "Électricité", "Peinture") that groups tasks.

import Foundation
import SwiftData

@Model
final class ActiviteEntity {
    var nom: String
    var createdAt: Date = Date()

    /// Tasks belonging to this activity. No cascade — deleting an activity does not delete tasks.
    @Relationship(inverse: \TacheEntity.activite)
    var taches: [TacheEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \AstuceEntity.activite)
    var astuces: [AstuceEntity] = []

    init(nom: String) {
        self.nom = nom
    }
}
