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
                ToDoEntity.self, AchatEntity.self, CaptureEntity.self,
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

    @Test("classify toDo appends summary item with toDo type")
    func classifyToDoAppendsSummaryItem() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let piece = PieceEntity(nom: "Salon")
        context.insert(piece)
        let tache = makeTache(in: context)
        tache.piece = piece
        let capture = makeCapture(texte: "ToDo chantier", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .toDo(.urgent))

        #expect(vm.summaryItems.count == 1)
        if case .toDo(let p) = vm.summaryItems[0].type {
            #expect(p == .urgent)
        } else {
            Issue.record("Expected .toDo(.urgent) type")
        }
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
        let piece = PieceEntity(nom: "Salon")
        context.insert(piece)
        let tache = makeTache(in: context)
        tache.piece = piece
        let c1 = makeCapture(texte: "Un", tache: tache, in: context)
        let c2 = makeCapture(texte: "Deux", tache: tache, in: context)
        let c3 = makeCapture(texte: "Trois", in: context)
        try context.save()

        vm.charger()
        vm.classify(c1, as: .alerte)
        vm.classify(c2, as: .toDo(.bientot))
        vm.classify(c3, as: .achat)

        #expect(vm.summaryItems.count == 3)
    }

    // MARK: - reclassify

    @Test("reclassify alerte to toDo creates ToDoEntity and removes AlerteEntity")
    func reclassifyChangesType() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let piece = PieceEntity(nom: "Salon")
        context.insert(piece)
        let tache = makeTache(in: context)
        tache.piece = piece
        let capture = makeCapture(texte: "A reclassifier", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .alerte)
        #expect(vm.summaryItems.count == 1)

        let item = vm.summaryItems[0]
        vm.reclassify(item: item, newType: .toDo(.bientot))

        #expect(vm.summaryItems.count == 1)
        if case .toDo(let p) = vm.summaryItems[0].type {
            #expect(p == .bientot)
        } else {
            Issue.record("Expected .toDo(.bientot) after reclassify")
        }
        let alertes = try context.fetch(FetchDescriptor<AlerteEntity>())
        #expect(alertes.isEmpty)
        let todos = try context.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.count == 1)
    }

    @Test("reclassify preserves original blocksData in new ToDoEntity")
    func reclassifyPreservesBlocksData() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let piece = PieceEntity(nom: "Buanderie")
        context.insert(piece)
        let tache = makeTache(in: context)
        tache.piece = piece
        let capture = makeCapture(texte: "Contenu original", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .alerte)

        let item = vm.summaryItems[0]
        vm.reclassify(item: item, newType: .toDo(.urgent))

        let todos = try context.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.count == 1)
        #expect(todos[0].titre == "Contenu original")
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

    @Test("reclassify toDo to achat creates AchatEntity with transcription text")
    func reclassifyToAchat() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        _ = makeLDC(in: context)
        let piece = PieceEntity(nom: "Garage")
        context.insert(piece)
        let tache = makeTache(in: context)
        tache.piece = piece
        let capture = makeCapture(texte: "Visses bois 4mm", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .toDo(.unJour))
        let item = vm.summaryItems[0]
        vm.reclassify(item: item, newType: .achat)

        let achats = try context.fetch(FetchDescriptor<AchatEntity>())
        #expect(achats.count == 1)
        #expect(achats[0].texte == "Visses bois 4mm")
    }

    // MARK: - validateClassifications

    @Test("validateClassifications returns false when captures remain (not yet classified)")
    func validateFalseWhenCapturesRemain() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        // A capture still in store = not yet classified (classify() deletes it)
        let capture = CaptureEntity()
        context.insert(capture)
        try context.save()

        #expect(vm.validateClassifications() == false)
    }

    @Test("validateClassifications returns true when all captures are deleted (all classified)")
    func validateTrueWhenAllClassified() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        // Insert then delete — simulates classify() deleting the capture
        let capture = CaptureEntity()
        context.insert(capture)
        try context.save()
        context.delete(capture)
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

    // MARK: - reclassify when LDC absent (create-before-delete safety)

    @Test("reclassify to achat without LDC sets reclassifyError and leaves summaryItems unchanged")
    func reclassifyToAchatWithoutLDCSetsError() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        // No LDC inserted intentionally
        let tache = makeTache(in: context)
        let capture = makeCapture(texte: "Chevilles sans LDC", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .alerte)
        #expect(vm.summaryItems.count == 1)

        let item = vm.summaryItems[0]
        vm.reclassify(item: item, newType: .achat)

        // Error must be set
        #expect(vm.reclassifyError != nil)
        // summaryItems must remain unchanged (still alerte, not updated)
        #expect(vm.summaryItems.count == 1)
        if case .alerte = vm.summaryItems[0].type {} else {
            Issue.record("summaryItems should still show .alerte after failed reclassify")
        }
    }

    @Test("reclassify to achat without LDC does not delete the original AlerteEntity")
    func reclassifyToAchatWithoutLDCPreservesOldEntity() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        // No LDC inserted intentionally
        let tache = makeTache(in: context)
        let capture = makeCapture(texte: "Données à préserver", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .alerte)

        let item = vm.summaryItems[0]
        vm.reclassify(item: item, newType: .achat)

        // AlerteEntity must still be in the store (create-before-delete guarantee)
        let alertes = try context.fetch(FetchDescriptor<AlerteEntity>())
        #expect(alertes.count == 1, "AlerteEntity must not be deleted when reclassify guard fails")
        // No AchatEntity must have been created
        let achats = try context.fetch(FetchDescriptor<AchatEntity>())
        #expect(achats.isEmpty)
    }

    // MARK: - reclassify ASTUCE → different ASTUCE level

    @Test("reclassify astuce critique to astuce utile creates new AstuceEntity with correct niveau")
    func reclassifyAstuceCritiqueToUtile() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let activite = ActiviteEntity(nom: "Électricité")
        context.insert(activite)
        let tache = makeTache(in: context)
        tache.activite = activite
        let capture = makeCapture(texte: "Astuce niveaux", tache: tache, in: context)
        try context.save()

        vm.charger()
        vm.classify(capture, as: .astuce(.critique))

        let item = vm.summaryItems[0]
        vm.reclassify(item: item, newType: .astuce(.utile))

        if case .astuce(let niveau) = vm.summaryItems[0].type {
            #expect(niveau == .utile)
        } else {
            Issue.record("Expected .astuce(.utile) after reclassify")
        }
        let astuces = try context.fetch(FetchDescriptor<AstuceEntity>())
        #expect(astuces.count == 1)
        #expect(astuces[0].niveau == .utile)
    }

    // MARK: - tacheCourante (Story 3.3 bug fix: uses loaded.last, not loaded.first)

    @Test("charger sets tacheCourante from single capture's tache")
    func chargerSetsTacheCourante() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let tache = makeTache(in: context)
        _ = makeCapture(tache: tache, in: context)
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

    @Test("charger sets tacheCourante from LAST capture — picks active task after task switch")
    func chargerSetsTacheCouranteFromLastCapture() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        // Simulate task switch: Tache A (older captures) → Tache B (most recent capture)
        let tacheA = TacheEntity(titre: "Tâche A — ancienne")
        let tacheB = TacheEntity(titre: "Tâche B — dernière active")
        context.insert(tacheA)
        context.insert(tacheB)

        let captureA = CaptureEntity()
        captureA.tache = tacheA
        captureA.createdAt = Date().addingTimeInterval(-60)  // 1 min ago
        context.insert(captureA)

        let captureB = CaptureEntity()
        captureB.tache = tacheB
        captureB.createdAt = Date()                          // now (most recent)
        context.insert(captureB)

        try context.save()
        vm.charger()

        // tacheCourante must be Tache B — the task active at end of session
        #expect(vm.tacheCourante?.titre == tacheB.titre)
    }

    // MARK: - saveProchaineAction — duplicate ToDo detection (exact match)

    @Test("saveProchaineAction sets alreadyUrgent when exact same title already urgent")
    func saveProchaineActionExactMatchAlreadyUrgent() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let piece = PieceEntity(nom: "Salon")
        context.insert(piece)
        let tache = TacheEntity(titre: "Salon — Peinture")
        tache.piece = piece
        context.insert(tache)

        // Pre-existing urgent ToDo with the exact same title
        let existing = ToDoEntity(titre: "Repeindre le plafond", priorite: .urgent, piece: piece)
        context.insert(existing)
        try context.save()

        vm.prochaineActionInput = "Repeindre le plafond"
        vm.saveProchaineAction(for: tache)

        guard case .alreadyUrgent(let todo, let titre) = vm.pendingToDoDecision else {
            Issue.record("Expected .alreadyUrgent, got \(String(describing: vm.pendingToDoDecision))")
            return
        }
        #expect(todo.id == existing.id)
        #expect(titre == "Repeindre le plafond")
    }

    @Test("saveProchaineAction sets alreadyUrgent for case-insensitive exact match")
    func saveProchaineActionExactMatchCaseInsensitive() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let piece = PieceEntity(nom: "Cuisine")
        context.insert(piece)
        let tache = TacheEntity(titre: "Cuisine — Carrelage")
        tache.piece = piece
        context.insert(tache)

        let existing = ToDoEntity(titre: "Poser le carrelage", priorite: .urgent, piece: piece)
        context.insert(existing)
        try context.save()

        vm.prochaineActionInput = "poser le carrelage"
        vm.saveProchaineAction(for: tache)

        guard case .alreadyUrgent = vm.pendingToDoDecision else {
            Issue.record("Expected .alreadyUrgent for case-insensitive match")
            return
        }
    }

    @Test("saveProchaineAction sets upgradeToUrgent for exact match not yet urgent")
    func saveProchaineActionExactMatchNotUrgent() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let piece = PieceEntity(nom: "Buanderie")
        context.insert(piece)
        let tache = TacheEntity(titre: "Buanderie — Plomberie")
        tache.piece = piece
        context.insert(tache)

        let existing = ToDoEntity(titre: "Réparer la fuite", priorite: .bientot, piece: piece)
        context.insert(existing)
        try context.save()

        vm.prochaineActionInput = "Réparer la fuite"
        vm.saveProchaineAction(for: tache)

        guard case .upgradeToUrgent = vm.pendingToDoDecision else {
            Issue.record("Expected .upgradeToUrgent for bientot exact match")
            return
        }
    }

    @Test("saveProchaineAction creates new ToDo when no match found")
    func saveProchaineActionNoMatchCreatesToDo() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = ClassificationViewModel(modelContext: context)

        let piece = PieceEntity(nom: "Chambre")
        context.insert(piece)
        let tache = TacheEntity(titre: "Chambre — Peinture")
        tache.piece = piece
        context.insert(tache)
        try context.save()

        vm.prochaineActionInput = "Peindre les murs"
        vm.saveProchaineAction(for: tache)

        #expect(vm.pendingToDoDecision == nil)
        let todos = try context.fetch(FetchDescriptor<ToDoEntity>())
        #expect(todos.count == 1)
        #expect(todos[0].titre == "Peindre les murs")
        #expect(todos[0].priorite == .urgent)
    }
}
