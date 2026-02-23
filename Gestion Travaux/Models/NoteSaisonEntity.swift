// NoteSaisonEntity.swift
// Gestion Travaux
//
// A seasonal note left by Nico for his future self.
// Displayed on the dashboard after ≥ 2 months of inactivity (FR42).

import Foundation
import SwiftData

@Model
final class NoteSaisonEntity {
    var texte: String
    var createdAt: Date = Date()
    var archivee: Bool = false

    var maison: MaisonEntity?

    init(texte: String) {
        self.texte = texte
    }
}
