// ActiviteDetailViewModel.swift
// Gestion Travaux
//
// Loads AstuceEntities grouped by level for ActiviteDetailView (Story 4.3).
// Synchronous fetch — SwiftData relationships are already in-memory.

import Foundation
import SwiftData

@Observable
@MainActor
final class ActiviteDetailViewModel {

    let activite: ActiviteEntity

    private(set) var astucesCritiques: [AstuceEntity] = []
    private(set) var astucesImportantes: [AstuceEntity] = []
    private(set) var astucesUtiles: [AstuceEntity] = []

    var totalCount: Int {
        astucesCritiques.count + astucesImportantes.count + astucesUtiles.count
    }

    init(activite: ActiviteEntity) {
        self.activite = activite
    }

    func load() {
        let all = activite.astuces.sorted { $0.createdAt > $1.createdAt }
        astucesCritiques   = all.filter { $0.niveau == .critique }
        astucesImportantes = all.filter { $0.niveau == .importante }
        astucesUtiles      = all.filter { $0.niveau == .utile }
    }
}
