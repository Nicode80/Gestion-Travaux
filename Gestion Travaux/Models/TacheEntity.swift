// TacheEntity.swift
// Gestion Travaux
//
// A work task (chantier item) linked to a room and optionally an activity.

import Foundation
import SwiftData

@Model
final class TacheEntity {
    // titre is derived dynamically from piece.nom and activite.nom.
    // SwiftData ignores computed properties — no column is stored for this.
    var titre: String {
        let p = piece?.nom ?? "Sans pièce"
        let a = activite?.nom ?? "Sans activité"
        return "\(p) — \(a)"
    }

    var statut: StatutTache = StatutTache.active
    var prochaineAction: String?
    var createdAt: Date = Date()
    /// Set each time a Mode Chantier session starts on this task.
    /// Used to propose the most-recently-worked task first. Nil until first session.
    var lastSessionDate: Date? = nil

    var piece: PieceEntity?
    var activite: ActiviteEntity?

    @Relationship(deleteRule: .cascade, inverse: \ToDoEntity.tache)
    var todos: [ToDoEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \AlerteEntity.tache)
    var alertes: [AlerteEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \CaptureEntity.tache)
    var captures: [CaptureEntity] = []

    init() {}
}
