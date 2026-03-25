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
    private let modelContext: ModelContext

    private(set) var astucesCritiques: [AstuceEntity] = []
    private(set) var astucesImportantes: [AstuceEntity] = []
    private(set) var astucesUtiles: [AstuceEntity] = []
    var editError: String? = nil

    var totalCount: Int {
        astucesCritiques.count + astucesImportantes.count + astucesUtiles.count
    }

    init(activite: ActiviteEntity, modelContext: ModelContext) {
        self.activite = activite
        self.modelContext = modelContext
    }

    // MARK: - Edition (Story 7.2)

    func modifierAstuce(_ astuce: AstuceEntity, nouveauxBlocks: [ContentBlock], niveau: AstuceLevel) {
        astuce.blocksData = nouveauxBlocks.toData()
        astuce.niveau = niveau
        do {
            try modelContext.save()
            load()
        } catch {
            editError = "Impossible de modifier cette fiche. Réessayez."
        }
    }

    func load() {
        let all = activite.astuces.sorted { $0.createdAt > $1.createdAt }
        astucesCritiques   = all.filter { $0.niveau == .critique }
        astucesImportantes = all.filter { $0.niveau == .importante }
        astucesUtiles      = all.filter { $0.niveau == .utile }
    }
}
