// CheckoutViewModelTests.swift
// Gestion TravauxTests
//
// Story 3.3: Tests for ClassificationViewModel additions —
//   summaryItems accumulation, reclassify, validateClassifications,
//   saveProchaineAction, and markTaskAsTerminee.
// Uses an in-memory ModelContainer to avoid touching the real SwiftData store.

import Testing
import Foundation
import SwiftData
@testable import Gestion_Travaux

@MainActor
struct CheckoutViewModelTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MaisonEntity.self, PieceEntity.self, TacheEntity.self,
                ActiviteEntity.self, AlerteEntity.self, AstuceEntity.self,
                NoteEntity.self, AchatEntity.self, CaptureEntity.self,
                ListeDeCoursesEntity.self, NoteSaisonEntity.self,
            configurations: config
        )
    }

    /// Creates a CaptureEntity with a single text block and inserts it.
    private func makeCapture(
        texte: String = "Texte test",
        tache: TacheEntity? = nil,
        in context: ModelContext
    ) -> CaptureEntity {
        let block = ContentBlock(type: .text, text: texte, order: 0)
        let capture = CaptureEntity()
        capture.blocksData = [block].toData()
        capture.tache = tache
        context.insert(capture)
        return capture
    }

    private func makeTache(in context: ModelContext) -> TacheEntity {
        let tache = TacheEntity(titre: "Salon — Peinture")
        context.insert(tache)
        return tache
    }

    private func makeLDC(in context: ModelContext) -> ListeDeCoursesEntity {
        let ldc = ListeDeCoursesEntity()
        context.insert(ldc)
        return ldc
    }

    // MARK: - summaryItems accumulation

    @Test("classify alerte appends one summary item with correct type and destination")
    func classifyAlerteAppendsSummaryItem() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = makeTache(in: context)
        let capture = makeCapture(texte: "Risque electrique", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .alerte)

        #expect(vm.summaryItems.count == 1)
        let item = vm.summaryItems[0]
        if case .alerte = item.type {} else { Issue.record("Expected .alerte type") }
        #expect(item.destination == tache.titre)
        #expect(item.capturePreview == "Risque electrique")
    }

    @Test("classify astuce appends summary item with niveau and activite destination")
    func classifyAstuceAppendsSummaryItem() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let activite = ActiviteEntity(nom: "Pose Placo")
        context.insert(activite)
        let tache = makeTache(in: context)
        tache.activite = activite
        let capture = makeCapture(texte: "Astuce placo", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .astuce(.critique))

        #expect(vm.summaryItems.count == 1)
        let item = vm.summaryItems[0]
        if case .astuce(let niveau) = item.type {
            #expect(niveau == .critique)
        } else {
            Issue.record("Expected .astuce(.critique) type")
        }
        #expect(item.destination == "Activité : Pose Placo")
    }

    @Test("classify note appends summary item with note type")
    func classifyNoteAppendsSummaryItem() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = makeTache(in: context)
        let capture = makeCapture(texte: "Note chantier", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .note)

        #expect(vm.summaryItems.count == 1)
        if case .note = vm.summaryItems[0].type {} else { Issue.record("Expected .note type") }
    }

    @Test("classify achat appends summary item with achat type and Liste de courses destination")
    func classifyAchatAppendsSummaryItem() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        _ = makeLDC(in: context)
        let capture = makeCapture(texte: "Chevilles 6mm", in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .achat)

        #expect(vm.summaryItems.count == 1)
        if case .achat = vm.summaryItems[0].type {} else { Issue.record("Expected .achat type") }
        #expect(vm.summaryItems[0].destination == "Liste de courses")
    }

    @Test("multiple classify calls accumulate all summary items")
    func multipleClassifiesAccumulate() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        _ = makeLDC(in: context)
        let c1 = makeCapture(texte: "Un", in: context)
        let c2 = makeCapture(texte: "Deux", in: context)
        let c3 = makeCapture(texte: "Trois", in: context)
        try context.save()

        vm.charger()
        vm.classify(c1, as: .alerte)
        vm.classify(c2, as: .note)
        vm.classify(c3, as: .achat)

        #expect(vm.summaryItems.count == 3)
    }

    // MARK: - reclassify

    @Test("reclassify changes entity type and updates summaryItems")
    func reclassifyChangesType() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = makeTache(in: context)
        let capture = makeCapture(texte: "A reclassifier", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .alerte)
        #expect(vm.summaryItems.count == 1)

        let item = vm.summaryItems[0]
        vm.reclassify(item: item, newType: .note)

        #expect(vm.summaryItems.count == 1)
        if case .note = vm.summaryItems[0].type {} else { Issue.record("Expected .note after reclassify") }
        // Original AlerteEntity should be gone
        let alertes = try context.fetch(FetchDescriptor<AlerteEntity>())
        #expect(alertes.isEmpty)
        // New NoteEntity should exist
        let notes = try context.fetch(FetchDescriptor<NoteEntity>())
        #expect(notes.count == 1)
    }

    @Test("reclassify preserves original blocksData in new entity")
    func reclassifyPreservesBlocksData() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = makeTache(in: context)
        let capture = makeCapture(texte: "Contenu original", tache: tache, in: context)
        let originalData = capture.blocksData
        try context.save()

        vm.charger()
        vm.classify(capture, as: .alerte)

        let item = vm.summaryItems[0]
        vm.reclassify(item: item, newType: .note)

        let notes = try context.fetch(FetchDescriptor<NoteEntity>())
        #expect(notes.count == 1)
        #expect(notes[0].blocksData == originalData)
    }

    @Test("reclassify alerte to astuce creates AstuceEntity")
    func reclassifyAlerteToAstuce() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let activite = ActiviteEntity(nom: "Peinture")
        context.insert(activite)
        let tache = makeTache(in: context)
        tache.activite = activite
        let capture = makeCapture(texte: "Astuce repeinture", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .alerte)
        let item = vm.summaryItems[0]
        vm.reclassify(item: item, newType: .astuce(.importante))

        if case .astuce(let niveau) = vm.summaryItems[0].type {
            #expect(niveau == .importante)
        } else {
            Issue.record("Expected .astuce(.importante)")
        }
        let astuces = try context.fetch(FetchDescriptor<AstuceEntity>())
        #expect(astuces.count == 1)
        #expect(astuces[0].niveau == .importante)
    }

    @Test("reclassify to achat creates AchatEntity with transcription text")
    func reclassifyToAchat() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        _ = makeLDC(in: context)
        let tache = makeTache(in: context)
        let capture = makeCapture(texte: "Visses bois 4mm", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .note)
        let item = vm.summaryItems[0]
        vm.reclassify(item: item, newType: .achat)

        let achats = try context.fetch(FetchDescriptor<AchatEntity>())
        #expect(achats.count == 1)
        #expect(achats[0].texte == "Visses bois 4mm")
    }

    // MARK: - validateClassifications

    @Test("validateClassifications returns true when no unclassified captures remain")
    func validateTrueWhenAllClassified() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        // No captures inserted → all classified by default
        #expect(vm.validateClassifications() == true)
    }

    @Test("validateClassifications returns false when unclassified captures remain")
    func validateFalseWhenCapturesRemain() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let capture = CaptureEntity()
        capture.classifiee = false
        context.insert(capture)
        try context.save()

        #expect(vm.validateClassifications() == false)
    }

    @Test("validateClassifications returns true when all captures are marked classifiee=true")
    func validateTrueWhenMarkedClassified() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let capture = CaptureEntity()
        capture.classifiee = true
        context.insert(capture)
        try context.save()

        #expect(vm.validateClassifications() == true)
    }

    // MARK: - saveProchaineAction

    @Test("saveProchaineAction updates tache.prochaineAction and persists")
    func saveProchaineActionUpdates() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = makeTache(in: context)
        try context.save()

        vm.prochaineActionInput = "Acheter chevilles"
        vm.saveProchaineAction(for: tache)

        #expect(vm.checkoutError == nil)
        #expect(tache.prochaineAction == "Acheter chevilles")

        // Verify persisted by re-fetching
        let taches = try context.fetch(FetchDescriptor<TacheEntity>())
        #expect(taches.first?.prochaineAction == "Acheter chevilles")
    }

    @Test("saveProchaineAction trims whitespace before saving")
    func saveProchaineActionTrimsWhitespace() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = makeTache(in: context)
        try context.save()

        vm.prochaineActionInput = "  Poser le placo  "
        vm.saveProchaineAction(for: tache)

        #expect(tache.prochaineAction == "Poser le placo")
    }

    @Test("saveProchaineAction does nothing when input is blank")
    func saveProchaineActionIgnoresBlank() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = makeTache(in: context)
        tache.prochaineAction = "Ancienne action"
        try context.save()

        vm.prochaineActionInput = "   "
        vm.saveProchaineAction(for: tache)

        // Should not overwrite existing value with blank
        #expect(tache.prochaineAction == "Ancienne action")
    }

    // MARK: - markTaskAsTerminee

    @Test("markTaskAsTerminee sets statut to .terminee and persists")
    func markTaskAsTermineeUpdatesStatut() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = makeTache(in: context)
        #expect(tache.statut == .active)
        try context.save()

        vm.markTaskAsTerminee(tache)

        #expect(vm.checkoutError == nil)
        #expect(tache.statut == .terminee)

        let taches = try context.fetch(FetchDescriptor<TacheEntity>())
        #expect(taches.first?.statut == .terminee)
    }

    @Test("markTaskAsTerminee does not affect other tasks")
    func markTaskAsTermineeIsolated() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let t1 = TacheEntity(titre: "Tache 1")
        let t2 = TacheEntity(titre: "Tache 2")
        context.insert(t1)
        context.insert(t2)
        try context.save()

        vm.markTaskAsTerminee(t1)

        #expect(t1.statut == .terminee)
        #expect(t2.statut == .active)
    }

    // MARK: - tacheCourante

    @Test("charger sets tacheCourante from first capture's tache")
    func chargerSetsTacheCourante() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = makeTache(in: context)
        let capture = makeCapture(tache: tache, in: context)
        _ = capture
        try context.save()

        vm.charger()

        #expect(vm.tacheCourante?.titre == tache.titre)
    }

    @Test("charger sets tacheCourante to nil when no captures")
    func chargerSetsTacheCouranteNilWhenEmpty() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        vm.charger()

        #expect(vm.tacheCourante == nil)
    }
}
