// BriefingViewModelTests.swift
// Gestion TravauxTests
//
// Tests for BriefingViewModel (Story 4.1): loading active alerts,
// critique tips, and AlerteEntity.preview helper.

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

// MARK: - Helpers

private func makeContainer() throws -> ModelContainer {
    let schema = Schema([
        MaisonEntity.self,
        PieceEntity.self,
        TacheEntity.self,
        ActiviteEntity.self,
        AlerteEntity.self,
        AstuceEntity.self,
        NoteEntity.self,
        AchatEntity.self,
        CaptureEntity.self,
        NoteSaisonEntity.self,
        ListeDeCoursesEntity.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

// MARK: - BriefingViewModel tests

@MainActor
struct BriefingViewModelTests {

    @Test("state is .idle before load()")
    func stateIdleBeforeLoad() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let tache = TacheEntity(titre: "Tâche test")
        context.insert(tache)
        try context.save()

        let vm = BriefingViewModel(tache: tache)

        guard case .idle = vm.state else {
            Issue.record("Expected .idle, got \(vm.state)")
            return
        }
    }

    @Test("load() sets state to .success")
    func loadSetsSuccess() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let tache = TacheEntity(titre: "Tâche test")
        context.insert(tache)
        try context.save()

        let vm = BriefingViewModel(tache: tache)
        vm.load()

        guard case .success = vm.state else {
            Issue.record("Expected .success, got \(vm.state)")
            return
        }
    }

    @Test("load() filters out resolved alerts")
    func loadFiltresAlertesResolues() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let tache = TacheEntity(titre: "Tâche")
        context.insert(tache)

        let alerteActive = AlerteEntity()
        alerteActive.resolue = false
        alerteActive.tache = tache

        let alerteResolue = AlerteEntity()
        alerteResolue.resolue = true
        alerteResolue.tache = tache

        context.insert(alerteActive)
        context.insert(alerteResolue)
        try context.save()

        let vm = BriefingViewModel(tache: tache)
        vm.load()

        #expect(vm.alertesActives.count == 1)
        #expect(vm.alertesActives.first?.resolue == false)
    }

    @Test("load() returns empty alertes when task has none")
    func loadEmptyAlertes() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let tache = TacheEntity(titre: "Tâche sans alertes")
        context.insert(tache)
        try context.save()

        let vm = BriefingViewModel(tache: tache)
        vm.load()

        #expect(vm.alertesActives.isEmpty)
    }

    @Test("load() returns only .critique astuces")
    func loadFiltresAstucesCritiques() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let activite = ActiviteEntity(nom: "Peinture")
        let tache = TacheEntity(titre: "Tâche")
        tache.activite = activite

        let astuceCritique = AstuceEntity(niveau: .critique)
        astuceCritique.activite = activite
        let astuceImportante = AstuceEntity(niveau: .importante)
        astuceImportante.activite = activite
        let astuceUtile = AstuceEntity(niveau: .utile)
        astuceUtile.activite = activite

        context.insert(activite)
        context.insert(tache)
        context.insert(astuceCritique)
        context.insert(astuceImportante)
        context.insert(astuceUtile)
        try context.save()

        let vm = BriefingViewModel(tache: tache)
        vm.load()

        #expect(vm.astucesCritiques.count == 1)
        #expect(vm.astucesCritiques.first?.niveau == .critique)
    }

    @Test("load() returns empty astuces when activite is nil")
    func loadEmptyAstucesWhenNoActivite() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let tache = TacheEntity(titre: "Tâche sans activité")
        context.insert(tache)
        try context.save()

        let vm = BriefingViewModel(tache: tache)
        vm.load()

        #expect(vm.astucesCritiques.isEmpty)
    }

    @Test("load() returns all non-resolved alerts when multiple exist")
    func loadMultipleAlertesActives() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let tache = TacheEntity(titre: "Tâche multi-alertes")
        context.insert(tache)

        for _ in 0..<3 {
            let alerte = AlerteEntity()
            alerte.resolue = false
            alerte.tache = tache
            context.insert(alerte)
        }
        let alerteResolue = AlerteEntity()
        alerteResolue.resolue = true
        alerteResolue.tache = tache
        context.insert(alerteResolue)
        try context.save()

        let vm = BriefingViewModel(tache: tache)
        vm.load()

        #expect(vm.alertesActives.count == 3)
    }
}

// MARK: - AlerteEntity.preview tests

@MainActor
struct AlertePreviewTests {

    @Test("preview extracts first text block")
    func previewExtractsText() {
        let alerte = AlerteEntity()
        let blocks = [ContentBlock(type: .text, text: "Risque électrique", order: 0)]
        alerte.blocksData = blocks.toData()
        #expect(alerte.preview == "Risque électrique")
    }

    @Test("preview is empty when no text blocks")
    func previewEmptyWhenNoText() {
        let alerte = AlerteEntity()
        alerte.blocksData = [ContentBlock(type: .photo, photoLocalPath: "x.jpg", order: 0)].toData()
        #expect(alerte.preview.isEmpty)
    }

    @Test("preview is empty when blocksData is empty")
    func previewEmptyWhenNoBlocks() {
        let alerte = AlerteEntity()
        // blocksData defaults to Data()
        #expect(alerte.preview.isEmpty)
    }

    @Test("preview returns first text block ignoring empty strings")
    func previewSkipsEmptyTextBlocks() {
        let alerte = AlerteEntity()
        let blocks = [
            ContentBlock(type: .text, text: "", order: 0),
            ContentBlock(type: .text, text: "Attention plafond fragile", order: 1),
        ]
        alerte.blocksData = blocks.toData()
        #expect(alerte.preview == "Attention plafond fragile")
    }

    @Test("AlerteEntity.resolue defaults to false")
    func resolueDefaultsFalse() {
        let alerte = AlerteEntity()
        #expect(alerte.resolue == false)
    }
}

// MARK: - AstuceEntity.preview tests

@MainActor
struct AstucePreviewTests {

    @Test("preview extracts first text block")
    func previewExtractsText() {
        let astuce = AstuceEntity(niveau: .critique)
        let blocks = [ContentBlock(type: .text, text: "Ne pas couper le courant", order: 0)]
        astuce.blocksData = blocks.toData()
        #expect(astuce.preview == "Ne pas couper le courant")
    }

    @Test("preview is empty when no text blocks")
    func previewEmptyWhenNoText() {
        let astuce = AstuceEntity()
        astuce.blocksData = [ContentBlock(type: .photo, photoLocalPath: "x.jpg", order: 0)].toData()
        #expect(astuce.preview.isEmpty)
    }

    @Test("preview is empty when blocksData is empty")
    func previewEmptyWhenNoBlocks() {
        let astuce = AstuceEntity()
        // blocksData defaults to Data()
        #expect(astuce.preview.isEmpty)
    }

    @Test("preview skips empty text blocks")
    func previewSkipsEmptyTextBlocks() {
        let astuce = AstuceEntity(niveau: .importante)
        let blocks = [
            ContentBlock(type: .text, text: "", order: 0),
            ContentBlock(type: .text, text: "Aérer la pièce avant de peindre", order: 1),
        ]
        astuce.blocksData = blocks.toData()
        #expect(astuce.preview == "Aérer la pièce avant de peindre")
    }
}
