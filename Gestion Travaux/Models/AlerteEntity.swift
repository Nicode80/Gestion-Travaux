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
    /// False by default; set to true once the alert is resolved.
    var resolue: Bool = false

    var tache: TacheEntity?

    init() {}

    // MARK: - Computed helpers (not persisted)

    /// First text block content, used in compact displays (BriefingCard, BriefingView).
    var preview: String {
        blocksData.toContentBlocks()
            .first(where: { $0.type == .text && ($0.text?.isEmpty == false) })?
            .text ?? ""
    }
}
