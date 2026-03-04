// AstuceEntity.swift
// Gestion Travaux
//
// A professional tip or best practice linked to an activity.
// Content stored as JSON-encoded [ContentBlock] in blocksData.

import Foundation
import SwiftData

@Model
final class AstuceEntity {
    var niveau: AstuceLevel = AstuceLevel.utile
    /// JSON-encoded [ContentBlock]
    var blocksData: Data = Data()
    var createdAt: Date = Date()

    var activite: ActiviteEntity?

    init(niveau: AstuceLevel = .utile) {
        self.niveau = niveau
    }

    // MARK: - Computed helpers (not persisted)

    /// First text block content, used in compact displays (BriefingView).
    var preview: String {
        blocksData.toContentBlocks()
            .first(where: { $0.type == .text && ($0.text?.isEmpty == false) })?
            .text ?? ""
    }
}
