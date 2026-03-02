// CaptureEntity.swift
// Gestion Travaux
//
// A raw capture made during a Mode Chantier session (voice + optional photo).
// Content stored as JSON-encoded [ContentBlock] in blocksData.
// sessionId links the capture to the active ModeChantierState session.
//
// Story 3.1: classifiee flag + transcription/firstPhotoPath computed helpers.

import Foundation
import SwiftData

@Model
final class CaptureEntity {
    /// JSON-encoded [ContentBlock] (text blocks from transcription + photo blocks)
    var blocksData: Data = Data()
    var createdAt: Date = Date()
    /// UUID matching ModeChantierState.sessionId at capture time
    var sessionId: UUID?

    var tache: TacheEntity?

    /// Whether this capture has been classified (Story 3.1+). Defaults to false.
    var classifiee: Bool = false

    init() {}

    // MARK: - Computed helpers (not persisted)

    /// Aggregated text from all text ContentBlocks, joined by a space.
    var transcription: String {
        blocksData.toContentBlocks()
            .filter { $0.type == .text }
            .compactMap { $0.text }
            .joined(separator: " ")
    }

    /// Relative path of the first photo ContentBlock, or nil if none.
    var firstPhotoPath: String? {
        blocksData.toContentBlocks()
            .first { $0.type == .photo }?
            .photoLocalPath
    }
}
