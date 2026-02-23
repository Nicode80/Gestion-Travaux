// NoteEntity.swift
// Gestion Travaux
//
// A free-form note attached to a task (voice transcription or manual text).
// Content stored as JSON-encoded [ContentBlock] in blocksData.

import Foundation
import SwiftData

@Model
final class NoteEntity {
    /// JSON-encoded [ContentBlock]
    var blocksData: Data = Data()
    var createdAt: Date = Date()

    var tache: TacheEntity?

    init() {}
}
