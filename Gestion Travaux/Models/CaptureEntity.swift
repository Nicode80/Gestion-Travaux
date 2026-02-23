// CaptureEntity.swift
// Gestion Travaux
//
// A raw capture made during a Mode Chantier session (voice + optional photo).
// Content stored as JSON-encoded [ContentBlock] in blocksData.
// sessionId links the capture to the active ModeChantierState session.

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

    init() {}
}
