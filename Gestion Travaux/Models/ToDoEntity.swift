// ToDoEntity.swift
// Gestion Travaux
//
// Story 6.1: Replaces NoteEntity. A to-do item with a priority level and
// iOS Reminders-style animated completion.
// Story 7.4: Linked to TacheEntity (piece + activite) instead of PieceEntity directly,
// so each task has its own independent todo list.

import Foundation
import SwiftData

@Model
final class ToDoEntity {
    var id: UUID = UUID()
    var titre: String
    /// JSON-encoded [ContentBlock] — stores the original capture content (text + photos).
    /// Empty for checkout-created todos (text only).
    var blocksData: Data = Data()
    var priorite: PrioriteToDo
    var estFaite: Bool = false
    var dateFaite: Date?
    var isArchived: Bool = false
    var dateCreation: Date = Date()
    var source: SourceToDo = SourceToDo.manuel

    @Relationship(deleteRule: .nullify)
    var tache: TacheEntity?

    init(titre: String, priorite: PrioriteToDo, tache: TacheEntity, source: SourceToDo = .manuel, blocksData: Data = Data()) {
        self.titre = titre
        self.priorite = priorite
        self.tache = tache
        self.source = source
        self.blocksData = blocksData
    }
}
