// AlerteEntity.swift
// Gestion Travaux
//
// A safety alert or important warning captured during a work session.
// Content stored as JSON-encoded [ContentBlock] in blocksData.

import Foundation
import SwiftData

@Model
final class AlerteEntity {
    /// JSON-encoded [ContentBlock]
    var blocksData: Data = Data()
    var createdAt: Date = Date()

    var tache: TacheEntity?

    init() {}
}
