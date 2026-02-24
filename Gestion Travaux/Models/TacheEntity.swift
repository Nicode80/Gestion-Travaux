// TacheEntity.swift
// Gestion Travaux
//
// A work task (chantier item) linked to a room and optionally an activity.

import Foundation
import SwiftData

@Model
final class TacheEntity {
    var titre: String
    var statut: StatutTache = StatutTache.active
    var prochaineAction: String?
    var createdAt: Date = Date()
    /// Set each time a Mode Chantier session starts on this task.
    /// Used to propose the most-recently-worked task first. Nil until first session.
    var lastSessionDate: Date? = nil

    var piece: PieceEntity?
    var activite: ActiviteEntity?

    @Relationship(deleteRule: .cascade, inverse: \AlerteEntity.tache)
    var alertes: [AlerteEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \NoteEntity.tache)
    var notes: [NoteEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \CaptureEntity.tache)
    var captures: [CaptureEntity] = []

    init(titre: String) {
        self.titre = titre
    }
}
