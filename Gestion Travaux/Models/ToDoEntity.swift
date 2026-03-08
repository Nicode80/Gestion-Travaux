// ToDoEntity.swift
// Gestion Travaux
//
// Story 6.1: Replaces NoteEntity. A to-do item linked to a room (PieceEntity),
// with a priority level and iOS Reminders-style animated completion.

import Foundation
import SwiftData

@Model
final class ToDoEntity {
    var id: UUID = UUID()
    var titre: String
    var priorite: PrioriteToDo
    var estFaite: Bool = false
    var dateFaite: Date?
    var isArchived: Bool = false
    var dateCreation: Date = Date()
    var source: SourceToDo = SourceToDo.manuel

    @Relationship(deleteRule: .nullify)
    var piece: PieceEntity?

    init(titre: String, priorite: PrioriteToDo, piece: PieceEntity, source: SourceToDo = .manuel) {
        self.titre = titre
        self.priorite = priorite
        self.piece = piece
        self.source = source
    }
}
